import os
import re

translations = {
    '🎮 Demo Control Panel': "{t('demoControl') || 'Demo Control Panel'}",
    '💧 Water Points — Admin': "💧 {t('waterDist') || 'Water Points'}",
    '👤 Missing Persons — Admin': "👤 {t('lostPersons') || 'Missing Persons'}",
    '🚻 Toilet Overview — Admin': "🚻 {t('toilets') || 'Toilet Overview'}",
    '👥 User Management': "👥 {t('users') || 'User Management'}",
    '🍛 Food Centre Management': "🍛 {t('foodDist') || 'Food Centre Management'}",
    '📢 Community Moderation': "📢 {t('community') || 'Community Moderation'}",
    '🗺️ Digital Twin — Live Map': "🗺️ {t('digitalTwin') || 'Digital Twin — Live Map'}",
    '🤖 AI Predictions': "🤖 {t('aiPredictions') || 'AI Predictions'}",
    '📊 Analytics Dashboard': "📊 {t('analytics') || 'Analytics Dashboard'}",
}

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    changed = False
    for k, v in translations.items():
        if k in content:
            content = content.replace(k, v)
            changed = True

    if changed:
        if "useLanguage" not in content:
            content = content.replace("import Sidebar from '@/components/Sidebar';", "import Sidebar from '@/components/Sidebar';\nimport { useLanguage } from '@/context/LanguageContext';")
            # Inject const { t, tn } = useLanguage();
            content = re.sub(r'(export default function [^\(]+\(\) \{)', r'\1\n  const { t, tn } = useLanguage();', content)
        
        with open(filepath, 'w') as f:
            f.write(content)

base_dir = 'app/dashboard/admin'
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith('page.tsx'):
            process_file(os.path.join(root, file))

