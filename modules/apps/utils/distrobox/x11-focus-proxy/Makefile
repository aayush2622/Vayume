CC ?= cc

CFLAGS  += -std=gnu11 -O2 -Wall -Wextra -pthread
BIN := x11-focus-proxy

.PHONY: all clean
all: $(BIN)

$(BIN): src/proxy.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(BIN)
