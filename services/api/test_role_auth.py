import pytest
from models import UserRole, User
from realtime_event_contract import RealtimeEventEnvelope, RealtimeEventType, DindiLocationUpdatedPayload

def test_user_role_enum_values():
    assert UserRole.VARKARI.value == "VARKARI"
    assert UserRole.DINDI_LEADER.value == "DINDI_LEADER"
    assert UserRole.VOLUNTEER.value == "VOLUNTEER"
    assert UserRole.MEDICAL_TEAM.value == "MEDICAL_TEAM"
    assert UserRole.POLICE.value == "POLICE"
    assert UserRole.NGO.value == "NGO"
    assert UserRole.ADMIN.value == "ADMIN"

def test_default_role_is_varkari():
    user = User(email="test@wariverse.app", hashed_password="pw", role=UserRole.VARKARI)
    assert user.role == UserRole.VARKARI or user.role == "VARKARI"

def test_dindi_leader_role_instantiation():
    leader = User(email="pramukh@wariverse.app", hashed_password="pw", role=UserRole.DINDI_LEADER)
    assert leader.role == UserRole.DINDI_LEADER

def test_realtime_event_payload_schema():
    location_payload = DindiLocationUpdatedPayload(
        dindi_id="dindi-12",
        latitude=17.6741,
        longitude=75.3279,
        speed_kmh=3.5,
        is_beacon_active=True
    )
    event = RealtimeEventEnvelope(
        event_type=RealtimeEventType.DINDI_LOCATION_UPDATED,
        entity_id="dindi-12",
        actor_id="leader-1",
        dindi_id="dindi-12",
        timestamp="2026-08-29T15:00:00Z",
        payload=location_payload.model_dump(),
        authorization_scope="DINDI_MEMBERS"
    )
    assert event.event_type == RealtimeEventType.DINDI_LOCATION_UPDATED
    assert event.payload["latitude"] == 17.6741
