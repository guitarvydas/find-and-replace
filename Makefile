ODIN_FLAGS ?= -debug -o:none

all: dev

dev: 
	rm -f transpiler
	odin run . $(ODIN_FLAGS)
