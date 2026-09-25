/* x11-focus-proxy: relay an X11 connection, hiding focus loss from the client.
 *
 * Client->server bytes are forwarded untouched. Server->client bytes are
 * framed (setup reply, then 32-byte events/errors and length-extended
 * replies/generic events) so core FocusOut and LeaveNotify events can be
 * dropped, leaving the client believing it keeps focus and the pointer.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

#define X_DIR "/tmp/.X11-unix"

enum { EV_LEAVE_NOTIFY = 8, EV_FOCUS_OUT = 10, EV_GENERIC = 35 };

struct conn {
	int client;
	int server;
	atomic_int big; /* client byte order, from its setup request: 0 unknown, 1 LSB, 2 MSB */
};

#define MAX_FDS 32

struct fds {
	int fd[MAX_FDS];
	int n;
};

/* Like read(), but any SCM_RIGHTS descriptors received are appended to f. */
static ssize_t recv_fds(int sock, uint8_t *p, size_t n, struct fds *f)
{
	union {
		char buf[CMSG_SPACE(MAX_FDS * sizeof(int))];
		struct cmsghdr align;
	} u;
	struct iovec iov = { p, n };
	struct msghdr m = { .msg_iov = &iov, .msg_iovlen = 1,
			    .msg_control = u.buf, .msg_controllen = sizeof u.buf };
	ssize_t r;

	do
		r = recvmsg(sock, &m, MSG_CMSG_CLOEXEC);
	while (r < 0 && errno == EINTR);
	if (r <= 0)
		return r;
	for (struct cmsghdr *c = CMSG_FIRSTHDR(&m); c; c = CMSG_NXTHDR(&m, c)) {
		if (c->cmsg_level != SOL_SOCKET || c->cmsg_type != SCM_RIGHTS)
			continue;
		int cnt = (int)((c->cmsg_len - CMSG_LEN(0)) / sizeof(int));
		int *d = (int *)CMSG_DATA(c);
		for (int i = 0; i < cnt; i++) {
			if (f->n < MAX_FDS)
				f->fd[f->n++] = d[i];
			else
				close(d[i]);
		}
	}
	return r;
}

/* Writes all of p; f's descriptors ride with the first byte, then are closed. */
static int send_all(int sock, const uint8_t *p, size_t n, struct fds *f)
{
	while (n) {
		union {
			char buf[CMSG_SPACE(MAX_FDS * sizeof(int))];
			struct cmsghdr align;
		} u;
		struct iovec iov = { (void *)p, n };
		struct msghdr m = { .msg_iov = &iov, .msg_iovlen = 1 };
		ssize_t w;

		if (f->n) {
			m.msg_control = u.buf;
			m.msg_controllen = CMSG_SPACE(f->n * sizeof(int));
			struct cmsghdr *c = CMSG_FIRSTHDR(&m);
			c->cmsg_level = SOL_SOCKET;
			c->cmsg_type = SCM_RIGHTS;
			c->cmsg_len = CMSG_LEN(f->n * sizeof(int));
			memcpy(CMSG_DATA(c), f->fd, f->n * sizeof(int));
		}
		w = sendmsg(sock, &m, MSG_NOSIGNAL);
		if (w < 0) {
			if (errno == EINTR)
				continue;
			return -1;
		}
		for (int i = 0; i < f->n; i++)
			close(f->fd[i]);
		f->n = 0;
		p += w;
		n -= (size_t)w;
	}
	return 0;
}

static int read_full(int sock, uint8_t *p, size_t n, struct fds *f)
{
	while (n) {
		ssize_t r = recv_fds(sock, p, n, f);
		if (r <= 0)
			return -1;
		p += r;
		n -= (size_t)r;
	}
	return 0;
}

static void *client_to_server(void *arg)
{
	struct conn *c = arg;
	uint8_t buf[65536];
	ssize_t r;
	int first = 1;
	struct fds f = { .n = 0 };

	while ((r = recv_fds(c->client, buf, sizeof buf, &f)) > 0) {
		if (first) {
			atomic_store(&c->big, buf[0] == 'B' ? 2 : 1);
			first = 0;
		}
		if (send_all(c->server, buf, (size_t)r, &f) < 0)
			break;
	}
	shutdown(c->server, SHUT_WR);
	return NULL;
}

static uint32_t rd32(const uint8_t *p, int big)
{
	return big ? (uint32_t)p[0] << 24 | (uint32_t)p[1] << 16 | (uint32_t)p[2] << 8 | p[3]
		   : (uint32_t)p[3] << 24 | (uint32_t)p[2] << 16 | (uint32_t)p[1] << 8 | p[0];
}

static uint16_t rd16(const uint8_t *p, int big)
{
	return big ? (uint16_t)(p[0] << 8 | p[1]) : (uint16_t)(p[1] << 8 | p[0]);
}

static int forward(struct conn *c, uint8_t *buf, size_t n, int drop, struct fds *f)
{
	if (!drop)
		return send_all(c->client, buf, n, f);
	for (int i = 0; i < f->n; i++)
		close(f->fd[i]);
	f->n = 0;
	return 0;
}

static void *server_to_client(void *arg)
{
	struct conn *c = arg;
	uint8_t *buf = malloc(32);
	size_t cap = 32;
	int big;
	struct fds f = { .n = 0 };

	if (!buf)
		return NULL;

	/* setup reply: 8-byte header, then additional-length 4-byte units */
	if (read_full(c->server, buf, 8, &f) < 0)
		goto out;
	big = atomic_load(&c->big) == 2;
	{
		size_t extra = (size_t)rd16(buf + 6, big) * 4;
		if (extra + 8 > cap) {
			uint8_t *nb = realloc(buf, cap = extra + 8);
			if (!nb)
				goto out;
			buf = nb;
		}
		if (read_full(c->server, buf + 8, extra, &f) < 0 ||
		    send_all(c->client, buf, 8 + extra, &f) < 0)
			goto out;
	}

	for (;;) {
		size_t len = 32;
		int type, drop;

		if (read_full(c->server, buf, 32, &f) < 0)
			break;
		type = buf[0] & 0x7f;
		if (type == 1 || type == EV_GENERIC) {
			size_t extra = (size_t)rd32(buf + 4, big) * 4;
			if (extra) {
				if (32 + extra > cap) {
					uint8_t *nb = realloc(buf, cap = 32 + extra);
					if (!nb)
						break;
					buf = nb;
				}
				if (read_full(c->server, buf + 32, extra, &f) < 0)
					break;
				len += extra;
			}
		}
		drop = type == EV_FOCUS_OUT || type == EV_LEAVE_NOTIFY;
		if (forward(c, buf, len, drop, &f) < 0)
			break;
	}
out:
	free(buf);
	shutdown(c->client, SHUT_WR);
	return NULL;
}

static int unix_addr(struct sockaddr_un *a, const char *dir_display)
{
	memset(a, 0, sizeof *a);
	a->sun_family = AF_UNIX;
	return snprintf(a->sun_path, sizeof a->sun_path, X_DIR "/X%s", dir_display) >=
	       (int)sizeof a->sun_path;
}

static void *serve(void *arg)
{
	struct conn *c = arg;
	pthread_t up;

	if (pthread_create(&up, NULL, client_to_server, c) == 0) {
		server_to_client(c);
		pthread_join(up, NULL);
	}
	close(c->client);
	close(c->server);
	free(c);
	return NULL;
}

static void usage(void)
{
	fprintf(stderr, "usage: x11-focus-proxy [--listen N] [--upstream N]\n"
			"  N is a display number (99 for :99). --upstream defaults to $DISPLAY.\n");
	exit(2);
}

int main(int argc, char **argv)
{
	const char *listen_n = "99";
	const char *up_n = NULL;
	struct sockaddr_un la, ua;
	int ls;

	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "--listen") && i + 1 < argc)
			listen_n = argv[++i];
		else if (!strcmp(argv[i], "--upstream") && i + 1 < argc)
			up_n = argv[++i];
		else
			usage();
	}

	char dispbuf[32];
	if (!up_n) {
		const char *d = getenv("DISPLAY");
		if (!d || d[0] != ':') {
			fprintf(stderr, "x11-focus-proxy: no local $DISPLAY and no --upstream\n");
			return 1;
		}
		snprintf(dispbuf, sizeof dispbuf, "%s", d + 1);
		dispbuf[strcspn(dispbuf, ".")] = 0;
		up_n = dispbuf;
	}

	signal(SIGPIPE, SIG_IGN);

	if (unix_addr(&la, listen_n) || unix_addr(&ua, up_n)) {
		fprintf(stderr, "x11-focus-proxy: display number too long\n");
		return 1;
	}

	ls = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
	if (ls < 0) {
		perror("socket");
		return 1;
	}
	unlink(la.sun_path);
	if (bind(ls, (struct sockaddr *)&la, sizeof la) < 0 || listen(ls, 64) < 0) {
		perror(la.sun_path);
		return 1;
	}
	chmod(la.sun_path, 0700);

	for (;;) {
		int cs = accept4(ls, NULL, NULL, SOCK_CLOEXEC);
		if (cs < 0) {
			if (errno == EINTR)
				continue;
			perror("accept");
			return 1;
		}
		int ss = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
		if (ss < 0 || connect(ss, (struct sockaddr *)&ua, sizeof ua) < 0) {
			perror(ua.sun_path);
			if (ss >= 0)
				close(ss);
			close(cs);
			continue;
		}
		struct conn *c = calloc(1, sizeof *c);
		pthread_t t;
		if (!c) {
			close(cs);
			close(ss);
			continue;
		}
		c->client = cs;
		c->server = ss;
		if (pthread_create(&t, NULL, serve, c) != 0) {
			close(cs);
			close(ss);
			free(c);
			continue;
		}
		pthread_detach(t);
	}
}
