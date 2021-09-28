#!/usr/bin/env python3

from datetime import datetime
import json
import os
import subprocess
import sys

import click
import requests
import urllib.request
import yaml

@click.group()
@click.option('--debug/--no-debug', default=False)
def cli(debug):
    pass

@cli.group()
def config():
    pass

@cli.group()
def status():
    pass

###
# Commands for application configuration customization and inspection
###

DEFAULT_PRYSM_CONFIG_PATH = "/etc/prysm/config.yml"
DEFAULT_PRYSM_DATADIR = "/root/.eth2"

DEFAULT_API_HOST_ADDR = 'http://localhost:3501'
DEFAULT_API_METHOD = 'GET'
DEFAULT_API_PATH = 'eth/v1/node/health'
DEFAULT_API_DATA = '{}'

def print_json(json_blob):
    print(json.dumps(json_blob, indent=4, sort_keys=True))

def execute_command(command):
    process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
    output, error = process.communicate()

    if process.returncode > 0:
        print('Executing command \"%s\" returned a non-zero status code %d' % (command, process.returncode))
        sys.exit(process.returncode)

    if error:
        print(error.decode('utf-8'))

    return output.decode('utf-8')

@config.command()
@click.option('--config-path',
              default=lambda: os.environ.get("PRYSM_CONFIG", DEFAULT_PRYSM_CONFIG_PATH),
              show_default=DEFAULT_PRYSM_CONFIG_PATH,
              help='path to prysm configuration file to generate or customize from environment config settings')
@click.option('--download-genesis',
              default=lambda: os.environ.get("DOWNLOAD_GENESIS", "true"),
              show_default="true",
              help='Whether to automatically download the genesis state file associated with the designated Eth2 chain if specified in config')
def customize(config_path, download_genesis):
    config_dict = dict()
    if os.path.isfile(config_path):
        with open(config_path, "r") as stream:
            try:
                config_dict = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc)

    for var in os.environ.keys():
        var_split = var.split('_')
        if len(var_split) == 2 and var_split[0].lower() == "config":
            config_setting = var_split[1]
            value = os.environ[var]

            # download genesis state file according to set Eth2 chain automatically
            if config_setting.lower() == "genesis-state" and download_genesis.lower() == "true":
                # ensure genesis-state file DIR exists
                os.makedirs(os.path.dirname(value))
                genesis_url = "https://github.com/eth2-clients/eth2-networks/raw/32dcce003694ea17e04bc17cc56de2f7909a1d95/shared/{chain}/genesis.ssz".format(
                    chain=os.environ.get("ETH2_CHAIN", "pyrmont")
                )
                urllib.request.urlretrieve(genesis_url, value)

            # ensure values are cast appropriately
            if value.isdigit():
                value = int(value)
            elif value.lower() == "true":
                value = True
            elif value.lower() == "false":
                value = False
            config_dict[config_setting] = value

    with open(config_path, 'w+') as f:
        yaml.dump(config_dict, f)

@status.command()
@click.option('--host-addr',
              default=lambda: os.environ.get("API_HOST_ADDR", DEFAULT_API_HOST_ADDR),
              show_default=DEFAULT_API_HOST_ADDR,
              help='Prysm Eth2 API host address in format <protocol(http/https)>://<IP>:<port>')
@click.option('--api-method',
              default=lambda: os.environ.get("API_METHOD", DEFAULT_API_METHOD),
              show_default=DEFAULT_API_METHOD,
              help='HTTP method to execute a part of request')
@click.option('--api-path',
              default=lambda: os.environ.get("API_PATH", DEFAULT_API_PATH),
              show_default=DEFAULT_API_PATH,
              help='Restful API path to target resource')
@click.option('--api-data',
              default=lambda: os.environ.get("API_DATA", DEFAULT_API_DATA),
              show_default=DEFAULT_API_DATA,
              help='Restful API request body data included within POST requests')
def api_request(host_addr, api_method, api_path, api_data):
    """
    Execute RESTful API HTTP request
    """

    try:
        if api_method.upper() == "POST":
            resp = requests.post(
                "{host}/{path}".format(host=host_addr, path=api_path),
                json=json.loads(api_data),
                headers={'Content-Type': 'application/json'})
        else:
            resp = requests.get("{host}/{path}".format(host=host_addr, path=api_path))

        # signal error if non-OK response status
        resp.raise_for_status()

        print_json(resp.json())
    except requests.exceptions.RequestException as err:
        sys.exit(print_json({
            "error": "API request to {host} failed with: {error}".format(
                host=host_addr,
                error=err
            )
        }))
    except json.decoder.JSONDecodeError:
        print(resp.text)

if __name__ == "__main__":
    cli()