# dbt_fivetran_log v0.4.1

## 🚨 Breaking Changes
- n/a

## Bug Fixes
- Added logic in the `fivetran_log__connector_status` model to accommodate the way [priority-first syncs](https://fivetran.com/docs/getting-started/feature#priorityfirstsync) are currently logged. Now, each connector's `connector_health` field can be one of the following values:
    - "broken"
    - "incomplete"
    - "connected"
    - "paused"
    - "initial sync in progress"
    - "priority first sync"
Once your connector has completed its priority-first sync and begun syncing normally, it will be marked as `connected`.

## Features
- Added this changelog to capture iterations of the package!

## Under the Hood
- n/a