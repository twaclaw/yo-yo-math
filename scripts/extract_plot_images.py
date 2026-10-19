#!/usr/bin/env python3
"""Post-render: lift base64 images out of Plotly layouts into real files.

yoyo_plots inlines every icon it is given as a data URI, so an icon used on
twelve ticks is embedded twelve times, base64-inflated by a third, and re-sent
on every page that uses it. Writing each distinct image once and pointing the
figures at it lets the browser fetch it a single time and cache it book-wide.
"""
import base64
import hashlib
import os
import re
from pathlib import Path

BOOK = Path(os.environ.get("QUARTO_PROJECT_OUTPUT_DIR", "_book"))
SHARED = BOOK / "static_images" / "embedded"
# Plotly serialises "/" as /, in the media type and inside the payload
# alike, so both spellings have to be accepted and normalised before decoding.
SLASH = r"(?:/|\\u002f)"
DATA_URI = re.compile(
    rf"data:image{SLASH}(svg\+xml|png|jpeg|gif|webp);base64,"
    rf"((?:[A-Za-z0-9+=]|{SLASH})+)"
)
EXT = {"svg+xml": ".svg", "png": ".png", "jpeg": ".jpg", "gif": ".gif", "webp": ".webp"}

if not BOOK.is_dir():
    raise SystemExit(0)

# Prefer a resource Quarto already publishes over writing a second copy of it.
by_digest: dict[str, Path] = {}
for existing in (BOOK / "static_images").glob("**/*"):
    if existing.is_file() and SHARED not in existing.parents:
        by_digest.setdefault(hashlib.sha1(existing.read_bytes()).hexdigest(), existing)

pages = inlined = 0
missed: list[str] = []
saved = 0


def lift(blob: bytes, kind: str) -> Path:
    """Return the on-disk path for this image, writing it out if it is new."""
    digest = hashlib.sha1(blob).hexdigest()
    if digest not in by_digest:
        SHARED.mkdir(parents=True, exist_ok=True)
        target = SHARED / f"{digest[:16]}{EXT[kind]}"
        target.write_bytes(blob)
        by_digest[digest] = target
    return by_digest[digest]


for page in BOOK.glob("**/*.html"):
    html = page.read_text(encoding="utf8")
    if "data:image" not in html:
        continue  # nothing embedded, and nothing for the guard below to catch
    hits = 0
    before = len(html)

    def replace(m: re.Match) -> str:
        global hits
        kind, payload = m.group(1), m.group(2).replace("\\u002f", "/")
        try:
            blob = base64.b64decode(payload, validate=True)
        except Exception:
            return m.group(0)  # not a payload we understand; leave it alone
        hits += 1
        rel = os.path.relpath(lift(blob, kind), page.parent)
        return rel.replace(os.sep, "/")

    html = DATA_URI.sub(replace, html)
    if hits:
        page.write_text(html, encoding="utf8")
        pages += 1
        inlined += hits
        saved += before - len(html)

    # A Plotly or yoyo_plots upgrade could change how the URI is escaped, and a
    # pattern that quietly stops matching would just put the megabytes back
    # without failing anything. Name the page instead of letting that pass.
    for leftover in re.finditer(r'"source"\s*:\s*"(data:image[^"]{0,40})', html):
        missed.append(f"{page.relative_to(BOOK)}: {leftover.group(1)}...")

print(
    f"[plot-images] {inlined} data URIs on {pages} pages -> "
    f"{len(by_digest)} files, {saved / 1048576:.2f} MiB removed from HTML"
)
if missed:
    print(f"[plot-images] WARNING: {len(missed)} embedded image(s) not extracted:")
    for m in missed[:5]:
        print(f"  {m}")
    print("  The data-URI pattern in this script needs updating.")
