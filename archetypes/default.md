---
title: "{{ replace .TranslationBaseName "-" " " | title }}"
date: {{ .Date }}
lastmod: {{ .Date }}
draft: true
keywords: []
description: ""
tags: []
categories: []
author: "迷幻主义搬砖号子"
github: "madlogos"

# you can close something for this content if you open it in config.toml.
comment: true
show_comments: true
include_toc: true
toc: true
# you can define another contentCopyright. e.g. contentCopyright: "This is an another copyright."
contentCopyright: true
reward: true
mathjax: true
---

<!--more-->

{{ with .OutputFormats.Get "markdown" -}}
<a href="{{ .Permalink }}">查看本文 Markdown 版本</a>
{{- end }}

