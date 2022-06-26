FROM alpine:3.16

ARG USERNAME=ssh

RUN apk --no-cache --update add openssh-server && addgroup ${USERNAME} && adduser ${USERNAME} -D -G ${USERNAME} --shell=/bin/false && passwd -u ${USERNAME} && \
    mkdir -p /home/${USERNAME}/.ssh && touch /home/${USERNAME}/.ssh/authorized_keys && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh && chmod 600 /home/${USERNAME}/.ssh/authorized_keys && \
    rm  -rf /tmp/* /var/cache/apk/*

ENV SSH_PORT="2222" \
    SSH_USER=${USERNAME}

EXPOSE 2222

ADD entry.sh /usr/local/bin
ADD motd /etc/motd
RUN chmod 0755 /usr/local/bin/entry.sh
ENTRYPOINT ["entry.sh"]

CMD ["/usr/sbin/sshd", "-D", "-e"]

VOLUME /data
