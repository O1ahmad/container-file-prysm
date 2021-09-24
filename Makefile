filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))
image_repo      :=      0labs/prysm

build:
	docker build --tag $(image_repo):build-$(version) --build-arg prysm_version=$(version) .

test:
	docker build --target test --build-arg prysm_version=$(version) --tag prysm:test . && docker run --env-file test/test.env prysm:test

test-compose:
	cd compose && docker-compose config && docker-compose up -d && \
	sleep 5 && docker-compose logs 2>&1 | grep "Starting prysm on Rinkeby" && \
	docker-compose down

release:
	docker build --target release --tag $(image_repo):$(version) --build-arg prysm_version=$(version) .
	docker push $(image_repo):$(version)

latest:
	docker tag $(image_repo):$(version) $(image_repo):latest
	docker push $(image_repo):latest

tools:
	docker build --target tools --tag $(image_repo):$(version)-tools --build-arg prysm_version=$(version) .
	docker push ${image_repo}:$(version)-tools

.PHONY: test
