PKG_CONFIG ?= pkg-config
CC         ?= cc

WAYLAND_SCANNER   := $(shell $(PKG_CONFIG) --variable=wayland_scanner wayland-scanner 2>/dev/null || echo wayland-scanner)
WAYLAND_XML_DIR   := $(shell $(PKG_CONFIG) --variable=pkgdatadir wayland-scanner)
PROTOCOLS_DIR     := $(shell $(PKG_CONFIG) --variable=pkgdatadir wayland-protocols)

CFLAGS  += -std=gnu11 -O2 -Wall -Wextra -Wno-unused-parameter -Iprotocol \
           $(shell $(PKG_CONFIG) --cflags wayland-server)
LDLIBS  += $(shell $(PKG_CONFIG) --libs wayland-server)

PROTOCOLS := wayland xdg-shell xdg-decoration linux-dmabuf viewporter primary-selection

WAYLAND_XML          := $(WAYLAND_XML_DIR)/wayland.xml
XDG_SHELL_XML        := $(PROTOCOLS_DIR)/stable/xdg-shell/xdg-shell.xml
XDG_DECORATION_XML   := $(PROTOCOLS_DIR)/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml
LINUX_DMABUF_XML     := $(PROTOCOLS_DIR)/stable/linux-dmabuf/linux-dmabuf-v1.xml
VIEWPORTER_XML       := $(PROTOCOLS_DIR)/stable/viewporter/viewporter.xml
PRIMARY_SELECTION_XML := $(PROTOCOLS_DIR)/unstable/primary-selection/primary-selection-unstable-v1.xml

GEN_HEADERS := $(foreach p,$(PROTOCOLS),protocol/$(p)-client-protocol.h protocol/$(p)-server-protocol.h)
GEN_SOURCES := $(foreach p,$(PROTOCOLS),protocol/$(p)-protocol.c)
GEN_OBJECTS := $(GEN_SOURCES:.c=.o)

BIN := wl-focus-proxy

.PHONY: all clean
all: $(BIN)

protocol:
	mkdir -p protocol

protocol/wayland-client-protocol.h: $(WAYLAND_XML) | protocol
	$(WAYLAND_SCANNER) client-header < $< > $@
protocol/wayland-server-protocol.h: $(WAYLAND_XML) | protocol
	$(WAYLAND_SCANNER) server-header < $< > $@
protocol/wayland-protocol.c: $(WAYLAND_XML) | protocol
	$(WAYLAND_SCANNER) public-code < $< > $@

protocol/xdg-shell-client-protocol.h: $(XDG_SHELL_XML) | protocol
	$(WAYLAND_SCANNER) client-header < $< > $@
protocol/xdg-shell-server-protocol.h: $(XDG_SHELL_XML) | protocol
	$(WAYLAND_SCANNER) server-header < $< > $@
protocol/xdg-shell-protocol.c: $(XDG_SHELL_XML) | protocol
	$(WAYLAND_SCANNER) public-code < $< > $@

protocol/xdg-decoration-client-protocol.h: $(XDG_DECORATION_XML) | protocol
	$(WAYLAND_SCANNER) client-header < $< > $@
protocol/xdg-decoration-server-protocol.h: $(XDG_DECORATION_XML) | protocol
	$(WAYLAND_SCANNER) server-header < $< > $@
protocol/xdg-decoration-protocol.c: $(XDG_DECORATION_XML) | protocol
	$(WAYLAND_SCANNER) public-code < $< > $@

protocol/linux-dmabuf-client-protocol.h: $(LINUX_DMABUF_XML) | protocol
	$(WAYLAND_SCANNER) client-header < $< > $@
protocol/linux-dmabuf-server-protocol.h: $(LINUX_DMABUF_XML) | protocol
	$(WAYLAND_SCANNER) server-header < $< > $@
protocol/linux-dmabuf-protocol.c: $(LINUX_DMABUF_XML) | protocol
	$(WAYLAND_SCANNER) public-code < $< > $@

protocol/viewporter-client-protocol.h: $(VIEWPORTER_XML) | protocol
	$(WAYLAND_SCANNER) client-header < $< > $@
protocol/viewporter-server-protocol.h: $(VIEWPORTER_XML) | protocol
	$(WAYLAND_SCANNER) server-header < $< > $@
protocol/viewporter-protocol.c: $(VIEWPORTER_XML) | protocol
	$(WAYLAND_SCANNER) public-code < $< > $@

protocol/primary-selection-client-protocol.h: $(PRIMARY_SELECTION_XML) | protocol
	$(WAYLAND_SCANNER) client-header < $< > $@
protocol/primary-selection-server-protocol.h: $(PRIMARY_SELECTION_XML) | protocol
	$(WAYLAND_SCANNER) server-header < $< > $@
protocol/primary-selection-protocol.c: $(PRIMARY_SELECTION_XML) | protocol
	$(WAYLAND_SCANNER) public-code < $< > $@

src/proxy.o: src/proxy.c $(GEN_HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

protocol/%.o: protocol/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN): src/proxy.o $(GEN_OBJECTS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDLIBS)

clean:
	rm -rf protocol src/proxy.o $(BIN)
