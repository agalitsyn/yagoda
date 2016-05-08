#!/usr/bin/env make -f

.PHONY: start stop restart

start:
	if [ -d image ]; then \
		$(MAKE) -C image build ; \
		$(MAKE) -C image push ; \
	fi
	kubectl create -f k8s/

stop:
	kubectl delete -f k8s/

restart: stop start

