# Guía de Configuración: Consola Gaming Bazzite para el Living (Steam Deck Style)

Esta guía explica cómo funciona la máquina virtual Bazzite (VM ID 100) en Proxmox VE con PCIe Passthrough dedicado de la tarjeta gráfica **NVIDIA GeForce GTX 1060 6GB**, transformando tu computadora en una consola para conectar directamente a la TV del living.

---

## 1. Concepto y Arquitectura

Bazzite es una distribución inmutable optimizada para gaming basada en Fedora Silverblue, que integra la interfaz **Steam GamepadUI** (la misma interfaz gráfica y experiencia de usuario que la Steam Deck).

Al asignar la tarjeta gráfica NVIDIA GTX 1060 directamente a la máquina virtual mediante **PCIe Passthrough**:
1. **Salida de Video Directa**: Los puertos físicos HDMI y DisplayPort de la GTX 1060 son controlados exclusivamente por Bazzite. Al conectar un cable HDMI de la PC al televisor del living, se ve directamente la pantalla de inicio de Bazzite / Steam en la TV.
2. **Audio por HDMI**: El controlador de sonido de la GTX 1060 (`10de:10f0`) también es transferido a la VM, permitiendo que el sonido de los juegos salga directamente por los altavoces de la TV o receptor de audio.
3. **Aceleración Gráfica Completa**: Los controladores propietarios NVIDIA de la serie 550+ están integrados en la imagen Bazzite, permitiendo rendimiento 3D nativo a 1080p 60fps sin sobrecarga de emulación.
4. **Modo Consola**: Arranca automáticamente en modo pantalla completa para joysticks (Xbox, DualShock/DualSense, mandos genéricos Bluetooth o USB).

---

## 2. Configuración de Hardware en Proxmox VE

- **Tarjeta Gráfica**: NVIDIA GeForce GTX 1060 6GB (`10de:1b83`)
- **Controlador de Audio HDMI**: High Definition Audio Controller (`10de:10f0`)
- **Grupo IOMMU**: Grupo 15 aislado (sin dispositivos conflictivos).
- **Parámetros QEMU**:
  - `hostpci0: 0000:26:00,pcie=1,x-vga=1`
  - `machine: q35`
  - `bios: ovmf` (UEFI con SecureBoot deshabilitado para controladores de terceros)
  - `cpu: host,hidden=1` (evita bloqueos del controlador NVIDIA al ocultar la presencia del hipervisor).
  - `memory: 8192 MB`
  - `cores: 6` vCPUs dedicadas.

---

## 3. Conexión de Periféricos en el Living

1. **Pantalla**: Conectar un cable HDMI o DisplayPort desde la placa de video GTX 1060 hasta el televisor del living.
2. **Mandos / Controles**:
   - **Receptor USB (Xbox Wireless Adapter o dongle 2.4GHz)**: Se puede agregar a la VM mediante passthrough USB (`qm set 100 -usb0 host=<vendor:product>`).
   - **Bluetooth**: Si la placa madre tiene Bluetooth, se puede pasar el dongle o adaptador USB Bluetooth a la VM para emparejar mandos inalámbricos desde el menú de configuración de Steam.
3. **Red**: Conectar el cable Ethernet al switch/router. La VM obtendrá la IP `192.168.1.11` a través del bridge `vmbr0`.

---

## 4. Primer Inicio e Instalación

1. El instalador de Bazzite iniciará automáticamente en la pantalla de la TV una vez encendida la VM (`qm start 100`).
2. Seguir el asistente de instalación en disco (se ha asignado un disco virtual de 64GB SSD en `hdd-storage`).
3. Al finalizar, reiniciar la máquina: iniciará directamente en el asistente inicial de Steam Deck ("Bienvenido a Steam").
4. Iniciar sesión con tu cuenta de Steam, ¡y listo para jugar en la TV del living!
