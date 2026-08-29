# WariVerse AI Real-Time Architecture & Foundation Specification

## 1. High-Level Architecture Diagram

```
                                 MOBILE CLIENT (Flutter)
                                            │
                       1. Firebase Auth Identity (Phone / Google)
                                            │
                                            ▼
                                 FASTAPI OPERATIONAL BACKEND
                                            │
                       2. POST /auth/firebase (Identity Verification)
                       3. Resolve PostgreSQL User Record (User.id)
                       4. Issue Application JWT (sub = User.id, role = UserRole)
                                            │
                       ┌────────────────────┴────────────────────┐
                       ▼                                         ▼
            PostgreSQL Database                         Firestore Realtime Model
      (Authoritative Business Data)                   (Realtime Projections & Feeds)
     - Users, Roles, Memberships                     - /realtime/dindis/{id}/location
     - SOS Incidents & Emergency Contacts            - /realtime/dindis/{id}/broadcasts
     - CleanWari & Audit Logs                        - /realtime/sos/{incidentId}
                       │
                       ▼
            OneSignal Push Notification
       (Targeted Dispatch via User.id)
```

---

## 2. Canonical Identity Mapping

The system enforces a strict **1:1 Identity Mapping**:

$$\text{Firebase Auth UID} \iff \text{PostgreSQL User.firebase\_uid} \iff \text{PostgreSQL User.id} \iff \text{JWT sub} \iff \text{OneSignal External User ID}$$

1. **Firebase Auth**: Serves as the authentication provider (Phone OTP, Google Sign-In).
2. **FastAPI Verification**: Endpoint `POST /auth/firebase` verifies the Firebase ID token and resolves/creates the PostgreSQL `models.User` record.
3. **Session Token**: Backend issues JWT with `sub = User.id` and backend-authoritative `role`.
4. **Push Registration**: Flutter invokes `OneSignal.login(User.id)` binding notifications directly to `User.id`.
5. **Logout**: Safely clears Firebase Auth session, invalidates Flutter token state, and calls `OneSignal.logout()`.

---

## 3. Data Store Responsibilities

### A. PostgreSQL (Authoritative Relational Database)
- User identity, profile, and authoritative role assignment
- Dindi definitions, halt schedules, and membership rosters
- SOS incident records, emergency contact priority lists, and official resolution logs
- CleanWari toilet records and dispatch audit logs
- Abhangavali audio catalog & devotional metadata

### B. Firestore (Realtime Projection Model)
- `/realtime/dindis/{dindiId}/location/{doc}`: Live GPS beacon coordinates broadcast by Dindi Pramukhs.
- `/realtime/dindis/{dindiId}/broadcasts/{doc}`: Realtime Palkhi Voice audio stream status.
- `/realtime/dindis/{dindiId}/community/{doc}`: Realtime Dindi member community chat & announcements.
- `/realtime/sos/{incidentId}`: Active emergency state, live location tracking, and responder assignment stream.

---

## 4. Firestore Security Rules & Access Control Matrix

Defined in [`firebase/firestore.rules`](file:///d:/wari-main/firebase/firestore.rules):
- **Authentication**: `request.auth != null` required for all reads and writes.
- **Dindi Isolation**: Pilgrims can only read documents under `/realtime/dindis/{dindiId}` if `request.auth.token.dindi_id == dindiId` or `request.auth.token.role == 'ADMIN'`.
- **Leader Beacon Authority**: Writes to `/realtime/dindis/{dindiId}/location` permitted only for assigned `DINDI_LEADER` or `ADMIN`.
- **SOS Access**: Realtime SOS documents readable only by incident owner, assigned responders (`VOLUNTEER`, `MEDICAL_TEAM`, `POLICE`), and `ADMIN`.

---

## 5. Standard Realtime Event Envelope

Defined in [`services/api/realtime_event_contract.py`](file:///d:/wari-main/services/api/realtime_event_contract.py):

```json
{
  "event_type": "DINDI_LOCATION_UPDATED",
  "entity_id": "dindi-12-uuid",
  "actor_id": "leader-user-uuid",
  "dindi_id": "dindi-12-uuid",
  "timestamp": "2026-08-29T15:00:00Z",
  "payload": {
    "latitude": 17.6741,
    "longitude": 75.3279,
    "speed_kmh": 3.5,
    "is_beacon_active": true
  },
  "authorization_scope": "DINDI_MEMBERS",
  "version": "1.0"
}
```

---

## 6. Offline Operations Strategy & Connection States

### Connection States
- `LIVE`: Connected to backend/Firestore stream; active real-time updates.
- `RECONNECTING`: Network dropped; attempting automatic reconnect.
- `OFFLINE`: Network unavailable; serving cached data.
- `LAST_KNOWN`: Rendering last verified timestamped location/data with offline banner indicator.

### Feature Offline Matrix
- **Emergency SOS**: `OFFLINE_QUEUE_REQUIRED` (Local queue + SMS fallback gateway).
- **Live Dindi GPS**: `ONLINE_ONLY` (Renders last known location with clear timestamp label).
- **Digital Dindi Pass**: `OFFLINE_CAPABLE` (Stored in local encrypted storage).
- **Offline Abhangavali**: `OFFLINE_CAPABLE` (100% accessible offline via local database).
- **Health Shield**: `OFFLINE_CAPABLE` (Calculates heat index locally from cached environmental data).
