from pydantic import BaseModel, Field
from typing import Optional, Any, Dict
from enum import Enum

class RealtimeEventType(str, Enum):
    DINDI_LOCATION_UPDATED = "DINDI_LOCATION_UPDATED"
    DINDI_BROADCAST_CREATED = "DINDI_BROADCAST_CREATED"
    DINDI_POST_CREATED = "DINDI_POST_CREATED"
    SOS_CREATED = "SOS_CREATED"
    SOS_LOCATION_UPDATED = "SOS_LOCATION_UPDATED"
    SOS_STATUS_CHANGED = "SOS_STATUS_CHANGED"
    RESPONDER_ASSIGNED = "RESPONDER_ASSIGNED"
    RESPONDER_LOCATION_UPDATED = "RESPONDER_LOCATION_UPDATED"
    WEATHER_ALERT_CREATED = "WEATHER_ALERT_CREATED"

class DindiLocationUpdatedPayload(BaseModel):
    dindi_id: str
    latitude: float
    longitude: float
    speed_kmh: Optional[float] = 0.0
    is_beacon_active: bool = True

class DindiBroadcastCreatedPayload(BaseModel):
    dindi_id: str
    stream_id: str
    title: str
    audio_url: str

class DindiPostCreatedPayload(BaseModel):
    dindi_id: str
    post_id: str
    author_name: str
    message: str
    is_announcement: bool = False

class SosCreatedPayload(BaseModel):
    sos_id: str
    user_id: str
    category: str
    latitude: float
    longitude: float

class SosLocationUpdatedPayload(BaseModel):
    sos_id: str
    latitude: float
    longitude: float

class SosStatusChangedPayload(BaseModel):
    sos_id: str
    old_status: str
    new_status: str

class ResponderAssignedPayload(BaseModel):
    sos_id: str
    responder_id: str
    responder_role: str

class ResponderLocationUpdatedPayload(BaseModel):
    sos_id: str
    responder_id: str
    latitude: float
    longitude: float

class WeatherAlertCreatedPayload(BaseModel):
    alert_id: str
    alert_type: str
    severity: str
    message: str

class RealtimeEventEnvelope(BaseModel):
    event_type: RealtimeEventType
    entity_id: str
    actor_id: str
    dindi_id: Optional[str] = None
    timestamp: str
    payload: Dict[str, Any]
    authorization_scope: str = "AUTHENTICATED"
    version: str = "1.0"
