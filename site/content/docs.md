---
title: Docs

---

Inkval use Pandoc as render engine, for many questions you should check out [Pandoc documentation](https://pandoc.org/MANUAL.html).

## Configuration

Default source file directory, layout directory and static file directories are defined as bellows:

```bash
CONTENT_PATH=$(realpath content)
DIST_PATH=$(realpath dist)
LAYOUT_PATH=$(realpath layout)
```

## Markdown file

The md files must contain front matter(a snippet of YAML placed between two triple-dashed lines at the start of a file), and the content directory should contain at least one index.md file. The relevant configuration is as follows:

```md
---
title: site name(required for every md file)
subtitle: site subtitle
pagination: the count of entries in per archive page
lang: site language
description: site description
link: site root
rss: generate rss or not, default is true
---
```
