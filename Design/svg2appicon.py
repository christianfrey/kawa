import os
import json
import cairosvg

# Source SVG filename
SVG_FILE = "AppIcon.svg"

# Output directory for the AppIcon set
OUTPUT_DIR = "AppIcon.appiconset"

# macOS app icon base sizes
SIZES = [16, 32, 128, 256, 512]

# List to hold the JSON entries
images = []

# Create output directory if it doesn't exist
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Loop through each size and scale
for size in SIZES:
    for scale in [1, 2]:
        scaled_size = size * scale
        filename = f"icon_{size}x{size}@{scale}x.png"
        filepath = os.path.join(OUTPUT_DIR, filename)

        # Convert SVG -> PNG using CairoSVG
        cairosvg.svg2png(
            url=SVG_FILE,
            write_to=filepath,
            output_width=scaled_size,
            output_height=scaled_size
        )

        # Add entry for Contents.json
        images.append({
            "idiom": "mac",
            "scale": f"{scale}x",
            "size": f"{size}x{size}",
            "filename": filename
        })

# Generate Contents.json file
contents = {
    "images": images,
    "info": {
        "author": "xcode",
        "version": 1
    }
}

with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print(f"✅ AppIcon set generated in: {OUTPUT_DIR}")
