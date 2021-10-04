filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))
image_repo      :=      0labs/prysm

build:
	docker build --tag $(image_repo):build-$(version) --build-arg prysm_version=$(version) .

test:
	docker build --target test --build-arg prysm_version=$(version) --tag prysm:test . && docker run --env-file test/test.env prysm:test

test-compose-beacon:
	cd compose && docker-compose config && docker-compose up -d beacon-node && \
	sleep 5 && docker-compose logs 2>&1 | grep "Running on Pyrmont Testnet" && \
	docker-compose logs 2>&1 | grep "Starting initial chain sync" && \
	docker-compose logs 2>&1 | grep "Connected to eth1 proof-of-work chain" && \
	docker-compose down

test-compose-validator:
	cd compose && docker-compose config && docker-compose up -d  validator && \
	sleep 5 && docker-compose logs 2>&1 | grep "Running on Pyrmont Testnet" && \
	docker-compose logs 2>&1 | grep "Starting validator node" && \
	docker-compose logs 2>&1 | grep "Starting Prysm web UI on address" && \
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
