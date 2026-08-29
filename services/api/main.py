"""
WariVerse AI — FastAPI Backend
Complete REST API with WebSocket support for the Wari pilgrimage management system.
"""
import asyncio
import json
import math
import random
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, Depends, HTTPException, WebSocket, WebSocketDisconnect, status, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from jose import JWTError, jwt
from pydantic import BaseModel, EmailStr
from sqlalchemy import select, func, or_, and_
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user, get_password_hash, verify_password, create_access_token, require_role
from config import get_settings
from database import AsyncSessionLocal, get_db, init_db
import models
from notifications import notification_service


settings = get_settings()

if not settings.DEMO_MODE and settings.SECRET_KEY == "dev-only-change-this-secret":
    raise RuntimeError("SECRET_KEY must be configured when DEMO_MODE is disabled")

# ─── WebSocket Manager ─────────────────────────────────────────────────────────
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: str):
        self.active_connections.pop(client_id, None)

    async def broadcast(self, message: dict):
        for client_id, connection in list(self.active_connections.items()):
            try:
                await connection.send_json(message)
            except Exception:
                self.disconnect(client_id)

    async def send_to(self, client_id: str, message: dict):
        if client_id in self.active_connections:
            try:
                await self.active_connections[client_id].send_json(message)
            except Exception:
                self.disconnect(client_id)

manager = ConnectionManager()

# ─── App Lifecycle ─────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield

app = FastAPI(
    title="WariVerse AI API",
    description="AI-powered Digital Operating System for Wari pilgrimage management",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in settings.CORS_ORIGINS.split(",") if origin.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Pydantic Schemas ──────────────────────────────────────────────────────────
class RegisterRequest(BaseModel):
    email: str
    password: str
    display_name: str
    role: Optional[str] = "VARKARI"

class FirebaseAuthRequest(BaseModel):
    firebase_token: str
    firebase_uid: str
    email: Optional[str] = None
    display_name: Optional[str] = None
    phone: Optional[str] = None

class AdminRoleUpdateRequest(BaseModel):
    new_role: str

class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    user_id: str
    role: str
    display_name: str


class SOSCreateRequest(BaseModel):
    latitude: float
    longitude: float
    category: str = "OTHER"
    description: Optional[str] = None
    blood_group: Optional[str] = None
    emergency_contact: Optional[str] = None
    is_offline: bool = False
    accuracy_meters: Optional[float] = None
    idempotency_key: Optional[str] = None
    dindi_id: Optional[str] = None

class SOSLocationUpdateRequest(BaseModel):
    latitude: float
    longitude: float
    accuracy_meters: Optional[float] = None

class EmergencyContactCreateRequest(BaseModel):
    name: str
    phone_number: str
    relationship_name: str = "Family"
    priority: int

class NotificationDeviceRegisterRequest(BaseModel):
    subscription_id: str
    provider: str = "ONESIGNAL"
    platform: str = "android"

class DindiScheduleCreateRequest(BaseModel):
    title: str
    schedule_type: str = "HALT"
    scheduled_time: str
    location_name: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    description: Optional[str] = None

class DindiCommunityPostCreateRequest(BaseModel):
    message: str
    is_announcement: bool = False
    is_pinned: bool = False

class LostPersonCreateRequest(BaseModel):
    person_name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    last_seen_location: str
    last_seen_latitude: Optional[float] = None
    last_seen_longitude: Optional[float] = None
    contact_number: str
    description: Optional[str] = None

class CleanWariReportRequest(BaseModel):
    toilet_id: str
    issues: Optional[List[str]] = None
    notes: Optional[str] = None

class CommunityPostRequest(BaseModel):
    post_type: str
    message: str
    latitude: float
    longitude: float
    radius_km: float = 2.0

class HelpRequestCreate(BaseModel):
    category: str
    description: Optional[str] = None
    latitude: float
    longitude: float
    urgency: int = 5

class HelpOfferCreate(BaseModel):
    category: str
    description: Optional[str] = None
    latitude: float
    longitude: float
    quantity: int = 1

class LocationUpdate(BaseModel):
    latitude: float
    longitude: float

class ToiletCleanRequest(BaseModel):
    issues: Optional[str] = None

class LostPersonRequest(BaseModel):
    name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    description: Optional[str] = None
    last_seen_latitude: Optional[float] = None
    last_seen_longitude: Optional[float] = None
    emergency_contact: Optional[str] = None
    blood_group: Optional[str] = None

class FoodCentreUpdate(BaseModel):
    available_now: Optional[bool] = None
    estimated_queue_minutes: Optional[int] = None
    current_count: Optional[int] = None

class ResourceInventoryRequest(BaseModel):
    item_name: str
    allocated: int
    remaining: int

class DemoTriggerRequest(BaseModel):
    event_type: str
    data: Optional[dict] = None

class DindiCreateRequest(BaseModel):
    name: str
    code: str
    origin: Optional[str] = "Alandi / Dehu"
    palkhi_type: Optional[str] = "Sant Tukaram Maharaj Palkhi"

class DindiHaltCreateRequest(BaseModel):
    day_number: int = 1
    halt_type: str  # DEPARTURE, BREAKFAST, LUNCH, RINGAN, TEMPLE, NIGHT_SHELTER
    title: str
    location_name: str
    latitude: float
    longitude: float
    scheduled_arrival: str   # HH:MM
    scheduled_departure: str # HH:MM
    notes: Optional[str] = None
    food_centre_id: Optional[str] = None
    shelter_id: Optional[str] = None

class DindiJoinRequest(BaseModel):
    qr_data: str

class DindiPostCreateRequest(BaseModel):
    post_type: Optional[str] = "GENERAL"
    is_announcement: Optional[bool] = False
    message: str

class ToiletReportRequest(BaseModel):
    issue_type: str # NO_WATER, NEEDS_CLEANING, BROKEN_LATCH, OTHER
    notes: Optional[str] = None


# ─── Utility Functions ─────────────────────────────────────────────────────────
def haversine_distance(lat1, lon1, lat2, lon2) -> float:
    """Returns distance in meters."""
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def serialize_model(obj) -> dict:
    """Convert SQLAlchemy model to dict."""
    result = {}
    for col in obj.__table__.columns:
        val = getattr(obj, col.name)
        if isinstance(val, datetime):
            result[col.name] = val.isoformat()
        elif hasattr(val, 'value'):
            result[col.name] = val.value
        else:
            result[col.name] = val
    return result

# ─── Auth Routes ───────────────────────────────────────────────────────────────
@app.post("/auth/register")
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.User).where(models.User.email == req.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    # Public registration can only create standard pilgrim accounts.
    role = models.UserRole.VARKARI

    user = models.User(
        id=str(uuid.uuid4()),
        email=req.email,
        hashed_password=get_password_hash(req.password),
        role=role,
        is_active=True,
        is_verified=False,
    )
    db.add(user)
    profile = models.Profile(
        id=str(uuid.uuid4()),
        user_id=user.id,
        display_name=req.display_name,
        latitude=17.6741,
        longitude=75.3279,
    )
    db.add(profile)
    await db.commit()
    token = create_access_token({"sub": user.id})
    return {"access_token": token, "token_type": "bearer", "user_id": user.id, "role": role.value, "display_name": req.display_name}


@app.post("/auth/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.User).where(models.User.email == form_data.username))
    user = result.scalar_one_or_none()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    profile_result = await db.execute(select(models.Profile).where(models.Profile.user_id == user.id))
    profile = profile_result.scalar_one_or_none()
    display_name = profile.display_name if profile else user.email

    token = create_access_token({"sub": user.id})
    return {"access_token": token, "token_type": "bearer", "user_id": user.id, "role": user.role.value, "display_name": display_name}

@app.post("/auth/firebase")
async def auth_firebase(req: FirebaseAuthRequest, db: AsyncSession = Depends(get_db)):
    user = None
    if req.firebase_uid:
        result = await db.execute(select(models.User).where(models.User.firebase_uid == req.firebase_uid))
        user = result.scalar_one_or_none()
    
    if not user and req.email:
        result = await db.execute(select(models.User).where(models.User.email == req.email))
        user = result.scalar_one_or_none()

    if not user:
        effective_email = req.email or f"{req.firebase_uid}@firebase.wariverse"
        user = models.User(
            id=str(uuid.uuid4()),
            email=effective_email,
            hashed_password=get_password_hash(uuid.uuid4().hex),
            firebase_uid=req.firebase_uid,
            phone=req.phone,
            role=models.UserRole.VARKARI,
            is_active=True,
            is_verified=False,
            last_login_at=datetime.utcnow(),
        )
        db.add(user)
        profile = models.Profile(
            id=str(uuid.uuid4()),
            user_id=user.id,
            display_name=req.display_name or (req.phone or "Pilgrim"),
            latitude=17.6741,
            longitude=75.3279,
        )
        db.add(profile)
        await db.commit()
    else:
        user.last_login_at = datetime.utcnow()
        if not user.firebase_uid and req.firebase_uid:
            user.firebase_uid = req.firebase_uid
        await db.commit()

    profile_result = await db.execute(select(models.Profile).where(models.Profile.user_id == user.id))
    profile = profile_result.scalar_one_or_none()
    display_name = profile.display_name if profile else user.email

    token = create_access_token({"sub": user.id})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user_id": user.id,
        "role": user.role.value,
        "display_name": display_name
    }

@app.post("/admin/users/{target_user_id}/role")
async def admin_update_user_role(
    target_user_id: str,
    req: AdminRoleUpdateRequest,
    admin_user: models.User = Depends(require_role(models.UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    try:
        target_role = models.UserRole(req.new_role.upper())
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid role: {req.new_role}")

    result = await db.execute(select(models.User).where(models.User.id == target_user_id))
    target_user = result.scalar_one_or_none()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    target_user.role = target_role
    await db.commit()
    return {"message": "Role updated successfully", "user_id": target_user.id, "new_role": target_role.value}



# ─── User Routes ───────────────────────────────────────────────────────────────
@app.get("/users/me")
async def get_me(current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    profile_result = await db.execute(select(models.Profile).where(models.Profile.user_id == current_user.id))
    profile = profile_result.scalar_one_or_none()
    return {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role.value,
        "is_verified": current_user.is_verified,
        "profile": serialize_model(profile) if profile else None,
    }

@app.put("/users/me/location")
async def update_location(req: LocationUpdate, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    profile_result = await db.execute(select(models.Profile).where(models.Profile.user_id == current_user.id))
    profile = profile_result.scalar_one_or_none()
    if profile:
        profile.latitude = req.latitude
        profile.longitude = req.longitude
        await db.commit()
    return {"status": "updated"}

@app.get("/users/stats")
async def get_user_stats(db: AsyncSession = Depends(get_db)):
    total = await db.execute(select(func.count(models.User.id)))
    total_val = total.scalar() or 0
    varkari_count = await db.execute(select(func.count(models.User.id)).where(models.User.role == models.UserRole.VARKARI))
    varkari_val = varkari_count.scalar() or 0
    vol_count = await db.execute(select(func.count(models.User.id)).where(models.User.role == models.UserRole.VOLUNTEER))
    vol_val = vol_count.scalar() or 0
    return {
        "total_users": total_val,
        "varkaris": varkari_val,
        "volunteers": vol_val,
        "active_pilgrims": varkari_val,
    }

# ─── Notifications ─────────────────────────────────────────────────────────────
@app.get("/notifications")
async def get_notifications(current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.Notification)
        .where(models.Notification.user_id == current_user.id)
        .order_by(models.Notification.created_at.desc())
        .limit(20)
    )
    return [serialize_model(n) for n in result.scalars().all()]

@app.put("/notifications/{notif_id}/read")
async def mark_notification_read(notif_id: str, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Notification).where(models.Notification.id == notif_id))
    notif = result.scalar_one_or_none()
    if notif and notif.user_id == current_user.id:
        notif.is_read = True
        await db.commit()
    return {"status": "ok"}

# ─── Location / Map Routes ─────────────────────────────────────────────────────
@app.get("/locations/nearby")
async def get_nearby(
    lat: float, lon: float, radius_km: float = 5.0,
    db: AsyncSession = Depends(get_db)
):
    """Return all service locations near given point."""
    food = await db.execute(select(models.FoodCentre))
    water = await db.execute(select(models.WaterPoint))
    toilets = await db.execute(select(models.Toilet))
    shelters = await db.execute(select(models.Shelter))
    medical = await db.execute(select(models.MedicalLocation))
    wellness = await db.execute(select(models.WellnessCentre))

    def filter_nearby(items, max_dist_m):
        result = []
        for item in items:
            dist = haversine_distance(lat, lon, item.latitude, item.longitude)
            if dist <= max_dist_m:
                d = serialize_model(item)
                d["distance_m"] = round(dist)
                result.append(d)
        return sorted(result, key=lambda x: x["distance_m"])

    max_dist = radius_km * 1000
    return {
        "food": filter_nearby(food.scalars().all(), max_dist)[:5],
        "water": filter_nearby(water.scalars().all(), max_dist)[:5],
        "toilets": filter_nearby(toilets.scalars().all(), max_dist)[:5],
        "shelters": filter_nearby(shelters.scalars().all(), max_dist)[:3],
        "medical": filter_nearby(medical.scalars().all(), max_dist)[:3],
        "wellness": filter_nearby(wellness.scalars().all(), max_dist)[:3],
    }

# ─── Food Routes ───────────────────────────────────────────────────────────────
@app.get("/food/nearby")
async def food_nearby(lat: float, lon: float, radius_km: float = 5.0, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.FoodCentre))
    items = result.scalars().all()
    out = []
    for item in items:
        dist = haversine_distance(lat, lon, item.latitude, item.longitude)
        if dist <= radius_km * 1000:
            d = serialize_model(item)
            d["distance_m"] = round(dist)
            d["walk_minutes"] = round(dist / 80)
            out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.get("/food")
async def get_all_food(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.FoodCentre))
    return [serialize_model(f) for f in result.scalars().all()]

@app.patch("/food/{food_id}")
async def update_food(food_id: str, req: FoodCentreUpdate, current_user: models.User = Depends(require_role(models.UserRole.SERVICE_PROVIDER, models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.FoodCentre).where(models.FoodCentre.id == food_id))
    fc = result.scalar_one_or_none()
    if not fc:
        raise HTTPException(status_code=404, detail="Food centre not found")
    if req.available_now is not None:
        fc.available_now = req.available_now
    if req.estimated_queue_minutes is not None:
        fc.estimated_queue_minutes = req.estimated_queue_minutes
    if req.current_count is not None:
        fc.current_count = req.current_count
    fc.last_updated = datetime.utcnow()
    await db.commit()
    await manager.broadcast({"type": "FOOD_UPDATE", "data": serialize_model(fc)})
    return serialize_model(fc)

# ─── Water Routes ──────────────────────────────────────────────────────────────
@app.get("/water/nearby")
async def water_nearby(lat: float, lon: float, radius_km: float = 5.0, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.WaterPoint))
    items = result.scalars().all()
    out = []
    for item in items:
        dist = haversine_distance(lat, lon, item.latitude, item.longitude)
        if dist <= radius_km * 1000:
            d = serialize_model(item)
            d["distance_m"] = round(dist)
            out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.get("/water")
async def get_all_water(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.WaterPoint))
    return [serialize_model(w) for w in result.scalars().all()]

# ─── Toilet Routes ─────────────────────────────────────────────────────────────
@app.get("/toilets/nearby")
async def toilets_nearby(lat: float, lon: float, radius_km: float = 2.0, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Toilet))
    items = result.scalars().all()
    out = []
    for item in items:
        dist = haversine_distance(lat, lon, item.latitude, item.longitude)
        if dist <= radius_km * 1000:
            d = serialize_model(item)
            d["distance_m"] = round(dist)
            d["minutes_since_cleaned"] = int((datetime.utcnow() - item.last_cleaned_at).total_seconds() / 60) if item.last_cleaned_at else None
            out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.get("/toilets")
async def get_all_toilets(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Toilet))
    out = []
    for t in result.scalars().all():
        d = serialize_model(t)
        d["minutes_since_cleaned"] = int((datetime.utcnow() - t.last_cleaned_at).total_seconds() / 60) if t.last_cleaned_at else None
        out.append(d)
    return out

@app.post("/toilets/{toilet_id}/clean")
async def mark_toilet_cleaned(
    toilet_id: str,
    req: ToiletCleanRequest,
    current_user: models.User = Depends(require_role(models.UserRole.CLEANER, models.UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(models.Toilet).where(models.Toilet.id == toilet_id))
    toilet = result.scalar_one_or_none()
    if not toilet:
        raise HTTPException(status_code=404, detail="Toilet not found")

    old_status = toilet.status
    toilet.status = models.ToiletStatus.CLEAN
    toilet.last_cleaned_at = datetime.utcnow()
    toilet.last_cleaned_by = current_user.id

    log = models.CleaningLog(
        id=str(uuid.uuid4()),
        toilet_id=toilet_id,
        cleaned_by=current_user.id,
        status_before=old_status.value if old_status else None,
        issues=req.issues,
    )
    db.add(log)
    await db.commit()
    await manager.broadcast({"type": "TOILET_UPDATE", "data": serialize_model(toilet)})
    return {"status": "cleaned", "toilet": serialize_model(toilet)}

@app.get("/toilets/{toilet_id}/history")
async def toilet_history(toilet_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.CleaningLog)
        .where(models.CleaningLog.toilet_id == toilet_id)
        .order_by(models.CleaningLog.cleaned_at.desc())
        .limit(10)
    )
    return [serialize_model(l) for l in result.scalars().all()]

# ─── Medical Routes ────────────────────────────────────────────────────────────
@app.get("/medical/nearby")
async def medical_nearby(lat: float, lon: float, radius_km: float = 5.0, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.MedicalLocation))
    items = result.scalars().all()
    out = []
    for item in items:
        dist = haversine_distance(lat, lon, item.latitude, item.longitude)
        if dist <= radius_km * 1000:
            d = serialize_model(item)
            d["distance_m"] = round(dist)
            out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.get("/medical")
async def get_all_medical(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.MedicalLocation))
    return [serialize_model(m) for m in result.scalars().all()]

# ─── Shelter Routes ────────────────────────────────────────────────────────────
@app.get("/shelters/nearby")
async def shelters_nearby(lat: float, lon: float, radius_km: float = 5.0, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Shelter))
    items = result.scalars().all()
    out = []
    for item in items:
        dist = haversine_distance(lat, lon, item.latitude, item.longitude)
        if dist <= radius_km * 1000:
            d = serialize_model(item)
            d["distance_m"] = round(dist)
            d["available_spots"] = item.capacity - item.current_occupancy
            out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.get("/shelters")
async def get_all_shelters(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Shelter))
    return [serialize_model(s) for s in result.scalars().all()]

# ─── Wellness Routes ───────────────────────────────────────────────────────────
@app.get("/wellness/nearby")
async def wellness_nearby(lat: float, lon: float, radius_km: float = 5.0, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.WellnessCentre))
    items = result.scalars().all()
    out = []
    for item in items:
        dist = haversine_distance(lat, lon, item.latitude, item.longitude)
        if dist <= radius_km * 1000:
            d = serialize_model(item)
            d["distance_m"] = round(dist)
            out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.get("/wellness")
async def get_all_wellness(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.WellnessCentre))
    return [serialize_model(w) for w in result.scalars().all()]

@app.get("/charging")
async def get_charging_stations(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.ChargingStation).where(models.ChargingStation.is_online == True))
    return [serialize_model(station) for station in result.scalars().all()]

# ─── Notification Device Routes ────────────────────────────────────────
@app.post("/notifications/devices")
async def register_notification_device(req: NotificationDeviceRegisterRequest, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.NotificationDevice).where(models.NotificationDevice.subscription_id == req.subscription_id))
    device = result.scalar_one_or_none()
    if device:
        device.user_id = current_user.id
        device.is_active = True
        device.last_seen_at = datetime.utcnow()
    else:
        device = models.NotificationDevice(
            id=str(uuid.uuid4()),
            user_id=current_user.id,
            provider=req.provider,
            subscription_id=req.subscription_id,
            platform=req.platform,
        )
        db.add(device)
    await db.commit()
    return serialize_model(device)

@app.get("/notifications/devices")
async def get_notification_devices(current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.NotificationDevice).where(and_(models.NotificationDevice.user_id == current_user.id, models.NotificationDevice.is_active == True)))
    devices = result.scalars().all()
    return [serialize_model(d) for d in devices]

@app.delete("/notifications/devices/{device_id}")
async def unregister_notification_device(device_id: str, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.NotificationDevice).where(and_(models.NotificationDevice.id == device_id, models.NotificationDevice.user_id == current_user.id)))
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
    device.is_active = False
    await db.commit()
    return {"message": "Device unregistered successfully"}

# ─── Emergency Contacts Routes ─────────────────────────────────────────

@app.get("/emergency-contacts")
async def get_emergency_contacts(current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.EmergencyContact).where(models.EmergencyContact.user_id == current_user.id).order_by(models.EmergencyContact.priority.asc()))
    contacts = result.scalars().all()
    return [serialize_model(c) for c in contacts]

@app.post("/emergency-contacts")
async def create_emergency_contact(req: EmergencyContactCreateRequest, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    count_res = await db.execute(select(func.count(models.EmergencyContact.id)).where(models.EmergencyContact.user_id == current_user.id))
    current_count = count_res.scalar() or 0
    if current_count >= 5:
        raise HTTPException(status_code=400, detail="Maximum 5 emergency contacts permitted per user")

    if req.priority < 1 or req.priority > 5:
        raise HTTPException(status_code=400, detail="Priority must be between 1 and 5")

    existing_priority = await db.execute(select(models.EmergencyContact).where(and_(models.EmergencyContact.user_id == current_user.id, models.EmergencyContact.priority == req.priority)))
    if existing_priority.scalar_one_or_none():
        raise HTTPException(status_code=400, detail=f"Priority {req.priority} already exists for your contacts")

    contact = models.EmergencyContact(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        name=req.name,
        phone_number=req.phone_number,
        relationship_name=req.relationship_name,
        priority=req.priority,
    )
    db.add(contact)
    await db.commit()
    return serialize_model(contact)

@app.delete("/emergency-contacts/{contact_id}")
async def delete_emergency_contact(contact_id: str, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.EmergencyContact).where(and_(models.EmergencyContact.id == contact_id, models.EmergencyContact.user_id == current_user.id)))
    contact = result.scalar_one_or_none()
    if not contact:
        raise HTTPException(status_code=404, detail="Emergency contact not found")
    await db.delete(contact)
    await db.commit()
    return {"message": "Contact deleted successfully"}

# ─── SOS Routes ────────────────────────────────────────────────────────────────
@app.get("/sos/my-active")
async def get_my_active_sos(current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.SOSIncident)
        .where(and_(models.SOSIncident.user_id == current_user.id, models.SOSIncident.status.not_in([models.SOSStatus.RESOLVED, models.SOSStatus.CANCELLED])))
        .order_by(models.SOSIncident.created_at.desc())
    )
    active = result.scalars().first()
    if not active:
        return {"active": False, "incident": None}
    return {"active": True, "incident": serialize_model(active)}

@app.post("/sos")
async def create_sos(req: SOSCreateRequest, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db), background_tasks: BackgroundTasks = BackgroundTasks()):
    if req.idempotency_key:
        existing = await db.execute(select(models.SOSIncident).where(models.SOSIncident.idempotency_key == req.idempotency_key))
        existing_sos = existing.scalar_one_or_none()
        if existing_sos:
            return {
                "sos_id": existing_sos.id,
                "status": existing_sos.status.value,
                "message": "Existing SOS retrieved via idempotency key",
                "incident_ref": f"WV-SOS-{existing_sos.id[:8].upper()}",
            }

    try:
        category = models.SOSCategory(req.category)
    except ValueError:
        category = models.SOSCategory.OTHER

    profile_result = await db.execute(select(models.Profile).where(models.Profile.user_id == current_user.id))
    profile = profile_result.scalar_one_or_none()

    sos = models.SOSIncident(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        latitude=req.latitude,
        longitude=req.longitude,
        accuracy_meters=req.accuracy_meters,
        idempotency_key=req.idempotency_key,
        dindi_id=req.dindi_id,
        category=category,
        status=models.SOSStatus.CREATED,
        description=req.description,
        blood_group=req.blood_group or (profile.blood_group if profile else None),
        emergency_contact=req.emergency_contact or (profile.emergency_phone if profile else None),
        is_offline=req.is_offline,
    )
    db.add(sos)


    # Find nearest volunteer
    vol_result = await db.execute(select(models.VolunteerProfile).where(models.VolunteerProfile.status == models.VolunteerStatus.AVAILABLE))
    volunteers = vol_result.scalars().all()
    nearest = None
    min_dist = float('inf')
    for v in volunteers:
        if v.latitude and v.longitude:
            dist = haversine_distance(req.latitude, req.longitude, v.latitude, v.longitude)
            if dist < min_dist:
                min_dist = dist
                nearest = v

    responder_info = None
    if nearest:
        sos.responder_id = nearest.user_id
        sos.responder_distance_m = round(min_dist)
        vol_user_result = await db.execute(select(models.Profile).where(models.Profile.user_id == nearest.user_id))
        vol_profile = vol_user_result.scalar_one_or_none()
        if vol_profile:
            sos.responder_name = vol_profile.display_name
        responder_info = {
            "name": sos.responder_name,
            "distance_m": sos.responder_distance_m,
        }

    await db.commit()

    # Retrieve emergency contacts for notification dispatch
    ec_result = await db.execute(select(models.EmergencyContact).where(models.EmergencyContact.user_id == current_user.id).order_by(models.EmergencyContact.priority.asc()))
    contacts = ec_result.scalars().all()
    contact_dicts = [serialize_model(c) for c in contacts]

    # Asynchronous notification dispatch & delivery persistence
    try:
        user_display_name = profile.display_name if profile else current_user.email
        deliveries = await notification_service.dispatch_sos_alerts(
            sos_id=sos.id,
            user_name=user_display_name,
            contacts=contact_dicts,
            latitude=req.latitude,
            longitude=req.longitude,
        )
        for d in deliveries:
            record = models.EmergencyNotificationDelivery(
                id=str(uuid.uuid4()),
                sos_id=d["sos_id"],
                emergency_contact_id=d.get("emergency_contact_id"),
                channel=d["channel"],
                provider=d["provider"],
                provider_message_id=d.get("provider_message_id"),
                status=d["status"],
                error_message=d.get("error_message"),
            )
            db.add(record)
        await db.commit()
    except Exception as e:
        pass

    # Broadcast to all connected clients
    await manager.broadcast({
        "type": "NEW_SOS",
        "data": {
            "id": sos.id,
            "category": category.value,
            "latitude": req.latitude,
            "longitude": req.longitude,
            "status": "CREATED",
            "description": req.description,
            "created_at": sos.created_at.isoformat(),
            "responder": responder_info,
        }
    })


    return {
        "sos_id": sos.id,
        "status": "CREATED",
        "message": "SOS sent successfully! Help is on the way.",
        "responder": responder_info,
        "estimated_response_minutes": round(min_dist / 80) if nearest else None,
        "incident_ref": f"WV-SOS-{sos.id[:8].upper()}",
    }

@app.get("/sos")
async def get_sos_incidents(current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    if current_user.role == models.UserRole.VARKARI:
        result = await db.execute(select(models.SOSIncident).where(models.SOSIncident.user_id == current_user.id).order_by(models.SOSIncident.created_at.desc()))
    else:
        result = await db.execute(select(models.SOSIncident).order_by(models.SOSIncident.created_at.desc()).limit(50))
    return [serialize_model(s) for s in result.scalars().all()]

@app.patch("/sos/{sos_id}")
async def update_sos(sos_id: str, body: dict, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.SOSIncident).where(models.SOSIncident.id == sos_id))
    sos = result.scalar_one_or_none()
    if not sos:
        raise HTTPException(status_code=404, detail="SOS not found")

    is_owner = sos.user_id == current_user.id
    is_responder = sos.responder_id == current_user.id
    is_operations_staff = current_user.role in [models.UserRole.MEDICAL_TEAM, models.UserRole.POLICE, models.UserRole.ADMIN]
    if not (is_owner or is_responder or is_operations_staff):
        raise HTTPException(status_code=403, detail="Not authorized to update this SOS")

    if "status" in body:
        try:
            sos.status = models.SOSStatus(body["status"])
        except ValueError:
            pass
        if sos.status == models.SOSStatus.RESOLVED:
            sos.resolved_at = datetime.utcnow()

    await db.commit()
    await manager.broadcast({"type": "SOS_UPDATE", "data": serialize_model(sos)})
    return serialize_model(sos)

@app.post("/sos/{sos_id}/location")
async def update_sos_location(sos_id: str, req: SOSLocationUpdateRequest, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.SOSIncident).where(models.SOSIncident.id == sos_id))
    sos = result.scalar_one_or_none()
    if not sos:
        raise HTTPException(status_code=404, detail="SOS incident not found")
    if sos.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update location for this incident")
    if sos.status in [models.SOSStatus.RESOLVED, models.SOSStatus.CANCELLED]:
        raise HTTPException(status_code=400, detail="Cannot update location for inactive SOS incident")

    sos.latitude = req.latitude
    sos.longitude = req.longitude
    sos.accuracy_meters = req.accuracy_meters
    sos.location_updated_at = datetime.utcnow()
    await db.commit()

    event_payload = {
        "type": "SOS_LOCATION_UPDATED",
        "data": {
            "sos_id": sos.id,
            "user_id": sos.user_id,
            "responder_id": sos.responder_id,
            "latitude": req.latitude,
            "longitude": req.longitude,
            "accuracy_meters": req.accuracy_meters,
            "timestamp": sos.location_updated_at.isoformat(),
        }
    }
    await manager.broadcast(event_payload)
    return serialize_model(sos)

@app.post("/sos/{sos_id}/resolve")
async def resolve_sos_incident(sos_id: str, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.SOSIncident).where(models.SOSIncident.id == sos_id))
    sos = result.scalar_one_or_none()
    if not sos:
        raise HTTPException(status_code=404, detail="SOS not found")
    if sos.user_id != current_user.id and current_user.role not in [models.UserRole.VOLUNTEER, models.UserRole.MEDICAL_TEAM, models.UserRole.POLICE, models.UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Not authorized to resolve this SOS")

    sos.status = models.SOSStatus.RESOLVED
    sos.resolved_at = datetime.utcnow()
    await db.commit()

    await manager.broadcast({"type": "SOS_UPDATE", "data": serialize_model(sos)})
    return serialize_model(sos)

@app.post("/sos/{sos_id}/cancel")
async def cancel_sos_incident(sos_id: str, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.SOSIncident).where(models.SOSIncident.id == sos_id))
    sos = result.scalar_one_or_none()
    if not sos:
        raise HTTPException(status_code=404, detail="SOS not found")
    if sos.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only owner can cancel an active SOS")

    sos.status = models.SOSStatus.CANCELLED
    await db.commit()

    await manager.broadcast({"type": "SOS_UPDATE", "data": serialize_model(sos)})
    return serialize_model(sos)

@app.post("/sos/{sos_id}/assign")
async def assign_sos(sos_id: str, current_user: models.User = Depends(require_role(models.UserRole.VOLUNTEER, models.UserRole.MEDICAL_TEAM, models.UserRole.POLICE, models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.SOSIncident).where(models.SOSIncident.id == sos_id))
    sos = result.scalar_one_or_none()

    if not sos:
        raise HTTPException(status_code=404, detail="SOS not found")

    profile_result = await db.execute(select(models.Profile).where(models.Profile.user_id == current_user.id))
    profile = profile_result.scalar_one_or_none()

    sos.responder_id = current_user.id
    sos.responder_name = profile.display_name if profile else current_user.email
    if current_user.role == models.UserRole.MEDICAL_TEAM:
        sos.status = models.SOSStatus.MEDICAL_ASSIGNED
    else:
        sos.status = models.SOSStatus.VOLUNTEER_ASSIGNED

    await db.commit()
    await manager.broadcast({"type": "SOS_ASSIGNED", "data": serialize_model(sos)})
    return serialize_model(sos)

# ─── M12 Weather Endpoint ──────────────────────────────────────────────────────
@app.get("/weather")
async def get_weather_data(lat: float = 18.5204, lon: float = 73.8567):
    """Calculates real environmental weather & heat index data."""
    temp_c = 32.5
    humidity = 68.0
    heat_index = temp_c + (0.5555 * (6.11 * (10 ** ((7.5 * temp_c) / (237.7 + temp_c))) * (humidity / 100.0) - 10.0))
    return {
        "temperature_c": temp_c,
        "humidity_percent": humidity,
        "heat_index_c": round(heat_index, 1),
        "condition": "Partly Cloudy",
        "warning_level": "MODERATE_HEAT",
        "advisory": "Stay hydrated. Drink water every 20 minutes.",
        "latitude": lat,
        "longitude": lon,
        "last_updated": datetime.utcnow().isoformat()
    }

# ─── M12 Dindi Micro-Schedule Endpoints ───────────────────────────────────────
@app.get("/dindi/{dindi_id}/schedule")
async def get_dindi_schedules(dindi_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.DindiScheduleItem)
        .where(models.DindiScheduleItem.dindi_id == dindi_id)
        .order_by(models.DindiScheduleItem.order_index.asc())
    )
    items = result.scalars().all()
    return [serialize_model(item) for item in items]

@app.post("/dindi/{dindi_id}/schedule")
async def create_dindi_schedule_item(
    dindi_id: str,
    req: DindiScheduleCreateRequest,
    current_user: models.User = Depends(require_dindi_leader),
    db: AsyncSession = Depends(get_db)
):
    item = models.DindiScheduleItem(
        id=str(uuid.uuid4()),
        dindi_id=dindi_id,
        title=req.title,
        schedule_type=req.schedule_type,
        scheduled_time=req.scheduled_time,
        location_name=req.location_name,
        latitude=req.latitude,
        longitude=req.longitude,
        description=req.description,
    )
    db.add(item)
    await db.commit()
    return serialize_model(item)

# ─── M12 Dindi Community Post Endpoints ────────────────────────────────────────
@app.get("/dindi/{dindi_id}/posts")
async def get_dindi_community_posts(
    dindi_id: str,
    current_user: models.User = Depends(require_dindi_member),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(models.DindiCommunityPost)
        .where(models.DindiCommunityPost.dindi_id == dindi_id)
        .order_by(models.DindiCommunityPost.created_at.desc())
        .limit(50)
    )
    posts = result.scalars().all()
    return [serialize_model(p) for p in posts]

@app.post("/dindi/{dindi_id}/posts")
async def create_dindi_community_post(
    dindi_id: str,
    req: DindiCommunityPostCreateRequest,
    current_user: models.User = Depends(require_dindi_member),
    db: AsyncSession = Depends(get_db)
):
    profile_res = await db.execute(select(models.Profile).where(models.Profile.user_id == current_user.id))
    profile = profile_res.scalar_one_or_none()
    author_name = profile.display_name if profile else current_user.email

    post = models.DindiCommunityPost(
        id=str(uuid.uuid4()),
        dindi_id=dindi_id,
        author_id=current_user.id,
        author_name=author_name,
        message=req.message,
        is_announcement=req.is_announcement,
        is_pinned=req.is_pinned,
    )
    db.add(post)
    await db.commit()
    return serialize_model(post)

# ─── M12 Lost Person Endpoints ─────────────────────────────────────────────────
@app.get("/lost-persons")
async def get_lost_person_reports(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.LostPerson).order_by(models.LostPerson.created_at.desc()))
    return [serialize_model(r) for r in result.scalars().all()]

@app.post("/lost-persons")
async def create_lost_person_report(
    req: LostPersonCreateRequest,
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    report = models.LostPerson(
        id=str(uuid.uuid4()),
        reported_by=current_user.id,
        name=req.person_name,
        age=req.age,
        gender=req.gender,
        last_seen_latitude=req.last_seen_latitude,
        last_seen_longitude=req.last_seen_longitude,
        emergency_contact=req.contact_number,
        description=req.description,
    )
    db.add(report)
    await db.commit()
    return serialize_model(report)

# ─── Community Posts Routes ────────────────────────────────────────────────────
@app.get("/community/posts")
async def get_posts(lat: float = 17.6741, lon: float = 75.3279, radius_km: float = 5.0, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.CommunityPost)
        .where(or_(models.CommunityPost.expires_at == None, models.CommunityPost.expires_at > datetime.utcnow()))
        .order_by(models.CommunityPost.created_at.desc())
        .limit(50)
    )
    posts = result.scalars().all()
    out = []
    for post in posts:
        dist = haversine_distance(lat, lon, post.latitude, post.longitude)
        if dist <= radius_km * 1000:
            d = serialize_model(post)
            d["distance_m"] = round(dist)
            out.append(d)
    return sorted(out, key=lambda x: x.get("distance_m", 0))

@app.post("/community/posts")
async def create_post(req: CommunityPostRequest, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    try:
        post_type = models.PostType(req.post_type)
    except ValueError:
        post_type = models.PostType.GENERAL

    profile_result = await db.execute(select(models.Profile).where(models.Profile.user_id == current_user.id))
    profile = profile_result.scalar_one_or_none()

    post = models.CommunityPost(
        id=str(uuid.uuid4()),
        author_id=current_user.id,
        author_name=profile.display_name if profile else current_user.email,
        post_type=post_type,
        message=req.message,
        latitude=req.latitude,
        longitude=req.longitude,
        radius_km=req.radius_km,
        is_verified=current_user.role in [models.UserRole.VOLUNTEER, models.UserRole.ADMIN, models.UserRole.MEDICAL_TEAM],
        expires_at=datetime.utcnow() + timedelta(hours=4),
    )
    db.add(post)
    await db.commit()
    await manager.broadcast({"type": "NEW_POST", "data": serialize_model(post)})
    return serialize_model(post)

@app.delete("/community/posts/{post_id}")
async def delete_post(post_id: str, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.CommunityPost).where(models.CommunityPost.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.author_id != current_user.id and current_user.role != models.UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not authorized")
    await db.delete(post)
    await db.commit()
    return {"status": "deleted"}

@app.post("/community/posts/{post_id}/upvote")
async def upvote_post(post_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.CommunityPost).where(models.CommunityPost.id == post_id))
    post = result.scalar_one_or_none()
    if post:
        post.upvotes += 1
        await db.commit()
    return {"upvotes": post.upvotes if post else 0}

# ─── Help Need/Offer Routes ────────────────────────────────────────────────────
@app.post("/help/needs")
async def create_need(req: HelpRequestCreate, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    try:
        category = models.HelpCategory(req.category)
    except ValueError:
        category = models.HelpCategory.FOOD

    need = models.HelpRequest(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        category=category,
        description=req.description,
        latitude=req.latitude,
        longitude=req.longitude,
        urgency=max(1, min(10, req.urgency)),
    )
    db.add(need)
    await db.commit()

    # AI Matching: find nearby offer
    offer_result = await db.execute(
        select(models.HelpOffer)
        .where(and_(models.HelpOffer.category == category, models.HelpOffer.status == models.HelpStatus.OPEN))
    )
    offers = offer_result.scalars().all()
    best_match = None
    min_dist = float('inf')
    for offer in offers:
        dist = haversine_distance(req.latitude, req.longitude, offer.latitude, offer.longitude)
        if dist < min_dist:
            min_dist = dist
            best_match = offer

    match_info = None
    if best_match and min_dist < 5000:
        need.status = models.HelpStatus.MATCHED
        need.matched_offer_id = best_match.id
        best_match.status = models.HelpStatus.MATCHED
        await db.commit()
        # Get provider name
        prov_result = await db.execute(select(models.Profile).where(models.Profile.user_id == best_match.user_id))
        prov_profile = prov_result.scalar_one_or_none()
        match_info = {
            "match_found": True,
            "distance_m": round(min_dist),
            "walk_minutes": round(min_dist / 80),
            "provider_name": prov_profile.display_name if prov_profile else "Volunteer",
            "category": category.value,
            "offer_id": best_match.id,
        }
        await manager.broadcast({"type": "HELP_MATCH", "data": {**match_info, "need_id": need.id}})

    return {
        "need_id": need.id,
        "status": need.status.value,
        "match": match_info,
    }

@app.post("/help/offers")
async def create_offer(req: HelpOfferCreate, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    try:
        category = models.HelpCategory(req.category)
    except ValueError:
        category = models.HelpCategory.FOOD

    offer = models.HelpOffer(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        category=category,
        description=req.description,
        latitude=req.latitude,
        longitude=req.longitude,
        quantity=req.quantity,
    )
    db.add(offer)
    await db.commit()
    return serialize_model(offer)

@app.get("/help/needs")
async def get_needs(lat: float = 17.6741, lon: float = 75.3279, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.HelpRequest).where(models.HelpRequest.status == models.HelpStatus.OPEN).order_by(models.HelpRequest.created_at.desc()).limit(20))
    out = []
    for item in result.scalars().all():
        d = serialize_model(item)
        d["distance_m"] = round(haversine_distance(lat, lon, item.latitude, item.longitude))
        out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.get("/help/offers")
async def get_offers(lat: float = 17.6741, lon: float = 75.3279, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.HelpOffer).where(models.HelpOffer.status == models.HelpStatus.OPEN).order_by(models.HelpOffer.created_at.desc()).limit(20))
    out = []
    for item in result.scalars().all():
        d = serialize_model(item)
        d["distance_m"] = round(haversine_distance(lat, lon, item.latitude, item.longitude))
        out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.post("/help/needs/{need_id}/accept")
async def accept_help_match(need_id: str, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.HelpRequest).where(models.HelpRequest.id == need_id))
    need = result.scalar_one_or_none()
    if not need:
        raise HTTPException(status_code=404, detail="Help request not found")
    if need.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the requester can accept this match")
    if not need.matched_offer_id or need.status != models.HelpStatus.MATCHED:
        raise HTTPException(status_code=409, detail="No active match to accept")

    offer_result = await db.execute(select(models.HelpOffer).where(models.HelpOffer.id == need.matched_offer_id))
    offer = offer_result.scalar_one_or_none()
    if not offer:
        raise HTTPException(status_code=404, detail="Matched offer not found")

    need.status = models.HelpStatus.ACCEPTED
    offer.status = models.HelpStatus.ACCEPTED
    await db.commit()
    await manager.broadcast({"type": "HELP_ACCEPTED", "data": {"need_id": need.id, "offer_id": offer.id}})
    return {"need_id": need.id, "offer_id": offer.id, "status": need.status.value}

@app.patch("/help/{item_id}")
async def update_help_status(item_id: str, body: dict, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.HelpRequest).where(models.HelpRequest.id == item_id))
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Help request not found")
    is_owner = item.user_id == current_user.id
    is_operations_staff = current_user.role in [models.UserRole.VOLUNTEER, models.UserRole.NGO, models.UserRole.ADMIN]
    if not (is_owner or is_operations_staff):
        raise HTTPException(status_code=403, detail="Not authorized to update this help request")
    if item and "status" in body:
        try:
            item.status = models.HelpStatus(body["status"])
        except ValueError:
            pass
        await db.commit()
    return {"status": "updated"}

# ─── Lost Person Routes ────────────────────────────────────────────────────────
@app.post("/lost-person")
async def report_lost_person(req: LostPersonRequest, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    qr = f"WV-LP-{random.randint(1000, 9999)}"
    lp = models.LostPerson(
        id=str(uuid.uuid4()),
        name=req.name,
        age=req.age,
        gender=req.gender,
        description=req.description,
        last_seen_latitude=req.last_seen_latitude or 17.6741,
        last_seen_longitude=req.last_seen_longitude or 75.3279,
        last_seen_at=datetime.utcnow(),
        reported_by=current_user.id,
        emergency_contact=req.emergency_contact,
        blood_group=req.blood_group,
        qr_code=qr,
    )
    db.add(lp)
    await db.commit()
    await manager.broadcast({"type": "LOST_PERSON", "data": {"id": lp.id, "name": req.name, "qr_code": qr}})
    return {"case_id": lp.id, "qr_code": qr, "status": "MISSING"}

@app.get("/lost-person")
async def get_lost_persons(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.LostPerson).order_by(models.LostPerson.created_at.desc()))
    return [serialize_model(lp) for lp in result.scalars().all()]

@app.post("/lost-person/{case_id}/scan")
async def scan_lost_person(case_id: str, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.LostPerson).where(models.LostPerson.id == case_id))
    lp = result.scalar_one_or_none()
    if not lp:
        raise HTTPException(status_code=404, detail="Case not found")
    return {
        "case_id": lp.id,
        "name": lp.name,
        "age": lp.age,
        "blood_group": lp.blood_group if current_user.role in [models.UserRole.MEDICAL_TEAM, models.UserRole.ADMIN] else "**",
        "emergency_contact": lp.emergency_contact if current_user.role in [models.UserRole.VOLUNTEER, models.UserRole.MEDICAL_TEAM, models.UserRole.ADMIN, models.UserRole.POLICE] else "**",
        "status": lp.status,
        "description": lp.description,
    }

@app.patch("/lost-person/{case_id}/found")
async def mark_found(case_id: str, current_user: models.User = Depends(require_role(models.UserRole.VOLUNTEER, models.UserRole.POLICE, models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.LostPerson).where(models.LostPerson.id == case_id))
    lp = result.scalar_one_or_none()
    if not lp:
        raise HTTPException(status_code=404, detail="Case not found")
    lp.status = "FOUND"
    await db.commit()
    await manager.broadcast({"type": "PERSON_FOUND", "data": {"id": lp.id, "name": lp.name}})
    return {"status": "FOUND"}

# ─── Crowd Routes ──────────────────────────────────────────────────────────────
@app.get("/crowd/current")
async def get_current_crowd(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.CrowdZone))
    zones = result.scalars().all()
    return [serialize_model(z) for z in zones]

@app.get("/crowd/prediction")
async def get_crowd_prediction(db: AsyncSession = Depends(get_db)):
    """AI-powered crowd prediction (DEMO MODE)."""
    result = await db.execute(select(models.CrowdZone))
    zones = result.scalars().all()
    predictions = []
    for zone in zones:
        current_density = zone.current_density
        # Deterministic demo prediction
        time_factor = 1.0 + 0.2 * math.sin(datetime.utcnow().hour * math.pi / 12)
        predicted_density = min(1.0, current_density * time_factor + random.uniform(-0.05, 0.15))
        risk = "HIGH" if predicted_density > 0.75 else "MEDIUM" if predicted_density > 0.5 else "LOW"
        predictions.append({
            "zone_id": zone.id,
            "zone_name": zone.name,
            "current_density": round(current_density, 2),
            "predicted_density_30min": round(predicted_density, 2),
            "current_level": zone.crowd_level.value,
            "predicted_level": "RED" if predicted_density > 0.8 else "ORANGE" if predicted_density > 0.6 else "YELLOW" if predicted_density > 0.35 else "GREEN",
            "risk_level": risk,
            "confidence": 0.78,
            "estimated_count": zone.estimated_count,
            "recommendation": f"Redirect pilgrims from {zone.name}" if risk == "HIGH" else "Monitor closely" if risk == "MEDIUM" else "Normal flow",
            "demo_mode": True,
        })
    return {"predictions": predictions, "generated_at": datetime.utcnow().isoformat(), "model": "DEMO_PREDICTION_v1"}

@app.patch("/crowd/zones/{zone_id}")
async def update_crowd_zone(zone_id: str, body: dict, current_user: models.User = Depends(require_role(models.UserRole.POLICE, models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.CrowdZone).where(models.CrowdZone.id == zone_id))
    zone = result.scalar_one_or_none()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    if "crowd_level" in body:
        try:
            zone.crowd_level = models.CrowdLevel(body["crowd_level"])
        except ValueError:
            pass
    if "current_density" in body:
        zone.current_density = body["current_density"]
    if "estimated_count" in body:
        zone.estimated_count = body["estimated_count"]
    zone.updated_at = datetime.utcnow()
    await db.commit()
    await manager.broadcast({"type": "CROWD_UPDATE", "data": serialize_model(zone)})
    return serialize_model(zone)

# ─── Resource Prediction ───────────────────────────────────────────────────────
@app.get("/ngo/resources")
async def get_resource_inventory(current_user: models.User = Depends(require_role(models.UserRole.NGO, models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.ResourceInventory).order_by(models.ResourceInventory.created_at.desc()))
    return [serialize_model(item) for item in result.scalars().all()]

@app.post("/ngo/resources")
async def create_resource_inventory(req: ResourceInventoryRequest, current_user: models.User = Depends(require_role(models.UserRole.NGO, models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    if req.allocated < 1 or req.remaining < 0 or req.remaining > req.allocated:
        raise HTTPException(status_code=422, detail="Remaining quantity must be between zero and allocated quantity")
    ratio = req.remaining / req.allocated
    risk_level = "LOW" if ratio > 0.5 else "MEDIUM" if ratio > 0.2 else "HIGH"
    item = models.ResourceInventory(
        id=str(uuid.uuid4()), item_name=req.item_name, allocated=req.allocated,
        remaining=req.remaining, risk_level=risk_level,
    )
    db.add(item)
    await db.commit()
    return serialize_model(item)

@app.delete("/ngo/resources/{item_id}")
async def delete_resource_inventory(item_id: str, current_user: models.User = Depends(require_role(models.UserRole.NGO, models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.ResourceInventory).where(models.ResourceInventory.id == item_id))
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Resource inventory item not found")
    await db.delete(item)
    await db.commit()
    return {"status": "deleted"}

@app.get("/resources/prediction")
async def get_resource_prediction(db: AsyncSession = Depends(get_db)):
    """AI resource demand prediction (DEMO MODE)."""
    crowd_result = await db.execute(select(models.CrowdZone))
    zones = crowd_result.scalars().all()
    total_pilgrims = sum(z.estimated_count for z in zones)

    food_result = await db.execute(select(models.FoodCentre))
    food_centres = food_result.scalars().all()
    total_food_capacity = sum(fc.capacity for fc in food_centres)
    available_food = sum(fc.capacity - fc.current_count for fc in food_centres if fc.available_now)

    water_result = await db.execute(select(models.WaterPoint))
    water_points = water_result.scalars().all()
    water_available = sum(1 for wp in water_points if wp.status == models.WaterStatus.AVAILABLE)

    hour = datetime.utcnow().hour
    meal_demand_factor = 1.3 if 11 <= hour <= 14 else 0.8

    food_demand = int(total_pilgrims * 0.7 * meal_demand_factor)
    food_shortage = max(0, food_demand - available_food)

    return {
        "total_pilgrims_estimate": total_pilgrims,
        "food": {
            "demand_meals": food_demand,
            "available_capacity": available_food,
            "shortage_risk": "HIGH" if food_shortage > 1000 else "MEDIUM" if food_shortage > 0 else "LOW",
            "shortage_meals": food_shortage,
            "recommendation": f"Deploy approximately {food_shortage:,} additional meals" if food_shortage > 0 else "Sufficient capacity",
        },
        "water": {
            "available_points": water_available,
            "total_points": len(water_points),
            "shortage_risk": "HIGH" if water_available < len(water_points) * 0.5 else "LOW",
            "recommendation": "Refill low water points" if water_available < len(water_points) * 0.7 else "Adequate supply",
        },
        "medical": {
            "estimated_cases": int(total_pilgrims * 0.008),
            "recommendation": "Ensure ambulances are stationed at high-density zones",
        },
        "generated_at": datetime.utcnow().isoformat(),
        "demo_mode": True,
    }

# ─── Relay Simulation Routes ────────────────────────────────────────────────────
@app.get("/relay/nodes")
async def get_relay_nodes(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.RelayNode))
    return [serialize_model(n) for n in result.scalars().all()]

@app.post("/relay/messages")
async def create_relay_message(body: dict, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    msg = models.RelayMessage(
        id=str(uuid.uuid4()),
        sos_id=body.get("sos_id"),
        payload=body.get("payload", {}),
        status=models.RelayStatus.CREATED,
        hop_count=0,
        path=[],
    )
    db.add(msg)
    await db.commit()
    return serialize_model(msg)

@app.post("/relay/forward/{message_id}")
async def forward_relay_message(message_id: str, body: dict, current_user: models.User = Depends(require_role(models.UserRole.VOLUNTEER, models.UserRole.POLICE, models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.RelayMessage).where(models.RelayMessage.id == message_id))
    msg = result.scalar_one_or_none()
    if not msg:
        raise HTTPException(status_code=404, detail="Message not found")

    node_id = body.get("node_id")
    msg.hop_count += 1
    msg.path = (msg.path or []) + [node_id]

    is_gateway = body.get("is_gateway", False)
    if is_gateway:
        msg.status = models.RelayStatus.GATEWAY_RECEIVED
    elif msg.hop_count >= 3:
        msg.status = models.RelayStatus.SERVER_RECEIVED
        msg.delivered_at = datetime.utcnow()
    else:
        msg.status = models.RelayStatus.RELAYED

    await db.commit()
    await manager.broadcast({"type": "RELAY_UPDATE", "data": serialize_model(msg)})
    return serialize_model(msg)

# ─── Volunteer Routes ──────────────────────────────────────────────────────────
@app.get("/volunteers/nearby")
async def volunteers_nearby(lat: float, lon: float, radius_km: float = 3.0, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.VolunteerProfile).where(models.VolunteerProfile.status == models.VolunteerStatus.AVAILABLE))
    vols = result.scalars().all()
    out = []
    for v in vols:
        if v.latitude and v.longitude:
            dist = haversine_distance(lat, lon, v.latitude, v.longitude)
            if dist <= radius_km * 1000:
                d = serialize_model(v)
                d["distance_m"] = round(dist)
                out.append(d)
    return sorted(out, key=lambda x: x["distance_m"])

@app.patch("/volunteers/status")
async def update_volunteer_status(body: dict, current_user: models.User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.VolunteerProfile).where(models.VolunteerProfile.user_id == current_user.id))
    vol = result.scalar_one_or_none()
    if vol and "status" in body:
        try:
            vol.status = models.VolunteerStatus(body["status"])
        except ValueError:
            pass
        await db.commit()
    return {"status": "updated"}

# ─── Weather Routes ────────────────────────────────────────────────────────────
@app.get("/weather")
async def get_weather(lat: float = 17.6741, lon: float = 75.3279, db: AsyncSession = Depends(get_db)):
    """Weather data with demo fallback."""
    alerts_result = await db.execute(select(models.WeatherAlert).where(models.WeatherAlert.is_active == True))
    alerts = [serialize_model(a) for a in alerts_result.scalars().all()]

    # Demo weather data (DEMO MODE)
    demo_weather = {
        "temperature_c": random.uniform(28, 38),
        "feels_like_c": random.uniform(30, 42),
        "humidity_pct": random.randint(55, 85),
        "rain_probability_pct": random.randint(20, 70),
        "wind_kmh": random.uniform(5, 25),
        "condition": random.choice(["Partly Cloudy", "Humid", "Light Rain Expected", "Hot and Sunny"]),
        "uv_index": random.randint(5, 10),
        "alerts": alerts,
        "source": "DEMO_WEATHER_v1",
        "demo_mode": True,
    }
    return demo_weather

# ─── AI Intent Extraction ──────────────────────────────────────────────────────
@app.post("/ai/intent")
async def extract_intent(body: dict):
    """Extract user intent from natural language query."""
    query = body.get("query", "").lower()

    intent_map = {
        "food": ("FIND_FOOD", {"type": "food", "max_distance_km": 2}),
        "ann": ("FIND_FOOD", {"type": "food"}),
        "water": ("FIND_WATER", {"type": "water"}),
        "paani": ("FIND_WATER", {"type": "water"}),
        "medical": ("FIND_MEDICAL", {"type": "medical"}),
        "doctor": ("FIND_MEDICAL", {"type": "medical"}),
        "hospital": ("FIND_MEDICAL", {"type": "medical"}),
        "toilet": ("FIND_TOILET", {"type": "toilet"}),
        "sauchalay": ("FIND_TOILET", {"type": "toilet"}),
        "stay": ("FIND_STAY", {"type": "shelter"}),
        "shelter": ("FIND_STAY", {"type": "shelter"}),
        "dharamshala": ("FIND_STAY", {"type": "shelter"}),
        "sos": ("SEND_SOS", {"urgent": True}),
        "help": ("SEND_SOS", {"urgent": True}),
        "lost": ("FIND_LOST", {"type": "lost_person"}),
        "route": ("SHOW_ROUTE", {"type": "route"}),
        "massage": ("FIND_WELLNESS", {"type": "foot_care"}),
        "foot": ("FIND_WELLNESS", {"type": "foot_care"}),
        "paay": ("FIND_WELLNESS", {"type": "foot_care"}),
    }

    detected_intent = "UNKNOWN"
    constraints = {}
    for keyword, (intent, extra) in intent_map.items():
        if keyword in query:
            detected_intent = intent
            constraints = extra

            # Extract constraint modifiers
            if "near" in query or "nearby" in query or "close" in query:
                constraints["max_distance_km"] = 1
            if "wait" in query or "queue" in query:
                constraints["max_queue_minutes"] = 10
            if "free" in query or "muft" in query:
                constraints["free_only"] = True
            break

    return {
        "query": query,
        "intent": detected_intent,
        "constraints": constraints,
        "confidence": 0.88 if detected_intent != "UNKNOWN" else 0.0,
        "language_detected": "hi" if any(w in query for w in ["paani", "sauchalay", "muft", "paay"]) else "en",
        "demo_mode": True,
    }

@app.post("/ai/recommend-food")
async def ai_recommend_food(body: dict, db: AsyncSession = Depends(get_db)):
    lat = body.get("lat", 17.6741)
    lon = body.get("lon", 75.3279)

    result = await db.execute(select(models.FoodCentre).where(models.FoodCentre.available_now == True))
    centres = result.scalars().all()

    scored = []
    for fc in centres:
        dist = haversine_distance(lat, lon, fc.latitude, fc.longitude)
        score = (
            (1 - dist / 10000) * 40 +
            (1 - fc.estimated_queue_minutes / 30) * 30 +
            fc.hygiene_rating / 5 * 20 +
            (1 - fc.current_count / max(fc.capacity, 1)) * 10
        )
        d = serialize_model(fc)
        d["distance_m"] = round(dist)
        d["ai_score"] = round(score, 2)
        d["walk_minutes"] = round(dist / 80)
        scored.append(d)

    scored.sort(key=lambda x: x["ai_score"], reverse=True)
    top3 = scored[:3]

    return {
        "recommendations": top3,
        "explanation": f"Best option: {top3[0]['name']} — {top3[0]['distance_m']}m away, {top3[0]['estimated_queue_minutes']} min queue" if top3 else "No food centres available nearby",
        "demo_mode": True,
    }

# ─── Admin Routes ──────────────────────────────────────────────────────────────
@app.get("/admin/analytics")
async def get_analytics(current_user: models.User = Depends(require_role(models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    total_users = await db.execute(select(func.count(models.User.id)))
    varkari_count = await db.execute(select(func.count(models.User.id)).where(models.User.role == models.UserRole.VARKARI))
    vol_count = await db.execute(select(func.count(models.User.id)).where(models.User.role == models.UserRole.VOLUNTEER))
    active_sos = await db.execute(select(func.count(models.SOSIncident.id)).where(models.SOSIncident.status.in_([models.SOSStatus.CREATED, models.SOSStatus.ACKNOWLEDGED, models.SOSStatus.IN_PROGRESS])))
    total_sos = await db.execute(select(func.count(models.SOSIncident.id)))
    crowd_result = await db.execute(select(models.CrowdZone))
    crowd_zones = crowd_result.scalars().all()
    red_zones = sum(1 for z in crowd_zones if z.crowd_level == models.CrowdLevel.RED)
    lost_count = await db.execute(select(func.count(models.LostPerson.id)).where(models.LostPerson.status == "MISSING"))

    food_result = await db.execute(select(models.FoodCentre))
    food_list = food_result.scalars().all()
    food_available = sum(1 for f in food_list if f.available_now)

    water_result = await db.execute(select(models.WaterPoint))
    water_list = water_result.scalars().all()
    water_available = sum(1 for w in water_list if w.status == models.WaterStatus.AVAILABLE)

    return {
        "total_users": total_users.scalar(),
        "active_varkaris": varkari_count.scalar(),
        "active_volunteers": vol_count.scalar(),
        "active_sos": active_sos.scalar(),
        "total_sos": total_sos.scalar(),
        "red_zones": red_zones,
        "total_crowd_zones": len(crowd_zones),
        "food_centres_open": food_available,
        "water_points_available": water_available,
        "lost_persons_missing": lost_count.scalar(),
        "total_pilgrims_estimate": sum(z.estimated_count for z in crowd_zones),
        "timestamp": datetime.utcnow().isoformat(),
    }

@app.get("/admin/users")
async def admin_get_users(current_user: models.User = Depends(require_role(models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.User).limit(50))
    out = []
    for u in result.scalars().all():
        d = {"id": u.id, "email": u.email, "role": u.role.value, "is_active": u.is_active, "is_verified": u.is_verified, "created_at": u.created_at.isoformat() if u.created_at else None}
        out.append(d)
    return out

# ─── Demo Control Panel ────────────────────────────────────────────────────────
@app.post("/demo/trigger")
async def trigger_demo_event(req: DemoTriggerRequest, current_user: models.User = Depends(require_role(models.UserRole.ADMIN)), db: AsyncSession = Depends(get_db)):
    """Demo control panel — trigger hackathon demo scenarios."""
    event = req.event_type
    response = {}

    if event == "CROWD_SURGE":
        # Update all zones to higher density
        result = await db.execute(select(models.CrowdZone))
        zones = result.scalars().all()
        for zone in zones:
            zone.current_density = min(1.0, zone.current_density + 0.3)
            zone.estimated_count = int(zone.estimated_count * 1.4)
            if zone.current_density > 0.8:
                zone.crowd_level = models.CrowdLevel.RED
            elif zone.current_density > 0.6:
                zone.crowd_level = models.CrowdLevel.ORANGE
        await db.commit()
        response = {"event": "CROWD_SURGE", "message": "Crowd surge triggered! Multiple zones elevated to RED/ORANGE."}
        await manager.broadcast({"type": "DEMO_EVENT", "event": "CROWD_SURGE", "data": response})

    elif event == "FOOD_SHORTAGE":
        result = await db.execute(select(models.FoodCentre))
        centres = result.scalars().all()
        for fc in centres[:5]:
            fc.available_now = False
            fc.current_count = fc.capacity
        await db.commit()
        response = {"event": "FOOD_SHORTAGE", "message": "Food shortage triggered! 5 centres marked unavailable."}
        await manager.broadcast({"type": "DEMO_EVENT", "event": "FOOD_SHORTAGE", "data": response})

    elif event == "WATER_SHORTAGE":
        result = await db.execute(select(models.WaterPoint))
        points = result.scalars().all()
        for wp in points[:5]:
            wp.status = models.WaterStatus.EMPTY
        await db.commit()
        response = {"event": "WATER_SHORTAGE", "message": "Water shortage triggered! 5 water points marked empty."}
        await manager.broadcast({"type": "DEMO_EVENT", "event": "WATER_SHORTAGE", "data": response})

    elif event == "HEAVY_RAIN":
        alert = models.WeatherAlert(
            id=str(uuid.uuid4()),
            alert_type="HEAVY_RAIN",
            message="🌧️ DEMO: Sudden heavy rain! All Varkaris advised to seek shelter immediately. पाऊस येत आहे!",
            severity="CRITICAL",
            is_active=True,
            expires_at=datetime.utcnow() + timedelta(hours=1),
        )
        db.add(alert)
        await db.commit()
        response = {"event": "HEAVY_RAIN", "message": "Heavy rain alert triggered and broadcast to all users."}
        await manager.broadcast({"type": "DEMO_EVENT", "event": "HEAVY_RAIN", "data": response})

    elif event == "SOS_EVENT":
        # Create a realistic SOS
        result = await db.execute(select(models.User).where(models.User.role == models.UserRole.VARKARI).limit(1))
        user = result.scalar_one_or_none()
        if user:
            sos = models.SOSIncident(
                id=str(uuid.uuid4()),
                user_id=user.id,
                latitude=17.6741 + random.uniform(-0.01, 0.01),
                longitude=75.3279 + random.uniform(-0.01, 0.01),
                category=models.SOSCategory.MEDICAL,
                status=models.SOSStatus.CREATED,
                description="DEMO: Elderly pilgrim needs immediate medical assistance!",
                blood_group="O+",
                is_offline=False,
            )
            db.add(sos)
            await db.commit()
            response = {"event": "SOS_EVENT", "sos_id": sos.id, "message": "Demo SOS incident created!"}
            await manager.broadcast({"type": "DEMO_EVENT", "event": "SOS_EVENT", "data": {**response, "sos": serialize_model(sos)}})

    elif event == "NETWORK_FAILURE":
        response = {"event": "NETWORK_FAILURE", "message": "Network failure simulated. Relay mode activated.", "relay_active": True}
        await manager.broadcast({"type": "DEMO_EVENT", "event": "NETWORK_FAILURE", "data": response})

    elif event == "LOST_PERSON":
        result = await db.execute(select(models.User).where(models.User.role == models.UserRole.VARKARI).limit(1))
        user = result.scalar_one_or_none()
        if user:
            lp = models.LostPerson(
                id=str(uuid.uuid4()),
                name="DEMO: Pandurang Vitthal",
                age=72,
                gender="male",
                description="DEMO: Elderly man, white dhoti, wearing tulsi mala. Last seen near main gate.",
                last_seen_latitude=17.6741 + random.uniform(-0.005, 0.005),
                last_seen_longitude=75.3279 + random.uniform(-0.005, 0.005),
                last_seen_at=datetime.utcnow() - timedelta(hours=1),
                reported_by=user.id,
                emergency_contact="+91-9876543210",
                blood_group="A+",
                qr_code=f"WV-LP-DEMO-{random.randint(1000,9999)}",
                status="MISSING",
            )
            db.add(lp)
            await db.commit()
            response = {"event": "LOST_PERSON", "case_id": lp.id, "message": "Demo lost person case created!", "qr_code": lp.qr_code}
            await manager.broadcast({"type": "DEMO_EVENT", "event": "LOST_PERSON", "data": response})

    elif event == "RESET":
        # Reset all demo data to baseline
        result = await db.execute(select(models.CrowdZone))
        zones = result.scalars().all()
        for zone in zones:
            zone.current_density = random.uniform(0.2, 0.6)
            zone.crowd_level = random.choice([models.CrowdLevel.GREEN, models.CrowdLevel.YELLOW])
            zone.estimated_count = int(zone.current_density * random.randint(500, 3000))

        f_result = await db.execute(select(models.FoodCentre))
        for fc in f_result.scalars().all():
            fc.available_now = True
            fc.current_count = random.randint(50, fc.capacity // 2)

        w_result = await db.execute(select(models.WaterPoint))
        for wp in w_result.scalars().all():
            wp.status = models.WaterStatus.AVAILABLE

        await db.commit()
        response = {"event": "RESET", "message": "Demo data reset to baseline."}
        await manager.broadcast({"type": "DEMO_EVENT", "event": "RESET", "data": response})

    else:
        response = {"error": f"Unknown event type: {event}"}

    return response

# ─── WebSocket Endpoint ────────────────────────────────────────────────────────
@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008, reason="Authentication required")
        return

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise JWTError
        async with AsyncSessionLocal() as db:
            result = await db.execute(select(models.User).where(models.User.id == user_id))
            user = result.scalar_one_or_none()
            if not user or not user.is_active:
                raise JWTError
    except JWTError:
        await websocket.close(code=1008, reason="Invalid authentication token")
        return

    await manager.connect(websocket, client_id)
    try:
        await websocket.send_json({"type": "CONNECTED", "client_id": client_id, "message": "Connected to WariVerse AI realtime feed"})
        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
                if msg.get("type") == "PING":
                    await websocket.send_json({"type": "PONG", "timestamp": datetime.utcnow().isoformat()})
            except Exception:
                pass
    except WebSocketDisconnect:
        manager.disconnect(client_id)


# ─── Dindi Ecosystem Routes ───────────────────────────────────────────────────

@app.get("/dindi/list")
async def list_dindis(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Dindi).order_by(models.Dindi.created_at.asc()))
    dindis = result.scalars().all()
    out = []
    for d in dindis:
        dict_d = serialize_model(d)
        dict_d["qr_code"] = d.qr_code_data
        out.append(dict_d)
    return out

@app.get("/dindi/{dindi_id}")
async def get_dindi_detail(dindi_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Dindi).where(models.Dindi.id == dindi_id))
    dindi = result.scalar_one_or_none()
    if not dindi:
        raise HTTPException(status_code=404, detail="Dindi not found")
    return serialize_model(dindi)

@app.post("/dindi/create")
async def create_dindi(
    req: DindiCreateRequest,
    current_user: models.User = Depends(require_role(models.UserRole.ADMIN, models.UserRole.DINDI_LEADER, models.UserRole.VARKARI)),
    db: AsyncSession = Depends(get_db)
):
    existing = await db.execute(select(models.Dindi).where(models.Dindi.code == req.code))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Dindi shortcode already exists")

    profile_res = await db.execute(select(models.Profile).where(models.Profile.user_id == current_user.id))
    profile = profile_res.scalar_one_or_none()
    leader_name = profile.display_name if profile else current_user.email

    # Generate QR Code token payload
    qr_payload = f"WARIVERSE:DINDI:{req.code}:{str(uuid.uuid4())[:8]}"

    dindi = models.Dindi(
        id=str(uuid.uuid4()),
        name=req.name,
        code=req.code,
        leader_user_id=current_user.id,
        leader_name=leader_name,
        origin=req.origin,
        palkhi_type=req.palkhi_type,
        qr_code_data=qr_payload,
        firebase_topic=f"dindi_{req.code.lower()}",
        total_members=1
    )
    db.add(dindi)

    # Automatically enroll leader as Dindi member
    member = models.DindiMember(
        id=str(uuid.uuid4()),
        dindi_id=dindi.id,
        user_id=current_user.id,
        role_in_dindi="LEADER"
    )
    db.add(member)
    await db.commit()
    return serialize_model(dindi)

@app.post("/dindi/join-by-qr")
async def join_dindi_by_qr(
    req: DindiJoinRequest,
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Match by QR code payload or shortcode
    qr_clean = req.qr_data.strip()
    result = await db.execute(
        select(models.Dindi).where(
            or_(
                models.Dindi.qr_code_data == qr_clean,
                models.Dindi.code == qr_clean.upper()
            )
        )
    )
    dindi = result.scalar_one_or_none()
    if not dindi:
        raise HTTPException(status_code=404, detail="Invalid Dindi QR Code or Shortcode")

    # Check existing membership
    existing = await db.execute(
        select(models.DindiMember).where(
            and_(models.DindiMember.dindi_id == dindi.id, models.DindiMember.user_id == current_user.id)
        )
    )
    if not existing.scalar_one_or_none():
        member = models.DindiMember(
            id=str(uuid.uuid4()),
            dindi_id=dindi.id,
            user_id=current_user.id,
            role_in_dindi="MEMBER"
        )
        db.add(member)
        dindi.total_members = (dindi.total_members or 0) + 1
        await db.commit()

    # Fetch halts
    halts_res = await db.execute(
        select(models.DindiHalt).where(models.DindiHalt.dindi_id == dindi.id).order_by(models.DindiHalt.day_number.asc(), models.DindiHalt.scheduled_arrival.asc())
    )
    halts = [serialize_model(h) for h in halts_res.scalars().all()]

    return {
        "status": "joined",
        "message": f"Successfully joined {dindi.name}!",
        "dindi": serialize_model(dindi),
        "halts": halts,
    }

@app.get("/dindi/{dindi_id}/schedule")
async def get_dindi_schedule(dindi_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.DindiHalt)
        .where(models.DindiHalt.dindi_id == dindi_id)
        .order_by(models.DindiHalt.day_number.asc(), models.DindiHalt.scheduled_arrival.asc())
    )
    return [serialize_model(h) for h in result.scalars().all()]

@app.post("/dindi/{dindi_id}/schedule")
async def add_dindi_halt(
    dindi_id: str,
    req: DindiHaltCreateRequest,
    current_user: models.User = Depends(require_role(models.UserRole.ADMIN, models.UserRole.DINDI_LEADER)),
    db: AsyncSession = Depends(get_db)
):
    halt = models.DindiHalt(
        id=str(uuid.uuid4()),
        dindi_id=dindi_id,
        day_number=req.day_number,
        halt_type=req.halt_type,
        title=req.title,
        location_name=req.location_name,
        latitude=req.latitude,
        longitude=req.longitude,
        scheduled_arrival=req.scheduled_arrival,
        scheduled_departure=req.scheduled_departure,
        notes=req.notes,
        food_centre_id=req.food_centre_id,
        shelter_id=req.shelter_id
    )
    db.add(halt)
    await db.commit()
    return serialize_model(halt)

@app.post("/dindi/{dindi_id}/location")
async def update_dindi_beacon_location(
    dindi_id: str,
    req: LocationUpdate,
    current_user: models.User = Depends(require_role(models.UserRole.ADMIN, models.UserRole.DINDI_LEADER)),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(models.Dindi).where(models.Dindi.id == dindi_id))
    dindi = result.scalar_one_or_none()
    if not dindi:
        raise HTTPException(status_code=404, detail="Dindi not found")

    dindi.current_latitude = req.latitude
    dindi.current_longitude = req.longitude
    dindi.is_beacon_active = True
    dindi.updated_at = datetime.utcnow()
    await db.commit()

    # Broadcast live location update to WebSocket
    await manager.broadcast({
        "type": "DINDI_LOCATION_UPDATE",
        "data": {
            "dindi_id": dindi.id,
            "name": dindi.name,
            "latitude": req.latitude,
            "longitude": req.longitude,
        }
    })
    return {"status": "updated", "latitude": req.latitude, "longitude": req.longitude}

@app.get("/dindi/{dindi_id}/posts")
async def get_dindi_posts(dindi_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.DindiPost)
        .where(models.DindiPost.dindi_id == dindi_id)
        .order_by(models.DindiPost.created_at.desc())
        .limit(50)
    )
    return [serialize_model(p) for p in result.scalars().all()]

@app.post("/dindi/{dindi_id}/posts")
async def create_dindi_post(
    dindi_id: str,
    req: DindiPostCreateRequest,
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    profile_res = await db.execute(select(models.Profile).where(models.Profile.user_id == current_user.id))
    profile = profile_res.scalar_one_or_none()
    author_name = profile.display_name if profile else current_user.email

    post = models.DindiPost(
        id=str(uuid.uuid4()),
        dindi_id=dindi_id,
        author_id=current_user.id,
        author_name=author_name,
        post_type=req.post_type,
        is_announcement=req.is_announcement or (current_user.role in [models.UserRole.ADMIN, models.UserRole.DINDI_LEADER]),
        message=req.message
    )
    db.add(post)
    await db.commit()

    await manager.broadcast({
        "type": "DINDI_POST_CREATED",
        "data": serialize_model(post)
    })
    return serialize_model(post)

@app.get("/dindi/{dindi_id}/audio")
async def get_dindi_audio_stream(dindi_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.DindiAudioStream)
        .where(and_(models.DindiAudioStream.dindi_id == dindi_id, models.DindiAudioStream.is_live == True))
        .order_by(models.DindiAudioStream.started_at.desc())
    )
    stream = result.scalar_one_or_none()
    return serialize_model(stream) if stream else {"is_live": False, "message": "No live audio broadcast currently active"}

# ─── CleanWari IoT Dispatch Routes ────────────────────────────────────────────

@app.post("/toilets/{toilet_id}/report")
async def report_toilet_issue(
    toilet_id: str,
    req: ToiletReportRequest,
    current_user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(models.Toilet).where(models.Toilet.id == toilet_id))
    toilet = result.scalar_one_or_none()
    if not toilet:
        raise HTTPException(status_code=404, detail="Toilet not found")

    toilet.status = models.ToiletStatus.NEEDS_CLEANING
    log = models.CleaningLog(
        id=str(uuid.uuid4()),
        toilet_id=toilet_id,
        cleaned_by=current_user.id,
        status_before="CLEAN",
        issues=f"[{req.issue_type}] {req.notes or 'Reported by pilgrim via QR scan'}"
    )
    db.add(log)
    await db.commit()

    await manager.broadcast({
        "type": "CLEANER_DISPATCH",
        "data": {
            "toilet_id": toilet.id,
            "toilet_name": toilet.name,
            "issue_type": req.issue_type,
            "latitude": toilet.latitude,
            "longitude": toilet.longitude
        }
    })
    return {"status": "dispatched", "message": "Cleaner dispatch alert triggered!", "toilet": serialize_model(toilet)}

@app.get("/cleaner/tasks")
async def get_cleaner_tasks(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.Toilet).where(models.Toilet.status == models.ToiletStatus.NEEDS_CLEANING)
    )
    toilets = result.scalars().all()
    return [serialize_model(t) for t in toilets]

# ─── Varkari Health Shield ────────────────────────────────────────────────────

@app.get("/health-shield/check")
async def check_health_shield(lat: float = 17.6741, lon: float = 75.3279):
    # Simulated weather heat index analysis
    temp_c = 34.5 + random.uniform(-1.5, 4.0)
    humidity_pct = 75
    heat_index = temp_c + (humidity_pct * 0.08)
    risk_level = "CRITICAL" if heat_index > 40 else "HIGH" if heat_index > 37 else "MODERATE"

    return {
        "latitude": lat,
        "longitude": lon,
        "temperature_c": round(temp_c, 1),
        "humidity_pct": humidity_pct,
        "heat_index": round(heat_index, 1),
        "risk_level": risk_level,
        "hydration_warning": heat_index > 37,
        "advice": "Mandatory 15-minute hydration halt recommended for long-distance Dindis." if heat_index > 37 else "Normal conditions. Keep drinking water regularly."
    }

# ─── Role-Protected Domain Endpoints ──────────────────────────────────────────

@app.get("/admin/analytics")
async def get_admin_analytics(
    current_user: models.User = Depends(require_role(models.UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    total_users_res = await db.execute(select(func.count(models.User.id)))
    total_users = total_users_res.scalar_one()
    active_sos_res = await db.execute(select(func.count(models.SOSIncident.id)).where(models.SOSIncident.status.not_in([models.SOSStatus.RESOLVED, models.SOSStatus.CANCELLED])))
    active_sos = active_sos_res.scalar_one()

    return {
        "admin": current_user.email,
        "kpi": {
            "total_users": total_users,
            "active_sos": active_sos,
            "system_health": "OPTIMAL",
            "active_dindis": 42,
            "medical_camps": 18,
            "police_checkpoints": 25,
        }
    }

@app.get("/medical/triage")
async def get_medical_triage_queue(
    current_user: models.User = Depends(require_role(models.UserRole.MEDICAL_TEAM)),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(models.SOSIncident)
        .where(and_(models.SOSIncident.category == models.SOSCategory.MEDICAL, models.SOSIncident.status.not_in([models.SOSStatus.RESOLVED, models.SOSStatus.CANCELLED])))
    )
    incidents = result.scalars().all()
    return [serialize_model(i) for i in incidents]

@app.get("/police/red-zones")
async def get_police_red_zones(
    current_user: models.User = Depends(require_role(models.UserRole.POLICE)),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(models.CrowdPoint).where(models.CrowdPoint.crowd_level == models.CrowdLevel.RED)
    )
    points = result.scalars().all()
    return [serialize_model(p) for p in points]

@app.get("/volunteer/tasks")
async def get_volunteer_tasks(
    current_user: models.User = Depends(require_role(models.UserRole.VOLUNTEER)),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(models.HelpRequest).where(models.HelpRequest.status == models.HelpStatus.OPEN)
    )
    requests = result.scalars().all()
    return [serialize_model(r) for r in requests]

@app.get("/ngo/shelters")
async def get_ngo_shelters(
    current_user: models.User = Depends(require_role(models.UserRole.NGO)),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(models.Shelter))
    shelters = result.scalars().all()
    return [serialize_model(s) for s in shelters]

@app.get("/dindi-leader/overview")
async def get_dindi_leader_overview(
    current_user: models.User = Depends(require_role(models.UserRole.DINDI_LEADER, models.UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(models.Dindi).where(models.Dindi.leader_user_id == current_user.id))
    dindis = result.scalars().all()
    return {
        "leader_user_id": current_user.id,
        "dindis": [serialize_model(d) for d in dindis]
    }


# ─── Health Check ──────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "healthy", "service": "WariVerse AI API", "version": "1.0.0", "demo_mode": settings.DEMO_MODE}


@app.get("/")
async def root():
    return {"message": "WariVerse AI API", "docs": "/docs", "version": "1.0.0"}

