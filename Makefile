IMAGE_TAG=test
CONTAINER_NAME=keyvalue

all: stop build start

stop:
	docker stop ${CONTAINER_NAME} || true

build:
	docker build -t ${IMAGE_TAG} . 

start:
	docker run -d --name ${CONTAINER_NAME} -p 8080:8080 ${IMAGE_TAG} -v ./init.lua:/opt/tarantool/init.lua || docker start ${CONTAINER_NAME}

dele : 
	docker 