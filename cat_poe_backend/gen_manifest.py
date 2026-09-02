import os
import json

def generate_manifest():
    static_dir = os.path.join(os.path.dirname(__file__), "static", "game", "runner")
    assets = []
    
    for root, dirs, files in os.walk(static_dir):
        for file in files:
            if file == "manifest.json":
                continue
            
            # Get relative path from the static_dir
            rel_path = os.path.relpath(os.path.join(root, file), static_dir)
            # Use forward slashes for cross-platform compatibility
            rel_path = rel_path.replace(os.sep, "/")
            assets.append(rel_path)
    
    manifest = {
        "assets": assets
    }
    
    manifest_path = os.path.join(static_dir, "manifest.json")
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=4)
    
    print(f"Generated manifest with {len(assets)} assets at {manifest_path}")

if __name__ == "__main__":
    generate_manifest()
