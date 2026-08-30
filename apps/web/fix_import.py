with open('app/dashboard/admin/page.tsx', 'r') as f:
    content = f.read()

content = content.replace(
    "import Sidebar from '@/components/Sidebar';\nimport { useLanguage } from '@/context/LanguageContext' from '@/components/Sidebar';",
    "import Sidebar from '@/components/Sidebar';\nimport { useLanguage } from '@/context/LanguageContext';"
)

with open('app/dashboard/admin/page.tsx', 'w') as f:
    f.write(content)
