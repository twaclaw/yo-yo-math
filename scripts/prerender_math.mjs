#!/usr/bin/env node
// Post-render: render every TeX expression with KaTeX at build time and drop the
// client-side math JS, so formulas are laid out in the HTML instead of flashing
// as raw TeX while a script typesets them. KaTeX CSS and fonts are self-hosted
// so the markup can never drift from a different CDN version.
import katex from "katex";
import { readFileSync, writeFileSync, cpSync, mkdirSync, readdirSync, statSync } from "node:fs";
import { join, relative, dirname, sep } from "node:path";
import { createRequire } from "node:module";

const BOOK = process.env.QUARTO_PROJECT_OUTPUT_DIR ?? "_book";
const KATEX_DIR = join(BOOK, "site_libs", "katex");

// twemoji.lua emits \style, a MathJax extension; \htmlStyle is the KaTeX spelling.
const MACROS = { "\\style": "\\htmlStyle{#1}{#2}" };

const MATH_SPAN = /<span class="math (inline|display)">([\s\S]*?)<\/span>/g;
const KATEX_BOOTSTRAP =
  /[ \t]*<script>window\.backupDefine[\s\S]*?<script>window\.define = window\.backupDefine; window\.backupDefine = undefined;<\/script>/;
const KATEX_CSS = /<link rel="stylesheet" href="[^"]*katex[^"]*\.css">/;

const unescape = (s) =>
  s.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"')
   .replace(/&#39;/g, "'").replace(/&amp;/g, "&");

const htmlFiles = (dir) =>
  readdirSync(dir).flatMap((name) => {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) return name === "site_libs" ? [] : htmlFiles(p);
    return p.endsWith(".html") ? [p] : [];
  });

// Self-host katex.min.css + the woff2 fonts it references.
const require = createRequire(import.meta.url);
const dist = dirname(require.resolve("katex/package.json")) + "/dist";
mkdirSync(KATEX_DIR, { recursive: true });
cpSync(join(dist, "katex.min.css"), join(KATEX_DIR, "katex.min.css"));
// Only woff2 is needed; every browser that supports MathML supports woff2 too.
mkdirSync(join(KATEX_DIR, "fonts"), { recursive: true });
for (const font of readdirSync(join(dist, "fonts")).filter((f) => f.endsWith(".woff2"))) {
  cpSync(join(dist, "fonts", font), join(KATEX_DIR, "fonts", font));
}

let pages = 0, rendered = 0;
const failures = [];

for (const file of htmlFiles(BOOK)) {
  const src = readFileSync(file, "utf8");
  if (!MATH_SPAN.test(src)) { MATH_SPAN.lastIndex = 0; continue; }
  MATH_SPAN.lastIndex = 0;

  let out = src.replace(MATH_SPAN, (whole, kind, body) => {
    const display = kind === "display";
    const tex = unescape(body).trim()
      .replace(display ? /^\\\[|\\\]$/g : /^\\\(|\\\)$/g, "").trim();
    try {
      const html = katex.renderToString(tex, {
        displayMode: display, throwOnError: true, strict: false,
        // Only \htmlStyle is trusted; it is the one HTML-emitting command used.
        trust: (ctx) => ctx.command === "\\htmlStyle",
        macros: { ...MACROS },
        output: "htmlAndMathml", // keeps a MathML copy for screen readers
      });
      rendered++;
      return html;
    } catch (err) {
      failures.push({ file, tex: tex.replace(/\s+/g, " ").slice(0, 70), msg: err.message.split("\n")[0] });
      return whole; // leave it for the client; see the warning below
    }
  });

  const cssHref = relative(dirname(file), join(KATEX_DIR, "katex.min.css")).split(sep).join("/");
  out = out.replace(KATEX_CSS, `<link rel="stylesheet" href="${cssHref}">`);
  // Only drop the client-side renderer once every expression on the page is baked in.
  if (!failures.some((f) => f.file === file)) out = out.replace(KATEX_BOOTSTRAP, "");

  writeFileSync(file, out);
  pages++;
}

console.log(`[prerender-math] ${rendered} expressions on ${pages} pages`);
for (const f of failures) console.warn(`[prerender-math] WARN ${f.file}: ${f.tex}\n    ${f.msg}`);
if (failures.length) console.warn(`[prerender-math] ${failures.length} expression(s) left to the browser`);
