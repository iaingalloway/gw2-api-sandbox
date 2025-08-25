# GW2 API Sandbox

This repository contains some sandbox code for experimenting with the Guild Wars 2 API.

## Snippets

Make a file `api-key.env` with the contents:

```bash
GW2_API_KEY={Your API Key}
```

Source the file for the current terminal session:

```bash
source api-key.env
```

An example call:

```bash
curl https://api.guildwars2.com/v2/account?access_token=$GW2_API_KEY
```

Source common.sh:

```bash
source common.sh
```

An example call using the script wrapper:

```bash
gw2_api characters
```

Another example, get a character's Jade Bot:

```bash
gw2_api "characters/{:id}" | jq '.equipment[] | select(.slot=="ServiceChip" or .slot=="PowerCore" or .slot=="SensoryArray")'
```

Get jade bot data for all characters:

```bash
./get-jade-bots.sh
```
