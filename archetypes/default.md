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
image: "favicon-32x32.png"
# you can close something for this content if you open it in config.toml.
comment: true
show_comments: true
include_toc: true
toc: true
# you can define another contentCopyright. e.g. contentCopyright: "This is an another copyright."
contentCopyright: true
reward: true
mathjax: true
flowchartDiagrams:
  enable: true
  options: ""
sequenceDiagrams: 
  enable: true
  options: ""
---

<!--more-->

{{ with .OutputFormats.Get "markdown" -}}
<a href="{{ .Permalink }}">查看本文 Markdown 版本</a>
{{- end }}
