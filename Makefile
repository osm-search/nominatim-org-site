all: build

build:
	jekyll build

export:
	scp -r _site/* d:www/nominatim.org/site/
