ODIN_FLAGS ?= -debug -o:none

all: dev

dev: 
	ohmjs/ohmjs.js Word rt/word.ohm rt/word.sem.js <test.md

hold-dev:
	rm -f find-and-replace
	odin run . $(ODIN_FLAGS)
