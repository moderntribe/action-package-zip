#!/usr/bin/env bash

GH_BOT_TOKEN=$1
BOT_WORKSPACE="/home/tr1b0t/bot-workspace"
SCRIPT_PATH="/home/tr1b0t/tribe-product-utils"

PLUGIN_NAME=$(cat $GITHUB_EVENT_PATH | jq '.repo.name')

rsync -a "$GITHUB_WORKSPACE/" "$BOT_WORKSPACE/$PLUGIN_NAME"
chown -R tr1b0t:tr1b0t /home/tr1b0t/
chown -R tr1b0t:tr1b0t /tmp

# Setup tribe-product-utils
gosu tr1b0t bash -c "git clone --depth 1 --branch master --single-branch https://tr1b0t:$GH_BOT_TOKEN@github.com/moderntribe/tribe-product-utils.git $SCRIPT_PATH"

cd $SCRIPT_PATH
gosu tr1b0t bash -c "composer update -o"
gosu tr1b0t bash -c "chmod +x mt"

cd $BOT_WORKSPACE

# Alias PHP to the path our mt-jenkins scripts expect
ln -s $(which php) /usr/bin/php

# Run codesniffing
$SCRIPT_PATH/mt package \
    --plugin $(cat $GITHUB_EVENT_PATH | jq '.repo.full_name') \
    --branch $(cat $GITHUB_EVENT_PATH | jq '.pull_request.head.ref') \
    --ignore-view-versions \
    --clear \
    -v
