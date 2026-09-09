# Extracting Text Without a Full Render

Status: technique note (2026-07-27, single occurrence so far — not yet a
skill; see `process-vs-work-doctrine` rule 1). Promote to a skill if this
recurs. The `.docx` technique below was corrected on 2026-08-25 after a real
occurrence showed the original regex-based approach silently corrupting
output. A 2026-09-08 occurrence (Rogers Trade-In spike) independently
re-derived the pre-correction regex/tag-stripping approach from scratch —
this doc already covers the fix; the recurrence is recorded here as
reinforcement, not as a new rule.

When the Read tool can't usefully return a file's text directly:

- **`.docx`**: unzip it and parse `word/document.xml` with a real namespaced
  XML parser — do not strip tags with regex. A `.docx` is a zip archive; the
  document body is XML with the visible text wrapped in `<w:t>` runs under the
  `w:` namespace. Regex-based tag stripping (e.g. `sed -e 's/<[^>]*>//g'`) is
  fragile and has been observed to silently corrupt or truncate the extracted
  text: it doesn't understand namespaced tags, self-closing tags, or attribute
  values that themselves contain `<`/`>`-like content, so it can strip too
  much, too little, or merge text that should stay separated. Instead, unzip
  `word/document.xml` and parse it properly — e.g. in Python:

  ```python
  import zipfile
  import xml.etree.ElementTree as ET

  ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
  with zipfile.ZipFile("file.docx") as z:
      xml_bytes = z.read("word/document.xml")
  root = ET.fromstring(xml_bytes)
  text = "".join(t.text or "" for t in root.iter(f"{{{ns['w']}}}t"))
  print(text)
  ```

  Register the `w:` namespace and pull text specifically from `<w:t>`
  elements — this correctly handles self-closing tags, attributes, and
  nesting that a regex strip cannot. Use the equivalent construct (a real XML
  library, not a regex) in whatever language is already in play for the task.
- **`.xlsx`/`.pptx`**: same zip-plus-real-XML-parser approach, different
  internal path. For `.xlsx`, read `xl/sharedStrings.xml` (or
  `xl/worksheets/sheetN.xml` for values/formulas not in the shared-string
  table) and pull text from `<t>` elements under the spreadsheetml namespace.
  For `.pptx`, read each `ppt/slides/slideN.xml` and pull text from `<a:t>`
  elements under the drawingml namespace. Do not regex-strip tags here
  either — the same corruption risk applies.
- **Large mermaid-exported `.svg`**: grep for the `>text<` patterns. A large
  rendered diagram's SVG can be too big to read in full, but the visible
  labels are still plain text between tag boundaries — `grep -oE '>[^<]+<'
  file.svg` pulls out the label strings without parsing the SVG structurally.
- **Large PDF, exact text needed (not visual layout)**: try `pdftotext`
  before concluding the primary source is unreachable. On a 2026-09-01
  occurrence, the "proper" tools were all missing — `pdftoppm` (page-image
  render) and every Python PDF library (`fitz`, `pypdf`, `PyPDF2`) were
  unavailable — which initially looked like a dead end for reading a
  115-page vendor spec PDF. `pdftotext` turned out to already be on PATH
  (bundled with Git for Windows) and worked fine: `pdftotext -layout -f
  <start> -l <end> file.pdf -` pulls an exact page range as text with no
  install needed, whenever the need is exact text/field names rather than
  visual layout.
