all: riscvcsimdeps.svg

%.pdf: %.tex
	pdflatex $<

%.svg: %.pdf %.tex
	dvisvgm -Z 1.5 --pdf $<

clean:
	rm riscvcsimdeps.pdf riscvcsimdeps.aux riscvcsimdeps.log
