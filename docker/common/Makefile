VERSION=3.6.0

checkout:
	if [ ! -d "selenium" ]; then git clone git@github.com:SeleniumHQ/selenium.git; fi
	git -C selenium fetch --all --tags --prune
	git -C selenium checkout -f tags/selenium-$(VERSION)

patch: checkout
	curl -L https://github.com/SeleniumHQ/selenium/pull/4027.patch > /tmp/4027.patch
	curl -L https://github.com/SeleniumHQ/selenium/commit/0eef6a15508d9491111049326a7dc3c16c5a901b.patch > /tmp/0eef6a15508d9491111049326a7dc3c16c5a901b.patch
	git -C selenium apply --check /tmp/4027.patch /tmp/0eef6a15508d9491111049326a7dc3c16c5a901b.patch
	git -C selenium apply /tmp/4027.patch /tmp/0eef6a15508d9491111049326a7dc3c16c5a901b.patch

build: patch
	cd selenium && ./go prep-release-zip;

dist: build
	cp selenium/build/dist/selenium-server-standalone-$(VERSION).jar ./selenium-server-standalone.jar
