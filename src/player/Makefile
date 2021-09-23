CC = gcc
BIN = player
CFLAGS = -O3 -w
LIBS = -lavformat -lao -lavcodec -lavutil -lavresample
SRC = player.c
OBJ = player.o

defualt:
	$(CC) $(CFLAGS) $(SRC) $(LIBS) -o $(BIN)
	mv player ../..

clean:
	rm $(OBJ) $(BIN)
