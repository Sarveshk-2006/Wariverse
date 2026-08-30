import re

with open('context/LanguageContext.tsx', 'r') as f:
    content = f.read()

content = content.replace('appSubtitle: "Wari Pilgrimage Management System",', 'appSubtitle: "Vari Pilgrimage Management System",')

with open('context/LanguageContext.tsx', 'w') as f:
    f.write(content)
print("Done")
