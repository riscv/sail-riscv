all: riscvcsimdeps.svg workflow.svg class_structure.svg

%.pdf: %.tex Makefile
	pdflatex $<

%.svg: %.pdf Makefile
	dvisvgm -Z 1.5 --pdf $<

%.pdf: %.typ Makefile
	typst c $<

%.svg: %.typ Makefile
	typst c -f svg $<

clean:
	rm -f riscvcsimdeps.pdf riscvcsimdeps.aux riscvcsimdeps.log
	rm -f workflow.pdf class_structure.pdf
