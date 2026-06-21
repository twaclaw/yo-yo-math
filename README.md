# Yo-Yo-Math

> A book for playing mathematics

![](./cover.jpg)


## Building

### Preparation

```bash
uv venv --python=3.13 # or something similar
source .venv/bin/activate
uv sync
```

### Dependencies

- A LaTeX distribution.
- `librsvg`, `inkscape` and `chrome` (required by kaleido)

```bash
.venv/bin/plotly_get_chrome # required by kaleido
```


### Building

```bash
make html
make pdf
```

