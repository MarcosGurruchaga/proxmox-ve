#!/usr/bin/env python3
import os
import sys
import subprocess
import urllib.request
import urllib.parse
from html.parser import HTMLParser

class IndexParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            for k, v in attrs:
                if k == 'href':
                    self.links.append(v)

def download_file(url, target_path):
    print(f"Downloading {url} -> {target_path}...", flush=True)
    d = os.path.dirname(target_path)
    fn = os.path.basename(target_path)
    
    # Try accelerated multi-stream aria2c first
    try:
        ret = subprocess.run(["aria2c", "-s", "8", "-x", "8", "-k", "1M", "-c", "-d", d, "-o", fn, url])
        if ret.returncode == 0:
            print(f"Downloaded via aria2c: {target_path} ({os.path.getsize(target_path)} bytes)", flush=True)
            return
    except Exception as e:
        print(f"aria2c failed ({e}), falling back to urllib...", flush=True)

    req = urllib.request.Request(url, headers={'User-Agent': 'Proxmox-Migrator'})
    with urllib.request.urlopen(req) as resp, open(target_path, 'wb') as out:
        total = int(resp.headers.get('Content-Length', 0))
        done = 0
        while True:
            chunk = resp.read(1024 * 1024 * 4) # 4MB chunks
            if not chunk:
                break
            out.write(chunk)
            done += len(chunk)
            if total > 0 and done % (1024 * 1024 * 50) < len(chunk):
                pct = (done / total) * 100
                print(f"  {done // (1024*1024)}MB / {total // (1024*1024)}MB ({pct:.1f}%)", flush=True)
    print(f"Downloaded {target_path} ({os.path.getsize(target_path)} bytes)", flush=True)

def migrate_vm(vmid, name, base_url, vmdk_descriptor, os_type, cores, memory, mac, efi=False):
    # Using the high-speed Kingston SSD storage pool
    tmp_dir = f"/mnt/ssd-storage/tmp_vmdk/vm{vmid}"
    target_img_dir = f"/mnt/ssd-storage/proxmox-data/images/{vmid}"
    os.makedirs(tmp_dir, exist_ok=True)
    os.makedirs(target_img_dir, exist_ok=True)

    target_qcow2 = f"{target_img_dir}/vm-{vmid}-disk-0.qcow2"

    print(f"\n=======================================================", flush=True)
    print(f"Starting migration for VM {vmid}: {name} (Storage: ssd-storage)", flush=True)
    print(f"Target disk: {target_qcow2}", flush=True)
    print(f"=======================================================", flush=True)

    # 1. Fetch file list from directory index
    req = urllib.request.Request(base_url, headers={'User-Agent': 'Proxmox-Migrator'})
    with urllib.request.urlopen(req) as resp:
        html = resp.read().decode('utf-8')

    parser = IndexParser()
    parser.feed(html)

    # Download all .vmdk files
    vmdk_links = [l for l in parser.links if l.lower().endswith('.vmdk')]
    print(f"Found {len(vmdk_links)} VMDK files to download:", flush=True)
    for l in vmdk_links:
        filename = urllib.parse.unquote(os.path.basename(l))
        file_url = urllib.parse.urljoin(base_url, l)
        file_path = os.path.join(tmp_dir, filename)
        if not os.path.exists(file_path):
            download_file(file_url, file_path)
        else:
            print(f"File {file_path} already exists, skipping download.", flush=True)

    # 2. Convert VMDK to QCOW2 on high speed SSD
    desc_path = os.path.join(tmp_dir, vmdk_descriptor)
    print(f"\nConverting {desc_path} to {target_qcow2} on SSD...", flush=True)
    cmd = ["qemu-img", "convert", "-p", "-f", "vmdk", "-O", "qcow2", desc_path, target_qcow2]
    ret = subprocess.run(cmd)
    if ret.returncode != 0:
        print(f"Error during qemu-img convert! Exit code {ret.returncode}", flush=True)
        sys.exit(1)
    print(f"Conversion complete! Result size: {os.path.getsize(target_qcow2)} bytes", flush=True)

    # 3. Create or update Proxmox VM on ssd-storage
    print(f"\nCreating Proxmox VM {vmid} on ssd-storage...", flush=True)
    subprocess.run(["qm", "destroy", str(vmid), "--purge"], stderr=subprocess.DEVNULL)

    create_cmd = [
        "qm", "create", str(vmid),
        "--name", name,
        "--ostype", os_type,
        "--memory", str(memory),
        "--cores", str(cores),
        "--cpu", "host",
        "--sata0", f"ssd-storage:{vmid}/vm-{vmid}-disk-0.qcow2,discard=on,ssd=1",
        "--net0", f"e1000e={mac},bridge=vmbr0,firewall=0",
        "--boot", "order=sata0",
        "--onboot", "0"
    ]
    if efi:
        create_cmd.extend(["--bios", "ovmf", "--efidisk0", "ssd-storage:0,efitype=4m,pre-enrolled-keys=0"])

    ret = subprocess.run(create_cmd)
    if ret.returncode != 0:
        print(f"Error creating VM {vmid}!", flush=True)
        sys.exit(1)

    print(f"\nVM {vmid} created successfully on ssd-storage!", flush=True)
    subprocess.run(["qm", "config", str(vmid)])

    # 4. Cleanup temp VMDK files
    print(f"Cleaning up {tmp_dir}...", flush=True)
    for f in os.listdir(tmp_dir):
        os.remove(os.path.join(tmp_dir, f))
    os.rmdir(tmp_dir)
    print(f"Cleanup done for VM {vmid}!", flush=True)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: migrate_vms.py <vmid>")
        sys.exit(1)

    vmid = sys.argv[1]
    if vmid == "101":
        migrate_vm(
            vmid=101,
            name="W7-Emu-hasta-V20",
            base_url="http://192.168.1.44:8080/W7%20Emu%20hasta%20V20%20-%20Marcos/W7%20Emu%20hasta%20V20%20-%20Marcos/",
            vmdk_descriptor="W7 Emu hasta V20.vmdk",
            os_type="win7",
            cores=2,
            memory=2048,
            mac="00:50:56:2E:8A:0A",
            efi=False
        )
    elif vmid == "102":
        migrate_vm(
            vmid=102,
            name="Win10-iFix-Ruston",
            base_url="http://192.168.1.44:8080/Win10%20iFix%206.5%20(HMI%20Ruston)/",
            vmdk_descriptor="Win10.vmdk",
            os_type="win10",
            cores=8,
            memory=8192,
            mac="00:50:56:35:FF:87",
            efi=False
        )
    elif vmid == "103":
        migrate_vm(
            vmid=103,
            name="Win10-Studio-GasAndes",
            base_url="http://192.168.1.44:8080/Windows%2010%20Studio%20V34%20+%20CCW23%20GasAndes/",
            vmdk_descriptor="Windows 10 Studio V34 + CCW23 GasAndes.vmdk",
            os_type="win10",
            cores=8,
            memory=8192,
            mac="00:50:56:2B:40:FD",
            efi=True
        )
