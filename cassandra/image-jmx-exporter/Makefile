include vars.mk
include ../../Makefile.docker

build:
	if [ ! -f rootfs/opt/prometheus/jmx_prometheus_httpserver.jar ]; then \
		docker run -v $(shell pwd)/rootfs/opt/prometheus/:/build:rw maven \
			bash -c 'git clone https://github.com/prometheus/jmx_exporter.git \
				&& cd jmx_exporter \
				&& mvn package \
				&& cp jmx_prometheus_httpserver/target/jmx_prometheus_httpserver-*-jar-with-dependencies.jar /build/jmx_prometheus_httpserver.jar' ; \
	fi
	docker build --pull --rm -t $(IMAGE) .
