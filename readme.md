# freshawair

<!-- markdownlint-disable MD033 -->

Host and view your [Awair data](https://www.getawair.com/) locally.

- **Store** Awair data in your own database
- **View** Awair data from a self hosted web-app (grafana).

<img alt="freshawair grafana" src="./img/preview.png" width="600" />

## description

`freshawair` is three macro components

- `agent` - captures data from your awair(s) and load data into the database
- `database` - [timescale db](https://www.timescale.com/) instance
- [grafana](https://grafana.com/) - visualize your data

## usage

`docker-compose -f docker-compose.yml -f docker-compose.prod.yml up`

`docker-compose` is the primary supported deployment mechanism. Services may be deployed independently as desired, but users will need to adopt the `docker-compose.yml` configurations into the alternative desired format.

The agent has a CLI with all options configurable via ENV or CLI args:

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

Postgres/TimescaleDB & Grafana configuration is left to the user. Sensible
defaults are set in compose files.

### local builds

The only supported mechanism for _building_ is following:

- install [rad](https://github.com/cdaringe/rad#install)
- `./rad build`
- `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up`
- visit grafana@[localhost:3000](https://localhost:3000) and select the prebuilt dashboard

See [rad.ts](./rad.ts) or run `rad --list` for various actions.

## Performance

Here are some typical CPU/Mem usage from the different components:

```sh
$ docker stats
NAME                      CPU %     MEM USAGE / LIMIT
freshawair_freshagent_1   0.00%     2.355MiB / 5.641GiB
freshawair_grafana_1      0.05%     38.5MiB / 5.641GiB
freshawair_freshdb_1      0.01%     101.6MiB / 5.641GiB
```

Further tuning can be done to tweak the postgres & grafana runtime characteristics.
