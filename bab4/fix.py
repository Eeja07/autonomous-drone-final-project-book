import re
with open('bab4.tex', 'r') as f:
    data = f.read()
# Find all combinations of backslashes before space and hline
data = re.sub(r'\\+\s+\\hline', r'\\\\ \\hline', data)
with open('bab4.tex', 'w') as f:
    f.write(data)
print("Done")
