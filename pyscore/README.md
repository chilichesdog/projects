# pyscore

Two small scripts for turning screenshots of a score into a printable PDF.
`pyscore.py` crops a folder of page images to the same box and assembles them
into one PDF. `merge_pdf.py` joins a folder of PDFs into a single file.

## Layout

| Path | Contents |
| --- | --- |
| `pyscore.py` | Crops every image in a folder and builds a PDF from the crops |
| `merge_pdf.py` | Merges every PDF in a folder, in sorted order |

Both scripts use the `projects` pixi environment (`img2pdf`, `pypdf`, and
Pillow).

## Usage

Run these from the `projects/` folder.

### Crop images into a PDF

```sh
pixi run python pyscore/pyscore.py <input_dir> <output.pdf> left upper right lower
```

The four numbers are the crop box in pixels, measured from the top-left corner
of the image, in the order Pillow expects: left edge, top edge, right edge,
bottom edge.

To get them in Photopea, draw a rectangular selection around the music and
read X, Y, W, and H from the Info panel. Then pass:

```text
left = X    upper = Y    right = X + W    lower = Y + H
```

The cropped images are saved to `<input_dir>/cropped_imgs/` as
`crop_0.png`, `crop_1.png`, and so on, in the same order as the input files.
Each crop becomes one page. Pages are sized from the image at 96 DPI, so a
crop 816 pixels wide comes out 8.5 inches wide.

### Merge PDFs

```sh
pixi run python pyscore/merge_pdf.py <input_dir> <output.pdf>
```

Add `-v` to print each file as it is appended.

## Limitations

- Files are processed in plain string order, so `page10.png` sorts before
  `page2.png`. Zero-pad the numbers (`page02.png`) to keep pages in order.
- The input folder should contain only images (for `pyscore.py`) or only PDFs
  (for `merge_pdf.py`). Any other file, or a subfolder, stops the script.
- `pyscore.py` writes `cropped_imgs/` inside the input folder. Delete or move
  it before running the script on the same folder again.
- One crop box is applied to every page, so all screenshots need the same
  framing.

---

_This README was generated with AI (Claude). The code is my own._
