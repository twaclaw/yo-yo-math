BOOK_DIR := _book
PDF := $(BOOK_DIR)/Yo-Yo-Math.pdf
QUARTO := PATH="/opt/homebrew/bin:$$PATH" uv run quarto

.PHONY: all pdf html render publish clean

all: html

pdf:
	$(QUARTO) render --to pdf

html:
	$(QUARTO) render --to html

render:
	$(QUARTO) render

# Render all formats in one pass so neither output overwrites the other
publish:
	$(QUARTO) render
	uv run ghp-import -n -p -f $(BOOK_DIR)

clean:
	rm -rf $(BOOK_DIR)
	rm -f Yo-Yo-Math.tex
	rm -rf _book/
	rm -rf _freeze/
	rm -rf index_files/
	rm -rf counting_faster/index_files
	rm -rf counting/index_files
	rm -rf counting_recap/countin_recap_files
	rm -rf number_line/number_line_files
	rm -rf site_libs/
