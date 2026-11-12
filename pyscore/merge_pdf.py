from argparse import ArgumentParser
from os import listdir, path

from pypdf import PdfWriter


def main():
    """Merges pdfs in a directory to a single pdf. -v for debug."""

    parser = ArgumentParser()
    parser.add_argument("input_directory", type=str)
    parser.add_argument("output_path", type=str)
    parser.add_argument(
        "-v", "--verbose", action="store_true", required=False, default=False
    )
    args = parser.parse_args()
    debug: bool = args.verbose
    if debug:
        print(args.input_directory, args.output_path, args.verbose)

    in_dir: str = args.input_directory
    if debug:
        print(f"input directory: {in_dir}")
    out_path: str = args.output_path
    if debug:
        print(f"output: {out_path}")
    in_files: list[str] = sorted(listdir(in_dir))
    if debug:
        print(f"input files: {in_files}")

    merger = PdfWriter()
    if debug:
        print("initialized merger")
    for f in in_files:
        in_path: str = path.join(in_dir, f)
        merger.append(in_path)
        if debug:
            print(f"appended {f}")
    merger.write(out_path)
    merger.close()


if __name__ == "__main__":
    main()
