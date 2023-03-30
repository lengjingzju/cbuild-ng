############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

import sys, os, re, requests
from argparse import ArgumentParser

use_html_table = True
SPDX_URL = 'https://spdx.org/licenses/'

html_head = r'''<!DOCTYPE html>
<html>

<head>
  <title>Package Information</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/katex.min.css">
  <style>
    code[class*="language-"],
    pre[class*="language-"] {
      color: black;
      background: none;
      text-shadow: 0 1px white;
      font-family: Consolas, Monaco, 'Andale Mono', 'Ubuntu Mono', monospace;
      text-align: left;
      white-space: pre;
      word-spacing: normal;
      word-break: normal;
      word-wrap: normal;
      line-height: 1.5;
      -moz-tab-size: 4;
      -o-tab-size: 4;
      tab-size: 4;
      -webkit-hyphens: none;
      -moz-hyphens: none;
      -ms-hyphens: none;
      hyphens: none;
    }

    pre[class*="language-"]::-moz-selection,
    pre[class*="language-"] ::-moz-selection,
    code[class*="language-"]::-moz-selection,
    code[class*="language-"] ::-moz-selection {
      text-shadow: none;
      background: #b3d4fc;
    }

    pre[class*="language-"]::selection,
    pre[class*="language-"] ::selection,
    code[class*="language-"]::selection,
    code[class*="language-"] ::selection {
      text-shadow: none;
      background: #b3d4fc;
    }

    @media print {

      code[class*="language-"],
      pre[class*="language-"] {
        text-shadow: none;
      }
    }

    /* Code blocks */
    pre[class*="language-"] {
      padding: 1em;
      margin: .5em 0;
      overflow: auto;
    }

    :not(pre)>code[class*="language-"],
    pre[class*="language-"] {
      background: #f5f2f0;
    }

    /* Inline code */
    :not(pre)>code[class*="language-"] {
      padding: .1em;
      border-radius: .3em;
      white-space: normal;
    }

    .token.comment,
    .token.prolog,
    .token.doctype,
    .token.cdata {
      color: slategray;
    }

    .token.punctuation {
      color: #999;
    }

    .namespace {
      opacity: .7;
    }

    .token.property,
    .token.tag,
    .token.boolean,
    .token.number,
    .token.constant,
    .token.symbol,
    .token.deleted {
      color: #905;
    }

    .token.selector,
    .token.attr-name,
    .token.string,
    .token.char,
    .token.builtin,
    .token.inserted {
      color: #690;
    }

    .token.operator,
    .token.entity,
    .token.url,
    .language-css .token.string,
    .style .token.string {
      color: #a67f59;
      background: hsla(0, 0%, 100%, .5);
    }

    .token.atrule,
    .token.attr-value,
    .token.keyword {
      color: #07a;
    }

    .token.function {
      color: #DD4A68;
    }

    .token.regex,
    .token.important,
    .token.variable {
      color: #e90;
    }

    .token.important,
    .token.bold {
      font-weight: bold;
    }

    .token.italic {
      font-style: italic;
    }

    .token.entity {
      cursor: help;
    }

    /* highlight */
    pre[data-line] {
      position: relative;
      padding: 1em 0 1em 3em;
    }

    pre[data-line] .line-highlight-wrapper {
      position: absolute;
      top: 0;
      left: 0;
      background-color: transparent;
      display: block;
      width: 100%;
    }

    pre[data-line] .line-highlight {
      position: absolute;
      left: 0;
      right: 0;
      padding: inherit 0;
      margin-top: 1em;
      background: hsla(24, 20%, 50%, .08);
      background: linear-gradient(to right, hsla(24, 20%, 50%, .1) 70%, hsla(24, 20%, 50%, 0));
      pointer-events: none;
      line-height: inherit;
      white-space: pre;
    }

    pre[data-line] .line-highlight:before,
    pre[data-line] .line-highlight[data-end]:after {
      content: attr(data-start);
      position: absolute;
      top: .4em;
      left: .6em;
      min-width: 1em;
      padding: 0 .5em;
      background-color: hsla(24, 20%, 50%, .4);
      color: hsl(24, 20%, 95%);
      font: bold 65%/1.5 sans-serif;
      text-align: center;
      vertical-align: .3em;
      border-radius: 999px;
      text-shadow: none;
      box-shadow: 0 1px white;
    }

    pre[data-line] .line-highlight[data-end]:after {
      content: attr(data-end);
      top: auto;
      bottom: .4em;
    }

    html body {
      font-family: "Helvetica Neue", Helvetica, "Segoe UI", Arial, freesans, sans-serif;
      font-size: 16px;
      line-height: 1.6;
      color: #333;
      background-color: #fff;
      overflow: initial;
      box-sizing: border-box;
      word-wrap: break-word
    }

    html body>:first-child {
      margin-top: 0
    }

    html body h1,
    html body h2,
    html body h3,
    html body h4,
    html body h5,
    html body h6 {
      line-height: 1.2;
      margin-top: 1em;
      margin-bottom: 16px;
      color: #000
    }

    html body h1 {
      font-size: 2.25em;
      font-weight: 300;
      padding-bottom: .3em
    }

    html body h2 {
      font-size: 1.75em;
      font-weight: 400;
      padding-bottom: .3em
    }

    html body h3 {
      font-size: 1.5em;
      font-weight: 500
    }

    html body h4 {
      font-size: 1.25em;
      font-weight: 600
    }

    html body h5 {
      font-size: 1.1em;
      font-weight: 600
    }

    html body h6 {
      font-size: 1em;
      font-weight: 600
    }

    html body h1,
    html body h2,
    html body h3,
    html body h4,
    html body h5 {
      font-weight: 600
    }

    html body h5 {
      font-size: 1em
    }

    html body h6 {
      color: #5c5c5c
    }

    html body strong {
      color: #000
    }

    html body del {
      color: #5c5c5c
    }

    html body a:not([href]) {
      color: inherit;
      text-decoration: none
    }

    html body a {
      color: #08c;
      text-decoration: none
    }

    html body a:hover {
      color: #00a3f5;
      text-decoration: none
    }

    html body img {
      max-width: 100%
    }

    html body>p {
      margin-top: 0;
      margin-bottom: 16px;
      word-wrap: break-word
    }

    html body>ul,
    html body>ol {
      margin-bottom: 16px
    }

    html body ul,
    html body ol {
      padding-left: 2em
    }

    html body ul.no-list,
    html body ol.no-list {
      padding: 0;
      list-style-type: none
    }

    html body ul ul,
    html body ul ol,
    html body ol ol,
    html body ol ul {
      margin-top: 0;
      margin-bottom: 0
    }

    html body li {
      margin-bottom: 0
    }

    html body li.task-list-item {
      list-style: none
    }

    html body li>p {
      margin-top: 0;
      margin-bottom: 0
    }

    html body .task-list-item-checkbox {
      margin: 0 .2em .25em -1.8em;
      vertical-align: middle
    }

    html body .task-list-item-checkbox:hover {
      cursor: pointer
    }

    html body blockquote {
      margin: 16px 0;
      font-size: inherit;
      padding: 0 15px;
      color: #5c5c5c;
      background-color: #f0f0f0;
      border-left: 4px solid #d6d6d6
    }

    html body blockquote>:first-child {
      margin-top: 0
    }

    html body blockquote>:last-child {
      margin-bottom: 0
    }

    html body hr {
      height: 4px;
      margin: 32px 0;
      background-color: #d6d6d6;
      border: 0 none
    }

    html body table {
      margin: 10px 0 15px 0;
      border-collapse: collapse;
      border-spacing: 0;
      display: table;
      width: 100%;
      overflow: auto;
      word-break: normal;
      word-break: keep-all
    }

    html body table th {
      font-weight: bold;
      color: #000
    }

    html body table td,
    html body table th {
      border: 1px solid #d6d6d6;
      padding: 6px 13px
    }

    html body dl {
      padding: 0
    }

    html body dl dt {
      padding: 0;
      margin-top: 16px;
      font-size: 1em;
      font-style: italic;
      font-weight: bold
    }

    html body dl dd {
      padding: 0 16px;
      margin-bottom: 16px
    }

    html body code {
      font-family: Menlo, Monaco, Consolas, 'Courier New', monospace;
      font-size: .85em !important;
      color: #000;
      background-color: #f0f0f0;
      border-radius: 3px;
      padding: .2em 0
    }

    html body code::before,
    html body code::after {
      letter-spacing: -0.2em;
      content:
        "\00a0"
    }

    html body pre>code {
      padding: 0;
      margin: 0;
      font-size: .85em !important;
      word-break: normal;
      white-space: pre;
      background: transparent;
      border: 0
    }

    html body .highlight {
      margin-bottom: 16px
    }

    html body .highlight pre,
    html body pre {
      padding: 1em;
      overflow: auto;
      font-size: .85em !important;
      line-height: 1.45;
      border: #d6d6d6;
      border-radius: 3px
    }

    html body .highlight pre {
      margin-bottom: 0;
      word-break: normal
    }

    html body pre code,
    html body pre tt {
      display: inline;
      max-width: initial;
      padding: 0;
      margin: 0;
      overflow: initial;
      line-height: inherit;
      word-wrap: normal;
      background-color: transparent;
      border: 0
    }

    html body pre code:before,
    html body pre tt:before,
    html body pre code:after,
    html body pre tt:after {
      content: normal
    }

    html body p,
    html body blockquote,
    html body ul,
    html body ol,
    html body dl,
    html body pre {
      margin-top: 0;
      margin-bottom: 16px
    }

    html body kbd {
      color: #000;
      border: 1px solid #d6d6d6;
      border-bottom: 2px solid #c7c7c7;
      padding: 2px 4px;
      background-color: #f0f0f0;
      border-radius: 3px
    }

    @media print {
      html body {
        background-color: #fff
      }

      html body h1,
      html body h2,
      html body h3,
      html body h4,
      html body h5,
      html body h6 {
        color: #000;
        page-break-after: avoid
      }

      html body blockquote {
        color: #5c5c5c
      }

      html body pre {
        page-break-inside: avoid
      }

      html body table {
        display: table
      }

      html body img {
        display: block;
        max-width: 100%;
        max-height: 100%
      }

      html body pre,
      html body code {
        word-wrap: break-word;
        white-space: pre
      }
    }

    .markdown-preview {
      width: 100%;
      height: 100%;
      box-sizing: border-box
    }

    .markdown-preview .pagebreak,
    .markdown-preview .newpage {
      page-break-before: always
    }

    .markdown-preview pre.line-numbers {
      position: relative;
      padding-left: 3.8em;
      counter-reset: linenumber
    }

    .markdown-preview pre.line-numbers>code {
      position: relative
    }

    .markdown-preview pre.line-numbers .line-numbers-rows {
      position: absolute;
      pointer-events: none;
      top: 1em;
      font-size: 100%;
      left: 0;
      width: 3em;
      letter-spacing: -1px;
      border-right: 1px solid #999;
      -webkit-user-select: none;
      -moz-user-select: none;
      -ms-user-select: none;
      user-select: none
    }

    .markdown-preview pre.line-numbers .line-numbers-rows>span {
      pointer-events: none;
      display: block;
      counter-increment: linenumber
    }

    .markdown-preview pre.line-numbers .line-numbers-rows>span:before {
      content: counter(linenumber);
      color: #999;
      display: block;
      padding-right: .8em;
      text-align: right
    }

    .markdown-preview .mathjax-exps .MathJax_Display {
      text-align: center !important
    }

    .markdown-preview:not([for="preview"]) .code-chunk .btn-group {
      display: none
    }

    .markdown-preview:not([for="preview"]) .code-chunk .status {
      display: none
    }

    .markdown-preview:not([for="preview"]) .code-chunk .output-div {
      margin-bottom: 16px
    }

    .markdown-preview .md-toc {
      padding: 0
    }

    .markdown-preview .md-toc .md-toc-link-wrapper .md-toc-link {
      display: inline;
      padding: .25rem 0
    }

    .markdown-preview .md-toc .md-toc-link-wrapper .md-toc-link p,
    .markdown-preview .md-toc .md-toc-link-wrapper .md-toc-link div {
      display: inline
    }

    .markdown-preview .md-toc .md-toc-link-wrapper.highlighted .md-toc-link {
      font-weight: 800
    }

    .scrollbar-style::-webkit-scrollbar {
      width: 8px
    }

    .scrollbar-style::-webkit-scrollbar-track {
      border-radius: 10px;
      background-color: transparent
    }

    .scrollbar-style::-webkit-scrollbar-thumb {
      border-radius: 5px;
      background-color: rgba(150, 150, 150, 0.66);
      border: 4px solid rgba(150, 150, 150, 0.66);
      background-clip: content-box
    }

    html body[for="html-export"]:not([data-presentation-mode]) {
      position: relative;
      width: 100%;
      height: 100%;
      top: 0;
      left: 0;
      margin: 0;
      padding: 0;
      overflow: auto
    }

    html body[for="html-export"]:not([data-presentation-mode]) .markdown-preview {
      position: relative;
      top: 0
    }

    @media screen and (min-width:914px) {
      html body[for="html-export"]:not([data-presentation-mode]) .markdown-preview {
        padding: 2em calc(50% - 457px + 2em)
      }
    }

    @media screen and (max-width:914px) {
      html body[for="html-export"]:not([data-presentation-mode]) .markdown-preview {
        padding: 2em
      }
    }

    @media screen and (max-width:450px) {
      html body[for="html-export"]:not([data-presentation-mode]) .markdown-preview {
        font-size: 14px !important;
        padding: 1em
      }
    }

    @media print {
      html body[for="html-export"]:not([data-presentation-mode]) #sidebar-toc-btn {
        display: none
      }
    }

    html body[for="html-export"]:not([data-presentation-mode]) #sidebar-toc-btn {
      position: fixed;
      bottom: 8px;
      left: 8px;
      font-size: 28px;
      cursor: pointer;
      color: inherit;
      z-index: 99;
      width: 32px;
      text-align: center;
      opacity: .4
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] #sidebar-toc-btn {
      opacity: 1
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc {
      position: fixed;
      top: 0;
      left: 0;
      width: 300px;
      height: 100%;
      padding: 32px 0 48px 0;
      font-size: 14px;
      box-shadow: 0 0 4px rgba(150, 150, 150, 0.33);
      box-sizing: border-box;
      overflow: auto;
      background-color: inherit
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc::-webkit-scrollbar {
      width: 8px
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc::-webkit-scrollbar-track {
      border-radius: 10px;
      background-color: transparent
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc::-webkit-scrollbar-thumb {
      border-radius: 5px;
      background-color: rgba(150, 150, 150, 0.66);
      border: 4px solid rgba(150, 150, 150, 0.66);
      background-clip: content-box
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc a {
      text-decoration: none
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc .md-toc {
      padding: 0 16px
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc .md-toc .md-toc-link-wrapper .md-toc-link {
      display: inline;
      padding: .25rem 0
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc .md-toc .md-toc-link-wrapper .md-toc-link p,
    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc .md-toc .md-toc-link-wrapper .md-toc-link div {
      display: inline
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .md-sidebar-toc .md-toc .md-toc-link-wrapper.highlighted .md-toc-link {
      font-weight: 800
    }

    html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .markdown-preview {
      left: 300px;
      width: calc(100% - 300px);
      padding: 2em calc(50% - 457px - 300px/2);
      margin: 0;
      box-sizing: border-box
    }

    @media screen and (max-width:1274px) {
      html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .markdown-preview {
        padding: 2em
      }
    }

    @media screen and (max-width:450px) {
      html body[for="html-export"]:not([data-presentation-mode])[html-show-sidebar-toc] .markdown-preview {
        width: 100%
      }
    }

    html body[for="html-export"]:not([data-presentation-mode]):not([html-show-sidebar-toc]) .markdown-preview {
      left: 50%;
      transform: translateX(-50%)
    }

    html body[for="html-export"]:not([data-presentation-mode]):not([html-show-sidebar-toc]) .md-sidebar-toc {
      display: none
    }
  </style>
</head>

<body for="html-export">
'''

html_tail = r'''
  <a id="sidebar-toc-btn">&#x2261;</a>

<script>
    var sidebarTOCBtn = document.getElementById('sidebar-toc-btn')
    sidebarTOCBtn.addEventListener('click', function(event) {
        event.stopPropagation()
        if (document.body.hasAttribute('html-show-sidebar-toc')) {
            document.body.removeAttribute('html-show-sidebar-toc')
        } else {
            document.body.setAttribute('html-show-sidebar-toc', true)
        }
    })
</script>

</body>

</html>
'''

compatible_licenses = {
    'AGPL-3'        : 'AGPL-3.0-only',
    'AGPL-3+'       : 'AGPL-3.0-or-later',
    'AGPLv3'        : 'AGPL-3.0-only',
    'AGPLv3+'       : 'AGPL-3.0-or-later',
    'AGPLv3.0'      : 'AGPL-3.0-only',
    'AGPLv3.0+'     : 'AGPL-3.0-or-later',
    'AGPL-3.0'      : 'AGPL-3.0-only',
    'AGPL-3.0+'     : 'AGPL-3.0-or-later',
    'BSD-0-Clause'  : '0BSD',
    'GPL-1'         : 'GPL-1.0-only',
    'GPL-1+'        : 'GPL-1.0-or-later',
    'GPLv1'         : 'GPL-1.0-only',
    'GPLv1+'        : 'GPL-1.0-or-later',
    'GPLv1.0'       : 'GPL-1.0-only',
    'GPLv1.0+'      : 'GPL-1.0-or-later',
    'GPL-1.0'       : 'GPL-1.0-only',
    'GPL-1.0+'      : 'GPL-1.0-or-later',
    'GPL-2'         : 'GPL-2.0-only',
    'GPL-2+'        : 'GPL-2.0-or-later',
    'GPLv2'         : 'GPL-2.0-only',
    'GPLv2+'        : 'GPL-2.0-or-later',
    'GPLv2.0'       : 'GPL-2.0-only',
    'GPLv2.0+'      : 'GPL-2.0-or-later',
    'GPL-2.0'       : 'GPL-2.0-only',
    'GPL-2.0+'      : 'GPL-2.0-or-later',
    'GPL-3'         : 'GPL-3.0-only',
    'GPL-3+'        : 'GPL-3.0-or-later',
    'GPLv3'         : 'GPL-3.0-only',
    'GPLv3+'        : 'GPL-3.0-or-later',
    'GPLv3.0'       : 'GPL-3.0-only',
    'GPLv3.0+'      : 'GPL-3.0-or-later',
    'GPL-3.0'       : 'GPL-3.0-only',
    'GPL-3.0+'      : 'GPL-3.0-or-later',
    'LGPLv2'        : 'LGPL-2.0-only',
    'LGPLv2+'       : 'LGPL-2.0-or-later',
    'LGPLv2.0'      : 'LGPL-2.0-only',
    'LGPLv2.0+'     : 'LGPL-2.0-or-later',
    'LGPL-2.0'      : 'LGPL-2.0-only',
    'LGPL-2.0+'     : 'LGPL-2.0-or-later',
    'LGPL2.1'       : 'LGPL-2.1-only',
    'LGPL2.1+'      : 'LGPL-2.1-or-later',
    'LGPLv2.1'      : 'LGPL-2.1-only',
    'LGPLv2.1+'     : 'LGPL-2.1-or-later',
    'LGPL-2.1'      : 'LGPL-2.1-only',
    'LGPL-2.1+'     : 'LGPL-2.1-or-later',
    'LGPLv3'        : 'LGPL-3.0-only',
    'LGPLv3+'       : 'LGPL-3.0-or-later',
    'LGPL-3.0'      : 'LGPL-3.0-only',
    'LGPL-3.0+'     : 'LGPL-3.0-or-later',
    'MPL-1'         : 'MPL-1.0',
    'MPLv1'         : 'MPL-1.0',
    'MPLv1.1'       : 'MPL-1.1',
    'MPLv2'         : 'MPL-2.0',
    'MIT-X'         : 'MIT',
    'MIT-style'     : 'MIT',
    'openssl'       : 'OpenSSL',
    'PSF'           : 'PSF-2.0',
    'PSFv2'         : 'PSF-2.0',
    'Python-2'      : 'Python-2.0',
    'Apachev2'      : 'Apache-2.0',
    'Apache-2'      : 'Apache-2.0',
    'Artisticv1'    : 'Artistic-1.0',
    'Artistic-1'    : 'Artistic-1.0',
    'AFL-2'         : 'AFL-2.0',
    'AFL-1'         : 'AFL-1.2',
    'AFLv2'         : 'AFL-2.0',
    'AFLv1'         : 'AFL-1.2',
    'CDDLv1'        : 'CDDL-1.0',
    'CDDL-1'        : 'CDDL-1.0',
    'EPLv1.0'       : 'EPL-1.0',
    'FreeType'      : 'FTL',
    'Nauman'        : 'Naumen',
    'tcl'           : 'TCL',
    'vim'           : 'Vim',
    'SGIv1'         : 'SGI-1',
}


def html_convert(var):
    return var.replace('&', '&amp;').replace('"', '&quot;').replace('<', '&lt;').replace('>', '&gt;').replace('\n', '<br>')


def get_license(package, spdxs, coms):
    lic = html_convert(package['LICENSE'])
    if 'LICFILE' in package.keys():
        licfile = package['LICFILE']
        if re.match(r'http[s]?://.*', licfile):
            lic = '<a href="%s" target="_blank">%s</a>' % (licfile, lic)
        elif re.match(r'common://.*', licfile):
            lic = '<a href="./common/%s" target="_blank">%s</a>' % (licfile.replace('common://', ''), lic)
        else:
            lic = '<a href="./%s" target="_blank">%s</a>' % (package['NAME'], lic)
    else:
        if lic in spdxs:
            lic = '<a href="%s%s.html" target="_blank">%s</a>' % (SPDX_URL, lic, lic)
        elif lic in coms:
            lic = '<a href="%s%s.html" target="_blank">%s</a>' % (SPDX_URL, compatible_licenses[lic], lic)

    return lic


def html_body(infos, spdxs):
    coms = compatible_licenses.keys()
    letter   = ''
    contents = '''  <div class="mume markdown-preview">
'''
    sidebars = '''  <div class="md-sidebar-toc"><div class="md-toc">
'''

    for package in sorted(infos):
        package_keys = infos[package].keys()

        if letter != package[0]:
            if letter:
                sidebars += '''    </details>
'''
            letter = package[0]

            contents += '''    <h1 class="mume-header" id="%s">%s</h1>

''' % (letter, letter.upper())

            sidebars += '''    <details style="padding:0;;padding-left:0px;" open>
      <summary class="md-toc-link-wrapper">
        <a href="#%s" class="md-toc-link"><p>%s</p></a>
      </summary>

'''  % (letter, letter.upper())

        contents += '''    <h2 class="mume-header" id="%s">%s</h2>
''' % (package, package)

        if use_html_table:
            contents += '''    <table border="1">
'''
            contents += '''      <tr><td width="20px">Name</td><td>%s</td></tr>
''' % (infos[package]['NAME'])
            if 'LICENSE' in package_keys:
                contents += '''      <tr><td>License</td><td>%s</td></tr>
''' % (get_license(infos[package], spdxs, coms))
            if 'VERSION' in package_keys:
                contents += '''      <tr><td>Version</td><td>%s</td></tr>
''' % (infos[package]['VERSION'])
            if 'HOMEPAGE' in package_keys:
                contents += '''      <tr><td>Homepage</td><td><a href="%s" target="_blank">%s</a></td></tr>
''' % (infos[package]['HOMEPAGE'], infos[package]['HOMEPAGE'])
            if 'LOCATION' in package_keys:
                contents += '''      <tr><td>Location</td><td>%s</td></tr>
''' % (infos[package]['LOCATION'])
            if 'DESCRIPTION' in package_keys:
                contents += '''      <tr><td>Description</td><td>%s</td></tr>
''' % (html_convert(infos[package]['DESCRIPTION']))
            contents += '''    </table>

'''
        else:
            contents += '''    <ul>
'''
            contents += '''      <li>Name : %s</li>
''' % (infos[package]['NAME'])
            if 'LICENSE' in package_keys:
                contents += '''      <li>License : %s</li>
''' % (get_license(infos[package], spdxs, coms))
            if 'VERSION' in package_keys:
                contents += '''      <li>Version : %s</li>
''' % (infos[package]['VERSION'])
            if 'HOMEPAGE' in package_keys:
                contents += '''      <li>Homepage : <a href="%s" target="_blank">%s</a></li>
''' % (infos[package]['HOMEPAGE'], infos[package]['HOMEPAGE'])
            if 'LOCATION' in package_keys:
                contents += '''      <li>Location : %s</li>
''' % (infos[package]['LOCATION'])
            if 'DESCRIPTION' in package_keys:
                contents += '''      <li>Description : %s</li>
''' % (html_convert(infos[package]['DESCRIPTION']))
            contents += '''    </ul>

'''

        sidebars += '''      <div><div class="md-toc-link-wrapper" style="padding:0;;display:list-item;list-style:square;margin-left:42px">
        <a href="#%s" class="md-toc-link"><p>%s</p></a>
      </div></div>

''' % (package, package)

    sidebars += '''    </details>
'''
    contents += '''  </div>
'''
    sidebars += '''  </div></div>
'''

    return contents,sidebars


def parse_spdx(args):
    spdx_info = ''
    if args.spdx_file and os.path.exists(args.spdx_file):
        with open(args.spdx_file , 'r') as fp:
            spdx_info = fp.read()
    else:
        spdx_info = requests.get('https://spdx.org/licenses/').text

    spdx_list = re.findall(r'<tr>\s*<td><a href="./([^"]+)" rel="rdf:[^"]+">([^<]+)</a></td>\s*<td about="[^"]+" typeof="spdx:License">\s*<code property="spdx:licenseId">([^<]+)</code></td>\s*<td style="[^"]+">[^<]*</td>\s*<td style="[^"]+">[^<]*</td>\s*</tr>', spdx_info)

    if not args.info_file:
        print('%-40s%s' % ('Identifier', 'Full name'))
        for item in spdx_list:
             print('%-40s%s' % (item[2], item[1]))

    return [t[2] for t in spdx_list]


def escape_tolower(var):
    return var.lower().replace('_', '-').replace('__dot__', '.').replace('__plus__', '+')


def gen_license(args, spdxs):
    configs = set()
    filter_flag = [1, 1]
    if args.filter_flag:
        filter_flag = [int(var) for var in args.filter_flag.split(':')]

    if filter_flag[0]:
        with open(args.conf_file, 'r') as fp:
            for per_line in fp.read().splitlines():
                ret = re.match(r'CONFIG_(.*)=y', per_line)
                if ret:
                    configs.add(escape_tolower(ret.groups()[0]).replace('prebuild-', '', 1))

    infos = {}
    with open(args.info_file, 'r') as fp:
        infos = eval(fp.read())
        for package in set(infos.keys()):
            package_keys = infos[package].keys()
            if filter_flag[0] and package not in configs:
                del infos[package]
            elif filter_flag[1] and 'LICENSE' not in package_keys:
                del infos[package]
    if not infos:
        return

    if args.out_file:
        with open(args.out_file, 'w') as fp:
            for package in sorted(infos):
                package_keys = infos[package].keys()

                fp.write('Name        : %s\n' % (infos[package]['NAME']))
                if 'LICENSE' in package_keys:
                    fp.write('License     : %s\n' % (infos[package]['LICENSE']))
                if 'VERSION' in package_keys:
                    fp.write('Version     : %s\n' % (infos[package]['VERSION']))
                if 'HOMEPAGE' in package_keys:
                    fp.write('Homepage    : %s\n' % (infos[package]['HOMEPAGE']))
                if 'LOCATION' in package_keys:
                    fp.write('Location    : %s\n' % (infos[package]['LOCATION']))
                if 'DESCRIPTION' in package_keys:
                    fp.write('Description : %s\n' % (infos[package]['DESCRIPTION'].replace('\n', '\n              ')))
                fp.write('\n')
        print('\033[32mGenerate %s OK.\033[0m' % args.out_file)

    if args.web_file:
        with open(args.web_file, 'w') as fp:
            contents,sidebars = html_body(infos, spdxs)
            fp.write(html_head)
            fp.write(contents)
            fp.write(sidebars)
            fp.write(html_tail)
        print('\033[32mGenerate %s OK.\033[0m' % args.web_file)


def parse_options():
    parser = ArgumentParser( description='''
            Tool to generate license information file.
            ''')

    parser.add_argument('-c', '--conf',
            dest='conf_file',
            help='Specify the .config file path.')

    parser.add_argument('-i', '--info',
            dest='info_file',
            help='Specify the information file path.')

    parser.add_argument('-o', '--out',
            dest='out_file',
            help='Specify the output file path.')

    parser.add_argument('-w', '--web',
            dest='web_file',
            help='Specify the html output file path.')

    parser.add_argument('-f', '--filter',
            dest='filter_flag',
            help='Filter ackages with licenses, 0:0 means no filter, 1:1 means filtering packages that are not enabled and not licensed')

    parser.add_argument('-s', '--spdx',
            dest='spdx_file',
            help='Specify the SPDX html file path.')

    args = parser.parse_args()
    if args.info_file and not args.out_file and not args.web_file:
        print('\033[31mERROR: Invalid parameters.\033[0m\n')
        parser.print_help()
        sys.exit(1)

    return args


if __name__ == '__main__':
    args = parse_options()
    spdxs = parse_spdx(args)
    if args.info_file:
        gen_license(args, spdxs)
