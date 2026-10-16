# Plan de Direccionamiento IP y Asignación de Servicios

Este documento detalla la asignación de direcciones IP para la infraestructura Proxmox VE, servicios y máquinas virtuales en la red local doméstica (`192.168.1.0/24`).

## Resumen de Direcciones IP

| Dirección IP | Servicio / Máquina Virtual | VM ID | Hostname / Descripción | Tipo de Adaptador | Dirección MAC | Estado |
|---|---|---|---|---|---|---|
| **192.168.1.1** | Router Gateway / DNS | - | Gateway LAN | - | 80:AE:3C:D7:19:A0 | Activo |
| **192.168.1.10** | **Proxmox VE 9 Host** | - | `debian` (pve-manager) | Bridge `vmbr0` (`enp37s0`) | 70:85:C2:B5:88:08 | **Configurado (Estática)** |
| **192.168.1.10** | **Portainer CE** | - | Portainer (Docker Container) | Puertos `9443` (HTTPS) / `9000` (HTTP) | Compartida con host | **Activo** |
| **192.168.1.11** | **Bazzite Gaming Console** | 100 | `Bazzite-LivingRoom` | VirtIO (`vmbr0`) | `BC:24:11:2C:67:67` | **Creada con Passthrough GTX 1060** |
| **192.168.1.12** | **W7 Emu hasta V20** | 101 | Windows 7 Emuladores V20 | Intel e1000 (`vmbr0`) | `00:50:56:2E:8A:0A` | **Migrando de VMware** |
| **192.168.1.13** | **Win10 iFix 6.5 Ruston** | 102 | Windows 10 Planta COC | Intel e1000e (`vmbr0`) | `00:50:56:35:FF:87` | **Migrando de VMware** |
| **192.168.1.14** | **Win10 Studio GasAndes** | 103 | Windows 10 Studio V34 + CCW23 | Intel e1000e (`vmbr0`) | `00:50:56:2B:40:FD` | **Migrando de VMware** |

---

## Servicios Web y Puertos

- **Proxmox VE Web GUI**: `https://192.168.1.10:8006/`
- **Portainer CE Web GUI**: `https://192.168.1.10:9443/`
- **Portainer HTTP GUI**: `http://192.168.1.10:9000/`
- **SSH Proxmox VE**: `192.168.1.10:22`

## Preservación de MACs en Migración de VMware

Para evitar la pérdida de perfiles de red, adaptadores duplicados ("Conexión de área local 2") o invalidación de licencias de software industrial (Rockwell Software, Studio 5000, GE iFix 6.5), cada VM en Proxmox fue configurada con la **misma dirección MAC original** que tenía en VMware Workstation.
