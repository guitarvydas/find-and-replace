ODIN_FLAGS ?= -debug -o:none

all: dev

dev:
	rm -f find-and-replace
	odin run . $(ODIN_FLAGS)
