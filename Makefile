ODIN_FLAGS ?= -debug -o:none

all: debugrwr

debugrwr:
	ohmjs/ohmjs.js

simple-dev: 
	ohmjs/ohmjs.js Word rt/word.ohm rt/word.sem.js <test.md

dev:
	rm -f find-and-replace
	odin run . $(ODIN_FLAGS)

find.sem.js:
	ohmjs/ohmjs.js RWR rwr/rwr.ohm rwr/rwr.sem.js <fr/find.rwr >out/find.sem.js

dev-find.sem.js:
	rm -f find.sem.js
	make find.sem.js
