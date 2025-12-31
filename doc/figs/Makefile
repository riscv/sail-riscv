all: riscvcsimdeps.svg workflow.svg

riscvcsimdeps.pdf: riscvcsimdeps.tex Makefile
	pdflatex $<

riscvcsimdeps.svg: riscvcsimdeps.pdf riscvcsimdeps.tex Makefile
	dvisvgm -Z 1.5 --pdf $<

workflow.pdf: workflow.typ Makefile
	typst c $<

workflow.svg: workflow.typ Makefile
	typst c -f svg $<

clean:
	rm -f riscvcsimdeps.pdf riscvcsimdeps.aux riscvcsimdeps.log
	rm -f workflow.pdf
