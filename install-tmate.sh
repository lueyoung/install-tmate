#!/bin/bash

info() {
    echo $(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - "$*"
}

error() {
    echo $(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - "$*"
}

fail() {
    error "$@"
    exit 1
}

SRC=/tmp/tmate.tar.gz
DIR=tmate-2.2.1-static-linux-amd64
URL=https://github.com/tmate-io/tmate/releases/download/2.2.1/${DIR}.tar.gz

if [[ -x $(command -v wget) ]]; then
  wget -c -O $SRC $URL 
elif [[ -x $(command -v curl) ]]; then
  curl $URL -o $SRC --progress
else
  fail cannot download $URL
fi

tar -zxvf $SRC -C /tmp
chmod +x /tmp/${DIR}/tmate
mv /tmp/${DIR}/tmate /usr/local/bin
info installed tmate

BIN=/usr/local/bin/tmate.sh
#BIN=/tmp/tmate.sh
cat > $BIN <<"EOF"
#!/bin/bash
if [[ -f /var/env/env.conf ]]; then
  . /var/env/env.conf
fi
SSH=$(/usr/local/bin/tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')
WEB=$(/usr/local/bin/tmate -S /tmp/tmate.sock display -p '#{tmate_web}')
if [[ -z $SSH ]]; then
  /usr/bin/killall tmate
fi
while [[ -z ${SSH} ]]; do
  /usr/local/bin/tmate -S /tmp/tmate.sock new-session -d
  SSH=$(/usr/local/bin/tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')
  sleep 1
done

SSH=$(/usr/local/bin/tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')
WEB=$(/usr/local/bin/tmate -S /tmp/tmate.sock display -p '#{tmate_web}')
MSG="text=${HOSTNAME}@${NODE_IP}&desp=ssh:${SSH},web:${WEB}"
#MSG=$(echo ${MSG} | tr ' ' '_')
echo $MSG
# usr 1
SCKEY1=SCU31080T5747dd558f09b5ecab28adf0b081d80b5b7cdf2331e11
URL1=https://sc.ftqq.com/${SCKEY1}.send
CMD="curl -d \"${MSG}\" ${URL1}"
echo "Running: ${CMD}"
eval ${CMD}
# usr 2
SCKEY2=SCU31117T4ea33e3f348ef4cb6ca4fd88c7ef7e805b7e0839105ab
URL2=https://sc.ftqq.com/${SCKEY2}.send
CMD="curl -d \"${MSG}\" ${URL2}"
echo "Running: ${CMD}"
eval ${CMD}
EOF
chmod +x ${BIN}
info ${BIN} made 

CRON=/etc/crontab
#CRON=/tmp/crontab
MIN=37
cat >> $CRON <<EOF
$MIN */1 * * * root $BIN 
EOF
info ${CRON} made 

UNIT=/etc/systemd/system/tmate.service
#UNIT=/tmp/tmate.service
cat > $UNIT <<EOF
[Unit]
Description=tmate: Instant terminal sharing
Documentation=https://tmate.io/#source

[Service]
Type=oneshot
ExecStart=${BIN}

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable tmate.service
systemctl restart tmate.service
info ${UNIT} made 
