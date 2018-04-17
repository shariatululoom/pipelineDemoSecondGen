#!/usr/bin/env bash

set -o errexit    # always exit on error
set -o pipefail   # don't ignore exit codes when piping output
set -o nounset    # fail on unset variables

#################################################################
# Script to setup a fully configured pipeline for Salesforce DX #
#################################################################

### Declare values

# Create a unique var to append
TICKS=$(echo $(date +%s | cut -b1-13))

# Name of your team (optional)
HEROKU_TEAM_NAME=""

# Descriptive name for the Heroku app
HEROKU_APP_NAME="MyLightningApp"

# Name of the Heroku apps you'll use
HEROKU_DEV_APP_NAME="dev$TICKS"
HEROKU_STAGING_APP_NAME="staging$TICKS"
HEROKU_PROD_APP_NAME="prod$TICKS"

# Pipeline
HEROKU_PIPELINE_NAME="pipelineskms"

# Usernames or aliases of the orgs you're using
DEV_HUB_USERNAME="huborg"
DEV_USERNAME="DevOrg"
STAGING_USERNAME="StagingOrg"
PROD_USERNAME="ProdOrg"

# Repository with your code
GITHUB_REPO="https://github.com/shariatululoom/pipelineDemoSecondGen"

# Your package name
PACKAGE_NAME="PackageName"

### Setup script

# Support a Heroku team
HEROKU_TEAM_FLAG=""
if [ ! "$HEROKU_TEAM_NAME" == "" ]; then
  HEROKU_TEAM_FLAG="-t $HEROKU_TEAM_NAME"
fi

# Clean up script
echo "heroku pipelines:destroy $HEROKU_PIPELINE_NAME
heroku apps:destroy -a $HEROKU_DEV_APP_NAME -c $HEROKU_DEV_APP_NAME
heroku apps:destroy -a $HEROKU_STAGING_APP_NAME -c $HEROKU_STAGING_APP_NAME
heroku apps:destroy -a $HEROKU_PROD_APP_NAME -c $HEROKU_PROD_APP_NAME
rm -- \"destroy$TICKS.sh\"" > destroy$TICKS.sh

echo ""
echo "Run ./destroy$TICKS.sh to remove resources"
echo ""

chmod +x "destroy$TICKS.sh"

# Create three Heroku apps to map to orgs
heroku apps:create $HEROKU_DEV_APP_NAME $HEROKU_TEAM_FLAG
heroku apps:create $HEROKU_STAGING_APP_NAME $HEROKU_TEAM_FLAG
heroku apps:create $HEROKU_PROD_APP_NAME $HEROKU_TEAM_FLAG

# Set the stage (since STAGE isn't required, review apps don't get one)
heroku config:set STAGE=DEV -a $HEROKU_DEV_APP_NAME
heroku config:set STAGE=STAGING -a $HEROKU_STAGING_APP_NAME
heroku config:set STAGE=PROD -a $HEROKU_PROD_APP_NAME

# Set whether or not to use DCP packaging
heroku config:set SFDX_INSTALL_PACKAGE_VERSION=true -a $HEROKU_DEV_APP_NAME
heroku config:set SFDX_INSTALL_PACKAGE_VERSION=true -a $HEROKU_STAGING_APP_NAME
heroku config:set SFDX_INSTALL_PACKAGE_VERSION=true -a $HEROKU_PROD_APP_NAME

# Set whether to create package version
heroku config:set SFDX_CREATE_PACKAGE_VERSION=true -a $HEROKU_DEV_APP_NAME
heroku config:set SFDX_CREATE_PACKAGE_VERSION=false -a $HEROKU_STAGING_APP_NAME
heroku config:set SFDX_CREATE_PACKAGE_VERSION=false -a $HEROKU_PROD_APP_NAME

# Package name
heroku config:set SFDX_PACKAGE_NAME="$PACKAGE_NAME" -a $HEROKU_DEV_APP_NAME
heroku config:set SFDX_PACKAGE_NAME="$PACKAGE_NAME" -a $HEROKU_STAGING_APP_NAME
heroku config:set SFDX_PACKAGE_NAME="$PACKAGE_NAME" -a $HEROKU_PROD_APP_NAME

# Turn on debug logging
heroku config:set SFDX_BUILDPACK_DEBUG=true -a $HEROKU_DEV_APP_NAME
heroku config:set SFDX_BUILDPACK_DEBUG=true -a $HEROKU_STAGING_APP_NAME
heroku config:set SFDX_BUILDPACK_DEBUG=true -a $HEROKU_PROD_APP_NAME

# Setup sfdxUrl's for auth
devHubSfdxAuthUrl="force://SalesforceDevelopmentExperience:1384510088588713504:5Aep8613hy0tHCYdhyfTOHpm.pursBbRdo0wVfdG3FFHMRkxuF7Y6RAlx5N_d5wkbZ7XmirJdF9sllFWmkl_U0N@battlestar-serenity-72610.my.salesforce.com"
heroku config:set SFDX_DEV_HUB_AUTH_URL=$devHubSfdxAuthUrl -a $HEROKU_DEV_APP_NAME

devSfdxAuthUrl="force://SalesforceDevelopmentExperience:1384510088588713504:5Aep861hkUriVVOXT6yidRBSQWIDQWwBbJ330ywaKXnzM_8jhzSBNr7gVgFJsiWzLId9mBPXOXR5iPAeMynvLBt@customer-data-9813-dev-ed.cs31.my.salesforce.com"
heroku config:set SFDX_AUTH_URL=$devSfdxAuthUrl -a $HEROKU_DEV_APP_NAME

stagingSfdxAuthUrl="force://SalesforceDevelopmentExperience:1384510088588713504:5Aep86110KCjUDVVh32IZcrcvspzhrNl.SlsFdhDI56GijWyiKNP6DzGKW5pbQUMg_tDB.4MKY35gV55RVmZWDl@java-energy-8659-dev-ed.cs5.my.salesforce.com"  
heroku config:set SFDX_AUTH_URL=$stagingSfdxAuthUrl -a $HEROKU_STAGING_APP_NAME

stagingSfdxAuthUrl="force://SalesforceDevelopmentExperience:1384510088588713504:5Aep861M6dhd2BtI2502m_lYMrcAouq7yN_SDgA7pu3ebUPXHtUJ7aqand4ZFs6CGQUm5j3eZX7AUYvm3xjS1dn@inspiration-efficiency-5219-dev-ed.cs57.my.salesforce.com"            
heroku config:set SFDX_AUTH_URL=$stagingSfdxAuthUrl -a $HEROKU_PROD_APP_NAME

# Add buildpacks to apps
heroku buildpacks:add -i 1 https://github.com/heroku/salesforce-cli-buildpack -a $HEROKU_DEV_APP_NAME
heroku buildpacks:add -i 1 https://github.com/heroku/salesforce-cli-buildpack -a $HEROKU_STAGING_APP_NAME
heroku buildpacks:add -i 1 https://github.com/heroku/salesforce-cli-buildpack -a $HEROKU_PROD_APP_NAME

heroku buildpacks:add -i 2 https://github.com/heroku/salesforce-buildpack -a $HEROKU_DEV_APP_NAME
heroku buildpacks:add -i 2 https://github.com/heroku/salesforce-buildpack -a $HEROKU_STAGING_APP_NAME
heroku buildpacks:add -i 2 https://github.com/heroku/salesforce-buildpack -a $HEROKU_PROD_APP_NAME

# Create Pipeline
# Valid stages: "test", "review", "development", "staging", "production"
heroku pipelines:create $HEROKU_PIPELINE_NAME -a $HEROKU_DEV_APP_NAME -s development $HEROKU_TEAM_FLAG
heroku pipelines:add $HEROKU_PIPELINE_NAME -a $HEROKU_STAGING_APP_NAME -s staging
heroku pipelines:add $HEROKU_PIPELINE_NAME -a $HEROKU_PROD_APP_NAME -s production

# Setup your pipeline
heroku pipelines:connect $HEROKU_PIPELINE_NAME --repo $GITHUB_REPO
heroku reviewapps:enable -p $HEROKU_PIPELINE_NAME -a $HEROKU_DEV_APP_NAME --autodeploy --autodestroy

heroku ci:config:set -p $HEROKU_PIPELINE_NAME SFDX_DEV_HUB_AUTH_URL=$devHubSfdxAuthUrl
heroku ci:config:set -p $HEROKU_PIPELINE_NAME SFDX_AUTH_URL=$devSfdxAuthUrl
heroku ci:config:set -p $HEROKU_PIPELINE_NAME SFDX_BUILDPACK_DEBUG=true
heroku ci:config:set -p $HEROKU_PIPELINE_NAME SFDX_INSTALL_PACKAGE_VERSION=true
heroku ci:config:set -p $HEROKU_PIPELINE_NAME SFDX_CREATE_PACKAGE_VERSION=false
heroku ci:config:set -p $HEROKU_PIPELINE_NAME SFDX_PACKAGE_NAME="$PACKAGE_NAME"
heroku ci:config:set -p $HEROKU_PIPELINE_NAME HEROKU_APP_NAME="$HEROKU_APP_NAME"
