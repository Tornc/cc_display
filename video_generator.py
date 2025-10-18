import lib.media_converter as mc

mc.video_to_rle(
    file_path="./media/water_144",
    resolution=(51 * 2, 19 * 3),  # 51, 19 is default CraftOS terminal/monitor size.
    fps=20,  # os.sleep(0.05)
    max_colours=16,  # You're limited to 16 colour palette.
    file_type="mp4",
)
