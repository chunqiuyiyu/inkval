#!/usr/bin/env bash

set -e

start=$(date +%s.%N)

rm -rf dist
mkdir dist

rm -rf tmp
mkdir tmp

files=$(find content -name "*.md")
total=$(echo "$files" | wc -l)
columns=$(tput cols)

file_index=0
echo 'Start deal...'

spin='-\|/'

for file in $files; do
  file_index=$((file_index + 1))
  {
    file_base=$(basename "$file" .md)
    html_file=$(dirname "$file" | sed 's/^content/dist/g')/${file_base}.html
    html_dir=$(dirname "$html_file")
    [ ! -d "$html_dir" ] && mkdir -p "$html_dir"

    created=$(sed -n /^date:/p "$file")
    title=$(sed -n /^title:/p "$file")

    tags=$(sed -n /^tags:/p "$file")

    if [[ -n $title ]] && [[ -n $created ]]; then
      pandoc -s --template=layout.html --metadata=title:"$file_base" "$file" >"$html_file"
      relative_path=$(echo "$html_file" | sed 's/^dist\///g')
      archive+="* <time>${created:5:10}</time>[${title:5}]($relative_path)"
      [ ! -d "tmp/archive" ] && mkdir -p tmp/archive
      echo -e "$archive" >>tmp/archive/index

      if [[ -n $tags ]]; then
        new=${tags:5}
        t=${new# [*}
        t=${t%]*}
        IFS=', ' read -r -a a <<<"$t"
        archive_tag+="* <time>${created:5:10}</time>[${title:5}](../$relative_path)"
        for item in "${a[@]}"; do
          tag_dir=tmp/tags
          [ ! -d "$tag_dir" ] && mkdir -p "$tag_dir"
          echo -e "$archive_tag" >>"$tag_dir"/"$item".md
        done
      fi
    fi
  } &

  i=$(((i + 1) % 4))
  printf "\r%-${columns}s" ""
  printf "\r(${file_index}/${total})${spin:$i:1} %s""$file"
done

wait

tags=$(find tmp/tags -name "*.md")
[ ! -d "dist/tags" ] && mkdir -p dist/tags
for tag in $tags; do
  {
    base=$(basename "$tag" .md)
    sort -r "$tag" >tmp/tmp_"$base".md
    pandoc -s --from gfm --to html --metadata title="$base" tmp/tmp_"$base".md >dist/tags/"$base".html
  } &
done

wait

sort -r tmp/archive/index >tmp/archive/tmp_archive.md
cd tmp/archive
mkdir indexes
cd indexes
split --numeric-suffixes=1 --additional-suffix=.md -l 60 ../tmp_archive.md
cd ..

archives=$(find indexes -name "*.md")
for archive in $archives; do
  {
    archive_base=$(basename "$archive" .md)
    current_index=10#${archive_base:1}

    next=$(printf "%02d" $((current_index + 1)))
    prev=$(printf "%02d" $((current_index - 1)))

    html_name=inde"$archive_base"
    if [ "$archive_base" = "x01" ]; then
      html_name=index
    fi

    echo -e '\n' >>"$archive"
    if [ -e "indexes/x$prev.md" ]; then
      if [ "$archive_base" = "x02" ]; then
        prev=''
      fi

      echo "[<< Prev](index$prev.html)" >>"$archive"
    fi
    if [ -e "indexes/x$next.md" ]; then
      echo "[Next >>](index$next.html)" >>"$archive"
    fi

    pandoc -s --from gfm --to html "$archive"  >../../dist/"$html_name".html
  } &
done

wait

end=$(date +%s.%N)
runtime=$(echo "scale=2; ($end - $start)/1" | bc -l)

printf '\n'
echo "Done in $runtime s"
