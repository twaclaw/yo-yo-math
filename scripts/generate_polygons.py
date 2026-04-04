"""Pre-render script: generates SVG files for regular polygons (3–10 sides)."""
import math
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "static_images", "polygons")


def generate_polygon_svg(n_sides: int, size: int = 60) -> str:
    cx, cy = size, size
    r = size * 0.8
    vertices = []
    for k in range(n_sides):
        angle = 2 * math.pi * k / n_sides - math.pi / 2
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        vertices.append((x, y))
    points = " ".join(f"{x:.2f},{y:.2f}" for x, y in vertices)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{2*size}" height="{2*size}" viewBox="0 0 {2*size} {2*size}">\n'
        f'  <polygon points="{points}" fill="none" stroke="black" stroke-width="2"/>\n'
        f'</svg>\n'
    )


def generate_filled_polygon_svg(n_sides: int, size: int = 60, fill_color: str = "red") -> str:
    cx, cy = size, size
    r = size * 0.8
    vertices = []
    for k in range(n_sides):
        angle = 2 * math.pi * k / n_sides - math.pi / 2
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        vertices.append((x, y))
    points = " ".join(f"{x:.2f},{y:.2f}" for x, y in vertices)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{2*size}" height="{2*size}" viewBox="0 0 {2*size} {2*size}">\n'
        f'  <polygon points="{points}" fill="{fill_color}" stroke="{fill_color}" stroke-width="2"/>\n'
        f'</svg>\n'
    )


os.makedirs(OUTPUT_DIR, exist_ok=True)
for n in range(3, 11):
    path = os.path.join(OUTPUT_DIR, f"polygon_{n}.svg")
    with open(path, "w") as f:
        f.write(generate_polygon_svg(n))
    print(f"Generated {path}")

path = os.path.join(OUTPUT_DIR, "square_filled.svg")
with open(path, "w") as f:
    f.write(generate_filled_polygon_svg(4, fill_color="red"))
print(f"Generated {path}")
