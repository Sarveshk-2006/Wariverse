with open('app/dashboard/admin/reports/page.tsx', 'r') as f:
    content = f.read()

content = content.replace('FeedbackDashboard', 'ReportsDashboard')
content = content.replace('feedback', 'reports')
content = content.replace('feedbacks', 'reports')
content = content.replace('Feedbacks', 'Reports')
content = content.replace("t('reportsAndFeedback') || 'Report & Feedback'", "t('reports') || 'Reports'")
content = content.replace('User Reports', 'Actionable Reports')

with open('app/dashboard/admin/reports/page.tsx', 'w') as f:
    f.write(content)
