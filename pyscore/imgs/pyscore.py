import argparse

from PIL import Image


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("input directory")
    parser.add_argument("output directory")
    parser.add_argument(
        "crop dimensions",
        nargs=4,
        default=(0, 0, 0, 0),
        metavar=("NORTH", "SOUTH", "EAST", "WEST"),
        type=int,
    )

    args = parser.parse_args()
    img = Image.open()
