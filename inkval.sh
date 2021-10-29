#!/bin/bash

start=$(date +%s)

rm -rf dist
mkdir dist

files=$(find content -name "*.md")
for file in $files
do
 file_base=$(basename "$file" .md)
 html_file=$(dirname "$file" | sed 's/^content/dist/g')/${file_base}.html
 html_dir=$(dirname "$html_file")
 [ ! -d "$html_dir" ] && mkdir -p "$html_dir"
 touch "$html_file"
 echo "$html_file"
 created=$(cat "$file" | sed -n /^date:/p)
 title=$(cat "$file" | sed -n /^title:/p)

 if  [[ -n $title ]] && [[ -n $created ]]
 then
      index=$("# [${created:5:11}-${title:5}]($html_file)")
      echo $index
 fi

pandoc --from gfm --to html $file > tmp
 cat layout/head.html tmp layout/foot.html > $html_file
done

rm tmp

end=$(date +%s)
elapsed=$("$end-$start")
echo $elapsed
