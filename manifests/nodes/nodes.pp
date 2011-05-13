node default {
    include socorro-db
    include socorro-monitor
    include socorro-admin
    include socorro-php
    include socorro-processor
    include socorro-collector
    include socorro-api
    include socorro-hbase
}

