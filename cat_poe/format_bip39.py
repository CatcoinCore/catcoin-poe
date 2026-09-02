import os

_here = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(_here, "lib", "utils", "bip39_words.dart")

with open(file_path, "r") as f:
    words = [line.strip() for line in f if line.strip()]

dart_content = "const list<String> bip39Words = [\n"
dart_content += ",\n".join([f'  "{w}"' for w in words])
dart_content += "\n];"

with open(file_path, "w") as f:
    f.write(dart_content)
print("Converted to Dart list")
