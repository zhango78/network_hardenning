# Assumptions — TP6 Network Infrastructure

## General architecture

- The infrastructure uses a classic **three-zone model**: LAN (client-side), a Transit/interconnect segment between the two firewalls, and a DMZ hosting exposed services.
- `gw-fwA` acts as the **LAN-facing firewall**, sitting on `10.10.10.0/24` (LAN) and `10.10.99.0/24` (transit).
- `gw-fwB` acts as the **DMZ-facing firewall**, sitting on `10.10.99.0/24` (transit) and `10.10.20.0/24` (DMZ).
- Traffic from clients must traverse **both firewalls** before reaching `srv-web`, enforcing a double-firewall architecture.
- The two firewalls communicate exclusively through the transit segment `10.10.99.0/24`, which is not directly accessible from either the LAN or the DMZ.

---

## IP addressing

- The subnet masks are assumed to be `/24` for all three segments unless otherwise specified.
- `gw-fwB` uses `10.10.20.254` as its DMZ-side IP, which is conventionally the last usable address — this is assumed to be the default gateway for all DMZ hosts.
- No IPv6 addressing is assumed for this lab environment.
- There is no NAT assumed between LAN and DMZ unless explicitly configured in a later TD.

---

## Hosts and services

- `srv-web` (`10.10.20.20`) is the only service host in the DMZ and is assumed to run an HTTP/HTTPS web server (e.g., Apache or Nginx).
- SSH on port 22 is currently open for administrative access — this is a temporary setup expected to be restricted in TD5.
- HTTPS (port 443) is not yet functional on `srv-web`; the service is planned but not configured. Flows referencing it should be marked `REVIEW`.
- `sensor-ids` (`10.10.20.50`) is a passive monitoring host. It does not initiate connections and is assumed to operate in **promiscuous/mirror mode**, observing DMZ traffic without being a traffic target itself.

---

## Firewall policy

- The **default policy is DENY ALL** (F10 — `any → any`). All allowed flows must be explicitly whitelisted.
- Stateful inspection is assumed on both firewalls — return traffic for established connections is implicitly allowed.
- ICMP is currently allowed for diagnostic purposes but is expected to be **rate-limited in TD2** to prevent ICMP-based DoS or reconnaissance.
- No application-layer (L7) filtering is assumed at this stage.

---

## Routing

- Static routing is assumed between the two firewalls via the `10.10.99.0/24` transit segment.
- `gw-fwA` is the default gateway for LAN clients (`10.10.10.0/24`).
- `gw-fwB` is the default gateway for DMZ hosts (`10.10.20.0/24`).
- No dynamic routing protocol (OSPF, BGP, etc.) is assumed unless introduced in a later TD.

---

## Security assumptions

- The LAN (`10.10.10.0/24`) is considered a **trusted zone**; clients are assumed to be legitimate users or administrators.
- The DMZ (`10.10.20.0/24`) is a **semi-trusted zone** — hosts are exposed to incoming traffic but should not be able to initiate connections back into the LAN.
- Direct LAN-to-DMZ traffic **does not bypass** the firewall chain; all flows must pass through `gw-fwA` then `gw-fwB`.
- No VPN or encrypted tunnel is assumed between zones at this stage.
- Host-based firewalls on `srv-web` or `sensor-ids` are **not** assumed to be configured unless specified.

---

## Lab-specific assumptions

- The "client" in the reachability matrix represents any host on the LAN subnet, not a specific machine.
- Flow IDs (F01, F04, etc.) are non-contiguous by design — gaps (F02, F03, F07–F09) are reserved for flows introduced in other TDs.
- All TDs are assumed to build incrementally on the same base infrastructure — changes in one TD persist into subsequent ones unless explicitly reverted.
- The network diagram reflects the **logical topology**; physical cabling or hypervisor configuration is out of scope.
