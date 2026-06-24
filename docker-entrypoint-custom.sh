#!/bin/sh
set -eu

cat > /usr/local/etc/php/conf.d/zz-resource-limits.ini <<EOF
memory_limit = ${PHP_MEMORY_LIMIT:-256M}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE:-64M}
post_max_size = ${PHP_POST_MAX_SIZE:-64M}
max_execution_time = ${PHP_MAX_EXECUTION_TIME:-300}
max_input_vars = ${PHP_MAX_INPUT_VARS:-10000}
EOF

cat > /usr/local/etc/php-fpm.d/zz-resource-limits.conf <<EOF
[www]
pm = dynamic
pm.max_children = ${PHP_FPM_MAX_CHILDREN:-5}
pm.start_servers = ${PHP_FPM_START_SERVERS:-2}
pm.min_spare_servers = ${PHP_FPM_MIN_SPARE_SERVERS:-1}
pm.max_spare_servers = ${PHP_FPM_MAX_SPARE_SERVERS:-3}
pm.max_requests = ${PHP_FPM_MAX_REQUESTS:-500}
EOF

exec docker-entrypoint.sh "$@"
