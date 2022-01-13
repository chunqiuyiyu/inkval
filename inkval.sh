#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

echo 'Start...'
start=$(date +%s.%N)

# constants
CONTENT_PATH=$(realpath content)
readonly CONTENT_PATH
TMP_PATH=$(realpath tmp)
readonly TMP_PATH
DIST_PATH=$(realpath dist)
readonly DIST_PATH
readonly INDEX_PATH=$CONTENT_PATH/index.md
BASE_PATH=$(pwd)
readonly BASE_PATH
LAYOUT_PATH=$(realpath layout)
readonly LAYOUT_PATH

# Prepare dist and tmp dir
set_env() {
  rm -rf dist
  mkdir dist

  rm -rf tmp
  mkdir tmp
}

# Output new blank line
br() {
  printf '\n'
}

# Remove prefix and suffix of given string
thin() {
  local input=$1
  local prefix=$2
  local suffix=$3

  local result=${input#*"$prefix"}
  result=${result%"$suffix"*}
  echo "$result"
}

# Get value from metadata block
meta_grep() {
  local val
  local file=$1
  local key=$2
  local key_len

  if [[ -e $file ]]; then
    key_len=$(echo -n "$key" | wc -c)
    local cut_index=$((key_len + 3))
    val=$(sed -n /^"$key":/p "$file" | cut -c"$cut_index"-)
    echo "$val" | tr -d '\r' | cut -d$'\n' -f1
  fi
}

# Read config from content/index.md
get_config() {
  lang=$(meta_grep "$INDEX_PATH" lang)
  desc=$(meta_grep "$INDEX_PATH" description)
  name=$(meta_grep "$INDEX_PATH" title)
  link=$(meta_grep "$INDEX_PATH" link)
  pagination=$(meta_grep "$INDEX_PATH" pagination)
  rss=$(meta_grep "$INDEX_PATH" rss)
}

# Generate feed.xml
gen_rss() {
  if [ ! -d "$TMP_PATH"/archive ] || [ "$rss" = false ]; then
    return 0
  fi

  printf "Creating RSS file..."

  local rss
  local line
  local title
  local date
  local link

  cat <<-EOF >"$DIST_PATH"/feed.xml
<rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
    <channel>
        <title>$name</title>
        <description>$desc</description>
        <language>$lang</language>
        <link>${link-""}</link>
        <atom:link href="${link-""}/feed.xml" rel="self" type="application/rss+xml"/>
EOF
  while IFS= read -r line; do
    title=$(thin "$line" "[" "]")

    date=$(thin "$line" "<time>" "</time>")
    date=$(date --date="$date" -R)

    link=$(thin "$line" "(" ")")

    cat <<-EOF >>"$DIST_PATH"/feed.xml
    <item>
        <title>$title</title>
        <pubDate>$date</pubDate>
        <link>$link</link>
        <guid>$link</guid>
        <description/>
    </item>
EOF
  done <"$TMP_PATH"/archive/tmp_archive.md
  echo -e "    </channel>\n</rss>" >>"$DIST_PATH"/feed.xml

  printf "\e[32mOK\e[0m"
  br
}

gen_archive() {
  if [ ! -d "$TMP_PATH"/archive ]; then
    return 0
  fi

  printf "Creating Archive..."

  sort -r tmp/archive/index >tmp/archive/tmp_archive.md
  cd tmp/archive
  mkdir indexes
  cd indexes
  split --numeric-suffixes=1 --additional-suffix=.md -l "$pagination" ../tmp_archive.md
  cd ..

  local archives
  local archive_base
  local current_index
  local next
  local prev
  local html_name

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

        echo "[<< Newer](index$prev.html)" >>"$archive"
      fi
      if [ -e "indexes/x$next.md" ]; then
        echo "[Older >>](index$next.html)" >>"$archive"
      fi

      cat "$INDEX_PATH" "$archive" >tmp.md
      render tmp.md ../../dist/"$html_name".html
    }
  done

  wait
  printf "\e[32mOK\e[0m"
  br
}

iterate_tags() {
  local tmp
  if [[ -n $1 ]]; then
    tmp=$(thin "$1" "[" "]")
    IFS=', ' read -r -a tmp <<<"$tmp"
    for item in "${tmp[@]}"; do
      eval "$2" "$item" "${3-""}"
    done
  fi
}

insert_tag_slugs() {
  if [[ -e $2 ]]; then
    local tag_slugs
    tag_slugs=$(meta_grep "$INDEX_PATH" "$1")
    if [[ -n $tag_slugs ]]; then
      echo -e "  - name: $1\n    slug: $tag_slugs" >>"$2"
    else
      echo -e "  - name: $1\n    slug: $1" >>"$2"
    fi
  fi
}

gen_tmp_tag() {
  [ ! -d tmp/tags ] && mkdir -p "$TMP_PATH"/tags
  echo -e "$archive" >>"$TMP_PATH"/tags/"$item".md
}

gen_tags() {
  if [ ! -d "$TMP_PATH"/tags ]; then
    return 0
  fi

  printf "Creating Tags..."

  local tags
  local base
  local tag_slug
  local html_name

  cd "$BASE_PATH"
  tags=$(find tmp/tags -name "*.md")
  [ ! -d "dist/tags" ] && mkdir -p dist/tags
  touch tmp/tags/index.md
  for tag in $tags; do
    {
      base=$(basename "$tag" .md)
      sort -r "$tag" >tmp/tmp_"$base".md
      html_name=$base
      tag_slug=$(meta_grep "$INDEX_PATH" "$base")
      [[ -n $tag_slug ]] && html_name=$tag_slug
      render tmp/tmp_"$base".md dist/tags/"$html_name".html "$base"
      echo -e "[$base]($link/tags/$html_name.html)" >>tmp/tags/index.md
    } &
  done

  wait
  render tmp/tags/index.md dist/tags/index.html "Tags"
  printf "\e[32mOK\e[0m"
  br
}

# Generate default template of layout
gen_layout() {
  if [[ -d $LAYOUT_PATH ]]; then
    return 0
  fi

  mkdir -p "$LAYOUT_PATH"

  pandoc -D html >"$LAYOUT_PATH"/template.html
  echo "" >"$LAYOUT_PATH"/header.html

  local repo="https://github.com/chunqiuyiyu/inkval"
  local updated
  updated="<time>$(date)</time>"
  echo "<footer><div>©$(date +"%Y") built with <a href=\"$repo\">Inkval</a> at $updated</div></footer>" >"$LAYOUT_PATH"/footer.html
}

# Use pandoc to render html files from markdown file
render() {
  local input=$1
  local output=$2
  local title=${3-""}
  local others=${4-""}

  local base_options="-s --from gfm --to html --template=$LAYOUT_PATH/template.html --metadata link=$link"
  base_options+=" --include-before-body=$LAYOUT_PATH/header.html --include-after-body=$LAYOUT_PATH/footer.html"

  [[ -n $title ]] && base_options+=" --metadata title=$title"
  [[ -n $desc ]] && base_options+=" --metadata description=$desc"
  [[ -n $lang ]] && base_options+=" -V lang=$lang"
  [[ -e $others ]] && base_options+=" -d \"$others\""

  eval pandoc "$base_options" "$input" >"$output"
}

# Main loop to collect post info
main() {
  local files
  local total
  local columns
  files=$(find "$CONTENT_PATH" -name "*.md")
  total=$(echo "$files" | wc -l)
  columns=$(tput cols)

  local file_index
  local spin
  file_index=0
  spin='-\|/'

  local file_base
  local html_file
  local html_dir
  local title
  local created
  local tags
  local path
  local relative_path
  local spin_index
  spin_index=0

  for file in $files; do
    file_index=$((file_index + 1))
    {
      file_base=$(basename "$file" .md)
      html_file=$(dirname "$file" | sed 's/^.*content/dist/g')/${file_base}.html
      html_dir=$(dirname "$html_file")
      [ ! -d "$html_dir" ] && mkdir -p "$html_dir"

      title=$(meta_grep "$file" title)
      created=$(meta_grep "$file" date)
      tags=$(meta_grep "$file" tags)

      if [[ -n $title ]]; then
        if [[ -n $tags ]]; then
          path=$TMP_PATH/"$file_base"_tags_map.yml
          echo -e "variables:\n tag_slugs:" >"$path"
          iterate_tags "$tags" insert_tag_slugs "$path"
        fi

        render "$file" "$html_file" "\"$title\"" "$TMP_PATH"/"$file_base"_tags_map.yml
        relative_path=$(echo "$html_file" | sed 's/^dist\///g')

        if [[ -n $created ]]; then
          archive+="* <time>$created</time> --- [$title]($link/$relative_path)"
          [ ! -d "tmp/archive" ] && mkdir -p tmp/archive
          echo -e "$archive" >>tmp/archive/index

          iterate_tags "$tags" gen_tmp_tag
        fi
      fi
    } &

    spin_index=$(((spin_index + 1) % 4))
    printf "\r%-${columns}s" ""
    printf "\r(${file_index}/${total}) ${spin:$spin_index:1} %s""$file..."
  done

  printf "\e[32mOK\e[0m"
  br
  wait
}

set_env
get_config
gen_layout
main
gen_archive
gen_tags
gen_rss

rm -rf "$TMP_PATH"
end=$(date +%s.%N)
runtime=$(echo "scale=2; ($end - $start)/1" | bc -l)

echo "Done in $runtime s"
