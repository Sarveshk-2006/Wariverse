import re

marathi_inject = """
    // Firebase New Names
    "Seva Jal Booth": "सेवा जल बूथ",
    "Mauli Jal Kendra": "माउली जल केंद्र",
    "Highway Water Station": "महामार्ग जल केंद्र",
    "Route Water Kiosk B": "रूट जल किओस्क बी",
    "Route Water Kiosk A": "रूट जल किओस्क ए",
    "Emergency Water Tanker 1": "आपत्कालीन पाण्याचा टँकर १",
    "Bhima River Water Point": "भीमा नदी जल केंद्र",
    "Warkari Pyaav 1": "वारकरी प्याऊ १",
    "Pandharpur Water Booth 1": "पंढरपूर जल केंद्र १",
    "Panduranga Jalaseva": "पांडुरंग जलसेवा",
    "Seva Water Point B": "सेवा जल केंद्र बी",
    "Medical Camp Water": "मेडिकल कॅम्प पाणी",
    "Village Water Booth": "गाव जल बूथ",
    "Community Water Hub": "सामुदायिक जल केंद्र",
    "Temple Water Point": "मंदिर जल केंद्र",
"""

hindi_inject = """
    // Firebase New Names
    "Seva Jal Booth": "सेवा जल बूथ",
    "Mauli Jal Kendra": "माउली जल केंद्र",
    "Highway Water Station": "राजमार्ग जल केंद्र",
    "Route Water Kiosk B": "रूट जल कियोस्क बी",
    "Route Water Kiosk A": "रूट जल कियोस्क ए",
    "Emergency Water Tanker 1": "आपातकालीन पानी का टैंकर १",
    "Bhima River Water Point": "भीमा नदी जल केंद्र",
    "Warkari Pyaav 1": "वारकरी प्याऊ १",
    "Pandharpur Water Booth 1": "पंढरपुर जल केंद्र १",
    "Panduranga Jalaseva": "पांडुरंग जलसेवा",
    "Seva Water Point B": "सेवा जल केंद्र बी",
    "Medical Camp Water": "चिकित्सा शिविर पानी",
    "Village Water Booth": "गाँव जल बूथ",
    "Community Water Hub": "सामुदायिक जल केंद्र",
    "Temple Water Point": "मंदिर जल केंद्र",
"""

english_inject = """
    // Firebase New Names
    "Seva Jal Booth": "Seva Jal Booth",
    "Mauli Jal Kendra": "Mauli Jal Kendra",
    "Highway Water Station": "Highway Water Station",
    "Route Water Kiosk B": "Route Water Kiosk B",
    "Route Water Kiosk A": "Route Water Kiosk A",
    "Emergency Water Tanker 1": "Emergency Water Tanker 1",
    "Bhima River Water Point": "Bhima River Water Point",
    "Warkari Pyaav 1": "Warkari Pyaav 1",
    "Pandharpur Water Booth 1": "Pandharpur Water Booth 1",
    "Panduranga Jalaseva": "Panduranga Jalaseva",
    "Seva Water Point B": "Seva Water Point B",
    "Medical Camp Water": "Medical Camp Water",
    "Village Water Booth": "Village Water Booth",
    "Community Water Hub": "Community Water Hub",
    "Temple Water Point": "Temple Water Point",
"""

with open('context/LanguageContext.tsx', 'r') as f:
    content = f.read()

content = content.replace('    "Vithal Annadan Kendra": "विठ्ठल अन्नदान केंद्र",', marathi_inject + '    "Vithal Annadan Kendra": "विठ्ठल अन्नदान केंद्र",')
content = content.replace('    "Vithal Annadan Kendra": "विट्ठल अन्नदान केंद्र",', hindi_inject + '    "Vithal Annadan Kendra": "विट्ठल अन्नदान केंद्र",')
content = content.replace('    "Vithal Annadan Kendra": "Vithal Annadan Kendra",', english_inject + '    "Vithal Annadan Kendra": "Vithal Annadan Kendra",')

with open('context/LanguageContext.tsx', 'w') as f:
    f.write(content)
print("Done")
