import cv2
import numpy as np
import struct
from PIL import Image


def quantize_frame(rgba, max_colours: int = 128):
    q = Image.fromarray(rgba, "RGBA").quantize(
        colors=max_colours, method=Image.FASTOCTREE
    )
    palette = q.getpalette()[: max_colours * 3]

    # Force RGBA (alpha always 255 here)
    palette_rgba = [
        (palette[i], palette[i + 1], palette[i + 2], 255)
        for i in range(0, len(palette), 3)
    ]

    indices = list(np.array(q).ravel())
    return palette_rgba, indices


def rle_encode(indices):
    encoded = []
    prev = indices[0]
    count = 1
    for idx in indices[1:]:
        if idx == prev and count < 255:
            count += 1
        else:
            encoded.append((prev, count))
            prev, count = idx, 1
    encoded.append((prev, count))
    return encoded


def video_to_rle(
    file_path: str,
    resolution: tuple[int, int] = None,
    fps: int = None,
    max_colours: int = 128,
    file_type: str = "mp4",
):
    cap = cv2.VideoCapture(f"{file_path}.{file_type}")
    w_in = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h_in = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps_in = int(cap.get(cv2.CAP_PROP_FPS))

    w_out, h_out = resolution if resolution else (w_in, h_in)
    fps_out = fps if fps else fps_in

    idx_in, idx_out = -1, -1
    with open(f"{file_path}.ev", "wb") as f:
        # Reserve a place for the header by writing placeholder values.
        f.write(struct.pack(">HHI", 0, 0, 0))
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            if resolution:
                frame = cv2.resize(frame, (w_out, h_out), interpolation=cv2.INTER_AREA)

            idx_in += 1
            out_due = int(idx_in / fps_in * fps_out)
            if out_due > idx_out:
                rgba = cv2.cvtColor(frame, cv2.COLOR_BGR2RGBA)
                palette, indices = quantize_frame(rgba, max_colours)
                encoded = rle_encode(indices)
                # palette block
                f.write(struct.pack(">H", len(palette)))
                for color in palette:
                    f.write(bytes(color))  # 4 bytes RGBA
                # rle block
                f.write(struct.pack(">I", len(encoded)))
                for idx, count in encoded:
                    f.write(struct.pack(">BB", idx, count))

                idx_out += 1

        # Write the header at the top
        f.seek(0)
        f.write(struct.pack(">HHI", w_out, h_out, idx_out + 1))

    cap.release()


def image_to_rle(
    file_path: str,
    resolution: tuple[int, int] = None,
    max_colours: int = 128,
    file_type: str = "png",
):
    img = Image.open(f"{file_path}.{file_type}").convert("RGBA")
    if resolution:
        img = img.resize(resolution, Image.Resampling.LANCZOS)
    w_out, h_out = img.size
    arr = np.array(img, dtype=np.uint8)
    palette, indices = quantize_frame(arr, max_colours)
    encoded = rle_encode(indices)

    with open(f"{file_path}.ei", "wb") as f:
        # Header
        f.write(struct.pack(">II", w_out, h_out))
        # Palette block
        f.write(struct.pack(">H", len(palette)))
        for color in palette:
            f.write(bytes(color))  # 4 bytes RGBA
        # RLE block
        f.write(struct.pack(">I", len(encoded)))
        for idx, count in encoded:
            f.write(struct.pack(">BB", idx, count))
