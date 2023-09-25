ODIN_FLAGS ?= -debug -o:none

all: dev

simple-dev: 
	ohmjs/ohmjs.js Word rt/word.ohm rt/word.sem.js <test.md

dev:
	rm -f find-and-replace
	odin run . $(ODIN_FLAGS)
