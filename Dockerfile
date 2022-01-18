FROM alpine:latest

ARG BUILD_DATE

# first, a bit about this container
LABEL build_info="cturra/docker-ntp build-date:- ${BUILD_DATE}"
LABEL maintainer="Chris Turra <cturra@gmail.com>"
LABEL documentation="https://github.com/cturra/docker-ntp"

# install chrony
RUN echo 'http://mirrors.ustc.edu.cn/alpine/v3.15/main' > /etc/apk/repositories
&& echo 'http://mirrors.ustc.edu.cn/alpine/v3.15/community' >>/etc/apk/repositories
&& apk update && apk add --no-cache chrony tzdata
&& ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
&& echo "Asia/Shanghai" > /etc/timezone

# script to configure/startup chrony (ntp)
COPY assets/startup.sh /opt/startup.sh

# ntp port
EXPOSE 123/udp

# let docker know how to test container health
HEALTHCHECK CMD chronyc tracking || exit 1

# start chronyd in the foreground
ENTRYPOINT [ "/bin/sh", "/opt/startup.sh" ]
