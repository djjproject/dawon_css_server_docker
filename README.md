# Docker Container for CSS PowerMangerServer
architecture : arm/v7, arm64, amd64  
dockerhub : https://hub.docker.com/r/djjproject/dawon_css_server  
container git : https://github.com/djjproject/dawon_css_server_docker  
original server source : https://github.com/SeongSikChae/PowerManagerServerV2  
original certificate create source : https://github.com/SeongSikChae/Certificate

# Install Guide
detailed : https://blog.djjproject.com/807
### docker macvlan network create
```
# physical network : enp2s0
# enp2s0 network : 192.168.0.0/24
# enp2s0 gateway : 192.168.0.1
docker network create -d macvlan \
	--subnet=192.168.0.0/24 \
	--gateway=192.168.0.1 \
	-o parent=enp2s0 \
	macvlan
```
### pull and container run
```
# macvlan ip : 192.168.0.200
mkdir -p /opt/powermanager
docker run -dit --name powermanager \
	--restart unless-stopped \
	--network macvlan \
	--ip=192.168.0.200 \
	-v /opt/powermanager:/app/data \
	djjproject/dawon_css_server:latest
```
### configure container
```
docker exec -it powermanager /app/config.sh
```


