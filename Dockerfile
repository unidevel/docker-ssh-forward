FROM alpine:3.16

ARG USERNAME=ssh

RUN apk --no-cache --update add openssh-server openssh-client && rm  -rf /tmp/* /var/cache/apk/*

ENV SSH_PORT="2222" \
    SSH_USER=${USERNAME}

EXPOSE 2222

ADD entry.sh /usr/local/bin
ADD motd /etc/motd
RUN chmod 0755 /usr/local/bin/entry.sh
ENTRYPOINT ["entry.sh"]

VOLUME /data
