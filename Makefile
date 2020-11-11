all: build

serve:
	jekyll serve --future

build:
	jekyll build

export:
	rsync -e ssh -avzF --exclude '/release-docs/develop' --exclude '/data' --exclude '/release' --delete _site/ wyre:/mnt/nominatim-org-data/site/
