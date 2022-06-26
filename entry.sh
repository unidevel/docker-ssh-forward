#!/bin/sh
if [ ! -d "/data/ssh" ]; then
  echo "copy the orignal ssh config to /data/ssh"
  mv /etc/ssh /data/ssh
else
  echo "remove the original ssh config"
  rm -rf /etc/ssh
fi
echo "link /data/ssh to /etc/ssh"
ln -sf /data/ssh /etc/ssh


if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
  echo "generating fresh rsa key"
  ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi

if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
  echo "generating fresh dsa key"
  ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

if [ -f "/config/sshd_config" ]; then
  echo "overriding /etc/ssh/sshd_config with /config/sshd_config"
  cat /config/sshd_config > /etc/ssh/sshd_config
else
  echo "enable port forward"
  sed -i '/^AllowAgentForwarding/c\AllowAgentForwarding yes' /etc/ssh/sshd_config
  sed -i '/^#AllowAgentForwarding/c\AllowAgentForwarding yes' /etc/ssh/sshd_config
  sed -i '/^AllowTcpForwarding/c\AllowTcpForwarding yes' /etc/ssh/sshd_config
  sed -i '/^#AllowTcpForwarding/c\AllowTcpForwarding yes' /etc/ssh/sshd_config
  sed -i '/^GatewayPorts/c\GatewayPorts yes' /etc/ssh/sshd_config
  sed -i '/^#GatewayPorts/c\GatewayPorts yes' /etc/ssh/sshd_config
  sed -i '/^X11Forwarding/c\X11Forwarding yes' /etc/ssh/sshd_config
  sed -i '/^#X11Forwarding/c\X11Forwarding yes' /etc/ssh/sshd_config
  sed -i '/^PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
  sed -i '/^#PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config

  echo "disable password login"
  sed -i '/^PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config

  if [ ! -z "$SSH_PORT" ]; then
    echo "set port to ${SSH_PORT}"
    sed -i "/^Port /c\Port ${SSH_PORT}" /etc/ssh/sshd_config
    sed -i "/^#Port/c\Port ${SSH_PORT}" /etc/ssh/sshd_config
  fi
fi

if [ -z "$SSH_USER" -o "$SSH_USER" = "root" ]; then
  echo "SSH_USER must set to non-root user"
  exit 1
fi

echo "SSH_USER is ${SSH_USER}"
if [ "${SSH_USER}" != "root" ]; then
  echo "adding new user ${SSH_USER}"
  addgroup ${SSH_USER}
  adduser ${SSH_USER} -D -G ${SSH_USER} --shell=/bin/false
  passwd -u ${SSH_USER}
  mkdir -p /home/${SSH_USER}/.ssh
  touch /home/${SSH_USER}/.ssh/authorized_keys
  chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh
  chmod 600 /home/${SSH_USER}/.ssh/authorized_keys
  ssh-keygen -b 2048 -t rsa -q -N "" -f /home/${SSH_USER}/.ssh/mykey
  echo "generating ssh key for ${SSH_USER}"
  cat /home/${SSH_USER}/.ssh/mykey.pub > /home/${SSH_USER}/.ssh/authorized_keys
  mkdir -p ${HOME}/.ssh
  cat /home/${SSH_USER}/.ssh/mykey > ${HOME}/.ssh/id_rsa
  chmod 0600 ${HOME}/.ssh/id_rsa
  chmod 600 ${HOME}/.ssh/authorized_keys
fi

if [ ! -z "$SSH_PUBLIC_KEY" ]; then
  echo "overriding authorized_keys with env SSH_PUBLIC_KEY"
  echo "$SSH_PUBLIC_KEY" > /home/${SSH_USER}/.ssh/authorized_keys
fi

if [ -f "/config/authorized_keys" ]; then
  echo "overriding authorized_keys with file /config/authorized_keys"
  cat /config/authorized_keys >> /home/${SSH_USER}/.ssh/authorized_keys
fi

if [ ! -d "/var/run/sshd" ]; then
  echo "preparing sshd run dir"
  mkdir -p /var/run/sshd
fi

echo "[[[[[[[[[[[[[[[[[[[[ /etc/ssh/sshd_config ]]]]]]]]]]]]]]]]]]]]"
cat /etc/ssh/sshd_config
echo "==============================================================="

USER=`whoami`
echo "Current user is $USER, HOME is $HOME"

if [ ! -z "${SSH_ARGS}" ]; then
  echo "starting sshd and ssh"
  /usr/sbin/sshd -e
  echo "ssh -o 'StrictHostKeyChecking no' ${SSH_USER}@localhost -N -v ${SSH_ARGS}"
  ssh -o 'StrictHostKeyChecking no' -p ${SSH_PORT} ${SSH_USER}@localhost -N -v ${SSH_ARGS}
else
  echo "starting sshd"
  /usr/sbin/sshd -D -e
fi
