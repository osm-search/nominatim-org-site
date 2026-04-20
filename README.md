# www.nominatim.org website

[jekyll](https://jekyllrb.com/) template system to generate [nominatim.org](http://nominatim.org/)

The [/release-docs](http://nominatim.org/release-docs) are build by [MkDocs](http://www.mkdocs.org/)

## Prerequisites

### jekyll

* ruby 2.3 or higher

### MkDocs

* python 2.7 or 3.3/3.4/3.5
* cmake

## Installation

### jekyll

[official jekyll documentation](https://jekyllrb.com/docs/installation/)

```bash
gem install jekyll
```

### MkDocs

[official MkDocs documentation](http://www.mkdocs.org/#installation)

```bash
pip install mkdocs
```

## Development

The following command will start a webserver on [127.0.0.1:4000](http://127.0.0.1:4000/) and recompile templates on-the-fly.

Output goes to the `_site/` directory, don't edit files there!

```bash
jekyll serve --incremental
```

### MkDocs


## Deployment

See `Makefile`

```bash
make; make export
```
