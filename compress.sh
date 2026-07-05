#!/usr/bin/env bash

set -e

MAX_SIZE=$((2*1024*1024))
BACKUP_DIR="backup_original"

mkdir -p "$BACKUP_DIR"

processed=0
skipped=0

total_before=0
total_after=0

echo ""
echo "================================================="
echo "      Thesis Image Compression Utility"
echo "================================================="
echo ""
echo "Target Size : <= 2 MB"
echo "Backup Dir  : $BACKUP_DIR"
echo ""

while IFS= read -r img
do

    size=$(stat -c%s "$img")

    if [ "$size" -le "$MAX_SIZE" ]; then
        skipped=$((skipped+1))
        continue
    fi

    processed=$((processed+1))

    echo ""
    echo "-------------------------------------------------"
    echo "[$processed]"
    echo ""

    echo "File      : $img"

    before_human=$(du -h "$img" | cut -f1)

    echo "Before    : $before_human"

    backup="$BACKUP_DIR/$img"

    mkdir -p "$(dirname "$backup")"

    if [ ! -f "$backup" ]; then

        cp "$img" "$backup"

        echo "Backup    : created"

    else

        echo "Backup    : exists"

    fi

    ext=$(echo "${img##*.}" | tr '[:upper:]' '[:lower:]')

    if [[ "$ext" == "png" ]]; then

    echo "Method    : pngquant + adaptive resize"

    pngquant \
    --quality=70-90 \
    --speed 4 \
    --force \
    --ext .png \
    "$img"

    current=$(stat -c%s "$img")

    if [ "$current" -gt "$MAX_SIZE" ]
    then

    echo "Resize    : enabled"

    scale=95

    while [ "$(stat -c%s "$img")" -gt "$MAX_SIZE" ]
    do

    echo ""

    echo "Trying scale ${scale}%"

    convert "$img" \
    -resize ${scale}% \
    "$img"

    pngquant \
    --quality=70-90 \
    --speed 4 \
    --force \
    --ext .png \
    "$img"

    current=$(stat -c%s "$img")

    echo "Current   : $(du -h "$img" | cut -f1)"

    scale=$((scale-5))

    if [ "$scale" -lt 50 ]
    then

    echo "Reached minimum scale"

    break

    fi

    done

    fi

    else

    echo "Method    : ImageMagick (no pngquant)"

    quality=90

    while [ "$(stat -c%s "$img")" -gt "$MAX_SIZE" ]
    do

    convert "$img" \
    -strip \
    -quality "$quality" \
    "$img"

    quality=$((quality-5))

    if [ "$quality" -lt 60 ]
    then
    break
    fi
    done

    fi

    old=$(stat -c%s "$backup")
    new=$(stat -c%s "$img")

    total_before=$((total_before+old))
    total_after=$((total_after+new))

    after_human=$(du -h "$img" | cut -f1)

    saved=$((old-new))

    percent=$((saved*100/old))

    echo "After     : $after_human"

    echo "Reduced   : ${percent}%"

    echo "Saved     : $((saved/1024)) KB"

done < <(

find . \
-type f \
\( \
-iname "*.png" \
-o -iname "*.jpg" \
-o -iname "*.jpeg" \
\) \
! -path "./backup_original/*" \
! -path "./.git/*"

)

echo ""
echo "================================================="
echo "SUMMARY"
echo "================================================="

echo ""

echo "Processed : $processed"

echo "Skipped   : $skipped"

echo ""

before=$(numfmt --to=iec $total_before)

after=$(numfmt --to=iec $total_after)

echo "Original  : $before"

echo "Compressed: $after"

saved=$((total_before-total_after))

echo "Saved     : $(numfmt --to=iec $saved)"

if [ "$total_before" -gt 0 ]
then

pct=$((saved*100/total_before))

echo "Reduction : ${pct}%"

fi

echo ""
echo "Done."
echo ""