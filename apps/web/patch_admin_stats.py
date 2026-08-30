import re
with open('app/dashboard/admin/page.tsx', 'r') as f:
    content = f.read()

content = content.replace(
    "{ label: 'Active Varkaris'",
    "{ label: t('totalVarkaris') || 'Active Varkaris'"
)
content = content.replace(
    "sub: 'On pilgrimage today'",
    "sub: t('onPilgrimage') || 'On pilgrimage today'"
)

content = content.replace(
    "{ label: 'Active SOS'",
    "{ label: t('activeSOS') || 'Active SOS'"
)
content = content.replace(
    "sub: analytics.total_sos + ' total incidents'",
    "sub: tn(analytics.total_sos) + ' ' + (t('totalIncidents') || 'total incidents')"
)

content = content.replace(
    "{ label: 'Red Zones'",
    "{ label: t('redZones') || 'Red Zones'"
)
content = content.replace(
    "sub: analytics.total_crowd_zones + ' total zones'",
    "sub: tn(analytics.total_crowd_zones) + ' ' + (t('totalZones') || 'total zones')"
)

content = content.replace(
    "{ label: 'Volunteers'",
    "{ label: t('activeVolunteers') || 'Volunteers'"
)
content = content.replace(
    "sub: 'Available now'",
    "sub: t('availableNow') || 'Available now'"
)

# Also fix the subtitle
content = content.replace(
    "Real-time situational awareness · {analytics ? new Date(analytics.timestamp).toLocaleTimeString() : '—'}",
    "{t('situationalAwareness') || 'Real-time situational awareness'} · {analytics ? new Date(analytics.timestamp).toLocaleTimeString() : '—'}"
)

# "Refresh" button
content = content.replace(
    ">🔄 Refresh<",
    ">🔄 {t('refresh') || 'Refresh'}<"
)
content = content.replace(
    ">View All<",
    ">{t('viewAll') || 'View All'}<"
)
content = content.replace(
    ">Moderate<",
    ">{t('moderate') || 'Moderate'}<"
)
content = content.replace(
    ">AI Predict<",
    ">{t('aiPredict') || 'AI Predict'}<"
)

with open('app/dashboard/admin/page.tsx', 'w') as f:
    f.write(content)
