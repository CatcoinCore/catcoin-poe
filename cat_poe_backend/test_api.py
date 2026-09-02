import urllib.request
import json

try:
    req = urllib.request.Request("http://127.0.0.1:8000/v1/config/")
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        print("API Response:")
        print(json.dumps(data, indent=2))
except Exception as e:
    print(f"Error fetching config: {e}")
