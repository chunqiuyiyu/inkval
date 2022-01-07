---
title: Inkval
---

[Inkval][1] is a tiny SSG(Static Site Generator) based on [Pandoc][2] and Bash.

Quickly use it in three steps:
<details open>
  <summary>Prepare Markdown files</summary>

```bash
content/
├── docs.md
├── examples.md
└── index.md
```

</details>
<details open>
  <summary>Load up Inkval</summary>
  
```bash
# raw_bash:
# https://raw.githubusercontent.com/chunqiuyiyu/inkval/main/inkval.sh
curl -s $raw_bash | bash
# or
wget -qO - $raw_bash | bash
```

</details>
<details open>
  <summary>Deploy static files</summary>
  
```bash
dist/
├── docs.html
├── examples.html
└── index.html
```

</details>

Inkval is built on the top of [Pandoc][2] and [Markdown][3] file system.

Checkout [Docs](/inkval/docs.html) and [Examples](/inkval/examples.html) for more details.

[1]: https://github.com/chunqiuyiyu/inkval
[2]: https://pandoc.org/
[3]: https://en.wikipedia.org/wiki/Markdown
