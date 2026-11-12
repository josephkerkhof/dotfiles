#!/bin/sh
# Adapted from DomiStyle/docker-idrac6's startapp.sh (MIT).
# Copyright (c) 2018 Dominik; see UPSTREAM-LICENSE.
# Quote credentials, bound downloads, and never retain incomplete JARs.
set -eu
IDRAC_HOST=$(cat /run/secrets/idrac_host)
IDRAC_PORT=$(cat /run/secrets/idrac_port)
IDRAC_USER=$(cat /run/secrets/idrac_user)
IDRAC_PASSWORD=$(cat /run/secrets/idrac_password)
cd /app
mkdir -p lib
for jar in avctKVM.jar avctKVMIOLinux64.jar avctVMLinux64.jar; do
    destination=$jar
    [ "$jar" = avctKVM.jar ] || destination=lib/$jar
    echo "Downloading $jar from iDRAC"
    wget --no-verbose --timeout=20 --tries=2 --no-check-certificate \
        -O "$destination.part" "https://$IDRAC_HOST:$IDRAC_PORT/software/$jar" || {
        echo "Could not download $jar; check iDRAC address, HTTPS reachability, and container logs." >&2
        exit 1
    }
    mv "$destination.part" "$destination"
done
cd lib
jar -xf avctKVMIOLinux64.jar
jar -xf avctVMLinux64.jar
cd /app
echo "Starting Dell Java viewer"
exec java -cp avctKVM.jar -Djava.library.path=./lib com.avocent.idrac.kvm.Main \
    "ip=$IDRAC_HOST" kmport=5900 vport=5900 "user=$IDRAC_USER" "passwd=$IDRAC_PASSWORD" \
    apcp=1 version=2 vmprivilege=true "helpurl=https://$IDRAC_HOST:$IDRAC_PORT/help/contents.html"
