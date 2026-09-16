# Tools (Swift, macOS-native, no dependencies)

Run: `swift <script>.swift <args>`

| Script | Purpose |
|---|---|
| `extract_frames.swift <video> <outdir> [interval_s]` | Pull frames from screen recordings (.mov) for reviewing enrollments/tests |
| `pdf_text.swift <file.pdf>` | Extract all text from a PDF page by page |
| `pdf_page.swift <file.pdf> <page#> <out.png>` | Render one PDF page to PNG (for PDFs with image-only pages) |
| `sample_colors.swift <image>...` | Sample hex colors at grid points of PNGs (used to extract brand palette) |
| `gen_brand*.swift` | Generate Okta background gradients (diagonal family gradients, radial glow). Edit hexes/paths at top |
