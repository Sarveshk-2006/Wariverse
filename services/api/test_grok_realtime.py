import pytest
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient
from main import app
from auth import get_current_user
from models import User, UserRole
from config import get_settings

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
    settings = get_settings()
    old_key = settings.XAI_API_KEY
    settings.XAI_API_KEY = "test_xai_key_xyz"

    import httpx
    from unittest.mock import MagicMock

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "id": "grok_sess_test_123",
        "ws_url": "wss://api.x.ai/v1/realtime?session_id=grok_sess_test_123",
        "client_secret": {"value": "eph_token_abc_456"}
    }

    try:
        with patch.object(httpx.AsyncClient, "post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
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
        settings.XAI_API_KEY = old_key
        app.dependency_overrides.clear()
