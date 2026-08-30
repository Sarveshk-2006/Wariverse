with open('context/LanguageContext.tsx', 'r') as f:
    content = f.read()

content = content.replace('feedback: "Report & Feedback",', 'feedback: "Feedback",\n    reports: "Reports",')
content = content.replace('feedback: "अहवाल आणि अभिप्राय",', 'feedback: "अभिप्राय",\n    reports: "अहवाल",')
content = content.replace('feedback: "रिपोर्ट और फीडबैक",', 'feedback: "फीडबैक",\n    reports: "रिपोर्ट",')

with open('context/LanguageContext.tsx', 'w') as f:
    f.write(content)
