ODIN_FLAGS ?= -debug -o:none

all: dev

simple-dev: 
	ohmjs/ohmjs.js Word rt/word.ohm rt/word.sem.js <test.md

tokenize:
	rm -f find-and-replace
	odin run . $(ODIN_FLAGS)

find.sem.js:
	ohmjs/ohmjs.js RWR rwr/rwr.ohm rwr/rwr.sem.js <find.rwr >find.sem.js
