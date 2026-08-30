with open('lib/api.ts', 'r') as f:
    content = f.read()

fallback_logic = """
  // Hardcoded interception for reports and feedback if backend doesn't support it yet
  if (endpoint === '/reports') return MOCK_DATA['/reports'];
  if (endpoint.startsWith('/reports/') && options.method === 'PATCH') return { success: true };
  if (endpoint === '/feedback') return MOCK_DATA['/feedback'];

  let backendUnavailable = false;
"""

content = content.replace("  let backendUnavailable = false;", fallback_logic)

with open('lib/api.ts', 'w') as f:
    f.write(content)
