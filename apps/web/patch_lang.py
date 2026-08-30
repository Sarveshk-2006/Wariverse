import re
with open('context/LanguageContext.tsx', 'r') as f:
    content = f.read()

content = content.replace('users: "User Directory",', 'users: "User Directory",\n    feedback: "Report & Feedback",')
content = content.replace('users: "वापरकर्ते सूची",', 'users: "वापरकर्ते सूची",\n    feedback: "अहवाल आणि अभिप्राय",')
content = content.replace('users: "उपयोगकर्ता सूची",', 'users: "उपयोगकर्ता सूची",\n    feedback: "रिपोर्ट और फीडबैक",')

with open('context/LanguageContext.tsx', 'w') as f:
    f.write(content)
