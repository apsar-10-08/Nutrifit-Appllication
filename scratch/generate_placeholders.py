import os
from PIL import Image, ImageDraw, ImageFont

images = {
    'walk.png': '5 Min Brisk Walk',
    'arm_circles.png': 'Arm Circles',
    'hip_rotation.png': 'Hip Rotation',
    'cat_cow.png': 'Cat-Cow Stretch',
    'hamstring.png': 'Hamstring Stretch',
    'pushup.png': 'Light Push-up'
}

out_dir = 'c:/project/NutriFit_Flutter_Supabase/assets/images/workouts'
os.makedirs(out_dir, exist_ok=True)

for filename, text in images.items():
    img = Image.new('RGB', (400, 300), color=(232, 248, 240)) # lightGreen from app
    d = ImageDraw.Draw(img)
    
    # Try to load a font, otherwise use default
    try:
        font = ImageFont.truetype("arial.ttf", 36)
    except IOError:
        font = ImageFont.load_default()
        
    text_bbox = d.textbbox((0, 0), text, font=font)
    text_w = text_bbox[2] - text_bbox[0]
    text_h = text_bbox[3] - text_bbox[1]
    
    # draw text in center, color darkGreen
    d.text(((400-text_w)/2, (300-text_h)/2), text, font=font, fill=(8, 122, 74))
    
    img.save(os.path.join(out_dir, filename))
    print(f'Created {filename}')
