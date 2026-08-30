with open('context/LanguageContext.tsx', 'r') as f:
    content = f.read()

en_adds = """
    totalVarkaris: "Total Varkaris",
    activeVolunteers: "Active Volunteers",
    securityPersonnel: "Security Personnel",
    medicalStaff: "Medical Staff",
    liveSOS: "Live SOS Feed",
    crowdZones: "Crowd Zones",
    missingPersons: "Missing Persons",
    activity: "Vari Connect Activity",
"""

mr_adds = """
    totalVarkaris: "एकूण वारकरी",
    activeVolunteers: "सक्रिय स्वयंसेवक",
    securityPersonnel: "सुरक्षा रक्षक",
    medicalStaff: "वैद्यकीय कर्मचारी",
    liveSOS: "थेट आपत्कालीन (SOS)",
    crowdZones: "गर्दीचे ठिकाणे",
    missingPersons: "हरवलेल्या व्यक्ती",
    activity: "वारी कनेक्ट घडामोडी",
"""

hi_adds = """
    totalVarkaris: "कुल वारकरी",
    activeVolunteers: "सक्रिय स्वयंसेवक",
    securityPersonnel: "सुरक्षा कर्मी",
    medicalStaff: "चिकित्सा कर्मचारी",
    liveSOS: "लाइव आपातकालीन (SOS)",
    crowdZones: "भीड़ वाले क्षेत्र",
    missingPersons: "लापता व्यक्ति",
    activity: "वारी कनेक्ट गतिविधि",
"""

content = content.replace('commandCenter: "Command Center",', 'commandCenter: "Command Center",' + en_adds)
content = content.replace('commandCenter: "मुख्य नियंत्रण केंद्र",', 'commandCenter: "मुख्य नियंत्रण केंद्र",' + mr_adds)
content = content.replace('commandCenter: "कमांड सेंटर",', 'commandCenter: "कमांड सेंटर",' + hi_adds)

with open('context/LanguageContext.tsx', 'w') as f:
    f.write(content)
