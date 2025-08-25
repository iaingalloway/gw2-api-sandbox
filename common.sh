#!/bin/bash

API_URL="https://api.guildwars2.com/v2/"

gw2_api() {
    local endpoint="${1// /%20}"
    shift
    curl -s "${API_URL}${endpoint}?access_token=$GW2_API_KEY"
}
