# tailscale-nordvpn-adguard

[English](README.md) | [日本語](README.ja.md)

Create a dockerized Tailscale exit node with NordVPN's exit nodes and AdGuard Home integration.

This project will create three docker containers: Tailscale, NordVPN, and AdGuard Home. The Tailscale instance will advertise as an exit node, use the NordVPN container as an egress route, and forward DNS queries to AdGuard Home for ad-blocking and privacy.

## Requirements
* A docker host, and docker build tools.
* NordVPN account.

## Features
* Support for using an alternate login-server.
* Connect to any NordVPN region.
* Run `AdGuard Home` in this stack and forward DNS from the Tailscale exit node to it

## Usage
1. Copy the `.env.example` to `.env`.
2. Customize your .env file with the desired settings:
    * `NORDVPN_TOKEN`: Your NordVPN login token.
    * `TAILSCALE_UP_LOGIN_SERVER`: Your custom Tailscale login server.
    * `NORDVPN_ENDPOINT`: a NordVPN location (the same argument as `nordvpn connect ...`)
    * `NORDVPN_TECHNOLOGY`: `OPENVPN` or `NORDLYNX`
    * `NORDVPN_OPENVPN_PROTOCOL`: `TCP` or `UDP`
    * `IP_ADGUARD`: IPv4 address for the AdGuard container (e.g. `10.1.1.4`); the exit node will forward DNS queries here
3. Run `docker compose up -d`. You will have to watch the logs of the tailscale container for next steps. If you need to get a shell into the container, run:
     `docker compose exec -it tailscale /bin/sh`

### AdGuard integration
1. After the stack is running, visit `http://<docker-host-ip>:3000` to finish the AdGuard Home setup. (The config/workdir is stored under `./adguard/`.)
2. In AdGuard, set upstream DNS servers to stable IPv4 resolvers (for example `1.1.1.1`, `8.8.8.8`) and consider lowering upstream timeouts from the default 20s if you see timeouts when combined with NordVPN.
3. In the Tailscale admin dashboard, under **DNS**:
   - Set a **Global nameserver** to the host’s Tailscale IP (for example `100.84.35.43` for `hide-deployment2`), not the Docker-internal `IP_ADGUARD` like `10.1.1.4`.
   - Leave “Restrict to domain” empty to apply globally.
   - Keep “Use with exit node” enabled so this nameserver is used even when clients route via the exit node.
   With this setup, Tailscale DNS (100.100.100.100) will forward non-MagicDNS queries to AdGuard, while MagicDNS lookups are still handled by Tailscale.
4. Alternatively, you can disable Tailscale DNS on clients and let the exit node’s iptables rules (`tailscale_up.sh`) DNAT plain UDP/TCP 53 traffic to `IP_ADGUARD`. Note that when Tailscale DNS is enabled, those iptables rules do not see the DNS traffic.
5. You can still reach the NordVPN exit node normally; only DNS is filtered through AdGuard while the rest of the traffic runs through NordVPN.

### Removing host-installed AdGuard
If you previously installed AdGuard Home on the host, stop and disable it so the container can own the ports:
```sh
sudo systemctl stop AdGuardHome
sudo systemctl disable AdGuardHome
```
If you used another installation method, stop the service in the same way before you `docker compose up`.

## Troubleshooting

### Cannot Access Local Network

**Symptom**: When using an exit node, you cannot access devices on your local network (e.g., 192.168.0.x)

**Cause**: When using an exit node, all traffic (including local network traffic) goes through the VPN by default

**Solution**:

**Windows/Mac/Linux (GUI)**:
1. Open the Tailscale app
2. In the exit node settings, enable **"Allow LAN access"**

**Linux/CLI**:
```bash
tailscale set --exit-node-allow-lan-access=true
```

**Or configure via Tailscale Admin Console**:
1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
2. Select the device using the exit node
3. Enable "Allow LAN access when using an exit node" in settings

This setting allows local network traffic to bypass the VPN and route directly to your LAN.
