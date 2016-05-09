include vars.mk

build:
	docker run -v $(shell pwd)/rootfs/opt/prometheus/:/build:rw maven \
		bash -c 'git clone https://github.com/prometheus/jmx_exporter.git \
			&& cd jmx_exporter \
			&& mvn package \
			&& cp jmx_prometheus_httpserver/target/jmx_prometheus_httpserver-*-jar-with-dependencies.jar /build/jmx_prometheus_httpserver.jar'
	docker build --pull --rm -t $(IMAGE) .

clean:
	docker rmi -f $$(docker images -q $(IMAGE))

push:
	docker tag $(IMAGE) $(REGISTRY)/$(IMAGE)
	docker push $(REGISTRY)/$(IMAGE)
