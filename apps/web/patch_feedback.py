with open('app/dashboard/admin/feedback/page.tsx', 'r') as f:
    content = f.read()

# Remove changePriority
import re
content = re.sub(r'  const changePriority = async .*?};\n', '', content, flags=re.DOTALL)

# Replace the select and badge with nothing
content = re.sub(r'<select.*?</select>\s*<span.*?>.*?</span>', '', content, flags=re.DOTALL)

# Update texts
content = content.replace("t('reportsAndFeedback') || 'Report & Feedback'", "t('feedback') || 'Feedback'")
content = content.replace('User Reports', 'User Feedback')
content = content.replace('Pilgrim reports straight from the app.', 'Pilgrim feedback and suggestions.')

with open('app/dashboard/admin/feedback/page.tsx', 'w') as f:
    f.write(content)
