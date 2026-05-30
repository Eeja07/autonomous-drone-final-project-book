#!/bin/sh
set -eu

chapter_dir="/home/eeja/Documents/TemplateBukuTATeknikKomputerITSMIP/bab3"
backup_dir="$chapter_dir/original_large_images"
min_bytes=2097152
max_bytes=2097152

if ! command -v convert >/dev/null 2>&1; then
  echo "ImageMagick 'convert' tidak ditemukan."
  exit 1
fi

mkdir -p "$backup_dir"

compress_one() {
  file="$1"
  rel=${file#"$chapter_dir"/}
  backup="$backup_dir/$rel"
  tmp="${file}.compressing"

  mkdir -p "$(dirname "$backup")"
  if [ ! -f "$backup" ]; then
    cp -p "$file" "$backup"
  fi

  best_tmp=""
  best_size=0

  lower=$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
    *.png) out_ext=".png" ;;
    *.jpg|*.jpeg) out_ext=".jpg" ;;
    *.heic) out_ext=".heic" ;;
    *) echo "Lewati format tidak didukung: $file"; return ;;
  esac

  for max_side in 1800 1600 1400 1200 1000; do
    candidate="${tmp}.${max_side}${out_ext}"
    case "$out_ext" in
      .png)
        convert "$backup" -auto-orient -resize "${max_side}x${max_side}>" -strip -colors 256 -define png:compression-level=9 "$candidate"
        ;;
      .jpg)
        convert "$backup" -auto-orient -resize "${max_side}x${max_side}>" -strip -quality 85 "$candidate"
        ;;
      .heic)
        convert "$backup" -auto-orient -resize "${max_side}x${max_side}>" -strip -quality 85 "$candidate"
        ;;
    esac
    size=$(wc -c < "$candidate" | tr -d ' ')

    if [ "$size" -le "$max_bytes" ]; then
      best_tmp="$candidate"
      best_size="$size"
      break
    fi

    if [ "$best_size" -eq 0 ] || [ "$size" -lt "$best_size" ]; then
      [ -n "$best_tmp" ] && rm -f "$best_tmp"
      best_tmp="$candidate"
      best_size="$size"
    else
      rm -f "$candidate"
    fi
  done

  mv "$best_tmp" "$file"
  rm -f "${tmp}".*.png

  before=$(wc -c < "$backup" | tr -d ' ')
  after=$(wc -c < "$file" | tr -d ' ')
  printf '%s: %s -> %s bytes\n' "$file" "$before" "$after"
}

find "$chapter_dir" -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.heic' \) \
  ! -path "$backup_dir/*" \
  -size +2048k |
while IFS= read -r file; do
  compress_one "$file"
done
