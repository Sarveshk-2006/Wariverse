with open('context/LanguageContext.tsx', 'r') as f:
    content = f.read()

en_adds = """
    acknowledge: "Acknowledge",
    inProgressBtn: "In Progress",
    all: "All",
    statusCreated: "CREATED",
    statusAck: "ACKNOWLEDGED",
    statusInProgress: "IN PROGRESS",
    statusResolved: "RESOLVED",
"""

mr_adds = """
    acknowledge: "नोंद घ्या",
    inProgressBtn: "प्रगतीपथावर",
    all: "सर्व",
    statusCreated: "नोंदवली",
    statusAck: "पाहिली",
    statusInProgress: "काम चालू",
    statusResolved: "पूर्ण",
"""

hi_adds = """
    acknowledge: "संज्ञान लें",
    inProgressBtn: "प्रगति पर",
    all: "सभी",
    statusCreated: "दर्ज की गई",
    statusAck: "संज्ञान लिया",
    statusInProgress: "प्रगति पर",
    statusResolved: "हल हो गई",
"""

content = content.replace('resolve: "Mark Resolved",', 'resolve: "Mark Resolved",' + en_adds)
content = content.replace('resolve: "पूर्ण झाले",', 'resolve: "पूर्ण झाले",' + mr_adds)
content = content.replace('resolve: "हल हुआ",', 'resolve: "हल हुआ",' + hi_adds)

with open('context/LanguageContext.tsx', 'w') as f:
    f.write(content)
