import re

with open('app/dashboard/admin/page.tsx', 'r') as f:
    content = f.read()

# Add useLanguage hook inside AdminDashboard
content = re.sub(
    r'export default function AdminDashboard\(\) \{',
    'export default function AdminDashboard() {\n  const { t, tn } = useLanguage();',
    content
)

# Update texts
content = content.replace("⚙️ VariVerse AI Command Center", "⚙️ {t('commandCenter')}")
content = content.replace("'Total Varkaris'", "t('totalVarkaris')")
content = content.replace("'Active Volunteers'", "t('activeVolunteers')")
content = content.replace("'Security Personnel'", "t('securityPersonnel')")
content = content.replace("'Medical Staff'", "t('medicalStaff')")

content = content.replace("<h3>🆘 Live SOS Feed</h3>", "<h3>🆘 {t('liveSOS')}</h3>")
content = content.replace("<h3>🚦 Crowd Zones</h3>", "<h3>🚦 {t('crowdZones')}</h3>")
content = content.replace("<h3>🤖 AI Resource Prediction</h3>", "<h3>🤖 {t('aiPredictions')}</h3>")
content = content.replace("<h3>👤 Missing Persons</h3>", "<h3>👤 {t('missingPersons')}</h3>")
content = content.replace("<h3>📢 Vari Connect Activity</h3>", "<h3>📢 {t('activity')}</h3>")

# Numbers formatting
content = re.sub(r'\{s\.value\}', '{tn(s.value)}', content)
content = re.sub(r'\{analytics\.stats\.total_users\.toLocaleString\(\)\}', '{tn(analytics.stats.total_users)}', content)

with open('app/dashboard/admin/page.tsx', 'w') as f:
    f.write(content)
