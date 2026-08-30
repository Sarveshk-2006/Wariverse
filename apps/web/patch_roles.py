import re

with open('context/LanguageContext.tsx', 'r') as f:
    content = f.read()

content = content.replace('ngo: "NGO Coordinator",', 'ngo: "NGO",')
content = content.replace('admin: "Command Center Admin",', 'admin: "Admin",')

content = content.replace('ngo: "एनजीओ समन्वयक",', 'ngo: "NGO",')
content = content.replace('admin: "नियंत्रण कक्ष प्रशासक",', 'admin: "Admin",')

content = content.replace('admin: "कमांड सेंटर एडमिन",', 'admin: "Admin",')

with open('context/LanguageContext.tsx', 'w') as f:
    f.write(content)
print("Done")
