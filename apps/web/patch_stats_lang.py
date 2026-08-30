with open('context/LanguageContext.tsx', 'r') as f:
    content = f.read()

en_adds = """
    onPilgrimage: "On pilgrimage today",
    activeSOS: "Active SOS",
    totalIncidents: "total incidents",
    redZones: "Red Zones",
    totalZones: "total zones",
    availableNow: "Available now",
    situationalAwareness: "Real-time situational awareness",
    viewAll: "View All",
    moderate: "Moderate",
    aiPredict: "AI Predict",
"""

mr_adds = """
    onPilgrimage: "आज वारीमध्ये",
    activeSOS: "सक्रिय SOS",
    totalIncidents: "एकूण घटना",
    redZones: "लाल क्षेत्रे (धोकादायक)",
    totalZones: "एकूण क्षेत्रे",
    availableNow: "सध्या उपलब्ध",
    situationalAwareness: "रिअल-टाइम परिस्थिती जाणीव",
    viewAll: "सर्व पहा",
    moderate: "नियंत्रण करा",
    aiPredict: "AI अंदाज",
"""

hi_adds = """
    onPilgrimage: "आज यात्रा में",
    activeSOS: "सक्रिय SOS",
    totalIncidents: "कुल घटनाएं",
    redZones: "रेड जोन (खतरनाक)",
    totalZones: "कुल क्षेत्र",
    availableNow: "अभी उपलब्ध",
    situationalAwareness: "वास्तविक समय स्थिति जागरूकता",
    viewAll: "सभी देखें",
    moderate: "नियंत्रण करें",
    aiPredict: "AI भविष्यवाणी",
"""

content = content.replace('activity: "Vari Connect Activity",', 'activity: "Vari Connect Activity",' + en_adds)
content = content.replace('activity: "वारी कनेक्ट घडामोडी",', 'activity: "वारी कनेक्ट घडामोडी",' + mr_adds)
content = content.replace('activity: "वारी कनेक्ट गतिविधि",', 'activity: "वारी कनेक्ट गतिविधि",' + hi_adds)

with open('context/LanguageContext.tsx', 'w') as f:
    f.write(content)
