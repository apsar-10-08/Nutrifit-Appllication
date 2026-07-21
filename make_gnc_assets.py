import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

out_dir = r'c:\project\NutriFit_Flutter_Supabase\assets\images\shop\gnc'
os.makedirs(out_dir, exist_ok=True)

W, H = 600, 600

def get_font(size, bold=False):
    font_names = ["arialbd.ttf", "arial.ttf", "dejavusans.ttf", "tahoma.ttf", "calibribd.ttf"] if bold else ["arial.ttf", "dejavusans.ttf", "calibri.ttf"]
    for name in font_names:
        try:
            return ImageFont.truetype(name, size)
        except Exception:
            pass
    return ImageFont.load_default()

def draw_shadow(draw, cx, cy, rx, ry, opacity=60):
    # Draw oval shadow beneath tub
    shape = [cx - rx, cy - ry, cx + rx, cy + ry]
    draw.ellipse(shape, fill=(200, 210, 205, opacity))

def create_product_image(filename, config):
    img = Image.new("RGBA", (W, H), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)

    # 1. Soft studio background with subtle pedestal gradient
    for y in range(H):
        v = int(255 - (y / H) * 12)
        draw.line([(0, y), (W, y)], fill=(v, v + 2, v + 4, 255))

    # Pedestal / Floor line
    draw.ellipse([80, 470, 520, 550], fill=(225, 232, 228, 255))
    draw.ellipse([110, 485, 490, 535], fill=(200, 210, 205, 255))
    draw.ellipse([140, 495, 460, 525], fill=(170, 180, 175, 255))

    # Tub dimensions
    tub_type = config.get("type", "tub") # 'tub', 'tall_tub', 'bottle', 'black_tub'
    
    if tub_type in ["tub", "tall_tub"]:
        bx1, by1, bx2, by2 = 160, 150, 440, 490
        lid_x1, lid_y1, lid_x2, lid_y2 = 180, 100, 420, 160
    elif tub_type == "bottle":
        bx1, by1, bx2, by2 = 180, 180, 420, 490
        lid_x1, lid_y1, lid_x2, lid_y2 = 220, 110, 380, 190
    else: # black_tub
        bx1, by1, bx2, by2 = 160, 150, 440, 490
        lid_x1, lid_y1, lid_x2, lid_y2 = 175, 95, 425, 160

    # Colors
    tub_bg = config.get("tub_color", (250, 250, 250))
    lid_color = config.get("lid_color", (215, 30, 40))
    accent_color = config.get("accent_color", (215, 30, 40))
    
    # Draw Tub Body (Rounded rectangle)
    radius = 35
    draw.rounded_rectangle([bx1, by1, bx2, by2], radius=radius, fill=tub_bg, outline=(210, 215, 210), width=3)
    
    # 3D Highlight & Shading on Tub
    for x in range(bx1, bx2):
        rel = (x - bx1) / (bx2 - bx1)
        if rel < 0.2:
            alpha = int((1.0 - rel/0.2) * 40)
            draw.line([(x, by1 + 10), (x, by2 - 10)], fill=(0, 0, 0, alpha))
        elif rel > 0.8:
            alpha = int(((rel - 0.8)/0.2) * 50)
            draw.line([(x, by1 + 10), (x, by2 - 10)], fill=(0, 0, 0, alpha))
        elif 0.3 <= rel <= 0.45:
            alpha = int((1.0 - abs(rel - 0.375)/0.075) * 35)
            draw.line([(x, by1 + 10), (x, by2 - 10)], fill=(255, 255, 255, alpha))

    # Draw Lid
    draw.rounded_rectangle([lid_x1, lid_y1, lid_x2, lid_y2], radius=15, fill=lid_color, outline=(160, 20, 30) if lid_color[0]>150 else (30,30,30), width=3)
    # Lid ridges
    for rx in range(lid_x1 + 15, lid_x2 - 10, 12):
        draw.line([(rx, lid_y1 + 5), (rx, lid_y2 - 5)], fill=(255, 255, 255, 40), width=2)
    # Lid rim
    draw.rounded_rectangle([lid_x1 - 5, lid_y2 - 15, lid_x2 + 5, lid_y2 + 5], radius=8, fill=lid_color, outline=(140, 15, 25) if lid_color[0]>150 else (20,20,20), width=2)

    # Label Area
    lx1, ly1, lx2, ly2 = bx1 + 8, by1 + 25, bx2 - 8, by2 - 20
    draw.rectangle([lx1, ly1, lx2, ly2], fill=config.get("label_bg", (255, 255, 255)))

    # Brand Header Bar (Red or Gold)
    header_color = config.get("header_color", (215, 30, 40))
    draw.rectangle([lx1, ly1, lx2, ly1 + 50], fill=header_color)
    
    # GNC Logo Text
    font_gnc = get_font(26, bold=True)
    draw.text((lx1 + 20, ly1 + 10), "GNC", fill=(255, 255, 255), font=font_gnc)
    
    font_subhead = get_font(12, bold=True)
    draw.text((lx1 + 95, ly1 + 12), "LIVE WELL", fill=(255, 255, 255), font=font_subhead)
    draw.text((lx1 + 95, ly1 + 26), "PRO PERFORMANCE", fill=(240, 240, 240), font=get_font(10, bold=False))

    # Product Sub-brand Badge
    sub_title = config.get("sub_title", "PRO PERFORMANCE")
    font_sub = get_font(13, bold=True)
    draw.text((lx1 + 20, ly1 + 62), sub_title, fill=accent_color, font=font_sub)

    # Main Product Title
    title1 = config.get("title1", "")
    title2 = config.get("title2", "")
    font_title1 = get_font(24, bold=True)
    font_title2 = get_font(20, bold=True)
    
    draw.text((lx1 + 20, ly1 + 85), title1, fill=(20, 20, 25) if config.get("label_bg", (255,255,255))[0]>100 else (255,255,255), font=font_title1)
    if title2:
        draw.text((lx1 + 20, ly1 + 115), title2, fill=accent_color, font=font_title2)

    # Product Feature Box / Flavor Badge
    badge_bg = config.get("badge_bg", (240, 245, 250))
    draw.rounded_rectangle([lx1 + 18, ly1 + 155, lx2 - 18, ly1 + 225], radius=10, fill=badge_bg, outline=accent_color, width=2)

    font_badge_head = get_font(14, bold=True)
    draw.text((lx1 + 30, ly1 + 165), config.get("badge_text1", ""), fill=(30, 30, 30), font=font_badge_head)
    
    font_badge_sub = get_font(12, bold=False)
    draw.text((lx1 + 30, ly1 + 190), config.get("badge_text2", ""), fill=(80, 80, 80), font=font_badge_sub)

    # Graphic Emblem on right side of badge
    emblem_type = config.get("emblem", "protein")
    ex, ey = lx2 - 60, ly1 + 190
    if emblem_type == "chocolate":
        draw.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(110, 60, 35))
        draw.ellipse([ex - 15, ey - 15, ex + 15, ey + 15], fill=(140, 80, 45))
        draw.text((ex - 10, ey - 8), "🍫", fill=(255,255,255), font=get_font(16))
    elif emblem_type == "whey":
        draw.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(215, 30, 40))
        draw.ellipse([ex - 18, ey - 18, ex + 18, ey + 18], fill=(255, 255, 255))
        draw.text((ex - 12, ey - 10), "100%", fill=(215, 30, 40), font=get_font(11, bold=True))
    elif emblem_type == "gold":
        draw.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(212, 175, 55))
        draw.ellipse([ex - 17, ey - 17, ex + 17, ey + 17], fill=(30, 30, 30))
        draw.text((ex - 12, ey - 10), "GOLD", fill=(212, 175, 55), font=get_font(9, bold=True))
    elif emblem_type == "creatine":
        draw.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(240, 120, 30))
        draw.text((ex - 12, ey - 10), "⚡", fill=(255, 255, 255), font=get_font(16))
    elif emblem_type == "multi":
        draw.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(40, 160, 90))
        draw.text((ex - 12, ey - 10), "🌿", fill=(255, 255, 255), font=get_font(16))
    elif emblem_type == "fish_oil":
        draw.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(0, 130, 200))
        draw.text((ex - 12, ey - 10), "🐟", fill=(255, 255, 255), font=get_font(16))
    elif emblem_type == "bcaa":
        draw.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(160, 40, 200))
        draw.text((ex - 12, ey - 10), "🍇", fill=(255, 255, 255), font=get_font(16))
    elif emblem_type == "carnitine":
        draw.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=(220, 50, 30))
        draw.text((ex - 12, ey - 10), "🔥", fill=(255, 255, 255), font=get_font(16))

    # Bottom Stat Pills
    stat1 = config.get("stat1", "73g PROTEIN")
    stat2 = config.get("stat2", "2200 CALORIES")
    
    draw.rounded_rectangle([lx1 + 20, ly1 + 240, lx1 + 130, ly1 + 270], radius=6, fill=accent_color)
    draw.text((lx1 + 26, ly1 + 247), stat1, fill=(255, 255, 255), font=get_font(10, bold=True))
    
    draw.rounded_rectangle([lx1 + 140, ly1 + 240, lx1 + 250, ly1 + 270], radius=6, fill=(40, 45, 55))
    draw.text((lx1 + 146, ly1 + 247), stat2, fill=(255, 255, 255), font=get_font(10, bold=True))

    # Weight / Net Wt Footer
    draw.text((lx1 + 20, ly1 + 280), "NET WT. 3 kg (6.6 lbs) | DIETARY SUPPLEMENT", fill=(120, 120, 120), font=get_font(9, bold=False))

    path = os.path.join(out_dir, filename)
    img.save(path, "PNG")
    print(f"Generated {filename} ({os.path.getsize(path)} bytes)")

# Configs for 8 products
products_config = {
    "gnc_weight_gainer.png": {
        "type": "tall_tub",
        "tub_color": (250, 250, 250),
        "lid_color": (215, 30, 40),
        "accent_color": (215, 30, 40),
        "header_color": (215, 30, 40),
        "sub_title": "PRO PERFORMANCE WEIGHT GAINER",
        "title1": "WEIGHT",
        "title2": "GAINER",
        "badge_text1": "Double Chocolate Flavor",
        "badge_text2": "High Calorie Muscle Mass Formula",
        "emblem": "chocolate",
        "stat1": "73g PROTEIN",
        "stat2": "2200 CALORIES",
    },
    "gnc_whey_protein.png": {
        "type": "tub",
        "tub_color": (250, 250, 250),
        "lid_color": (215, 30, 40),
        "accent_color": (215, 30, 40),
        "header_color": (215, 30, 40),
        "sub_title": "PRO PERFORMANCE 100% WHEY",
        "title1": "100% WHEY",
        "title2": "PROTEIN",
        "badge_text1": "Vanilla Cream Flavor",
        "badge_text2": "Fast Digesting Muscle Recovery",
        "emblem": "whey",
        "stat1": "24g PROTEIN",
        "stat2": "5.5g BCAA",
    },
    "gnc_amp_gold_whey.png": {
        "type": "black_tub",
        "tub_color": (35, 35, 40),
        "lid_color": (212, 175, 55),
        "accent_color": (212, 175, 55),
        "header_color": (20, 20, 25),
        "label_bg": (25, 25, 30),
        "sub_title": "AMP GOLD SERIES",
        "title1": "ADVANCED WHEY",
        "title2": "ISOLATE",
        "badge_bg": (45, 45, 50),
        "badge_text1": "Rich Gourmet Chocolate",
        "badge_text2": "Ultra Filtered Premium Whey",
        "emblem": "gold",
        "stat1": "25g ISOLATE",
        "stat2": "5.7g BCAA",
    },
    "gnc_creatine.png": {
        "type": "tub",
        "tub_color": (250, 250, 250),
        "lid_color": (240, 100, 20),
        "accent_color": (240, 100, 20),
        "header_color": (215, 30, 40),
        "sub_title": "PRO PERFORMANCE CREATINE",
        "title1": "CREATINE",
        "title2": "MONOHYDRATE",
        "badge_text1": "Unflavored / Orange Burst",
        "badge_text2": "Power & Muscle Strength",
        "emblem": "creatine",
        "stat1": "3g CREATINE",
        "stat2": "100% PURE",
    },
    "gnc_multivitamin.png": {
        "type": "bottle",
        "tub_color": (245, 248, 245),
        "lid_color": (40, 160, 90),
        "accent_color": (40, 160, 90),
        "header_color": (40, 160, 90),
        "sub_title": "MEGA MEN / ACTIVE",
        "title1": "MULTIVITAMIN",
        "title2": "ACTIVE",
        "badge_text1": "Daily Wellness & Energy",
        "badge_text2": "38 Key Essential Nutrients",
        "emblem": "multi",
        "stat1": "38 NUTRIENTS",
        "stat2": "60 CAPLETS",
    },
    "gnc_fish_oil.png": {
        "type": "bottle",
        "tub_color": (240, 248, 255),
        "lid_color": (0, 120, 200),
        "accent_color": (0, 120, 200),
        "header_color": (0, 120, 200),
        "sub_title": "TRIPLE STRENGTH",
        "title1": "FISH OIL",
        "title2": "OMEGA-3",
        "badge_text1": "Heart & Joint Support",
        "badge_text2": "Purified Mercury-Free Softgels",
        "emblem": "fish_oil",
        "stat1": "1000mg OMEGA3",
        "stat2": "60 SOFTGELS",
    },
    "gnc_bcaa.png": {
        "type": "tub",
        "tub_color": (250, 250, 250),
        "lid_color": (150, 40, 180),
        "accent_color": (150, 40, 180),
        "header_color": (150, 40, 180),
        "sub_title": "PRO PERFORMANCE BCAA",
        "title1": "BCAA",
        "title2": "ADVANCED 2:1:1",
        "badge_text1": "Blue Raspberry Flavor",
        "badge_text2": "Intra-Workout Muscle Recovery",
        "emblem": "bcaa",
        "stat1": "7g BCAA",
        "stat2": "0 SUGAR",
    },
    "gnc_l_carnitine.png": {
        "type": "bottle",
        "tub_color": (250, 250, 250),
        "lid_color": (220, 50, 30),
        "accent_color": (220, 50, 30),
        "header_color": (220, 50, 30),
        "sub_title": "PRO PERFORMANCE METABOLISM",
        "title1": "L-CARNITINE",
        "title2": "500 mg",
        "badge_text1": "Fat Metabolism & Energy",
        "badge_text2": "Converts Fat to Cellular Energy",
        "emblem": "carnitine",
        "stat1": "500mg CARNITINE",
        "stat2": "60 TABLETS",
    },
}

for filename, cfg in products_config.items():
    create_product_image(filename, cfg)

print("All 8 GNC product images generated successfully!")
