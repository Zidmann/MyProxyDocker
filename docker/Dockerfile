FROM centos:7

MAINTAINER Zidmann <emmanuel.zidel@gmail.com>
LABEL Description="Squid proxy in a docker container" Vendor="Emmanuel Zidel-Cauffet" Version="0.1"

ENV SQUID_VERSION=3.5.20 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=squid

RUN yum update -y \
 && yum install which -y \
 && yum install squid-7:${SQUID_VERSION}-* -y

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 3128/tcp

HEALTHCHECK --start-period=60s --timeout=3s CMD curl http://localhost:3128 1>/dev/null 2>/dev/null; || exit 1

ENTRYPOINT ["/sbin/entrypoint.sh"]

