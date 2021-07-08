TARGET := ./semi_circle.sh
PREFIX?=/usr/local

all: $(TARGET)

install:
	mkdir -p $(PREFIX)/bin
	install -c -m 555 $(TARGET) $(PREFIX)/bin
