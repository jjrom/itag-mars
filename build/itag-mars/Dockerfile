FROM jjrom/itag:5.3.2
LABEL maintainer="jerome.gasperi@gmail.com"

ENV BUILD_DIR=./build/itag-mars

# Copy Taggers
COPY ${BUILD_DIR}/Taggers/MarsGeologyTagger.php /app/include/iTag/Taggers/MarsGeologyTagger.php
COPY ${BUILD_DIR}/Taggers/HealpixTagger.php /app/include/iTag/Taggers/HealpixTagger.php


