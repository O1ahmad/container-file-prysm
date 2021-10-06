# Prysm :cloud: Compose

:octocat: Custom configuration of this deployment composition can be provided by setting environment variables of the operation environment explicitly:

`export image=0labs/prysm:v2.0.0`

or included within an environment config file located either at a `.beacon.env or .validator.env` file within the same directory or specified via one of the role type `env_vars` environment variables.

`export beacon_env_vars=/home/user/prysm/beacon.env`

## Config

**Required**

`none`

**Optional**

| var | description | default |
| --- | :---: | :---: |
| *image* | Prysm client container image to deploy | `0labs/prysm:latest` |
| *PRYSM_CONFIG_DIR* | configuration directory path within container | `/etc/prysm` |
| *p2p_tcp_port* | peer-to-peer network communication and listening port | `13000` |
| *p2p_udp_port* | peer-to-peer network discovery port | `12000` |
| *eth2_api_port* | Ethereum 2.0 RESTful HTTP API listening port | `3501` |
| *beacon_rpc_port* | RPC port exposed by a beacon node | `4000` |
| *beacon_metrics_port* | port used to listen and respond to metrics requests for prometheus | `8080` |
| *validator_gateway_port* | gRPC gateway for JSON requests | `7500` |
| *validator_rpc_port* | RPC port exposed by a validator client | `7000` |
| *validator_metrics_port* | port used to listen and respond to metrics requests for prometheus | `8081` |
| *host_data_dir* | host directory to store node runtime/operational data | `/var/tmp/prysm` |
| *host_wallet_dir* | host directory to store node account wallets | `/var/tmp/prysm/wallets` |
| *host_keys_dir* | host directory to store node account keys | `/var/tmp/prysm/keys` |
| *beacon_env_vars* | path to environment file to load by compose Beacon node container (see [list](https://docs.prylabs.network/docs/prysm-usage/parameters/#beacon-node-configuration) of available config options) | `.beacon.env` |
| *validator_env_vars* | Path to environment file to load by compose Validator container (see [list](https://docs.prylabs.network/docs/prysm-usage/parameters/#validator-configuration) of available config options | `.validator.env` |
| *restart_policy* | container restart policy | `unless-stopped` |

## Deploy examples

* Enable automatic acceptance of the terms of use when launching either a beacon-chain or validator node:
```
# cat .beacon.env
CONFIG_accept-terms-of-use=true

docker-compose up
```

* Launch a Prysm beacon-chain node connected to the Pyrmont Ethereum 2.0 testnet using a Goerli web3 Ethereum provider:
```
# cat .beacon.env
CONFIG_http-web3provider=http://ethereum-rpc.goerli.01labs.net:8545
CONFIG_pyrmont=true

docker-compose up beacon-node
```

* Customize the deploy container image and host + container node data directory:
```
# cat .beacon.env
image=0labs/prysm:v2.0.0
host_data_dir=/my/host/data
CONFIG_datadir=/container/data/dir

docker-compose up
```

* Install Eth2 deposit CLI tool and automatically setup multiple validator accounts/keys to register on the Pyrmont testnet:
```
# cat .beacon.env
SETUP_DEPOSIT_CLI=true
DEPOSIT_CLI_VERSION=v1.2.0
SETUP_DEPOSIT_ACCOUNTS=true
DEPOSIT_NUM_VALIDATORS=3
ETH2_CHAIN=pyrmont
DEPOSIT_KEY_PASSWORD=ABCabc123!@#$

docker-compose up beacon-node
```

* Setup automatic cron backups of a localhost beacon-chain node DB every 12 hours (or twice a day):
```
# cat .beacon.env
AUTO_BACKUP_DB=true
BACKUP_HOST_ADDR=http://localhost:8080
BACKUP_INTERVAL=0 */12 * * *

docker-compose up
```
