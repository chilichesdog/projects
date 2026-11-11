import argparse
import os

import img2pdf
from PIL import Image


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("input_directory", type=str)
    parser.add_argument("output_path", type=str)
    parser.add_argument(
        "crop_dimensions",
        nargs=4,
        metavar=("left", "upper", "right", "lower"),
        type=int,
    )

    args = parser.parse_args()

    in_dir: str = args.input_directory
    out_path: str = args.output_path
    in_files: list[str] = sorted(os.listdir(in_dir))
    left, upper, right, lower = args.crop_dimensions
    crop_box: tuple[int, int, int, int] = (left, upper, right, lower)

    crop_dir: str = os.path.join(in_dir, "cropped_imgs")
    os.makedirs(crop_dir, exist_ok=True)
    out_file_list: list[str] = []

    # crop and save all pngs
    for index, file_name in enumerate(in_files):
        img_path: str = os.path.join(in_dir, file_name)
        img = Image.open(img_path).convert("RGB")
        img_crop = img.crop(crop_box)
        out_file_name: str = f"crop_{index}.png"
        out_file_path: str = os.path.join(crop_dir, out_file_name)
        out_file_list.append(out_file_path)

        img_crop.save(out_file_path)

    layout = img2pdf.get_fixed_dpi_layout_fun((96, 96))
    with open(out_path, "wb") as out:
        img2pdf.convert(out_file_list, outputstream=out, layout_fun=layout)


if __name__ == "__main__":
    main()
