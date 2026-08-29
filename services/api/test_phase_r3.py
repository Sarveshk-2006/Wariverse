import pytest
from notifications import OneSignalNotificationProvider, SmsProvider, NotificationEventType, notification_service

@pytest.mark.asyncio
async def test_onesignal_provider_skipped_when_disabled():
    provider = OneSignalNotificationProvider()
    res = await provider.send_emergency_alert(
        player_ids=[],
        title="Test",
        message="Test message"
    )
    assert res["status"] == "SKIPPED"

@pytest.mark.asyncio
async def test_onesignal_notification_event_payload():
    provider = OneSignalNotificationProvider()
    res = await provider.send_notification_event(
        event_type=NotificationEventType.DINDI_BROADCAST,
        player_ids=["fake-player-id"],
        title="Dindi Announcement",
        message="Palkhi has reached Akurdi.",
        route="/dindi-community",
        extra_data={"dindi_id": "dindi-1"}
    )
    assert res["status"] in ["SKIPPED", "FAILED"]

@pytest.mark.asyncio
async def test_sms_provider_disabled_without_credentials():
    provider = SmsProvider()
    res = await provider.send_sms(phone_number="+919876543210", message="Test")
    assert res["status"] in ["NOT_CONFIGURED", "DISABLED"]

@pytest.mark.asyncio
async def test_emergency_notification_service_truthful_sms_status():
    deliveries = await notification_service.dispatch_sos_alerts(
        sos_id="test-sos-id",
        user_name="Varkari Test",
        contacts=[{"id": "c1", "phone_number": "+919876543210"}],
        latitude=18.5204,
        longitude=73.8567
    )
    assert len(deliveries) == 1
    assert deliveries[0]["channel"] == "SMS"
    assert deliveries[0]["status"] in ["DISABLED", "NOT_CONFIGURED"]
