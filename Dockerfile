FROM ubuntu:18.04
MAINTAINER djjproject <djj9404@gmail.com>

# ports
EXPOSE 18080 18443 1803 80 8883 443 53

# locales
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# copy files
COPY . /app

# run install script
RUN bash /app/install.sh

# run script
CMD ["/bin/bash", "/app/init.sh"] 
