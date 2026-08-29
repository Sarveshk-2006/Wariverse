import firebase_admin
from firebase_admin import credentials, firestore
import random
import math

def seed_firestore():
    # Initialize Firebase Admin if not initialized
    if not firebase_admin._apps:
        try:
            firebase_admin.initialize_app()
        except Exception:
            pass

    try:
        db = firestore.client()
    except Exception as e:
        print(f"Firestore client notice: {e}")
        return

    print("Cleaning and seeding Firestore collections with distinct GPS coordinates...")

    # Realistic Pilgrimage Route Points (Alandi -> Pune -> Saswad -> Jejuri -> Wakhari -> Pandharpur)
    route_points = [
        (18.6754, 73.8967, "Alandi Temple Campus"),
        (18.6475, 73.7745, "Akurdi Vitthal Grounds"),
        (18.5314, 73.8446, "Pune Shivajinagar Annadhan Camp"),
        (18.5180, 73.8680, "Pune Nana Peth Palkhi Rest"),
        (18.5100, 73.8800, "Pune Racecourse Grounds"),
        (18.3428, 73.9872, "Saswad ZP School Ground"),
        (18.2758, 74.1593, "Jejuri Khandoba Mandir Campus"),
        (17.8800, 75.1500, "Wathar Palkhi Halt"),
        (17.6845, 75.3160, "Wakhari Gol Ringan Ground"),
        (17.6780, 75.3250, "Pandharpur Vitthal Mandir Complex")
    ]

    def offset_coords(lat, lon, index):
        # Evenly space points 300m - 1200m apart so distances are unique and distinct
        dist_km = (index + 1) * 0.25
        deg = dist_km / 111.0
        angle = (index * 45) * (math.pi / 180.0)
        return round(lat + deg * math.cos(angle), 6), round(lon + deg * math.sin(angle), 6)

    # 1. PURGE & SEED WATER POINTS
    water_docs = [
        {"id": "wp_01", "name": "Alandi Temple Water Kiosk", "type": "drinking", "status": "AVAILABLE", "capacity_liters": 5000},
        {"id": "wp_02", "name": "Akurdi Vitthal Pyaav", "type": "filtered", "status": "AVAILABLE", "capacity_liters": 3500},
        {"id": "wp_03", "name": "Shivajinagar Hydration Booth", "type": "drinking", "status": "AVAILABLE", "capacity_liters": 4000},
        {"id": "wp_04", "name": "Nana Peth Seva Jal Center", "type": "filtered", "status": "AVAILABLE", "capacity_liters": 2500},
        {"id": "wp_05", "name": "Dive Ghat Refreshment Tanker", "type": "tanker", "status": "AVAILABLE", "capacity_liters": 8000},
        {"id": "wp_06", "name": "Saswad Annadhan Water Point", "type": "drinking", "status": "AVAILABLE", "capacity_liters": 6000},
        {"id": "wp_07", "name": "Jejuri Mandir Jal Kiosk", "type": "filtered", "status": "AVAILABLE", "capacity_liters": 3000},
        {"id": "wp_08", "name": "Wakhari Ringan Water Tanker", "type": "tanker", "status": "AVAILABLE", "capacity_liters": 10000},
        {"id": "wp_09", "name": "Pandharpur Main Pyaav Hub", "type": "drinking", "status": "AVAILABLE", "capacity_liters": 15000},
    ]

    batch = db.batch()
    # Delete existing water_points
    existing_wp = db.collection('water_points').get()
    for doc in existing_wp:
        batch.delete(doc.reference)

    for i, w in enumerate(water_docs):
        rp = route_points[i % len(route_points)]
        lat, lon = offset_coords(rp[0], rp[1], i)
        w_data = {
            "id": w["id"],
            "name": w["name"],
            "latitude": lat,
            "longitude": lon,
            "water_type": w["type"],
            "status": w["status"],
            "capacity_liters": w["capacity_liters"],
            "address": f"Near {rp[2]}"
        }
        batch.set(db.collection('water_points').doc(w["id"]), w_data)

    # 2. PURGE & SEED FOOD CENTERS
    food_docs = [
        {"id": "fc_01", "name": "Alandi Mauli Annadhan Seva", "capacity": 1500, "provider": "Alandi Sansthan Trust"},
        {"id": "fc_02", "name": "Akurdi Mahaprasad Pavilion", "capacity": 1200, "provider": "Vitthal Seva Mandal"},
        {"id": "fc_03", "name": "Shivajinagar Food Camp", "capacity": 2000, "provider": "Pune Varkari Seva"},
        {"id": "fc_04", "name": "Saswad Mahaprasad Pandal", "capacity": 1800, "provider": "Saswad Annadhan Trust"},
        {"id": "fc_05", "name": "Jejuri Bhandara Meal Center", "capacity": 2500, "provider": "Jejuri Devsthan"},
        {"id": "fc_06", "name": "Wakhari Ringan Annadhan Tent", "capacity": 3000, "provider": "Pandharpur Seva Sangh"},
    ]

    existing_fc = db.collection('food_centers').get()
    for doc in existing_fc:
        batch.delete(doc.reference)

    for i, f in enumerate(food_docs):
        rp = route_points[(i + 2) % len(route_points)]
        lat, lon = offset_coords(rp[0], rp[1], i + 1)
        f_data = {
            "id": f["id"],
            "name": f["name"],
            "latitude": lat,
            "longitude": lon,
            "capacity": f["capacity"],
            "current_count": random.randint(100, f["capacity"] - 200),
            "estimated_queue_minutes": random.randint(3, 15),
            "available_now": True,
            "provider": f["provider"],
            "address": f"Near {rp[2]}"
        }
        batch.set(db.collection('food_centers').doc(f["id"]), f_data)

    batch.commit()
    print("✓ Firestore collections cleaned and seeded with distinct, non-duplicate records!")

if __name__ == "__main__":
    seed_firestore()
