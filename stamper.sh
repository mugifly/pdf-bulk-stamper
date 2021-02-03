#!/bin/bash
# Script for bulk stamping stamp image on multi-page PDF file


set -e

SRC_PDF_FILE=""
STAMP_PDF_FILE=""
DST_PDF_FILE=""

ENABLE_SHIFT_STAMP=0
ENABLE_NOISE=0
NOISE_LEVEL=1
ENABLE_GRAYSCALE=0

TMP_DIR=/tmp/stamper


print_help () {

  echo "Usage: stamper.sh [OPTION]... SRC_PDF_FILE STAMP_PDF_FILE DST_PDF_FILE"
  echo -e "\n\
Script for bulk stamping the stamp image on PDF\n\
\n\
OPTION:\n\
\t-n, --noise LEVEL     Apply noise (LEVEL is integer from 1 to 15) to output\n\
\t-g, --grayscale       Apply grayscale to output\n\
\t-s, --staggered       Staggered when stamping\n"

}


get_num_of_pages_by_pdf () {
  pdf_file=$1
  pdftk "${1}" dump_data_annots | grep -o -e '[0-9]*'
}


generate_staggered_stamps () {

  if [ -d "${TMP_DIR}/stamp-pages/" ]; then
    rm -R "${TMP_DIR}/stamp-pages/"
  fi
  mkdir -p "${TMP_DIR}/stamp-pages/"

  tmp_stamp_pdf_file="${TMP_DIR}/tmp-stamp.pdf"
  echo "Generating staggered stamps... ${tmp_stamp_pdf_file}"

  num_of_src_pages=`get_num_of_pages_by_pdf "${SRC_PDF_FILE}"`
  for ((i=1; i <= $num_of_src_pages; i++)); do
    staggered_degree=`echo $(($RANDOM % 3 - 1))`
    convert -alpha set -background none -channel RGBA -fill '#ffffff' -rotate "${staggered_degree}" -fuzz 20% "${STAMP_PDF_FILE}" "${TMP_DIR}/stamp-pages/${i}.pdf"
    echo -n "."
  done

  echo ""

  pdftk "${TMP_DIR}"/stamp-pages/*.pdf cat output "${tmp_stamp_pdf_file}"

  STAMP_PDF_FILE="${tmp_stamp_pdf_file}"

}


generate_noises () {

  DST_NOISE_PDF_FILE=$1

  if [ -d "${TMP_DIR}/noises/" ]; then
    rm -R "${TMP_DIR}/noises/"
  fi
  mkdir -p "${TMP_DIR}/noises/"
  
  echo -e -n "Getting page size..."
  page_size=`identify "${SRC_PDF_FILE}[0]" | grep -oP "([0-9]*x[0-9]*) " -m 1`
  page_size_w=`echo $page_size | grep -Po "^[0-9]+"`
  page_size_h=`echo $page_size | grep -Po "[0-9]+$"`
  echo -e -n " ${page_size_w}x${page_size_h}\n"
  
  attenuate=`echo "$(( 300 * ( 16 - $NOISE_LEVEL ) ))"`
  echo -e "Generating noise... lv = $NOISE_LEVEL, attenuate = ${attenuate}, size = ${page_size_w}x${page_size_h}*2"
  noise_page_size_w=`echo "$((2 * $page_size_w))"`
  noise_page_size_h=`echo "$((2 * $page_size_h))"`
  noise_page_size="${noise_page_size_w}x${noise_page_size_h}"
  convert -size "${noise_page_size}" xc:gray -attenuate $attenuate +noise random "${TMP_DIR}/noise.png"
  convert -fuzz 90% -transparent white "${TMP_DIR}/noise.png" "${TMP_DIR}/noise.png"
  num_of_src_pages=`get_num_of_pages_by_pdf "${SRC_PDF_FILE}"`
  for ((i=1; i <= $num_of_src_pages; i++)); do
    noise_degree=`echo $(($RANDOM % 6 - 3))`
    convert -alpha set -background none -channel RGBA -fill '#ffffff' -rotate "${noise_degree}" "${TMP_DIR}/noise.png" "${TMP_DIR}/noises/${i}.pdf"
    echo -n "."
  done

  echo ""
  
  pdftk "${TMP_DIR}"/noises/*.pdf cat output "${DST_NOISE_PDF_FILE}"

}


# Parse arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
      -n|--noise)
      ENABLE_NOISE=1
      NOISE_LEVEL="$2"
      shift # past argument
      shift # past value
      ;;
      -g|--grayscale)
      ENABLE_GRAYSCALE=1
      shift # past argument
      ;;
      -s|--staggered)
      ENABLE_SHIFT_STAMP=1
      shift # past argument
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ $# -eq 0 ]; then
  print_help
  exit 0
fi

SRC_PDF_FILE=$1
STAMP_PDF_FILE=$2
DST_PDF_FILE=$3

if [ "${SRC_PDF_FILE}" = "" ] || [ "${STAMP_PDF_FILE}" = "" ] || [ "${DST_PDF_FILE}" = "" ]; then
  echo "Invalid arguments"
  print_help
  exit 1
fi

# Generate temporary directory
if [ ! -d "${TMP_DIR}" ]; then
  mkdir -p "${TMP_DIR}"
fi

# Generate staggered stamps
if [ $ENABLE_SHIFT_STAMP = 1 ]; then
  generate_staggered_stamps
fi

# Make stamping
echo "Stamping with ${STAMP_PDF_FILE}..."
pdftk "${SRC_PDF_FILE}" multistamp "${STAMP_PDF_FILE}" output "${DST_PDF_FILE}"

# Apply noise to output
if [ $ENABLE_NOISE = 1 ]; then
  generate_noises "${TMP_DIR}/noises.pdf"
  pdftk "${DST_PDF_FILE}" multistamp "${TMP_DIR}/noises.pdf" output "${TMP_DIR}/noised.pdf"
  cp "${TMP_DIR}/noised.pdf" "${DST_PDF_FILE}"
fi

# Apply grayscale to output
if [ $ENABLE_GRAYSCALE = 1 ]; then
  echo "Converting to grayscale..."
  convert -colorspace GRAY -density 200 -quality 90 "${DST_PDF_FILE}" "${DST_PDF_FILE}"
fi

# Done
echo "${DST_PDF_FILE} was generated"
