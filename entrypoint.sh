#!/usr/bin/env bash

GH_BOT_TOKEN=$1
BOT_WORKSPACE="/home/tr1b0t/bot-workspace"
SCRIPT_PATH="/home/tr1b0t/tribe-product-utils"

PLUGIN_NAME=$(cat $GITHUB_EVENT_PATH | jq '.repository.name')
BRANCH=$(cat $GITHUB_EVENT_PATH | jq '.pull_request.head.ref')

# Remove double quotes
PLUGIN_NAME="${PLUGIN_NAME%\"}"
PLUGIN_NAME="${PLUGIN_NAME#\"}"
BRANCH="${BRANCH%\"}"
BRANCH="${BRANCH#\"}"

mkdir $BOT_WORKSPACE
mkdir $GITHUB_WORKSPACE/zip

rsync -a "$GITHUB_WORKSPACE/" "$BOT_WORKSPACE/$PLUGIN_NAME"
chown -R tr1b0t:tr1b0t /home/tr1b0t/
chown -R tr1b0t:tr1b0t /tmp

cd $BOT_WORKSPACE/$PLUGIN_NAME

git submodule update --init --recursive

NODE_VERSION=$(cat .nvmrc)

if [[ ! -z "$NODE_VERSION" ]]
then
    curl https://raw.githubusercontent.com/creationix/nvm/v0.20.0/install.sh | bash \
        && . $NVM_DIR/nvm.sh \
        && nvm install $NODE_VERSION \
        && nvm alias default $NODE_VERSION \
        && nvm use default
fi

npm install -g gulp

# Setup tribe-product-utils
gosu tr1b0t bash -c "git clone --depth 1 --branch gh-action-test --single-branch https://tr1b0t:$GH_BOT_TOKEN@github.com/moderntribe/tribe-product-utils.git $SCRIPT_PATH"

cd $SCRIPT_PATH
gosu tr1b0t bash -c "cp mt-sample.json mt.json"
gosu tr1b0t bash -c "composer update -o"
gosu tr1b0t bash -c "chmod +x mt"

cd $BOT_WORKSPACE

npm --version
WHICH_NPM=$(which npm)
echo "WHICH NPM: $WHICH_NPM"

# Alias PHP to the path our mt-jenkins scripts expect
ln -s $(which php) /usr/bin/php

# Run codesniffing
$SCRIPT_PATH/mt package \
    --plugin $PLUGIN_NAME \
    --branch $BRANCH \
    --output "$GITHUB_WORKSPACE/zip" \
    --ignore-view-versions \
    --enable-s3 \
    -vvv

#RAW_RESULTS=$($SCRIPT_PATH/mt package \
#    --plugin $PLUGIN_NAME \
#    --branch $BRANCH \
#    --output "$GITHUB_WORKSPACE/zip" \
#    --ignore-view-versions \
#    --enable-s3 \
#    -vvv)

#echo $RAW_RESULTS

#RESULTS=$(echo "${RAW_RESULTS}" | sed -n -e '/Packaging results/,$p')
#ZIP=$(echo "${RESULTS}" | grep -o '".*"' | sed 's/"//g')

#echo "${RESULTS}" > $GITHUB_WORKSPACE/zip/$ZIP.txt

#echo ::set-output name=zip::$ZIP
#echo ::set-output name=results::"${RESULTS}"

exit 1
