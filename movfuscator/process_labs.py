from s_processor import process_s_file
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

input_dir = BASE_DIR / "./tests/input"
output_dir = BASE_DIR / "./tests/output"

files = [p for p in Path(input_dir).iterdir() if p.is_file()]

for file in files:
    path_to_file = str(file)
    file_name = file.name
    process_s_file(path_to_file, output_dir / ("mfsc_" + file_name))