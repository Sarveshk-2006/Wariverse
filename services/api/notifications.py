import os
import logging
import httpx
from enum import Enum
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone

logger = logging.getLogger("EmergencyNotificationService")

class NotificationEventType(str, Enum):
    DINDI_BROADCAST = "DINDI_BROADCAST"
    SOS_CREATED = "SOS_CREATED"
    SOS_UPDATED = "SOS_UPDATED"
    SOS_RESPONDER_ASSIGNED = "SOS_RESPONDER_ASSIGNED"
    WEATHER_WARNING = "WEATHER_WARNING"
    LOST_PERSON_ALERT = "LOST_PERSON_ALERT"
    CLEANWARI_ALERT = "CLEANWARI_ALERT"
    SYSTEM_ALERT = "SYSTEM_ALERT"

class OneSignalNotificationProvider:
    """Production provider sending push notifications via OneSignal REST API."""

    def __init__(self):
        self.app_id = os.getenv("ONESIGNAL_APP_ID", "")
        self.rest_api_key = os.getenv("ONESIGNAL_REST_API_KEY", "")
        self.enabled = os.getenv("ONESIGNAL_ENABLED", "false").lower() == "true"

    async def send_emergency_alert(
        self,
        player_ids: List[str],
        title: str,
        message: str,
        deep_link: Optional[str] = None
    ) -> Dict[str, Any]:
        return await self.send_notification_event(
            event_type=NotificationEventType.SOS_CREATED,
            player_ids=player_ids,
            title=title,
            message=message,
            route="/sos",
            extra_data={"deep_link": deep_link or "wariverse://sos"}
        )

    async def send_notification_event(
        self,
        event_type: NotificationEventType,
        player_ids: List[str],
        title: str,
        message: str,
        route: str = "/sos",
        extra_data: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        if not self.enabled or not self.app_id or not self.rest_api_key or not player_ids:
            logger.info(f"OneSignal push ({event_type.value}) skipped: not enabled or missing player_ids/keys.")
            return {"status": "SKIPPED", "recipients": 0}

        headers = {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": f"Basic {self.rest_api_key}",
        }
        data_payload = {
            "type": event_type.value,
            "route": route,
        }
        if extra_data:
            data_payload.update(extra_data)

        payload = {
            "app_id": self.app_id,
            "include_player_ids": player_ids,
            "headings": {"en": title},
            "contents": {"en": message},
            "data": data_payload,
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post("https://onesignal.com/api/v1/notifications", json=payload, headers=headers)
                if resp.status_code == 200:
                    data = resp.json()
                    logger.info(f"OneSignal push ({event_type.value}) sent: {data.get('id')}")
                    return {"status": "SENT", "id": data.get("id"), "recipients": len(player_ids)}
                else:
                    logger.error(f"OneSignal push error ({resp.status_code}): {resp.text}")
                    return {"status": "FAILED", "error": resp.text}
        except Exception as e:
            logger.error(f"Exception sending OneSignal notification: {e}")
            return {"status": "FAILED", "error": str(e)}


class SmsProvider:
    """Production HTTP provider for SMS emergency alert delivery."""

    def __init__(self):
        self.enabled = os.getenv("SMS_ENABLED", "false").lower() == "true"
        self.api_key = os.getenv("SMS_PROVIDER_API_KEY", "")
        self.sender_id = os.getenv("SMS_PROVIDER_SENDER_ID", "WARISOS")
        self.base_url = os.getenv("SMS_PROVIDER_BASE_URL", "")

    async def send_sms(self, phone_number: str, message: str) -> Dict[str, Any]:
        if not self.enabled or not self.api_key:
            logger.info("SMS service not configured in environment (SMS_ENABLED=false or SMS_PROVIDER_API_KEY missing).")
            return {"status": "NOT_CONFIGURED", "reason": "SMS service is not configured in environment"}

        cleaned_phone = phone_number.replace(" ", "").replace("-", "")
        if not cleaned_phone:
            return {"status": "FAILED", "error": "Invalid empty phone number"}

        if not cleaned_phone.startswith("+91") and len(cleaned_phone) == 10:
            cleaned_phone = f"+91{cleaned_phone}"

        payload = {
            "apiKey": self.api_key,
            "sender": self.sender_id,
            "number": cleaned_phone,
            "message": message,
        }

        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                target_url = self.base_url or "https://api.sms-provider.com/v1/send"
                resp = await client.post(target_url, json=payload)
                if resp.status_code == 200:
                    data = resp.json()
                    logger.info(f"SMS request accepted by gateway for {cleaned_phone[-4:]}")
                    return {"status": "SENT", "message_id": data.get("message_id")}
                else:
                    logger.error(f"SMS gateway error ({resp.status_code}): {resp.text}")
                    return {"status": "FAILED", "error": resp.text}
        except Exception as e:
            logger.error(f"Exception sending SMS: {e}")
            return {"status": "FAILED", "error": str(e)}


class EmergencyNotificationService:
    """Orchestrates push and SMS notification delivery for emergency alerts."""

    def __init__(self):
        self.onesignal = OneSignalNotificationProvider()
        self.sms = SmsProvider()

    async def dispatch_sos_alerts(
        self,
        sos_id: str,
        user_name: str,
        contacts: List[Dict[str, Any]],
        latitude: float,
        longitude: float,
        category: str = "MEDICAL"
    ) -> List[Dict[str, Any]]:
        deliveries = []
        maps_link = f"https://www.google.com/maps?q={latitude},{longitude}"
        msg = (
            f"🚨 WariVerse SOS ALERT\n\n"
            f"{user_name} has activated an emergency SOS.\n\n"
            f"Type: {category}\n\n"
            f"Current location:\n{maps_link}\n\n"
            f"Incident Ref: WV-SOS-{sos_id[:8].upper()}\n\n"
            f"Please contact them immediately."
        )

        for contact in contacts:
            contact_id = contact.get("id", "")
            phone = contact.get("phone_number", "")
            player_id = contact.get("onesignal_player_id")

            if player_id:
                push_res = await self.onesignal.send_notification_event(
                    event_type=NotificationEventType.SOS_CREATED,
                    player_ids=[player_id],
                    title="🚨 WariVerse SOS Alert",
                    message=msg,
                    route="/sos",
                    extra_data={"incident_id": sos_id}
                )
                deliveries.append({
                    "sos_id": sos_id,
                    "emergency_contact_id": contact_id,
                    "channel": "PUSH",
                    "provider": "ONESIGNAL",
                    "status": push_res.get("status", "FAILED"),
                    "provider_message_id": push_res.get("id"),
                    "created_at": datetime.now(timezone.utc).isoformat(),
                })
            else:
                sms_res = await self.sms.send_sms(phone_number=phone, message=msg)
                deliveries.append({
                    "sos_id": sos_id,
                    "emergency_contact_id": contact_id,
                    "channel": "SMS",
                    "provider": "SMS_GATEWAY",
                    "status": sms_res.get("status", "NOT_CONFIGURED"),
                    "provider_message_id": sms_res.get("message_id"),
                    "error_message": sms_res.get("error") or sms_res.get("reason"),
                    "created_at": datetime.now(timezone.utc).isoformat(),
                })

        return deliveries

notification_service = EmergencyNotificationService()
