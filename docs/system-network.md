[Index](CONFIGURATION.md)

---

DNS for the whole machine, a Tor toggle that really does route
everything, and the handful of sysctls that make the network stack less
credulous. One file, because these three keep colliding with each other -
and the Tor half is the most dangerous thing in this repo to get subtly
wrong, because "silently still leaking" and "working perfectly" look
identical from the outside.

## `modules/system/network/Network.nix`

Everything here is driven from `vayori.network` in
[Host.nix](core-host.md):

```nix
vayori.network = {
  dns = {
    provider = "cloudflare";      # quad9 | mullvad | adguard | google
    overTls = "opportunistic";    # "true" (strict) | "false"
    ipv6 = true;
  };

  tor = {
    enable = true;
    includeContainers = true;
  };

  hardening.enable = true;
  randomizeMac = false;
};
```

### DNS

**Every resolver is written with its DoT hostname**, e.g.
`1.1.1.1#one.one.one.one`, `9.9.9.9#dns.quad9.net`. That suffix isn't
decoration: systemd-resolved needs a name to validate the server's
certificate against, and without it `DNSOverTLS` still connects, still
encrypts, and verifies *nothing* - the failure mode is a tunnel that
looks right and authenticates no one. Each provider entry carries its
own hostname so switching providers can't leave a stale one behind.

**`overTls` defaults to `opportunistic`, not `true`.** Strict mode
refuses to resolve at all when DoT is unavailable, which is correct right
up until the first hotel captive portal, where it means no DNS, no portal
page, and no way to get online. Opportunistic encrypts wherever the
server supports it and falls back rather than stranding you.

**`networking.networkmanager.dns = "systemd-resolved"`** matters as much
as the resolver list. Without it NetworkManager writes DHCP-provided
servers straight into `resolv.conf` and the whole setting is decorative.

These are set through `services.resolved.settings.Resolve.*`, not the
flat `dnssec`/`dnsovertls`/`fallbackDns` options - those still work but
are renamed now, and warn on every single evaluation.

### Tor, and what "transparent" actually costs

The control-center widget starts and stops `tor.service`. Tor is
installed with `wantedBy = []`, so it never starts at boot - the toggle
genuinely owns whether it runs.

While it's on, three sets of rules are in place:

| Chain | Table | Does |
| --- | --- | --- |
| `VAYORI_TOR` | nat OUTPUT | all TCP → TransPort 9040, all DNS → DNSPort 9053 |
| `VAYORI_TORLEAK` | filter OUTPUT | rejects everything that isn't TCP or DNS |
| `VAYORI_TOR_PRE` / `VAYORI_TOR_FWD` | nat PREROUTING / filter FORWARD | the same, for container traffic |
| `VAYORI_TOR6` | filter OUTPUT (v6) | rejects all outbound IPv6 |

Ports 9040 and 9053 aren't chosen here - they come from NixOS's own
`services.tor.client.transparentProxy.enable` and `client.dns.enable`,
and the rules are written to match what that module actually configures.

Four things that are easy to get wrong, and why each rule exists:

- **Tor's own uid is exempt.** Without `-m owner --uid-owner tor -j
  RETURN`, Tor's outbound connections get redirected into Tor's own
  TransPort, and it deadlocks against itself.
- **Non-TCP is rejected, not allowed.** Tor carries TCP. It cannot carry
  QUIC, WireGuard, NTP or ICMP. Letting those through "because they'd
  break otherwise" is exactly the leak - the traffic goes out in the
  clear while the widget cheerfully says connected.
- **IPv6 is closed entirely.** This TransPort is v4-only. An open v6
  path is a complete bypass of every rule above it, so v6 gets rejected
  rather than left as an escape hatch. On an IPv6-only network this
  reads as "the internet is broken", which is the correct trade but
  worth knowing before you flip it on.
- **Containers need their own rules.** Docker and Podman traffic is
  *forwarded*, not locally generated - it never passes through OUTPUT, so
  the first two chains never see it. `includeContainers` adds the
  PREROUTING redirect and FORWARD reject for `172.16.0.0/12` and
  `10.88.0.0/16`. Turn it off and containers keep talking directly while
  everything else is routed.

**DNS still resolves through Cloudflare - over Tor.** Applications query
systemd-resolved on loopback, which is exempt; resolved then forwards
upstream to `1.1.1.1:53`, and *that* packet hits the nat chain and gets
redirected into Tor's DNSPort. The loopback exemption looks like a leak
and isn't, because the only thing behind it is a forwarder whose own
egress is captured.

### Fail-safes

A transparent proxy that half-applies is a machine with no network, so
both directions are ordered defensively:

- **Start** applies rules *only after* polling `ss` until port 9040 is
  actually listening (15s). If Tor never comes up, it stops Tor and
  leaves traffic untouched rather than blackholing the box against a
  dead port.
- **Stop** tears down rules *first*, then stops Tor - and deliberately
  runs without `set -e`, so a chain that's already gone can't abort
  teardown halfway and strand you between two states.
- **A firewall restart flushes everything**, including these chains,
  which would silently drop traffic back to direct while Tor is still
  running and the widget still says connected.
  `networking.firewall.extraCommands` re-applies the ruleset on every
  firewall (re)start if `tor.service` is active.

Privilege follows the same pattern as the rebuild/GC scripts in
[Dms.nix](desktop-dms.md): a root-side `vayori-torctl` that accepts only
`start`, `stop` and `newnym`, allowed NOPASSWD - never general
`systemctl` access. The user-facing `vayori-tor` wrapper shells out to it.

`vayori-tor newnym` asks Tor for fresh circuits over its control socket.
That lives on the privileged side because the socket is root-owned.

### The widget

`torWidget/` is a small DMS plugin, because nothing in the plugin
registry does Tor - the closest are ProtonVPN, Tailscale and mihomo,
which are all different things.

DMS's control center takes plugin widgets: `WidgetModel.qml` builds their
ids as `"plugin_" + plugin.id`, and `getPluginWidgets()` filters on the
component exposing a non-empty **`ccWidgetIcon`** - that property is the
entire contract for showing up there. The rest of the surface
(`ccWidgetPrimaryText`, `ccWidgetSecondaryText`, `ccWidgetIsActive`,
`onCcWidgetToggled`) is modelled on DMS's own `TailscaleWidget.qml`,
which is the closest built-in analogue since it's also a service toggle.

The widget re-polls `vayori-tor status` every 5s rather than trusting its
own last click, so starting or stopping Tor from a terminal doesn't leave
the toggle lying.

### Hardening

`hardening.enable` sets the usual suspects - no ICMP redirects, no source
routing, SYN cookies - plus BBR congestion control with an `fq` qdisc,
which is a straight throughput win on anything with real latency.

`rp_filter` is **2 (loose), not 1 (strict)**, on purpose: strict reverse
path filtering drops the asymmetric routing that container bridges and
VPN split-tunnels depend on, and the failure mode is confusing traffic
loss rather than an obvious error.

### Verified

The ruleset was applied for real in an unprivileged user+network
namespace, not just eyeballed: it applies cleanly (nat 4→20 rules, filter
3→23, v6 3→7), tears back down to the exact baseline with zero leftover
`VAYORI_*` chains, is idempotent when torn down twice, and survives
repeated up/down cycles. Rule *order* was checked too - exemptions first,
catch-all `REJECT` last - since that ordering is the entire difference
between blocking leaks and blocking your own network.

Not verified: whether real container traffic routes as intended, which
needs a live container and a running Tor, and the actual latency of
browsing through it.

---

[← GrubTheme.nix](system-grubtheme.md) · [Index](CONFIGURATION.md) · [AndroidStudio.nix →](apps-dev-androidstudio.md)
