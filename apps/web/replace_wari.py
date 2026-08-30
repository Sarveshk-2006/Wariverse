import os
import re

directories = ['app', 'components', 'context', 'lib']

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # We want to replace Wari with Vari, and wari with vari in user-facing text or strings.
    # We should NOT replace wariverse with variverse in email domains (like ngo@wariverse.demo) 
    # since that might break logic, but the user said "inside the entire app". 
    # The prompt actually said "change the name from wariVerse Ai to VariVerse" in the previous step,
    # so they might expect wariverse to become variverse everywhere too, but that could break API links if there are any.
    # However, for pure words "Wari" -> "Vari".
    
    # Let's replace:
    # Wari -> Vari
    # wari -> vari (but avoid breaking wariverse if it's an email or a package? Actually let's just do Wari -> Vari and Wariverse -> Variverse, wariverse -> variverse in text).
    
    new_content = content.replace("Wari ", "Vari ")
    new_content = new_content.replace("Wari", "Vari")
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for d in directories:
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith(('.ts', '.tsx', '.css')):
                process_file(os.path.join(root, file))
print("Done")
