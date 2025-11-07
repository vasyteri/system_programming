CC = gcc
ASM = fasm
CFLAGS = -Wall -Wextra -std=c99 -g
TARGET = queue_program
OBJ = main.o queue.o

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

main.o: main.c queue.h
	$(CC) $(CFLAGS) -c main.c

queue.o: queue.asm
	$(ASM) queue.asm queue.o

clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: all clean