#!/usr/bin/env bash

set -e

start=`date +%s`

rm -rf dist
mkdir dist

files=$(find content -name "*.md")
total=$(echo "$files" | wc -l)
columns=$(tput cols)

file_index=0
echo  'Start deal...'


spin='-\|/'

for file in $files
do
file_index=$(( file_index+1 ))
file_base=$(basename "$file" .md)
html_file=$(dirname "$file" | sed 's/^content/dist/g')/${file_base}.html
html_dir=$(dirname "$html_file")
[ ! -d "$html_dir" ] && mkdir -p "$html_dir"

created=$(cat "$file" | sed -n /^date:/p)
title=$(cat "$file" | sed -n /^title:/p)

if  [[ -n $title ]] && [[ -n $created ]]
then
    pandoc -s --from gfm --to html "$file" > "$html_file"
    relative_path=$(echo "$html_file" | sed 's/^dist\///g')

    archive+="* <time>${created:5:11}</time>[${title:5}]($relative_path)\n"
    i=$(( (i+1) %4 ))
    printf "\r%-${columns}s" ""
    printf "\r(${file_index}/${total})${spin:$i:1} %s""$file"
fi
done

echo 'Done!'

#echo -e "$archive" | sort -r | grep 2021 | sed '1s/^/## 2021\\n/' > tmp
echo -e "$archive" | sort -r > tmp
cat content/index.md tmp > tmp_archive.md

pandoc -s --from gfm --to html tmp_archive.md > dist/index.html

rm tmp
rm tmp_archive.md

end=$(date +%s)
runtime=$((end-start))
echo $runtime

echo "open explorer with url: file:///$(realpath 'dist/index.html')"
