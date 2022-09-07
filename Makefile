all: build run
build:
	docker build -t infracost-test .
run:
	docker run --rm -it --name infracost-test infracost-test bash
