import re

with open('app/dashboard/admin/demo/page.tsx', 'r') as f:
    content = f.read()

# Remove JUDGE_SCENARIO array
content = re.sub(r'const JUDGE_SCENARIO = \[.*?\];\n', '', content, flags=re.DOTALL)

# Remove currentStep state
content = re.sub(r'\s*const \[currentStep, setCurrentStep\] = useState<number \| null>\(null\);\n', '\n', content)

# Remove handleScenarioStep function
content = re.sub(r'\s*const handleScenarioStep = async \(step.*?};\n', '\n', content, flags=re.DOTALL)

# Remove JSX block
content = re.sub(r'\s*\{\/\* Judge Scenario \*\/\}.*?</div>\s*</div>\s*</div>', '\n            </div>', content, flags=re.DOTALL)

with open('app/dashboard/admin/demo/page.tsx', 'w') as f:
    f.write(content)
