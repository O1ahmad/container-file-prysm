filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))
image_repo      :=      0labs/prysm

build:
	docker build --tag $(image_repo):build-$(version) --build-arg prysm_version=$(version) .

test:
	docker build --target test --build-arg prysm_version=$(version) --tag prysm:test . && docker run --env-file test/test.env prysm:test

test-compose-beacon:
	echo "image=${image_repo}:${version}" > compose/.env-test
	cd compose && docker-compose --env-file .env-test config && docker-compose --env-file .env-test up -d beacon-node && \
	sleep 60 && docker-compose logs 2>&1 | grep "Running on Prater Testnet" && \
	docker-compose logs 2>&1 | grep "Starting initial chain sync" && \
	docker-compose logs 2>&1 | grep "Connected to eth1 proof-of-work chain" && \
	docker-compose down && rm .env-test

test-compose-validator:
	echo "image=${image_repo}:${version}" > compose/.env-test
	cd compose && docker-compose --env-file .env-test config && docker-compose --env-file .env-test up -d  validator && \
	sleep 30 && docker-compose logs 2>&1 | grep "Running on Prater Testnet" && \
	docker-compose logs 2>&1 | grep "Starting validator node" && \
	docker-compose logs 2>&1 | grep "Starting Prysm web UI on address" && \
	docker-compose down && rm .env-test

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
