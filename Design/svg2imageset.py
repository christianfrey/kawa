import os
import json
import cairosvg

# SVG files to convert (source → .imageset folder)
SVG_FILES = [
    ("CoffeeBean.svg", "CoffeeBean.imageset"),
    # ("CoffeeCupHot.svg", "CoffeeCupHot.imageset"),
    # ("CoffeeCupCold.svg", "CoffeeCupCold.imageset")
]

# Scales used by Xcode (@1x, @2x, @3x)
SCALES = [1, 2, 3]

# Base size in pixels
BASE_SIZE = 16

for svg_file, output_dir in SVG_FILES:
    os.makedirs(output_dir, exist_ok=True)
    images = []

    for scale in SCALES:
        # Output PNG filename
        png_name = f"{os.path.splitext(svg_file)[0]}@{scale}x.png"
        png_path = os.path.join(output_dir, png_name)

        # Final size
        size = BASE_SIZE * scale

        # Convert SVG → PNG with CairoSVG
        cairosvg.svg2png(
            url=svg_file,
            write_to=png_path,
            output_width=size,
            output_height=size
        )

        # Add entry to Contents.json
        images.append({
            "idiom": "universal",
            "filename": png_name,
            "scale": f"{scale}x"
        })

    # Generate Contents.json
    contents = {
        "images": images,
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    with open(os.path.join(output_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2, ensure_ascii=False)

    print(f"✅ Imageset generated: {output_dir}")
