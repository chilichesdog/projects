from argparse import ArgumentDefaultsHelpFormatter, ArgumentParser
from os import listdir, path

from pypdf import PageRange, PdfWriter


def main():
    """Merges pdfs in a directory to a single pdf."""

    parser = ArgumentParser(
        description=main.__doc__,
        epilog="python merge_pdf.py pdfs_directory new_score.pdf",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )

    parser.add_argument(
        "input_directory",
        type=str,
        help="Path to the folder holding the input pdfs.",
    )
    parser.add_argument(
        "output_path", type=str, help="Path with name of output pdf file."
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        required=False,
        default=False,
        help="Show debug info.",
    )
    parser.add_argument(
        "-s",
        "--skip",
        choices=["first", "last"],
        help="Skip first or last page of each input file.",
    )
    args = parser.parse_args()
    debug: bool = args.verbose

    in_dir: str = args.input_directory
    if debug:
        print(f"input directory: {in_dir}")
    out_path: str = args.output_path
    if debug:
        print(f"output: {out_path}")
    in_files: list[str] = sorted(listdir(in_dir))
    if debug:
        print(f"input files: {in_files}")
    skip = args.skip
    if debug:
        print(f"skipping: {skip}")
    pages = "1:" if skip == "first" else ":-1" if skip == "last" else ":"

    merger = PdfWriter()
    if debug:
        print("initialized merger")
    for f in in_files:
        in_path: str = path.join(in_dir, f)
        merger.append(in_path, pages=PageRange(pages))
        if debug:
            print(f"appended {f}")
    merger.write(out_path)
    merger.close()


if __name__ == "__main__":
    main()
