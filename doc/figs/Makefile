FIG=riscvspecdeps

all: $(FIG).svg

$(FIG).pdf: $(FIG).tex
	pdflatex $<

$(FIG).svg: $(FIG).pdf $(FIG).tex
	dvisvgm -Z 1.5 --pdf $<

clean:
	rm $(FIG).pdf $(FIG).aux $(FIG).log
