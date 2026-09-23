# wl-focus-proxy

A generic, protocol-introspecting Wayland relay. It sits between the real
compositor socket and a client and makes that client believe it always
has keyboard/pointer focus, regardless of what's actually focused on the
host.

It does this by relaying every Wayland message unmodified, except:

- `wl_pointer.leave` events are dropped
- `wl_keyboard.leave` events are dropped
- `xdg_toplevel.configure` events have their `states` array rewritten so
  `ACTIVATED` is always present

Nothing else is touched. Object ids are not translated (the proxy never
allocates ids of its own), so a message's bytes are forwarded as-is on
the wire in the vast majority of cases.

## How it knows what to intercept

Rather than hand-coding opcode numbers (which drift between protocol
versions), the proxy is built against the *real* `wayland-scanner`
output for each protocol it supports, and looks up messages by walking
those generated tables — the same tables `libwayland` itself uses. An
id → interface map is built up live by watching every `new_id` in both
directions (including the one special case in the whole protocol corpus
where the target interface isn't statically known: `wl_registry.bind`,
resolved from the interface-name string in that same request) and torn
down on destructors / `wl_display.delete_id`.

File descriptors (keymaps, shm pools, dmabuf planes, ...) are handled
correctly: they arrive out-of-band via `SCM_RIGHTS` independently of
message boundaries, so the proxy keeps a FIFO of received-but-unconsumed
fds and drains exactly as many as each message's signature says it
carries, in order — this only works because the signature is known from
the generated tables, which is also why fd handling for interfaces
outside `KNOWN_INTERFACES` (see below) can't be guaranteed correct.

## Coverage

`KNOWN_INTERFACES` in `proxy.c` covers core `wayland.xml`, `xdg-shell`,
`xdg-decoration`, `linux-dmabuf-v1`, `viewporter` and
`primary-selection-unstable-v1`. `FD_FREE_GLOBALS` lists further
protocols that are relayed byte-for-byte because none of their messages
carry file descriptors (fractional-scale, cursor-shape, presentation-time,
xdg-activation, relative-pointer, pointer-constraints, tablet, ...).

Every other global is removed from the `wl_registry.global` events the
client sees, so it can never bind it. This matters because file
descriptors travel out-of-band via `SCM_RIGHTS`; a protocol whose
signatures the proxy doesn't know (e.g. `wp_drm_lease_device_v1`,
`wp_linux_drm_syncobj`, `zwlr_data_control`) would lose its fds and
desync the queue, breaking unrelated messages such as `wl_keyboard.keymap`
and `zwp_linux_dmabuf_feedback_v1.format_table`
("file descriptor expected" in the client).

To support another protocol, add it to `PROTOCOLS` in the `Makefile` and
its `*_interface` externs to `KNOWN_INTERFACES`; if it never carries fds,
adding its global name to `FD_FREE_GLOBALS` is enough.

## What this does *not* do

- It doesn't change what's focused on the host, or fake input — see the
  `preventIdle` option in the Distrobox module for that (host-side mouse
  jiggling against the real X/Wayland idle counter). This proxy only
  lies to the *boxed app* about its own focus state.
- It doesn't touch rendering/buffers — `wl_shm`, `linux-dmabuf`, and
  friends are relayed like everything else, so GPU-accelerated apps
  (Chromium, mpv) work the same as without the proxy.
- It is a per-client relay: every app gets its own proxy connection to
  the real compositor (`fork()` per accepted client), the same as if it
  had connected directly — the proxy doesn't multiplex multiple apps
  onto one upstream connection.

## Building

Needs `wayland-scanner`, `wayland-protocols`' XML files, and
`libwayland-server`'s headers/pkg-config file at build time:

```sh
make
./wl-focus-proxy --listen wayland-focus-proxy --upstream wayland-1
```

`--upstream` defaults to `$WAYLAND_DISPLAY` (or `wayland-0`) as seen at
startup. `--listen` defaults to `wayland-focus-proxy`. Both are resolved
under `$XDG_RUNTIME_DIR`, matching how every other Wayland socket is
addressed.

## Testing without a real compositor

There's no way to exercise this against a live compositor in a sandbox
without a display. What *can* be, and was, verified without one: a
scripted fake "compositor" and fake "client" speaking raw Wayland wire
bytes to each other through a real running instance of the proxy,
confirming (a) generic pass-through is byte-exact for ordinary requests
including both the static and dynamic (`wl_registry.bind`) `new_id`
resolution paths, (b) `wl_pointer.leave` is dropped, and (c)
`xdg_toplevel.configure` gets `ACTIVATED` injected when absent and left
alone when already present. That test script isn't included here since
it's throwaway scaffolding, but the logic it exercises is exactly what's
described above — reproduce it if you want to re-verify after editing
`proxy.c`.

What was **not**, and cannot be, verified here: real GTK/Qt/Chromium apps
actually behaving differently when focus is spoofed, interaction with
`distrobox`'s specific socket-sharing setup, and protocols outside
`KNOWN_INTERFACES` that real apps might bind. Test against a real session
before relying on this.
