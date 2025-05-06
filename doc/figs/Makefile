all: riscvspecdeps.svg riscvcsimdeps.svg debug_mode_sm.svg

%.pdf: %.tex
	pdflatex $<

%.svg: %.pdf %.tex
	dvisvgm -Z 1.5 --pdf $<

clean:
	rm -f riscvspecdeps.pdf riscvspecdeps.aux riscvspecdeps.log
	rm -f riscvcsimdeps.pdf riscvcsimdeps.aux riscvcsimdeps.log
	rm -f debug_mode_sm.pdf debug_mode_sm.aux debug_mode_sm.log
