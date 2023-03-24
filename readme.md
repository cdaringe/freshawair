# freshawair

<!-- markdownlint-disable MD033 -->

Host and view your [Awair data](https://www.getawair.com/) locally.

- store your Awair data in your own db
- access your Awair data from a self hosted web-app (grafana).

<img alt="freshawair grafana" src="./img/preview.png" width="400" />

## description

`freshawair` is three macro components

- `agent` - captures data from your awair and forwards it to your `server`
- `db` - [timescale db](https://www.timescale.com/) instance
- [grafana](https://grafana.com/)

## usage

At the current time, even though there are [docker images](https://hub.docker.com/repository/docker/cdaringe/freshawair) available.

```sh
$ docker run --rm -it cdaringe/freshawair --help
Usage: agent [OPTIONS] --db-host <DB_HOST> --db-port <DB_PORT>

Options:
      --awair-endpoint <AWAIR_ENDPOINT>
      --db-host <DB_HOST>
      --db-port <DB_PORT>
      --db-user <DB_USER>                  [default: fresh]
      --db-password <DB_PASSWORD>          [default: fresh]
      --poll-duration-s <POLL_DURATION_S>  [default: 60]
  -h, --help                               Print help
  -V, --version                            Print version
```

You can also use the UPPER_CASE vars as ENV vars to set values

The only supported mechanism for building is following:

- install [rad](https://github.com/cdaringe/rad#install)
- `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up`
- visit grafana@[localhost:3000](https://localhost:3000) and select the prebuilt dashboard

See [rad.ts](./rad.ts) or run `rad --list` for various actions.
