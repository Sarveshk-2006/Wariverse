import pytest
from fastapi.testclient import TestClient
from main import app
from auth import get_current_user
from models import User, UserRole

client = TestClient(app)

def mock_get_current_user():
    return User(
        id="user_varkari_001",
        email="varkari@wariverse.app",
        hashed_password="pw",
        role=UserRole.VARKARI,
        is_active=True,
    )

def test_grok_session_requires_auth():
    """Unauthenticated requests to Grok Realtime session endpoint must return 401."""
    app.dependency_overrides.clear()
    response = client.post("/api/v1/realtime/grok-session", json={})
    assert response.status_code == 401

def test_grok_session_authorized():
    """Authenticated Varkari user receives a temporary Grok Realtime session token."""
    app.dependency_overrides[get_current_user] = mock_get_current_user
    try:
        response = client.post(
            "/api/v1/realtime/grok-session",
            json={"voice": "ara", "language": "mr_IN"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "session_id" in data
        assert "ws_url" in data
        assert "ephemeral_token" in data
        assert data["model"] == "grok-2-realtime"
        assert data["voice"] == "ara"
        assert "Pandharpur Wari" in data["default_instructions"]
        # Verify that secret API key is never exposed in response body
        assert "XAI_API_KEY" not in str(data)
    finally:
        app.dependency_overrides.clear()
