# tailscale-nordvpn
Create a dockerized Tailscale exit node with NordVPN's exit nodes.

This project will create two docker containers. One for Tailscale, and another for NordVPN. The Tailscale instance will advertise as an exit node, and use the NordVPN container as an egress route.

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
2. In the Tailscale admin dashboard go to **DNS** and add the exit node's Tailscale IP as a DNS server, or configure each device to use that IP. The exit node will forward DNS queries over to the AdGuard container (`IP_ADGUARD`), and AdGuard will answer them with your chosen blocklists.
3. You can still reach the NordVPN exit node normally; only DNS is filtered through AdGuard while the rest of the traffic runs through NordVPN.

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
