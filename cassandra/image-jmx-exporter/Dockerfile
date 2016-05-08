FROM java:alpine

ENV TERM=xterm

ADD rootfs/ /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/opt/prometheus/config.yml"]
