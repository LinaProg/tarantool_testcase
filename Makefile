IMAGE_TAG=test
CONTAINER_NAME=keyvalue

all: stop start

stop:
	docker stop ${CONTAINER_NAME} || true

build:
	docker build -t ${IMAGE_TAG} . 

start:
	docker run -d --name ${CONTAINER_NAME} -p 8080:8080 ${IMAGE_TAG} || docker start ${CONTAINER_NAME}

rmbuild: 
	docker rm ${CONTAINER_NAME} || true

rebuild: stop rmbuild build start
	