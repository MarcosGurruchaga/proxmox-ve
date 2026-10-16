#!/bin/bash
set -e

echo "[$(date)] Monitoring VM 101 migration..." >> /root/migration_master.log
while pgrep -f "migrate_vms.py 101" > /dev/null; do
    sleep 10
done
echo "[$(date)] VM 101 finished! Starting VM 102 (Win10-iFix-Ruston)..." >> /root/migration_master.log

python3 /root/migrate_vms.py 102 >> /root/migration_master.log 2>&1
echo "[$(date)] VM 102 finished! Starting VM 103 (Win10-Studio-GasAndes)..." >> /root/migration_master.log

python3 /root/migrate_vms.py 103 >> /root/migration_master.log 2>&1
echo "[$(date)] ALL VM MIGRATIONS FINISHED SUCCESSFULLY!" >> /root/migration_master.log
