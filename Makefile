all: build

build:
	jekyll build

export:
	scp -r _site/* wyre:/mnt/nominatim-org-data/site/
