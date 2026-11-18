# Projects

Personal projects for education and fun, separate from my DSP work. The main
goal of this repository is to track my programming progress. There is no
particular theme, but in general I'm working on:

- Improving my Mojo skills for my DSP work in MMMAudio
- Learning C to understand memory management
- Systems programming to improve my overall coding ability

## Projects

Each folder has its own README with more details.

| Folder | Language | Description |
| --- | --- | --- |
| [`gzip/`](gzip/) | C, Mojo | A gzip decompressor in C, ported to Mojo |
| [`chip8/`](chip8/) | Mojo | A CHIP-8 interpreter with a terminal display |
| [`euler/`](euler/) | Mojo | Project Euler problems |
| [`tonerow/`](tonerow/) | Python, Mojo | A random twelve-tone row generator |
| [`pyscore/`](pyscore/) | Python | Scripts that crop score screenshots into a PDF and merge PDFs |

## Setup

[pixi](https://pixi.sh) manages the environment (Mojo, Python packages, and
tools like Valgrind and hyperfine). From this folder:

```sh
pixi install
```

This recreates the environment from `pixi.lock`. Then either open a shell in
the environment with `pixi shell`, or prefix single commands with `pixi run`,
as the project READMEs do.

---

_This README was edited with AI (Claude). The code is my own._
