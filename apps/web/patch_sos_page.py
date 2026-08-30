import re

with open('app/dashboard/admin/sos/page.tsx', 'r') as f:
    content = f.read()

# Add useLanguage import
if "useLanguage" not in content:
    content = content.replace("import Sidebar from '@/components/Sidebar';", "import Sidebar from '@/components/Sidebar';\nimport { useLanguage } from '@/context/LanguageContext';")

# Add t, tn
content = re.sub(
    r'export default function AdminSOSPage\(\) \{',
    'export default function AdminSOSPage() {\n  const { t, tn } = useLanguage();',
    content
)

# Header
content = content.replace("🆘 SOS Feed", "🆘 {t('sosIncidents') || 'SOS Feed'}")

# Status mapping function
status_mapping = """
  const getStatusLabel = (status: string) => {
    switch(status) {
      case 'ALL': return t('all') || 'All';
      case 'CREATED': return t('statusCreated') || 'CREATED';
      case 'ACKNOWLEDGED': return t('statusAck') || 'ACKNOWLEDGED';
      case 'IN_PROGRESS': return t('statusInProgress') || 'IN PROGRESS';
      case 'RESOLVED': return t('statusResolved') || 'RESOLVED';
      default: return status.replace('_', ' ');
    }
  }
"""

content = content.replace("const statusColor:", status_mapping + "\n  const statusColor:")

# Filter buttons
content = re.sub(
    r'\{f === \'ALL\' \? \'All\' : f.replace\(\'_\', \' \'\)\} \{f !== \'ALL\' && `\(\$\{sos.filter\(s => s.status === f\).length\}\)`\}',
    '{getStatusLabel(f)} {f !== \'ALL\' && `(${tn(sos.filter(s => s.status === f).length)})`}',
    content
)

# Badges (if any, although I see badges in sos feed. Let's look at how they are rendered)
content = re.sub(
    r'className="badge" style=\{\{ background: statusColor\[s.status\].*?\}\}>\{s.status\}',
    'className="badge" style={{ background: statusColor[s.status] }}>{getStatusLabel(s.status)}',
    content
)

# Buttons
content = content.replace(">Acknowledge</button>", ">{t('acknowledge') || 'Acknowledge'}</button>")
content = content.replace(">In Progress</button>", ">{t('inProgressBtn') || 'In Progress'}</button>")
content = content.replace(">Mark Resolved</button>", ">{t('resolve') || 'Mark Resolved'}</button>")

with open('app/dashboard/admin/sos/page.tsx', 'w') as f:
    f.write(content)
