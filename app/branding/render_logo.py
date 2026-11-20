"""Render the original Hykes mark and update the native launcher PNGs."""

import json
from pathlib import Path

from PIL import Image, ImageDraw

APP = Path(__file__).resolve().parents[1]
SIZE = 1024


def render():
    image = Image.new("RGB", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    for y in range(SIZE):
        colors = (int(21 - 15 * y / SIZE), int(49 - 24 * y / SIZE), int(75 - 30 * y / SIZE))
        draw.line([(0, y), (SIZE, y)], fill=colors)

    # A single compass ring frames two open pages shaped like rising waves.
    draw.ellipse((145, 145, 879, 879), outline="#305878", width=14)
    draw.arc((145, 145, 879, 879), 200, 295, fill="#577F97", width=14)
    draw.polygon([(512, 208), (544, 253), (512, 298), (480, 253)], fill="#A2F1E5")
    left_page = [(250, 406), (319, 382), (385, 385), (446, 409), (497, 448),
                 (497, 675), (439, 640), (373, 618), (312, 614), (250, 633)]
    right_page = [(527, 448), (578, 409), (639, 385), (705, 382), (774, 406),
                  (774, 633), (712, 614), (651, 618), (585, 640), (527, 675)]
    draw.polygon(left_page, fill="#DDF7FC")
    draw.polygon(right_page, fill="#70E1D4")
    draw.polygon([(250, 551), (308, 529), (367, 534), (426, 558), (497, 607),
                  (497, 675), (439, 640), (373, 618), (312, 614), (250, 633)], fill="#76B9DE")
    draw.polygon([(527, 594), (586, 553), (644, 530), (701, 527), (774, 548),
                  (774, 633), (712, 614), (651, 618), (585, 640), (527, 675)], fill="#42B4AD")
    draw.line([(281, 698), (349, 681), (421, 697), (512, 747),
               (603, 697), (675, 681), (743, 698)], fill="#8BCEE0", width=24, joint="curve")
    return image


def main():
    image = render()
    image.save(APP / "branding" / "hykes-logo.png", optimize=True)

    android = APP / "android/app/src/main/res"
    for density, pixels in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        image.resize((pixels, pixels), Image.Resampling.LANCZOS).save(
            android / f"mipmap-{density}" / "ic_launcher.png", optimize=True,
        )

    ios = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    manifest = json.loads((ios / "Contents.json").read_text(encoding="utf-8"))
    for icon in manifest["images"]:
        size = float(icon["size"].split("x", 1)[0])
        pixels = round(size * int(icon["scale"].removesuffix("x")))
        image.resize((pixels, pixels), Image.Resampling.LANCZOS).save(
            ios / icon["filename"], optimize=True,
        )


if __name__ == "__main__":
    main()
