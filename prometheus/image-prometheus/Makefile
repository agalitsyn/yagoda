include vars.mk

build:
	docker build --pull --rm -t $(IMAGE) .

clean:
	docker rmi -f $$(docker images -q $(IMAGE))

push:
	docker tag $(IMAGE) $(REGISTRY)/$(IMAGE)
	docker push $(REGISTRY)/$(IMAGE)
