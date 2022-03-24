# pdf-bulk-stamper

Script for bulk stamping stamp image on multi-page PDF file.

NOTE: I don't guarantee anything. Also, DON'T USE it for important documents.

## Features

- Bulk stamping to multi-page PDF file.

- Apply noise to the output

- Apply grayscale to the output

- Angle staggered when stamping each page

## Usage

### 1. Create stamp image (`stamp.pdf`)

1. Duplicate the PDF file (e.g. `source.pdf`) you want to stamp, to `stamp.pdf`.

2. Open the duplicated file (`stamp.pdf`) on PDF editing software (e.g. [Inkscape](https://inkscape.org/)).

3. Paste the stamp image (recommends transparent PNG) to the place you want to stamp.

4. Delete the objects other than the stamp image.<br>Now, the background of the PDF file should be white. Also, there is only the stamp image.

5. Overwrite save the PDF file. This completes the stamp PDF file.

### 2. Execute command

#### Execute on Docker (Recommended)

Requirements: [Docker](https://www.docker.com/products/docker-desktop)

Print help:

```
$ sudo docker run -it mugifly/pdf-bulk-stamper stamper.sh
```

Example command:

```
$ sudo docker run -it -v $(pwd):/stamper/ mugifly/pdf-bulk-stamper stamper.sh --noise 1 --grayscale --staggered source.pdf stamp.pdf output.pdf
```
Please execute the above command, in the directory containing the `source.pdf` and `stamp.pdf`.

#### Execute on Standalone

Requirements: Bash, Image Magick (`convert` command), PDFtk (`pdftk` command)

Print help:

```
$ bash stamper.sh
```

Example command:

```
$ bash stamper.sh --noise 1 --grayscale --staggered source.pdf stamp.pdf outout.pdf
```
