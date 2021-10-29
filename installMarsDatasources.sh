#! /bin/bash
#
# Copyright 2018 Jérôme Gasperi
#
# Licensed under the Apache License, version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# Force script to exit on error
set -e

ENV_FILE=__NULL__
DATA_DIR=$(pwd)"/data"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
ENCODING=UTF8

function showUsage {
    echo ""
    echo "   Install itag mars datasources "
    echo ""
    echo "   Usage $0 -e config.env"
    echo ""
    echo "      -e | --envfile iTag environnement file (see https://github.com/jjrom/itag/blob/master/config.en)"
    echo "      -d | --dataDir Directory containing datasources (default is $(pwd)/data)"
    echo "      -h | --help show this help"
    echo ""
}

# Parsing arguments
while [[ $# > 0 ]]
do
	key="$1"
	case $key in
        -e|--envfile)
            ENV_FILE="$2"
            shift # past argument
            ;;
        -d|--dataDir)
            DATA_DIR="$2"
            shift # past argument
            ;;
        -h|--help)
            showUsage
            exit 0
            shift # past argument
            ;;
            *)
        shift # past argument
        # unknown option
        ;;
	esac
done

if [ ! -f "${ENV_FILE}" ]; then
    showUsage
    echo -e "${RED}[ERROR]${NC} Missing or invalid config file!"
    echo ""
    exit 0
fi

if [ ! -d "${DATA_DIR}" ]; then
    showUsage
    echo -e "${RED}[ERROR]${NC} You must specify a data directory!"
    echo ""
    exit 0
fi

# Source config file
. ${ENV_FILE}

if [ "${ITAG_DATABASE_HOST}" == "itagdb" ] || [ "${ITAG_DATABASE_HOST}" == "host.docker.internal" ]; then
    DATABASE_HOST_SEEN_FROM_DOCKERHOST=localhost
else
    DATABASE_HOST_SEEN_FROM_DOCKERHOST=${ITAG_DATABASE_HOST}
fi

echo -e "[INFO] Using ${DATA_DIR} directory"

echo -e "[INFO] Creating mars schema in database"
PGPASSWORD=${ITAG_DATABASE_USER_PASSWORD} psql -U ${ITAG_DATABASE_USER_NAME} -d ${ITAG_DATABASE_NAME} -h ${DATABASE_HOST_SEEN_FROM_DOCKERHOST} -p ${ITAG_DATABASE_EXPOSED_PORT} > /dev/null 2>errors.log << EOF
CREATE SCHEMA IF NOT EXISTS mars;
EOF

echo -e "[INFO] Retrieve jjrom/shp2pgsql docker image"
docker pull jjrom/shp2pgsql

SHP2PGSQL="docker run --rm -v ${DATA_DIR}:/data:ro jjrom/shp2pgsql"

# ================================================================================
echo -e "[INFO] Install Mars 15M Geologic Map GIS Renovation from USGS"
${SHP2PGSQL} -g geom -d -W ${ENCODING} -s 4326 -I /data/I1802ABC_Mars2000_Sphere/geo_units_oc_dd.shp mars.geologic_unit 2> /dev/null | PGPASSWORD=${ITAG_DATABASE_USER_PASSWORD} psql -U ${ITAG_DATABASE_USER_NAME} -d ${ITAG_DATABASE_NAME} -h ${DATABASE_HOST_SEEN_FROM_DOCKERHOST} -p ${ITAG_DATABASE_EXPOSED_PORT} > /dev/null 2>errors.log

echo -e "[INFO] Install Mars Healpix order 1 to 4"
PGPASSWORD=${ITAG_DATABASE_USER_PASSWORD} psql -U ${ITAG_DATABASE_USER_NAME} -d ${ITAG_DATABASE_NAME} -h ${DATABASE_HOST_SEEN_FROM_DOCKERHOST} -p ${ITAG_DATABASE_EXPOSED_PORT} << EOF
CREATE TABLE IF NOT EXISTS mars.healpix (
    level       INTEGER NOT NULL,
    pix         INTEGER NOT NULL,
    geom        GEOMETRY(GEOMETRY, 4326),
    PRIMARY KEY (level, pix)
);
EOF
PGPASSWORD=${ITAG_DATABASE_USER_PASSWORD} psql -U ${ITAG_DATABASE_USER_NAME} -d ${ITAG_DATABASE_NAME} -h ${DATABASE_HOST_SEEN_FROM_DOCKERHOST} -p ${ITAG_DATABASE_EXPOSED_PORT} -f ${DATA_DIR}/healpix_order1.sql > /dev/null 2>errors.log
PGPASSWORD=${ITAG_DATABASE_USER_PASSWORD} psql -U ${ITAG_DATABASE_USER_NAME} -d ${ITAG_DATABASE_NAME} -h ${DATABASE_HOST_SEEN_FROM_DOCKERHOST} -p ${ITAG_DATABASE_EXPOSED_PORT} -f ${DATA_DIR}/healpix_order2.sql > /dev/null 2>errors.log
PGPASSWORD=${ITAG_DATABASE_USER_PASSWORD} psql -U ${ITAG_DATABASE_USER_NAME} -d ${ITAG_DATABASE_NAME} -h ${DATABASE_HOST_SEEN_FROM_DOCKERHOST} -p ${ITAG_DATABASE_EXPOSED_PORT} -f ${DATA_DIR}/healpix_order3.sql > /dev/null 2>errors.log
PGPASSWORD=${ITAG_DATABASE_USER_PASSWORD} psql -U ${ITAG_DATABASE_USER_NAME} -d ${ITAG_DATABASE_NAME} -h ${DATABASE_HOST_SEEN_FROM_DOCKERHOST} -p ${ITAG_DATABASE_EXPOSED_PORT} -f ${DATA_DIR}/healpix_order4.sql > /dev/null 2>errors.log


