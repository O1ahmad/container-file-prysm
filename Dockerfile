ARG build_version="golang:1.16-buster"

# ******* Stage: builder ******* #
FROM ${build_version} as builder

ARG prysm_version=v1.4.4
ARG bazelisk_version=v1.10.1

RUN apt-get update && apt-get install -y cmake libtinfo5 libgmp-dev npm && npm install -g @bazel/bazelisk@${bazelisk_version} && bazel version

WORKDIR /tmp
RUN git clone --depth 1 --branch ${prysm_version} https://github.com/prysmaticlabs/prysm

RUN cd prysm && bazel build --config=release //beacon-chain:beacon-chain
RUN cd prysm && bazel build --config=release //validator:validator
RUN cd prysm && bazel build --config=release //slasher:slasher

# ******* Stage: base ******* #
FROM ubuntu:20.04 as base

RUN apt update && apt install --yes --no-install-recommends \
    ca-certificates \
    curl \
    pip \
    tini \
    # apt cleanup
	&& apt-get autoremove -y; \
	apt-get clean; \
	update-ca-certificates; \
	rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

WORKDIR /docker-entrypoint.d
COPY entrypoints /docker-entrypoint.d
COPY scripts/entrypoint.sh /usr/local/bin/prysm-entrypoint

COPY scripts/prysm-helper.py /usr/local/bin/prysm-helper
RUN chmod 775 /usr/local/bin/prysm-helper

RUN pip install click requests pyaml

COPY --from=builder /tmp/prysm/bazel-bin/cmd/beacon-chain/beacon-chain_/beacon-chain /usr/local/bin/
COPY --from=builder /tmp/prysm/bazel-bin/cmd/validator/validator_/validator /usr/local/bin/
COPY --from=builder /tmp/prysm/bazel-bin/cmd/slasher/slasher_/slasher /usr/local/bin/

ENTRYPOINT ["prysm-entrypoint"]

# ******* Stage: testing ******* #
FROM base as test

ARG goss_version=v0.3.16

RUN curl -fsSL https://goss.rocks/install | GOSS_VER=${goss_version} GOSS_DST=/usr/local/bin sh

WORKDIR /test

COPY test /test

CMD ["goss", "--gossfile", "/test/goss.yaml", "validate"]

# ******* Stage: release ******* #
FROM base as release

ARG version=0.1.0

LABEL 01labs.image.authors="zer0ne.io.x@gmail.com" \
	01labs.image.vendor="O1 Labs" \
	01labs.image.title="0labs/prysm" \
	01labs.image.description="Official Golang implementation of the Ethereum 2.0 protocol." \
	01labs.image.source="https://github.com/0x0I/container-file-prysm/blob/${version}/Dockerfile" \
	01labs.image.documentation="https://github.com/0x0I/container-file-prysm/blob/${version}/README.md" \
	01labs.image.version="${version}"

COPY --from=builder /tmp/prysm/bazel-bin/cmd/beacon-chain/beacon-chain_/beacon-chain /usr/local/bin/
COPY --from=builder /tmp/prysm/bazel-bin/cmd/validator/validator_/validator /usr/local/bin/
COPY --from=builder /tmp/prysm/bazel-bin/cmd/slasher/slasher_/slasher /usr/local/bin/
RUN chmod +x /usr/local/bin/beacon-chain /usr/local/bin/validator /usr/local/bin/slasher

# ORDER: 1. beacon-chain, 2. validator, 3. slasher
#      p2p/tcp  p2p/udp  rpc  grpc-gateway  metrics
#        ↓         ↓      ↓       ↓           ↓
EXPOSE 13000    12000   4000    3500        8080
EXPOSE                  7000    7500        8081
EXPOSE                                      8082

CMD ["beacon-chain", "--accept-terms-of-use"]

# ******* Stage: tools ******* #

FROM builder as build-tools

RUN cd /tmp/prysm && bazel build --config=release //cmd/client-stats:client-stats

# ------- #

FROM base as tools

COPY --from=build-tools /tmp/prysm/bazel-bin/cmd/client-stats/client-stats_/client-stats /usr/local/bin/

WORKDIR /var/lib/prysm

CMD ["/bin/bash"]
