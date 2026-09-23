/**
 ** wl-focus-proxy - a generic, protocol-introspecting Wayland relay that
 ** sits between a real compositor socket and a client (e.g. an app inside
 ** a Distrobox container sharing the host's XDG_RUNTIME_DIR) and makes
 ** that client believe it always has keyboard/pointer focus.
 **
 ** Design
 ** ------
 ** This is a byte-level relay, not a libwayland client/server. For every
 ** message crossing the wire in either direction we:
 **
 **   1. look up the sending object's interface (tracked in an id->interface
 **      map, seeded with id 1 = wl_display, updated on every new_id we see
 **      and every destructor/delete_id we see)
 **   2. find that message's `struct wl_message` (name + signature) in the
 **      real, wayland-scanner-generated interface tables - so opcode
 **      numbers are never hand-guessed, they come from the same tables
 **      libwayland itself uses
 **   3. walk the signature generically to (a) know how many bytes the
 **      message occupies -- actually given directly by the 16-bit size in
 **      the message header, so this is only needed to locate individual
 **      arguments -- and (b) know how many fds it carries, so fds read via
 **      SCM_RIGHTS ancillary data can be drained/attached in the right
 **      order even though they arrive independently of message boundaries
 **   4. apply three, and only three, special cases:
 **        - wl_pointer.leave (event)   -> dropped entirely
 **        - wl_keyboard.leave (event)  -> dropped entirely
 **        - xdg_toplevel.configure (event) -> "states" array is rewritten
 **          so the ACTIVATED bit is always present
 **      everything else is forwarded byte-for-byte, unmodified
 **
 ** Object ids are NOT translated: the same id numbers are valid on both
 ** legs of the relay since we never allocate objects of our own, so a
 ** single shared id->interface map is enough.
 **
 ** wl_registry.global events for interfaces outside KNOWN_INTERFACES and
 ** FD_FREE_GLOBALS are dropped, so clients never bind a protocol whose fd
 ** layout the proxy can't account for. See README "Coverage".
 **
 ** Build:  meson setup build && ninja -C build
 ** Run:    wl-focus-proxy --listen wayland-focus-proxy
 **         (relays to $WAYLAND_DISPLAY as seen at startup; point apps at
 **         WAYLAND_DISPLAY=wayland-focus-proxy)
 **/
#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <unistd.h>
#include <wayland-util.h>

#include "linux-dmabuf-client-protocol.h"
#include "linux-dmabuf-server-protocol.h"
#include "primary-selection-client-protocol.h"
#include "primary-selection-server-protocol.h"
#include "viewporter-client-protocol.h"
#include "viewporter-server-protocol.h"
#include "wayland-client-protocol.h"
#include "wayland-server-protocol.h"
#include "xdg-decoration-client-protocol.h"
#include "xdg-decoration-server-protocol.h"
#include "xdg-shell-client-protocol.h"
#include "xdg-shell-server-protocol.h"

/* ---------------------------------------------------------------- */
/* Interface name -> struct wl_interface* table, built from the real */
/* wayland-scanner output, so we never hand-guess opcode numbers.    */
/* ---------------------------------------------------------------- */
static const struct wl_interface* const KNOWN_INTERFACES[] = {
    &wl_display_interface,
    &wl_registry_interface,
    &wl_callback_interface,
    &wl_compositor_interface,
    &wl_shm_pool_interface,
    &wl_shm_interface,
    &wl_buffer_interface,
    &wl_data_offer_interface,
    &wl_data_source_interface,
    &wl_data_device_interface,
    &wl_data_device_manager_interface,
    &wl_shell_interface,
    &wl_shell_surface_interface,
    &wl_surface_interface,
    &wl_seat_interface,
    &wl_pointer_interface,
    &wl_keyboard_interface,
    &wl_touch_interface,
    &wl_output_interface,
    &wl_region_interface,
    &wl_subcompositor_interface,
    &wl_subsurface_interface,
    &xdg_wm_base_interface,
    &xdg_positioner_interface,
    &xdg_surface_interface,
    &xdg_toplevel_interface,
    &xdg_popup_interface,
    &zxdg_decoration_manager_v1_interface,
    &zxdg_toplevel_decoration_v1_interface,
    &zwp_linux_dmabuf_v1_interface,
    &zwp_linux_buffer_params_v1_interface,
    &zwp_linux_dmabuf_feedback_v1_interface,
    &wp_viewporter_interface,
    &wp_viewport_interface,
    &zwp_primary_selection_device_manager_v1_interface,
    &zwp_primary_selection_device_v1_interface,
    &zwp_primary_selection_offer_v1_interface,
    &zwp_primary_selection_source_v1_interface,
};

#define NUM_KNOWN_INTERFACES \
  (sizeof(KNOWN_INTERFACES) / sizeof(KNOWN_INTERFACES[0]))

static const char* const FD_FREE_GLOBALS[] = {
    "wp_fractional_scale_manager_v1",
    "wp_cursor_shape_manager_v1",
    "wp_presentation",
    "wp_content_type_manager_v1",
    "wp_single_pixel_buffer_manager_v1",
    "wp_alpha_modifier_v1",
    "xdg_activation_v1",
    "xdg_wm_dialog_v1",
    "xdg_toplevel_icon_manager_v1",
    "zxdg_output_manager_v1",
    "zxdg_exporter_v2",
    "zxdg_importer_v2",
    "zwp_relative_pointer_manager_v1",
    "zwp_pointer_constraints_v1",
    "zwp_keyboard_shortcuts_inhibit_manager_v1",
    "zwp_idle_inhibit_manager_v1",
    "zwp_tablet_manager_v2",
    "zwp_text_input_manager_v3",
    "ext_idle_notifier_v1",
    "org_kde_kwin_server_decoration_manager",
};

static bool global_is_relayable(const char* name, uint32_t len)
{
  for (size_t i = 0; i < NUM_KNOWN_INTERFACES; i++)
    if (strlen(KNOWN_INTERFACES[i]->name) == len &&
        memcmp(KNOWN_INTERFACES[i]->name, name, len) == 0)
      return true;
  for (size_t i = 0; i < sizeof(FD_FREE_GLOBALS) / sizeof(FD_FREE_GLOBALS[0]); i++)
    if (strlen(FD_FREE_GLOBALS[i]) == len &&
        memcmp(FD_FREE_GLOBALS[i], name, len) == 0)
      return true;
  return false;
}


static const struct wl_interface* find_interface_by_name(const char* name)
{
  for (size_t i = 0; i < NUM_KNOWN_INTERFACES; i++)
    if (strcmp(KNOWN_INTERFACES[i]->name, name) == 0)
      return KNOWN_INTERFACES[i];
  return NULL;
}

/* ---------------------------------------------------------------- */
/* id -> interface map                                               */
/* ---------------------------------------------------------------- */
#define ID_MAP_BUCKETS 4096

struct id_entry {
  uint32_t id;
  const struct wl_interface* iface;
  struct id_entry* next;
};

struct id_map {
  struct id_entry* buckets[ID_MAP_BUCKETS];
};

static void id_map_set(struct id_map* m, uint32_t id,
                       const struct wl_interface* iface)
{
  struct id_entry** slot = &m->buckets[id % ID_MAP_BUCKETS];
  for (struct id_entry* e = *slot; e; e = e->next) {
    if (e->id == id) {
      e->iface = iface;
      return;
    }
  }
  struct id_entry* e = calloc(1, sizeof(*e));
  e->id = id;
  e->iface = iface;
  e->next = *slot;
  *slot = e;
}

static const struct wl_interface* id_map_get(struct id_map* m, uint32_t id)
{
  for (struct id_entry* e = m->buckets[id % ID_MAP_BUCKETS]; e; e = e->next)
    if (e->id == id) return e->iface;
  return NULL;
}

static void id_map_del(struct id_map* m, uint32_t id)
{
  struct id_entry** slot = &m->buckets[id % ID_MAP_BUCKETS];
  for (struct id_entry** p = slot; *p; p = &(*p)->next) {
    if ((*p)->id == id) {
      struct id_entry* dead = *p;
      *p = dead->next;
      free(dead);
      return;
    }
  }
}

/* ---------------------------------------------------------------- */
/* fd queue: fds arrive via SCM_RIGHTS independently of message      */
/* boundaries, so we drain them into a FIFO and pop from it exactly  */
/* as many times as each message's signature says it carries an 'h'. */
/* ---------------------------------------------------------------- */
struct fd_queue {
  int fds[256];
  size_t head, tail;
};

static void fdq_push(struct fd_queue* q, int fd)
{
  if (q->tail - q->head >= sizeof(q->fds) / sizeof(q->fds[0])) {
    fprintf(stderr, "wl-focus-proxy: fd queue overflow, dropping fd\n");
    close(fd);
    return;
  }
  q->fds[q->tail % (sizeof(q->fds) / sizeof(q->fds[0]))] = fd;
  q->tail++;
}

static int fdq_pop(struct fd_queue* q)
{
  if (q->head == q->tail) {
    fprintf(stderr, "wl-focus-proxy: fd queue underflow (protocol desync?)\n");
    return -1;
  }
  int fd = q->fds[q->head % (sizeof(q->fds) / sizeof(q->fds[0]))];
  q->head++;
  return fd;
}

/* ---------------------------------------------------------------- */
/* growable byte buffer                                              */
/* ---------------------------------------------------------------- */
struct byte_buf {
  uint8_t* data;
  size_t len, cap;
};

static void bb_reserve(struct byte_buf* b, size_t extra)
{
  if (b->len + extra <= b->cap) return;
  size_t ncap = b->cap ? b->cap * 2 : 4096;
  while (ncap < b->len + extra) ncap *= 2;
  b->data = realloc(b->data, ncap);
  b->cap = ncap;
}

static void bb_append(struct byte_buf* b, const void* p, size_t n)
{
  bb_reserve(b, n);
  memcpy(b->data + b->len, p, n);
  b->len += n;
}

static void bb_consume(struct byte_buf* b, size_t n)
{
  memmove(b->data, b->data + n, b->len - n);
  b->len -= n;
}

/* ---------------------------------------------------------------- */
/* signature walking                                                 */
/* ---------------------------------------------------------------- */

/* Skip an optional leading "since version" digit some signatures carry. */
static const char* sig_skip_version(const char* sig)
{
  while (*sig >= '0' && *sig <= '9') sig++;
  return sig;
}

struct parsed_arg {
  char type; /* i u f s o n a h */
  uint32_t u32; /* value, for i/u/o/n; for s, the byte length that follows */
  const char* str; /* for s: pointer to the (non-terminated) string bytes in payload */
};

/**
 ** Walk one message's arguments out of `payload` (length `len`), per
 ** `signature`. Returns false on a malformed/short message. Calls
 ** `cb(ctx, argindex, parsed)` for each argument as it's found; the
 ** callback may inspect but must not assume `payload` outlives the call.
 ** Also fills *n_fds with how many 'h' arguments were present.
 **/
typedef void (*arg_cb_t)(void* ctx, int index, struct parsed_arg* arg);

static bool walk_args(const char* signature, const uint8_t* payload,
                      uint32_t len,
                      arg_cb_t cb, void* ctx, int* n_fds)
{
  const char* sig = sig_skip_version(signature);
  uint32_t off = 0;
  int idx = 0;
  *n_fds = 0;

  for (; *sig; sig++, idx++) {
    char c = *sig;
    if (c == '?') continue; /* nullable marker, doesn't affect wire layout */

    struct parsed_arg pa = {.type = c};
    switch (c) {
      case 'i':
      case 'u':
      case 'o':
      case 'n':
        if (off + 4 > len) return false;
        memcpy(&pa.u32, payload + off, 4);
        off += 4;
        if (cb) cb(ctx, idx, &pa);
        break;
      case 'f':
        if (off + 4 > len) return false;
        off += 4;
        if (cb) cb(ctx, idx, &pa);
        break;
      case 's':
      case 'a': {
        if (off + 4 > len) return false;
        uint32_t n;
        memcpy(&n, payload + off, 4);
        off += 4;
        uint32_t padded = (n + 3u) & ~3u;
        if (off + padded > len) return false;
        pa.u32 = n;
        pa.str = (const char*)(payload + off);
        off += padded;
        if (cb) cb(ctx, idx, &pa);
        break;
      }
      case 'h':
        (*n_fds)++;
        if (cb) cb(ctx, idx, &pa);
        break;
      default:
        fprintf(stderr, "wl-focus-proxy: unknown signature char '%c'\n", c);
        return false;
    }
  }
  (void)off;
  return true;
}

/* ---------------------------------------------------------------- */
/* connection state (one relay = one accepted client + its upstream) */
/* ---------------------------------------------------------------- */
struct leg {
  int fd;
  struct byte_buf in; /* raw bytes read, not yet fully processed */
  struct fd_queue fdq; /* fds read via SCM_RIGHTS, not yet consumed */
};

struct relay {
  struct leg client; /* the app inside the container */
  struct leg upstream; /* the real compositor */
  /*
   * Wayland object IDs are scoped to each protocol connection.
   * Keep a separate interface map for each side of the relay.
   */
  struct id_map client_ids;
  struct id_map upstream_ids;
};

#define XDG_TOPLEVEL_STATE_ACTIVATED 3

/**
 ** Rebuild an xdg_toplevel.configure event so its states array always
 ** contains ACTIVATED. Returns a newly malloc'd payload; caller frees.
 **/
static uint8_t* force_activated(const uint8_t* payload, uint32_t len,
                                uint32_t* out_len)
{
  /* iia: width(4) height(4) array_len(4) array_bytes(padded) */
  if (len < 12) {
    *out_len = len;
    uint8_t* copy = malloc(len);
    memcpy(copy, payload, len);
    return copy;
  }

  uint32_t arr_len;
  memcpy(&arr_len, payload + 8, 4);
  uint32_t arr_padded = (arr_len + 3u) & ~3u;

  bool has_activated = false;
  for (uint32_t o = 0; o + 4 <= arr_len; o += 4) {
    uint32_t v;
    memcpy(&v, payload + 12 + o, 4);
    if (v == XDG_TOPLEVEL_STATE_ACTIVATED) {
      has_activated = true;
      break;
    }
  }

  if (has_activated) {
    *out_len = len;
    uint8_t* copy = malloc(len);
    memcpy(copy, payload, len);
    return copy;
  }

  uint32_t new_arr_len = arr_len + 4;
  uint32_t new_arr_padded = (new_arr_len + 3u) & ~3u;
  uint32_t new_len = 12 + new_arr_padded;
  uint8_t* out = calloc(1, new_len);
  memcpy(out, payload, 8); /* width, height */
  memcpy(out + 8, &new_arr_len, 4); /* new array length */
  memcpy(out + 12, payload + 12, arr_len); /* existing states */
  uint32_t activated = XDG_TOPLEVEL_STATE_ACTIVATED;
  memcpy(out + 12 + arr_len, &activated, 4); /* appended state */
  /* padding bytes (if any) are already zero from calloc */
  (void)arr_padded;
  *out_len = new_len;
  return out;
}

/* ---------------------------------------------------------------- */
/* core per-message handling                                         */
/* ---------------------------------------------------------------- */

/**
 ** Writes a message (header + payload) to fd, attaching fds via SCM_RIGHTS.
 **/
static bool send_message(int fd, uint32_t obj, uint16_t opcode,
                         const uint8_t* payload,
                         uint32_t payload_len, int* fds, int n_fds)
{
  uint32_t header[2];
  header[0] = obj;
  header[1] = (uint32_t)((8 + payload_len) << 16) | opcode;

  struct iovec iov[2] = {
      {.iov_base = header, .iov_len = sizeof(header)},
      {.iov_base = (void*)payload, .iov_len = payload_len},
  };

  struct msghdr msg = {0};
  msg.msg_iov = iov;
  msg.msg_iovlen = payload_len ? 2 : 1;

  char cbuf[CMSG_SPACE(sizeof(int) * 64)];
  if (n_fds > 0) {
    msg.msg_control = cbuf;
    msg.msg_controllen = CMSG_SPACE(sizeof(int) * n_fds);
    struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(sizeof(int) * n_fds);
    memcpy(CMSG_DATA(cmsg), fds, sizeof(int) * n_fds);
    msg.msg_controllen = cmsg->cmsg_len;
  }

  ssize_t n = sendmsg(fd, &msg, MSG_NOSIGNAL);
  for (int i = 0; i < n_fds; i++) close(fds[i]);
  if (n < 0) {
    if (errno != EPIPE && errno != ECONNRESET) perror("sendmsg");
    return false;
  }
  return true;
}

/**
 ** Process every complete message currently buffered in `src->in`,
 ** relaying to `dst_fd`, applying the focus filters, and updating `ids`.
 ** `events` selects whether we're reading requests (client->upstream,
 ** events=false) or events (upstream->client, events=true), since that
 ** determines whether we consult interface->methods or interface->events.
 **/
static bool pump(
    struct leg* src,
    int dst_fd,
    struct id_map* ids,
    struct id_map* other_ids,
    bool events,
    const char* tag
)
{
  for (;;) {
    if (src->in.len < 8) return true;

    uint32_t obj;
    uint32_t szop;
    memcpy(&obj, src->in.data, 4);
    memcpy(&szop, src->in.data + 4, 4);

    uint32_t msg_len = szop >> 16;
    uint16_t opcode = szop & 0xffff;

    if (msg_len < 8) {
      fprintf(stderr, "wl-focus-proxy[%s]: malformed message (size %u)\n", tag, msg_len);
      return false;
    }
    if (src->in.len < msg_len) return true; /* wait for more bytes */

    uint8_t* payload = src->in.data + 8;
    uint32_t payload_len = msg_len - 8;

    const struct wl_interface* iface = id_map_get(ids, obj);
    const struct wl_message* table;
    int table_count;
    if (iface) {
      table = events ? iface->events : iface->methods;
      table_count = events ? iface->event_count : iface->method_count;
    } else {
      table = NULL;
      table_count = 0;
    }

    bool forward = true;
    uint8_t* rewritten = NULL;
    uint32_t rewritten_len = 0;
    int n_fds = 0;

    if (!iface) {
      /**
       ** Object we never saw created (e.g. we started mid-stream, or
       ** it came from an interface outside KNOWN_INTERFACES). We
       ** cannot safely know if this message carries fds, so we
       ** forward it blindly with zero fds. This is the documented
       ** best-effort fallback; see README "Coverage".
       **/
      forward = true;
    } else if (opcode >= (unsigned)table_count) {
      fprintf(stderr,
              "wl-focus-proxy[%s]: opcode %u out of range for %s (%s)\n",
              tag, opcode, iface->name, events ? "events" : "methods");
      forward = true;
    } else {
      const struct wl_message* m = &table[opcode];
      bool is_dtor = m->name[0] == '~';

      /* Track any new_id created by this message, and resolve the
       ** dynamic wl_registry.bind case via the preceding string arg. */
      struct new_id_scan {
        uint32_t new_id;
        bool have_new_id;
        const struct wl_interface* resolved;
        const char* last_string;
        const struct wl_message* m;
      } scan = {.m = m};

      const char* sig = sig_skip_version(m->signature);
      int type_idx = 0;
      for (const char* s = sig; *s; s++, type_idx++) {
        if (*s == '?') {
          type_idx--;
          continue;
        }
      }

      /* Re-walk properly with a callback that has access to m->types */
      struct cb_ctx {
        struct new_id_scan* scan;
      } cbctx = {.scan = &scan};

      void cb(void* ctxp, int index, struct parsed_arg* arg) {
        struct cb_ctx* c = ctxp;
        if (arg->type == 's') {
          c->scan->last_string = arg->str; /* not NUL-terminated; length in
                                              arg->u32, unused beyond bind */
        } else if (arg->type == 'n') {
          c->scan->have_new_id = true;
          c->scan->new_id = arg->u32;
          c->scan->resolved = c->scan->m->types[index];
        }
      }

      bool ok =
          walk_args(m->signature, payload, payload_len, cb, &cbctx, &n_fds);

      if (!ok) {
        fprintf(stderr,
                "wl-focus-proxy[%s]: failed to parse %s.%s, forwarding blind\n",
                tag, iface->name, m->name);
        n_fds = 0;
      } else if (scan.have_new_id) {
        const struct wl_interface* new_iface = scan.resolved;
        if (!new_iface && scan.last_string) {
          /* wl_registry.bind: resolve dynamically by interface name.
           ** last_string points into payload and is length-prefixed;
           ** we need a NUL-terminated copy to strcmp against our table. */
          struct len_ctx {
            const char* want;
            uint32_t len;
          } lc = {.want = scan.last_string, .len = 0};

          void lcb(void* cp, int idx2, struct parsed_arg* a2) {
            (void)idx2;
            struct len_ctx* l = cp;
            if (a2->type == 's' && a2->str == l->want) l->len = a2->u32;
          }

          int dummy;
          walk_args(m->signature, payload, payload_len, lcb, &lc, &dummy);

          char namebuf[256];
          uint32_t n =
              lc.len < sizeof(namebuf) - 1 ? lc.len : sizeof(namebuf) - 1;
          if (n > 0) memcpy(namebuf, scan.last_string, n);
          namebuf[n] = 0;

          new_iface = find_interface_by_name(namebuf);
        }

        id_map_set(ids, scan.new_id, new_iface);
        /* The same object ID is preserved on both relay legs. */
        id_map_set(other_ids, scan.new_id, new_iface);
      }

      if (is_dtor) id_map_del(ids, obj);

      /* --- the three focus-spoofing special cases --- */
      if (events && iface == &wl_pointer_interface &&
          strcmp(m->name, "leave") == 0) {
        forward = false;
      } else if (events && iface == &wl_keyboard_interface &&
                 strcmp(m->name, "leave") == 0) {
        forward = false;
      } else if (events && iface == &wl_registry_interface &&
                 strcmp(m->name, "global") == 0) {
        uint32_t slen;
        if (payload_len >= 8) {
          memcpy(&slen, payload + 4, 4);
          if (slen > 0 && 8 + slen <= payload_len &&
              !global_is_relayable((const char*)payload + 8, slen - 1))
            forward = false;
        }
      } else if (events && iface == &xdg_toplevel_interface &&
                 strcmp(m->name, "configure") == 0) {
        rewritten = force_activated(payload, payload_len, &rewritten_len);
      }

      /* wl_display.delete_id frees an id once the compositor has
       ** confirmed a client-side destroy is fully processed. */
      if (events && iface == &wl_display_interface &&
          strcmp(m->name, "delete_id") == 0) {
        uint32_t freed;
        memcpy(&freed, payload, 4);
        id_map_del(ids, freed);
        id_map_del(other_ids, freed);
      }
    }

    if (forward) {
      int fds[64];
      int nf = n_fds;
      if (nf > 64) nf = 64;
      for (int i = 0; i < nf; i++) fds[i] = fdq_pop(&src->fdq);

      if (rewritten) {
        send_message(dst_fd, obj, opcode, rewritten, rewritten_len, fds, nf);
        free(rewritten);
      } else {
        send_message(dst_fd, obj, opcode, payload, payload_len, fds, nf);
      }
    } else {
      /* Dropped message: still drain any fds it would have carried
       ** (leave events never carry fds, but stay correct in general). */
      for (int i = 0; i < n_fds; i++) {
        int f = fdq_pop(&src->fdq);
        if (f >= 0) close(f);
      }
    }

    bb_consume(&src->in, msg_len);
  }
}

/* ---------------------------------------------------------------- */
/* socket plumbing                                                   */
/* ---------------------------------------------------------------- */

static int connect_upstream(const char* name)
{
  const char* runtime_dir = getenv("XDG_RUNTIME_DIR");
  if (!runtime_dir) {
    fprintf(stderr, "XDG_RUNTIME_DIR not set\n");
    return -1;
  }

  struct sockaddr_un addr = {.sun_family = AF_UNIX};
  if (name[0] == '/')
    snprintf(addr.sun_path, sizeof(addr.sun_path), "%s", name);
  else
    snprintf(addr.sun_path, sizeof(addr.sun_path), "%s/%s", runtime_dir, name);

  int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (fd < 0) {
    perror("socket");
    return -1;
  }

  if (connect(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
    perror("connect upstream");
    close(fd);
    return -1;
  }
  return fd;
}

static int listen_socket(const char* name)
{
  const char* runtime_dir = getenv("XDG_RUNTIME_DIR");
  if (!runtime_dir) {
    fprintf(stderr, "XDG_RUNTIME_DIR not set\n");
    return -1;
  }

  char path[108], lockpath[120];
  int n = snprintf(path, sizeof(path), "%s/%s", runtime_dir, name);
  if (n < 0 || (size_t)n >= sizeof(path)) {
    fprintf(stderr, "wl-focus-proxy: socket path too long\n");
    return -1;
  }

  snprintf(lockpath, sizeof(lockpath), "%s.lock", path);
  int lockfd = open(lockpath, O_CREAT | O_CLOEXEC | O_RDWR, 0644);
  if (lockfd < 0) {
    perror("open lockfile");
    return -1;
  }
  if (flock(lockfd, LOCK_EX | LOCK_NB) < 0) {
    fprintf(stderr,
            "wl-focus-proxy: %s is already in use (another instance running?)\n",
            path);
    return -1;
  }
  unlink(path); /* stale socket from a previous unclean exit */

  struct sockaddr_un addr = {.sun_family = AF_UNIX};
  snprintf(addr.sun_path, sizeof(addr.sun_path), "%s", path);

  int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (fd < 0) {
    perror("socket");
    return -1;
  }
  if (bind(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
    perror("bind");
    close(fd);
    return -1;
  }
  if (listen(fd, 16) < 0) {
    perror("listen");
    close(fd);
    return -1;
  }
  fprintf(stderr, "wl-focus-proxy: listening on %s\n", path);
  return fd;
}

static ssize_t leg_read(struct leg* l)
{
  uint8_t buf[65536];
  char cbuf[CMSG_SPACE(sizeof(int) * 64)];
  struct iovec iov = {.iov_base = buf, .iov_len = sizeof(buf)};

  struct msghdr msg = {0};
  msg.msg_iov = &iov;
  msg.msg_iovlen = 1;
  msg.msg_control = cbuf;
  msg.msg_controllen = sizeof(cbuf);

  ssize_t n = recvmsg(l->fd, &msg, 0);
  if (n <= 0) return n;

  for (struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg); cmsg;
       cmsg = CMSG_NXTHDR(&msg, cmsg)) {
    if (cmsg->cmsg_level == SOL_SOCKET && cmsg->cmsg_type == SCM_RIGHTS) {
      int nfd = (cmsg->cmsg_len - CMSG_LEN(0)) / sizeof(int);
      int* fdp = (int*)CMSG_DATA(cmsg);
      for (int i = 0; i < nfd; i++) fdq_push(&l->fdq, fdp[i]);
    }
  }

  bb_append(&l->in, buf, (size_t)n);
  return n;
}

static void run_relay(int client_fd, const char* upstream_name)
{
  struct relay r = {0};
  r.client.fd = client_fd;
  r.upstream.fd = connect_upstream(upstream_name);
  if (r.upstream.fd < 0) {
    close(client_fd);
    return;
  }

  id_map_set(&r.client_ids, 1, &wl_display_interface);
  id_map_set(&r.upstream_ids, 1, &wl_display_interface);

  struct pollfd pfds[2];
  for (;;) {
    pfds[0] = (struct pollfd){.fd = r.client.fd, .events = POLLIN};
    pfds[1] = (struct pollfd){.fd = r.upstream.fd, .events = POLLIN};

    int ret = poll(pfds, 2, -1);
    if (ret < 0) {
      if (errno == EINTR) continue;
      perror("poll");
      break;
    }

    if (pfds[0].revents & (POLLIN | POLLHUP | POLLERR)) {
      ssize_t n = leg_read(&r.client);
      if (n <= 0) break;
      if (!pump(
              &r.client,
              r.upstream.fd,
              &r.client_ids,
              &r.upstream_ids,
              false,
              "req"
              ))
        break;
    }

    if (pfds[1].revents & (POLLIN | POLLHUP | POLLERR)) {
      ssize_t n = leg_read(&r.upstream);
      if (n <= 0) break;
      if (!pump(
              &r.upstream,
              r.client.fd,
              &r.upstream_ids,
              &r.client_ids,
              true,
              "evt"
              ))
        break;
    }
  }

  close(r.client.fd);
  close(r.upstream.fd);
}

int main(int argc, char** argv)
{
  const char* listen_name = "wayland-focus-proxy";

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--listen") == 0 && i + 1 < argc)
      listen_name = argv[++i];
    else {
      fprintf(stderr, "usage: %s [--listen NAME]\n", argv[0]);
      return 2;
    }
  }

  signal(SIGCHLD, SIG_IGN);
  signal(SIGPIPE, SIG_IGN);

  int lfd = listen_socket(listen_name);
  if (lfd < 0) return 1;

  fprintf(stderr, "wl-focus-proxy: listening on %s\n", listen_name);

  for (;;) {
    int cfd = accept4(lfd, NULL, NULL, SOCK_CLOEXEC);
    if (cfd < 0) {
      if (errno == EINTR) continue;
      perror("accept");
      continue;
    }

    pid_t pid = fork();
    if (pid == 0) {
      // In the child, resolve the upstream socket fresh from the environment.
      const char* upstream = getenv("WAYLAND_DISPLAY");
      if (!upstream) upstream = "wayland-0";
      close(lfd);
      run_relay(cfd, upstream);
      _exit(0);
    } else if (pid > 0) {
      close(cfd);
    } else {
      perror("fork");
      close(cfd);
    }
  }
}