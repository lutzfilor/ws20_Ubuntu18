#CC = g++
CC = gcc
CFLAGS = -Wall -g
#INCLUDES
#LFLAGS= -L/home/lfilor
LIBS = -lm

.PHONY: all
all: hello

.PHONY: install
install:
	mkdir -p bin
	cp -p hello bin

.PHONY: clean
	rm -f hello

ex2: ex2.c util2.c
	cc -o ex2 ex2.c util2.c

hello: hello.cpp
	$(CC) $(CFLAGS) -o hello hello.cpp
	
