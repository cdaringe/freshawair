# freshawair

<!-- markdownlint-disable MD033 -->

Host and view your Awair data locally.

- store your Awair data in your own db
- access your Awair data from a self hosted web-app (grafana).

<img alt="freshawair grafana" src="./img/preview.png" width="400" />

## description

`freshawair` is four macro components

- `agent` - captures data from your awair and forwards it to your `server`
- `db` - [timescale db](https://www.timescale.com/) instance
- [grafana](https://grafana.com/)

## usage

At the current time, even though there are [docker images](https://hub.docker.com/repository/docker/cdaringe/freshawair) available, the only supported mechanism for building is following:

- install [rad](https://github.com/cdaringe/rad#install)
- `docker-compose build`
- `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up`
- visit grafana@[localhost:3000](https://localhost:3000) and use the prebuilt dashboards

See [rad.ts](./rad.ts) or run `rad --list` for various actions.
