from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "nikoneko_video" / "captions"
OUT.mkdir(parents=True, exist_ok=True)

FONT_BOLD = "/System/Library/Fonts/Supplemental/Avenir Next.ttc"
FONT_REGULAR = "/System/Library/Fonts/Supplemental/Avenir Next.ttc"


CARDS = {
    "hook": ("Run with rhythm.", "Run with personality.", "center"),
    "onboarding": ("Choose your language.", "Pick your vibe.", "bottom"),
    "pace": ("Set your goal.", "Find your rhythm.", "bottom"),
    "ready": ("Health connected.", "Ready to go.", "bottom"),
    "run": ("Time. Distance. Steps.", "Everything you need, at a glance.", "bottom"),
    "settings": ("Countdown or stopwatch.", "Make every detail yours.", "bottom"),
    "characters": ("Pick your running partner.", "A new companion for every run.", "bottom"),
    "report": ("Every step becomes a record.", "See your progress over time.", "bottom"),
    "theme": ("Even the interface is yours.", "Run in your own style.", "bottom"),
    "end": ("NIKONEKO RUN", "Find your pace. Run your way.", "center"),
}


def centered(draw, text, font, y, fill):
    box = draw.textbbox((0, 0), text, font=font)
    x = (1080 - (box[2] - box[0])) // 2
    draw.text((x, y), text, font=font, fill=fill)


for name, (headline, subline, position) in CARDS.items():
    image = Image.new("RGBA", (1080, 1920), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    if name == "end":
        headline_font = ImageFont.truetype(FONT_BOLD, 76, index=1)
        subline_font = ImageFont.truetype(FONT_REGULAR, 36, index=0)
    else:
        headline_font = ImageFont.truetype(FONT_BOLD, 55, index=1)
        subline_font = ImageFont.truetype(FONT_REGULAR, 31, index=0)

    top = 730 if position == "center" else 1450
    left, right = 74, 1006
    bottom = top + 225
    draw.rounded_rectangle(
        (left, top, right, bottom),
        radius=44,
        fill=(17, 28, 42, 224),
        outline=(255, 255, 255, 28),
        width=2,
    )
    centered(draw, headline, headline_font, top + 42, (255, 255, 255, 255))
    centered(draw, subline, subline_font, top + 126, (214, 224, 235, 255))
    image.save(OUT / f"{name}.png")
