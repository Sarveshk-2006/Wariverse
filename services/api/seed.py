"""
WariVerse AI — Demo Data Seeder
Generates realistic Wari pilgrimage data for hackathon demonstration.
All data is clearly marked as DEMO DATA.
"""
import asyncio
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from datetime import datetime, timedelta
import random
import uuid
import math

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from models import (
    Base, User, Profile, VolunteerProfile, FoodCentre, WaterPoint, Toilet, Shelter,
    WellnessCentre, ChargingStation, MedicalLocation, SOSIncident, CommunityPost, HelpRequest, HelpOffer,
    LostPerson, CrowdZone, RelayNode, Notification, WeatherAlert, Dindi, DindiHalt, DindiMember, DindiPost, DindiAudioStream,
    UserRole, SOSCategory, SOSStatus, PostType, HelpCategory, HelpStatus,
    ToiletStatus, WaterStatus, CrowdLevel, RelayStatus, VolunteerStatus, MealType
)
from auth import get_password_hash

# Wari route center: Pandharpur
PANDHARPUR_LAT = 17.6741
PANDHARPUR_LON = 75.3279

# Wari route points (realistic approximation)
ROUTE_POINTS = [
    (17.6741, 75.3279, "Pandharpur - Vitthal Mandir"),
    (17.6850, 75.3200, "Pandharpur - Rukmini Mandir"),
    (17.7100, 75.3100, "Malshiras"),
    (17.7300, 75.2900, "Velapur"),
    (17.7600, 75.2700, "Tembi Naka"),
    (17.7900, 75.2400, "Phaltan"),
    (17.8200, 75.2100, "Barad"),
    (17.8500, 75.1800, "Lonand"),
    (17.8800, 75.1500, "Wathar"),
    (17.9100, 75.1200, "Wai"),
]

def rand_near(lat, lon, radius_km=0.5):
    """Generate a random point near the given coordinates."""
    r = radius_km / 111.0  # degrees
    angle = random.uniform(0, 2 * math.pi)
    dlat = r * math.cos(angle) * random.uniform(0.3, 1.0)
    dlon = r * math.sin(angle) * random.uniform(0.3, 1.0)
    return lat + dlat, lon + dlon

def pick_route_point():
    return random.choice(ROUTE_POINTS)

DEMO_PASSWORD = "Demo@123"

from config import get_settings

settings = get_settings()
DATABASE_URL = settings.DATABASE_URL

async def seed():
    engine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)

    Session = async_sessionmaker(engine, expire_on_commit=False)

    async with Session() as db:
        print("Seeding WariVerse AI Demo Data...")

        # ── Demo Accounts ─────────────────────────────────────────────────────
        demo_accounts = [
            ("varkari@wariverse.demo", "Ramabai Shinde", UserRole.VARKARI),
            ("volunteer@wariverse.demo", "Mahesh Patil", UserRole.VOLUNTEER),
            ("medical@wariverse.demo", "Dr. Priya Kulkarni", UserRole.MEDICAL_TEAM),
            ("police@wariverse.demo", "Inspector Anand More", UserRole.POLICE),
            ("ngo@wariverse.demo", "Sanjay Deshmukh", UserRole.NGO),
            ("provider@wariverse.demo", "Vithal Annadan Trust", UserRole.SERVICE_PROVIDER),
            ("cleaner@wariverse.demo", "Suresh Kamble", UserRole.CLEANER),
            ("leader@wariverse.demo", "Chopdar Sopanrao Maharaj", UserRole.DINDI_LEADER),
            ("admin@wariverse.demo", "WariVerse Admin", UserRole.ADMIN),
        ]

        demo_users = {}
        for email, name, role in demo_accounts:
            user = User(
                id=str(uuid.uuid4()),
                email=email,
                hashed_password=get_password_hash(DEMO_PASSWORD),
                role=role,
                is_active=True,
                is_verified=True,
            )
            db.add(user)
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.2)
            profile = Profile(
                id=str(uuid.uuid4()),
                user_id=user.id,
                display_name=name,
                phone=f"+91{random.randint(7000000000, 9999999999)}",
                blood_group=random.choice(["A+", "B+", "O+", "AB+", "A-", "B-"]),
                emergency_contact=f"Family Member",
                emergency_phone=f"+91{random.randint(7000000000, 9999999999)}",
                language="mr",
                latitude=lat,
                longitude=lon,
                age=random.randint(25, 65),
                city=random.choice(["Pune", "Nashik", "Aurangabad", "Solapur"]),
            )
            db.add(profile)
            demo_users[email] = user
            print(f"  [OK] Demo account: {email}")

        # ── 100 Varkari Users ──────────────────────────────────────────────────
        varkari_names = [
            "Tukaram Bhau", "Dnyanoba Mane", "Vitthal Shinde", "Pandhari Das",
            "Savitribai Kamble", "Laxmi Pawar", "Radhabai Jadhav", "Sushila Desai",
            "Namdev Dole", "Eknath Thorat", "Sopan Bhor", "Changdev Raut",
            "Muktabai Salve", "Janabai Pol", "Kanhopatra Kale", "Bahina Bai",
            "Rohidas Kumar", "Chokha Mela", "Gora Kumbhar", "Sena Nhavi",
            "Narhari Sonar", "Vishoba Khechara", "Banka Mahar", "Parisa Bhagwat",
        ] * 5

        varkari_users = []
        for i, name in enumerate(varkari_names[:100]):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 1.0)
            user = User(
                id=str(uuid.uuid4()),
                email=f"varkari{i+1}@wariverse.demo",
                hashed_password=get_password_hash(DEMO_PASSWORD),
                role=UserRole.VARKARI,
                is_active=True,
                is_verified=random.choice([True, False]),
            )
            db.add(user)
            profile = Profile(
                id=str(uuid.uuid4()),
                user_id=user.id,
                display_name=name,
                blood_group=random.choice(["A+", "B+", "O+", "AB+"]),
                language=random.choice(["mr", "hi", "en"]),
                latitude=lat,
                longitude=lon,
                age=random.randint(45, 80),
                city=random.choice(["Pune", "Nashik", "Satara", "Kolhapur", "Aurangabad"]),
            )
            db.add(profile)
            varkari_users.append(user)

        print(f"  [OK] 100 Varkari users created")

        # ── 20 Volunteers ──────────────────────────────────────────────────────
        volunteer_users = []
        for i in range(20):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.5)
            user = User(
                id=str(uuid.uuid4()),
                email=f"vol{i+1}@wariverse.demo",
                hashed_password=get_password_hash(DEMO_PASSWORD),
                role=UserRole.VOLUNTEER,
                is_active=True,
                is_verified=True,
            )
            db.add(user)
            vol_name = f"Volunteer {i+1}"
            profile = Profile(
                id=str(uuid.uuid4()),
                user_id=user.id,
                display_name=vol_name,
                latitude=lat,
                longitude=lon,
                age=random.randint(20, 40),
            )
            db.add(profile)
            vol_profile = VolunteerProfile(
                id=str(uuid.uuid4()),
                user_id=user.id,
                status=random.choice([VolunteerStatus.AVAILABLE, VolunteerStatus.AVAILABLE, VolunteerStatus.BUSY]),
                latitude=lat,
                longitude=lon,
                skills=random.sample(["first_aid", "crowd_management", "water_distribution", "transport", "translation"], k=2),
                organization=random.choice(["Wari Seva Mandal", "Vitthal Bhakt Samaj", "Pandhari Sewa Trust"]),
            )
            db.add(vol_profile)
            volunteer_users.append(user)

        print(f"  [OK] 20 Volunteer users created")

        # ── 15 Food Centres ────────────────────────────────────────────────────
        food_names = [
            "Vithal Annadan Kendra", "Rukhmini Bhojanalaay", "Sant Tukaram Prasad",
            "Mauli Annadan Trust", "Warkari Seva Bhojan", "Panduranga Annadan",
            "Dnyaneshwar Prasadalay", "Namdev Bhojan Griha", "Sopandev Annadan",
            "Changdev Seva Kendra", "Muktabai Bhojan Trust", "Janabai Annadan Sewa",
            "Eknath Maharaj Prasad", "Tukaram Maharaj Annadan", "Bahina Bai Seva"
        ]
        food_providers = ["Wari Seva Mandal", "Rotary Club", "Local Trust", "Temple Committee", "NGO Relief"]

        food_centres = []
        for i, name in enumerate(food_names):
            rp = ROUTE_POINTS[(i + 3) % len(ROUTE_POINTS)]
            lat, lon = rand_near(rp[0], rp[1], 0.2 + (i * 0.12))
            meals = random.sample(["BREAKFAST", "LUNCH", "DINNER", "SNACKS"], k=random.randint(2, 4))
            fc = FoodCentre(
                id=f"fc_{i+1:02d}",
                name=name,
                provider=random.choice(food_providers),
                latitude=round(lat, 6),
                longitude=round(lon, 6),
                meal_types=meals,
                available_now=random.choice([True, True, True, False]),
                opening_time=random.choice(["05:00", "06:00", "07:00"]),
                closing_time=random.choice(["20:00", "21:00", "22:00"]),
                estimated_queue_minutes=random.randint(2, 25),
                capacity=random.randint(300, 2000),
                current_count=random.randint(50, 800),
                hygiene_rating=round(random.uniform(3.5, 5.0), 1),
                address=f"Wari Route, Near {rp[2]}",
            )
            db.add(fc)
            food_centres.append(fc)

        print(f"  [OK] 15 Food centres created")

        # ── 15 Water Points ────────────────────────────────────────────────────
        water_names = [
            "Pandharpur Water Booth 1", "Bhima River Water Point", "Route Water Kiosk A",
            "Warkari Pyaav 1", "Panduranga Jalaseva", "Seva Water Point B",
            "Mauli Jal Kendra", "Village Water Booth", "Highway Water Station",
            "Emergency Water Tanker 1", "Seva Jal Booth", "Temple Water Point",
            "Medical Camp Water", "Route Water Kiosk B", "Community Water Hub"
        ]
        water_statuses = [WaterStatus.AVAILABLE, WaterStatus.AVAILABLE, WaterStatus.AVAILABLE, WaterStatus.LOW, WaterStatus.EMPTY]

        water_points = []
        for i, name in enumerate(water_names):
            rp = ROUTE_POINTS[i % len(ROUTE_POINTS)]
            lat, lon = rand_near(rp[0], rp[1], 0.3 + (i * 0.15))
            wp = WaterPoint(
                id=f"wp_{i+1:02d}",
                name=name,
                latitude=round(lat, 6),
                longitude=round(lon, 6),
                status=random.choice(water_statuses),
                water_type=random.choice(["drinking", "drinking", "filtered", "tanker"]),
                capacity_liters=random.randint(500, 5000),
                address=f"Wari Route, {rp[2]}",
            )
            db.add(wp)
            water_points.append(wp)

        print(f"  [OK] 15 Water points created")

        charging_stations = [
            ChargingStation(id=str(uuid.uuid4()), name="Wakhari Trust Charging Hub", latitude=17.6845, longitude=75.3160, total_ports=24, available_ports=8, queue_minutes=5, is_free=True),
            ChargingStation(id=str(uuid.uuid4()), name="BSNL Mobile Wi-Fi & Charge Point", latitude=17.6780, longitude=75.3250, total_ports=50, available_ports=12, queue_minutes=15, is_free=True),
            ChargingStation(id=str(uuid.uuid4()), name="Private Pay-and-Charge Tent", latitude=17.6760, longitude=75.3290, total_ports=16, available_ports=4, queue_minutes=2, is_free=False),
        ]
        db.add_all(charging_stations)
        print(f"  [OK] {len(charging_stations)} Charging stations created")

        # ── 20 Toilets ─────────────────────────────────────────────────────────
        toilet_statuses = [ToiletStatus.CLEAN, ToiletStatus.CLEAN, ToiletStatus.NEEDS_CLEANING, ToiletStatus.MAINTENANCE]

        toilets = []
        for i in range(20):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.3)
            minutes_ago = random.randint(5, 180)
            t = Toilet(
                id=str(uuid.uuid4()),
                name=f"Sauchalay {i+1} - {rp[2]}",
                latitude=lat,
                longitude=lon,
                status=random.choice(toilet_statuses),
                total_units=random.randint(4, 12),
                gender=random.choice(["mixed", "male", "female"]),
                last_cleaned_at=datetime.utcnow() - timedelta(minutes=minutes_ago),
                rating=round(random.uniform(2.5, 5.0), 1),
                address=f"Near {rp[2]}",
                qr_code=f"WV-T-{i+1:04d}",
            )
            db.add(t)
            toilets.append(t)

        print(f"  [OK] 20 Toilets created")

        # ── 10 Shelters ────────────────────────────────────────────────────────
        shelter_names = [
            "Vitthal Bhakta Niwas", "Warkari Dharamshala", "Seva Niwas 1",
            "Pandharpur Choultry", "Bhima Kinari Niwas", "Sant Tukaram Kutir",
            "Mauli Seva Niwas", "Panduranga Ashram", "Route Rest Camp A",
            "Emergency Shelter Hub"
        ]
        shelters = []
        for i, name in enumerate(shelter_names):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.4)
            cap = random.randint(50, 300)
            occ = random.randint(10, cap - 5)
            s = Shelter(
                id=str(uuid.uuid4()),
                name=name,
                latitude=lat,
                longitude=lon,
                capacity=cap,
                current_occupancy=occ,
                available_now=occ < cap,
                provider=random.choice(["Temple Trust", "NGO", "Government", "Wari Committee"]),
                address=f"Near {rp[2]}",
                amenities=random.sample(["drinking_water", "toilets", "meals", "medical", "charging"], k=3),
            )
            db.add(s)
            shelters.append(s)

        print(f"  [OK] 10 Shelters created")

        # ── 10 Wellness Centres ────────────────────────────────────────────────
        wellness_names = [
            "Paay Seva Kendra 1", "Foot Care Camp A", "Massage Centre Pandharpur",
            "Ayurvedic Seva Camp", "Warkari Vishram Kendra", "Paay Seva B",
            "Rest & Recovery Hub", "Wellness Camp Route A", "Seva Arogyam", "Holistic Care Camp"
        ]
        wellness_centres = []
        for i, name in enumerate(wellness_names):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.3)
            wc = WellnessCentre(
                id=str(uuid.uuid4()),
                name=name,
                latitude=lat,
                longitude=lon,
                services=random.sample(["foot_massage", "foot_care", "blister_treatment", "rest", "meditation", "physiotherapy"], k=3),
                available_now=random.choice([True, True, False]),
                address=f"Near {rp[2]}",
            )
            db.add(wc)
            wellness_centres.append(wc)

        print(f"  [OK] 10 Wellness centres created")

        # ── Medical Locations ──────────────────────────────────────────────────
        medical_names = [
            ("District Hospital Pandharpur", "hospital"),
            ("Medical Camp Alpha", "camp"),
            ("First Aid Post 1", "first_aid"),
            ("Mobile Medical Unit A", "camp"),
            ("First Aid Post 2", "first_aid"),
            ("Ambulance Station 1", "ambulance"),
            ("Medical Camp Beta", "camp"),
            ("First Aid Post 3", "first_aid"),
            ("Eye Care Camp", "camp"),
            ("Ambulance Station 2", "ambulance"),
        ]
        medical_locs = []
        for name, loc_type in medical_names:
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.4)
            ml = MedicalLocation(
                id=str(uuid.uuid4()),
                name=name,
                location_type=loc_type,
                latitude=lat,
                longitude=lon,
                services=random.sample(["emergency", "first_aid", "medicines", "ambulance", "blood_test", "xray"], k=3),
                available=random.choice([True, True, True, False]),
                capacity=random.randint(10, 100),
                contact=f"+91{random.randint(7000000000, 9999999999)}",
                address=f"Near {rp[2]}",
            )
            db.add(ml)
            medical_locs.append(ml)

        print(f"  [OK] 10 Medical locations created")

        # ── 10 Crowd Zones ─────────────────────────────────────────────────────
        crowd_levels_map = {
            CrowdLevel.GREEN: (0.0, 0.35),
            CrowdLevel.YELLOW: (0.35, 0.60),
            CrowdLevel.ORANGE: (0.60, 0.80),
            CrowdLevel.RED: (0.80, 1.0),
        }
        crowd_zones = []
        for i, rp in enumerate(ROUTE_POINTS):
            level = random.choice(list(CrowdLevel))
            lo, hi = crowd_levels_map[level]
            density = random.uniform(lo, hi)
            cz = CrowdZone(
                id=str(uuid.uuid4()),
                name=f"Zone {rp[2]}",
                latitude=rp[0],
                longitude=rp[1],
                radius_m=random.randint(200, 800),
                current_density=round(density, 2),
                crowd_level=level,
                estimated_count=int(density * random.randint(500, 5000)),
            )
            db.add(cz)
            crowd_zones.append(cz)

        print(f"  [OK] 10 Crowd zones created")

        # ── 10 Relay Nodes ─────────────────────────────────────────────────────
        relay_nodes = []
        for i in range(10):
            rp = ROUTE_POINTS[i % len(ROUTE_POINTS)]
            lat, lon = rand_near(rp[0], rp[1], 0.2)
            is_gateway = (i == 9)
            rn = RelayNode(
                id=str(uuid.uuid4()),
                node_id=f"WV-NODE-{i+1:03d}",
                name=f"{'Gateway Node' if is_gateway else f'Relay Node {i+1}'} ({rp[2]})",
                latitude=lat,
                longitude=lon,
                battery_pct=random.randint(40, 100),
                signal_strength=random.randint(-90, -50),
                is_gateway=is_gateway,
                is_online=random.choice([True, True, True, False]),
                last_seen=datetime.utcnow() - timedelta(minutes=random.randint(0, 30)),
            )
            db.add(rn)
            relay_nodes.append(rn)

        print(f"  [OK] 10 Relay nodes created")

        # ── Sample SOS Incidents ───────────────────────────────────────────────
        sos_data = [
            (SOSCategory.MEDICAL, SOSStatus.RESOLVED, "Elderly pilgrim fainted"),
            (SOSCategory.DEHYDRATION, SOSStatus.IN_PROGRESS, "Severe dehydration near route"),
            (SOSCategory.FATIGUE, SOSStatus.VOLUNTEER_ASSIGNED, "Need rest assistance"),
            (SOSCategory.LOST, SOSStatus.ACKNOWLEDGED, "Lost separated from family"),
            (SOSCategory.MEDICAL, SOSStatus.CREATED, "Chest pain reported"),
        ]
        sos_incidents = []
        for i, (cat, stat, desc) in enumerate(sos_data):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.5)
            user = random.choice(varkari_users) if varkari_users else list(demo_users.values())[0]
            sos = SOSIncident(
                id=str(uuid.uuid4()),
                user_id=user.id,
                latitude=lat,
                longitude=lon,
                category=cat,
                status=stat,
                description=desc,
                blood_group=random.choice(["A+", "B+", "O+"]),
                is_offline=random.choice([False, False, True]),
                responder_name="Volunteer" if stat != SOSStatus.CREATED else None,
                responder_distance_m=random.uniform(50, 500) if stat != SOSStatus.CREATED else None,
                created_at=datetime.utcnow() - timedelta(minutes=random.randint(5, 120)),
            )
            db.add(sos)
            sos_incidents.append(sos)

        print(f"  [OK] 5 SOS incidents created")

        # ── Community Posts ────────────────────────────────────────────────────
        community_post_data = [
            (PostType.FOOD_AVAILABLE, "मोफत अन्नदान उपलब्ध! 400 मीटर पुढे. Free Annadan available 400m ahead! Queue only 5 min.", True),
            (PostType.WATER_AVAILABLE, "पाणी पिण्यासाठी उपलब्ध आहे. Fresh drinking water available at next junction.", True),
            (PostType.ROUTE_WARNING, "⚠️ जड गर्दी - या मार्गावर जास्त गर्दी आहे. Heavy crowd near this stretch. Alternate route suggested.", False),
            (PostType.MEDICAL_HELP, "Medical camp 700m ahead. Free medicines available. डॉक्टर उपलब्ध आहेत.", True),
            (PostType.LOST_PERSON, "हरवलेली व्यक्ती: वृद्ध महिला, पांढरी साडी. Missing: elderly woman, white saree near Zone 3.", False),
            (PostType.HELP_REQUEST, "व्हीलचेअर हवी आहे. Need wheelchair assistance urgently.", False),
            (PostType.SHELTER_AVAILABLE, "Dharamshala has 20 spots available. No charge. धर्मशाळेत जागा आहे.", True),
            (PostType.WEATHER_WARNING, "⛈️ पुढे पाऊस येणार आहे. Heavy rain expected in 30 minutes. Seek shelter.", False),
            (PostType.FOOD_AVAILABLE, "Lunch available till 3PM. 1200 meals capacity. आजचा प्रसाद: भाकरी + वरण", True),
            (PostType.GENERAL, "जय हरी विठ्ठल! 🙏 Safe journey to all Varkaris. Helpers available throughout route.", True),
        ]

        vol_user = demo_users.get("volunteer@wariverse.demo")
        varkari_user = demo_users.get("varkari@wariverse.demo")

        community_posts = []
        for i, (ptype, msg, verified) in enumerate(community_post_data):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.8)
            author = vol_user if i % 2 == 0 else varkari_user
            post = CommunityPost(
                id=str(uuid.uuid4()),
                author_id=author.id,
                author_name=author.email.split("@")[0],
                post_type=ptype,
                message=msg,
                latitude=lat,
                longitude=lon,
                radius_km=random.choice([1.0, 2.0, 5.0]),
                is_verified=verified,
                upvotes=random.randint(0, 45),
                expires_at=datetime.utcnow() + timedelta(hours=random.randint(1, 6)),
                created_at=datetime.utcnow() - timedelta(minutes=random.randint(2, 90)),
            )
            db.add(post)
            community_posts.append(post)

        print(f"  [OK] 10 Community posts created")

        # ── Help Requests + Offers ─────────────────────────────────────────────
        help_categories = [HelpCategory.FOOD, HelpCategory.WATER, HelpCategory.WHEELCHAIR, HelpCategory.CHARGER, HelpCategory.MEDICINE]

        help_requests = []
        for i in range(8):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.5)
            user = random.choice(varkari_users) if varkari_users else varkari_user
            cat = random.choice(help_categories)
            req = HelpRequest(
                id=str(uuid.uuid4()),
                user_id=user.id,
                category=cat,
                description=f"Need {cat.value.lower()} assistance urgently",
                latitude=lat,
                longitude=lon,
                urgency=random.randint(5, 10),
                status=random.choice([HelpStatus.OPEN, HelpStatus.MATCHED, HelpStatus.FULFILLED]),
            )
            db.add(req)
            help_requests.append(req)

        for i in range(8):
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.5)
            user = random.choice(volunteer_users) if volunteer_users else vol_user
            cat = random.choice(help_categories)
            offer = HelpOffer(
                id=str(uuid.uuid4()),
                user_id=user.id,
                category=cat,
                description=f"Offering {cat.value.lower()} to pilgrims",
                latitude=lat,
                longitude=lon,
                quantity=random.randint(1, 20),
                status=random.choice([HelpStatus.OPEN, HelpStatus.OPEN, HelpStatus.FULFILLED]),
            )
            db.add(offer)

        print(f"  [OK] 8 Help requests + 8 offers created")

        # ── Lost Persons ───────────────────────────────────────────────────────
        lost_names = [
            ("Govinda Tukaram", 72, "male"),
            ("Sarita Baburao", 65, "female"),
            ("Bhimrao Dnyanoba", 68, "male"),
            ("Yamuna Krishnarao", 70, "female"),
        ]
        lost_persons = []
        for name, age, gender in lost_names:
            rp = random.choice(ROUTE_POINTS)
            lat, lon = rand_near(rp[0], rp[1], 0.5)
            lp = LostPerson(
                id=str(uuid.uuid4()),
                name=name,
                age=age,
                gender=gender,
                description=f"{'Elderly man' if gender == 'male' else 'Elderly woman'}, wearing traditional Wari attire",
                last_seen_latitude=lat,
                last_seen_longitude=lon,
                last_seen_at=datetime.utcnow() - timedelta(hours=random.randint(1, 8)),
                reported_by=varkari_user.id,
                emergency_contact=f"+91{random.randint(7000000000, 9999999999)}",
                blood_group=random.choice(["A+", "B+", "O+"]),
                status=random.choice(["MISSING", "MISSING", "FOUND"]),
                qr_code=f"WV-LP-{random.randint(1000, 9999)}",
            )
            db.add(lp)
            lost_persons.append(lp)

        print(f"  [OK] 4 Lost person cases created")

        # ── Weather Alerts ─────────────────────────────────────────────────────
        db.add(WeatherAlert(
            id=str(uuid.uuid4()),
            alert_type="HEAVY_RAIN",
            message="Heavy rain expected in Pandharpur region in next 2 hours. Pilgrims advised to seek shelter.",
            severity="HIGH",
            latitude=PANDHARPUR_LAT,
            longitude=PANDHARPUR_LON,
            is_active=True,
            expires_at=datetime.utcnow() + timedelta(hours=3),
        ))
        db.add(WeatherAlert(
            id=str(uuid.uuid4()),
            alert_type="HEAT_WAVE",
            message="High temperature alert: 38°C expected. Stay hydrated. पाणी पित रहा.",
            severity="MEDIUM",
            is_active=True,
        ))

        print(f"  [OK] Weather alerts created")

        # ── Notifications for demo users ───────────────────────────────────────
        admin_user = demo_users["admin@wariverse.demo"]
        vol_user_obj = demo_users["volunteer@wariverse.demo"]

        notifications_data = [
            (admin_user.id, "🆘 New SOS Incident", "Medical emergency reported near Zone 3. Volunteer assigned.", "SOS", "CRITICAL"),
            (admin_user.id, "🔴 Crowd Alert", "Zone RED detected near Pandharpur Main Gate. Estimated 3,200 people.", "CROWD", "HIGH"),
            (admin_user.id, "⚠️ Food Shortage Risk", "Lunch demand may exceed capacity by 1,300 meals. AI Prediction.", "RESOURCE", "HIGH"),
            (vol_user_obj.id, "📍 New SOS Nearby", "SOS incident 450m from your location. Medical emergency.", "SOS", "CRITICAL"),
            (vol_user_obj.id, "🤝 Help Request Match", "Your water offer matched with a nearby pilgrim.", "MATCH", "MEDIUM"),
        ]

        for uid, title, msg, ntype, priority in notifications_data:
            db.add(Notification(
                id=str(uuid.uuid4()),
                user_id=uid,
                title=title,
                message=msg,
                notification_type=ntype,
                priority=priority,
                is_read=False,
            ))

        print(f"  [OK] Notifications seeded")

        # ─── Dindi Ecosystem Seeding ──────────────────────────────────────────
        leader_user = demo_users["leader@wariverse.demo"]
        varkari_user = demo_users["varkari@wariverse.demo"]

        dindi_data = [
            {
                "name": "Sant Tukaram Maharaj Dindi No. 1",
                "code": "DINDI-TUKARAM-01",
                "origin": "Dehu",
                "palkhi_type": "Sant Tukaram Maharaj Palkhi",
                "leader": leader_user,
                "total_members": 450,
                "lat": 18.5204, "lon": 73.8567,
                "halts": [
                    (1, "DEPARTURE", "🌅 Morning Departure & Pooja", "Dehu Gatha Mandir", 18.7200, 73.7667, "05:00", "06:00", "Dawn Aarti & Morning Palkhi Departure"),
                    (1, "BREAKFAST", "🍵 Morning Tea & Breakfast Halt", "Akurdi Vitthal Temple Ground", 18.6475, 73.7745, "08:30", "09:30", "Free Poha & Tea distributed by Local Mandal"),
                    (1, "LUNCH", "🍛 Afternoon Lunch Halt (Annachhatra)", "Pune Shivajinagar Annachhatra Camp", 18.5314, 73.8446, "12:30", "14:00", "Free Mahaprasad provided by Vithal Annadan Trust"),
                    (1, "RINGAN", "🎪 First Gol Ringan Ceremony", "Pune Racecourse Grounds", 18.5100, 73.8800, "16:30", "18:00", "Traditional Horse Ringan & Abhang Chanting"),
                    (1, "NIGHT_SHELTER", "🏕️ Night Halt & Kirtan", "Pune Nana Peth Dharamshala", 18.5180, 73.8680, "20:00", "05:00", "Shelter & Dinner halt with overnight Haripath"),
                    (2, "DEPARTURE", "🌅 Day 2 Morning Start", "Pune Nana Peth", 18.5180, 73.8680, "05:30", "06:30", "Departure towards Dive Ghat"),
                    (2, "LUNCH", "🍛 Lunch & Rest Halt", "Saswad ZP School Ground", 18.3428, 73.9872, "13:00", "14:30", "Lunch halt after crossing Dive Ghat"),
                    (2, "NIGHT_SHELTER", "🛕 Temple Stop & Night Stay", "Jejuri Khandoba Mandir Campus", 18.2758, 74.1593, "19:30", "05:00", "Evening Abhang Sandhya & Night Stay"),
                ]
            },
            {
                "name": "Sant Dnyaneshwar Maharaj Palkhi Dindi No. 4",
                "code": "DINDI-MAULI-04",
                "origin": "Alandi",
                "palkhi_type": "Sant Dnyaneshwar Maharaj Palkhi",
                "leader": leader_user,
                "total_members": 620,
                "lat": 18.6754, "lon": 73.8967,
                "halts": [
                    (1, "DEPARTURE", "🌅 Palkhi Departure", "Alandi Temple Complex", 18.6754, 73.8967, "05:00", "06:00", "Alandi Mauli Sanjeevan Samadhi Pooja"),
                    (1, "LUNCH", "🍛 Lunch Halt", "Pune Sangamwadi Ground", 18.5400, 73.8680, "13:00", "14:30", "Mahaprasad Lunch Halt"),
                    (1, "NIGHT_SHELTER", "🏕️ Night Stay", "Pune Palkhi Vithoba Temple", 18.5190, 73.8600, "19:00", "05:00", "Overnight Kirtan & Rest"),
                ]
            },
            {
                "name": "Pune Varkari Mandal Dindi",
                "code": "DINDI-PUNE-12",
                "origin": "Pune",
                "palkhi_type": "Pune Joint Dindi",
                "leader": leader_user,
                "total_members": 180,
                "lat": 18.5204, "lon": 73.8567,
                "halts": [
                    (1, "DEPARTURE", "🌅 Group Assembly", "Pune Sarasbaug", 18.5000, 73.8500, "06:00", "07:00", "Gathering of Pune Varkari Mandal"),
                    (1, "LUNCH", "🍛 Lunch Stop", "Saswad Palkhi Ground", 18.3428, 73.9872, "13:00", "14:30", "Lunch & Tea Halt"),
                ]
            }
        ]

        for d_info in dindi_data:
            qr_data = f"https://web-one-tau-17.vercel.app/dashboard/varkari/dindi?code={d_info['code']}&token={str(uuid.uuid4())[:8]}"
            dindi_obj = Dindi(
                id=str(uuid.uuid4()),
                name=d_info["name"],
                code=d_info["code"],
                leader_user_id=d_info["leader"].id,
                leader_name="Chopdar Sopanrao Maharaj",
                origin=d_info["origin"],
                palkhi_type=d_info["palkhi_type"],
                total_members=d_info["total_members"],
                qr_code_data=qr_data,
                current_latitude=d_info["lat"],
                current_longitude=d_info["lon"],
                is_beacon_active=True,
                firebase_topic=f"dindi_{d_info['code'].lower()}"
            )
            db.add(dindi_obj)

            # Enroll leader & varkari member
            db.add(DindiMember(id=str(uuid.uuid4()), dindi_id=dindi_obj.id, user_id=leader_user.id, role_in_dindi="LEADER"))
            db.add(DindiMember(id=str(uuid.uuid4()), dindi_id=dindi_obj.id, user_id=varkari_user.id, role_in_dindi="MEMBER"))

            # Add halts
            for day_num, h_type, title, loc, lat, lon, arr, dep, notes in d_info["halts"]:
                db.add(DindiHalt(
                    id=str(uuid.uuid4()),
                    dindi_id=dindi_obj.id,
                    day_number=day_num,
                    halt_type=h_type,
                    title=title,
                    location_name=loc,
                    latitude=lat,
                    longitude=lon,
                    scheduled_arrival=arr,
                    scheduled_departure=dep,
                    is_completed=(day_num == 1 and h_type in ["DEPARTURE", "BREAKFAST"]),
                    notes=notes
                ))

            # Add announcements & posts
            db.add(DindiPost(
                id=str(uuid.uuid4()),
                dindi_id=dindi_obj.id,
                author_id=leader_user.id,
                author_name="Chopdar Sopanrao Maharaj",
                post_type="ANNOUNCEMENT",
                is_announcement=True,
                message="📢 माऊलींच्या पालखीचे प्रस्थान सकाळी ५ वाजता होईल. सर्वांनी वेळेवर उपस्थित राहावे."
            ))
            db.add(DindiPost(
                id=str(uuid.uuid4()),
                dindi_id=dindi_obj.id,
                author_id=varkari_user.id,
                author_name="Ramabai Shinde",
                post_type="GENERAL",
                is_announcement=False,
                message="माऊलींचा रिंगण सोहळा अतिशय सुरेख झाला! विठ्ठल रुक्मिणी नामस्मरण सुरू आहे. 🙏"
            ))

            # Add live audio stream
            db.add(DindiAudioStream(
                id=str(uuid.uuid4()),
                dindi_id=dindi_obj.id,
                title="🔴 Live Kirtan & Abhang Broadcast — Chopdar Maharaj",
                stream_url="https://stream.wariverse.org/live/audio.m3u8",
                is_live=True
            ))

        print("  [OK] Dindi ecosystem seeded with micro-schedules, halts, posts & live audio!")
        await db.commit()
        print("\n[OK] WariVerse AI Demo Data seeded successfully!")
        print("=" * 50)
        print("Demo Accounts:")
        print("  varkari@wariverse.demo   / Demo@123")
        print("  leader@wariverse.demo    / Demo@123")
        print("  volunteer@wariverse.demo / Demo@123")
        print("  medical@wariverse.demo   / Demo@123")
        print("  police@wariverse.demo    / Demo@123")
        print("  ngo@wariverse.demo       / Demo@123")
        print("  provider@wariverse.demo  / Demo@123")
        print("  cleaner@wariverse.demo   / Demo@123")
        print("  admin@wariverse.demo     / Demo@123")
        print("=" * 50)

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(seed())

