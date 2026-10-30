#!/bin/bash -e

CANARY_DB_HOST="${CANARY_DB_HOST:-db}"
CANARY_DB_PORT="${CANARY_DB_PORT:-3306}"
CANARY_DB_USER="${CANARY_DB_USER:-canary}"
CANARY_DB_PASSWORD="${CANARY_DB_PASSWORD:-canary}"
CANARY_DB_NAME="${CANARY_DB_NAME:-canary}"
CANARY_SERVER_NAME="${CANARY_SERVER_NAME:-OpenTibiaBR Canary}"
CANARY_SERVER_IP="${CANARY_SERVER_IP:-127.0.0.1}"
CANARY_SERVER_LOCATION="${CANARY_SERVER_LOCATION:-BRA}"
CANARY_SERVER_URL="${CANARY_SERVER_URL:-http://docs.opentibiabr.com/}"
CANARY_OWNER_NAME="${CANARY_OWNER_NAME:-OpenTibiaBR}"
CANARY_OWNER_EMAIL="${CANARY_OWNER_EMAIL:-opentibiabr@outlook.com}"
CANARY_MAX_PLAYERS="${CANARY_MAX_PLAYERS:-2000}"
CANARY_LOGIN_PORT="${CANARY_LOGIN_PORT:-7171}"
CANARY_GAME_PORT="${CANARY_GAME_PORT:-7172}"
CANARY_STATUS_PORT="${CANARY_STATUS_PORT:-7173}"
CANARY_STATUS_TIMEOUT="${CANARY_STATUS_TIMEOUT:-5000}"
CANARY_TEST_ACCOUNTS="${CANARY_TEST_ACCOUNTS:-false}"
CANARY_DATA_PACK="${CANARY_DATA_PACK:-data-otservbr-global}"
CANARY_MAP_URL="${CANARY_MAP_URL:-https://github.com/opentibiabr/canary/releases/download/v3.5.0/otservbr.otbm}"
CANARY_AUTH_TYPE="${CANARY_AUTH_TYPE:-session}"
CANARY_COIN_IMAGES_URL="${CANARY_COIN_IMAGES_URL:-http://127.0.0.1:8080/images/store/}"

validate_identifier() {
	local name="$1"
	local value="$2"
	if [[ ! "$value" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]]; then
		echo "Invalid ${name}: '${value}'. Use only letters, numbers, underscores, and hyphens." >&2
		exit 1
	fi
}

require_uint() {
	local name="$1"
	local value="$2"
	if [[ ! "$value" =~ ^[0-9]+$ ]]; then
		echo "Invalid ${name}: '${value}'. Use only unsigned integer values." >&2
		exit 1
	fi
}

escape_lua_string() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

set_lua_line() {
	local key="$1"
	local replacement="$2"
	local tmp_file
	local found=0

	tmp_file=$(mktemp)
	while IFS= read -r line || [ -n "$line" ]; do
		if [[ "$line" == "$key = "* ]]; then
			printf '%s\n' "$replacement"
			found=1
		else
			printf '%s\n' "$line"
		fi
	done <config.lua >"$tmp_file"

	if [ "$found" -eq 0 ]; then
		printf '%s\n' "$replacement" >>"$tmp_file"
	fi

	mv "$tmp_file" config.lua
}

set_lua_string() {
	local key="$1"
	local value="$2"
	set_lua_line "$key" "$key = \"$(escape_lua_string "$value")\""
}

set_lua_number() {
	local key="$1"
	local value="$2"
	set_lua_line "$key" "$key = $value"
}

mysql_cmd() {
	MYSQL_PWD="$CANARY_DB_PASSWORD" mysql \
		--protocol=tcp \
		--default-character-set=utf8mb4 \
		-u "$CANARY_DB_USER" \
		-h "$CANARY_DB_HOST" \
		--port="$CANARY_DB_PORT" \
		"$@"
}

mysqldump_cmd() {
	MYSQL_PWD="$CANARY_DB_PASSWORD" mysqldump \
		--protocol=tcp \
		--default-character-set=utf8mb4 \
		-u "$CANARY_DB_USER" \
		-h "$CANARY_DB_HOST" \
		--port="$CANARY_DB_PORT" \
		"$@"
}

validate_identifier "CANARY_DB_NAME" "$CANARY_DB_NAME"
require_uint "CANARY_DB_PORT" "$CANARY_DB_PORT"
require_uint "CANARY_MAX_PLAYERS" "$CANARY_MAX_PLAYERS"
require_uint "CANARY_LOGIN_PORT" "$CANARY_LOGIN_PORT"
require_uint "CANARY_GAME_PORT" "$CANARY_GAME_PORT"
require_uint "CANARY_STATUS_PORT" "$CANARY_STATUS_PORT"
require_uint "CANARY_STATUS_TIMEOUT" "$CANARY_STATUS_TIMEOUT"

echo ""
echo "===== Canary Docker Configuration ====="
echo ""
echo "CANARY_DB_HOST:[$CANARY_DB_HOST]"
echo "CANARY_DB_PORT:[$CANARY_DB_PORT]"
echo "CANARY_DB_USER:[$CANARY_DB_USER]"
echo "CANARY_DB_PASSWORD:[********]"
echo "CANARY_DB_NAME:[$CANARY_DB_NAME]"
echo "CANARY_SERVER_NAME:[$CANARY_SERVER_NAME]"
echo "CANARY_SERVER_IP:[$CANARY_SERVER_IP]"
echo "CANARY_SERVER_LOCATION:[$CANARY_SERVER_LOCATION]"
echo "CANARY_SERVER_URL:[$CANARY_SERVER_URL]"
echo "CANARY_OWNER_NAME:[$CANARY_OWNER_NAME]"
echo "CANARY_OWNER_EMAIL:[$CANARY_OWNER_EMAIL]"
echo "CANARY_MAX_PLAYERS:[$CANARY_MAX_PLAYERS]"
echo "CANARY_LOGIN_PORT:[$CANARY_LOGIN_PORT]"
echo "CANARY_GAME_PORT:[$CANARY_GAME_PORT]"
echo "CANARY_STATUS_PORT:[$CANARY_STATUS_PORT]"
echo "CANARY_STATUS_TIMEOUT:[$CANARY_STATUS_TIMEOUT]"
echo "CANARY_TEST_ACCOUNTS:[$CANARY_TEST_ACCOUNTS]"
echo "CANARY_DATA_PACK:[$CANARY_DATA_PACK]"
echo "CANARY_MAP_URL:[$CANARY_MAP_URL]"
echo "CANARY_COIN_IMAGES_URL:[$CANARY_COIN_IMAGES_URL]"
echo ""
echo "======================================="
echo ""

echo ""
echo "===== OTBR Global Data Pack ====="
echo ""

if [ "$CANARY_DATA_PACK" = "data-otservbr-global" ]; then
	map_path="data-otservbr-global/world/otservbr.otbm"
	tmp_map="${map_path}.tmp"
	map_needs_download=false

	if [ ! -f "$map_path" ]; then
		map_needs_download=true
	elif [ -n "${CANARY_MAP_SHA256:-}" ]; then
		current_map_sha256="$(sha256sum "$map_path" | awk '{print $1}')"
		if [ "$current_map_sha256" != "$CANARY_MAP_SHA256" ]; then
			echo "Installed map checksum differs from the configured Zealot map; replacing it."
			map_needs_download=true
		fi
	fi

	if [ "$map_needs_download" = true ]; then
		echo "Downloading configured map..."
		rm -f "$tmp_map"
		if ! curl --fail --show-error --location \
			--connect-timeout 5 --max-time 180 \
			"$CANARY_MAP_URL" -o "$tmp_map"; then
			rm -f "$tmp_map"
			exit 1
		fi
		if [ -n "${CANARY_MAP_SHA256:-}" ]; then
			downloaded_map_sha256="$(sha256sum "$tmp_map" | awk '{print $1}')"
			if [ "$downloaded_map_sha256" != "$CANARY_MAP_SHA256" ]; then
				echo "Downloaded map checksum does not match CANARY_MAP_SHA256."
				rm -f "$tmp_map"
				exit 1
			fi
		fi
		mv "$tmp_map" "$map_path"
		echo "Map ready"
	else
		echo "Map download skipped"
	fi
else
	echo "Map download skipped"
fi

echo ""
echo "================================"
echo ""

echo ""
echo "===== Wait For The DB To Be Up ====="
echo ""

until mysql_cmd -e "SELECT 1;" >/dev/null 2>&1; do
	echo "DB offline, trying again"
	sleep 5s
done

echo ""
echo "================================"
echo ""

echo ""
echo "===== Ensure Canary Database ====="
echo ""

if mysql_cmd -e "USE \`$CANARY_DB_NAME\`;" >/dev/null 2>&1; then
	echo "Database '$CANARY_DB_NAME' exists"
else
	echo "Creating database '$CANARY_DB_NAME'"
	mysql_cmd -e "CREATE DATABASE \`$CANARY_DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
fi

echo ""
echo "================================"
echo ""

echo ""
echo "===== Ensure Canary Schema ====="
echo ""

if mysql_cmd -D "$CANARY_DB_NAME" -e 'SHOW TABLES LIKE "server_config";' | grep -q server_config; then
	echo "Existing Canary schema detected"
	echo "Saving database backup to /data/${CANARY_DB_NAME}.sql"
	mysqldump_cmd "$CANARY_DB_NAME" >"/data/${CANARY_DB_NAME}.sql.tmp"
	mv "/data/${CANARY_DB_NAME}.sql.tmp" "/data/${CANARY_DB_NAME}.sql"
else
	echo "Importing Canary schema"
	mysql_cmd -D "$CANARY_DB_NAME" <schema.sql

	echo ""
	echo "===== Test Accounts ====="
	echo ""

	if [ "$CANARY_TEST_ACCOUNTS" = "true" ]; then
		echo "Creating test accounts..."
		mysql_cmd -D "$CANARY_DB_NAME" </canary/01-test_account.sql
		mysql_cmd -D "$CANARY_DB_NAME" </canary/02-test_account_players.sql
	else
		echo "Test account creation skipped"
	fi

	echo ""
	echo "================================"
	echo ""
fi

echo ""
echo "================================"
echo ""

echo ""
echo "===== Resolve Advertised Server IP ====="
echo ""

if [ "$CANARY_SERVER_IP" = "auto" ]; then
	echo "IP discovery enabled"
	CANARY_SERVER_IP=$(curl --fail --show-error --location \
		--connect-timeout 5 --max-time 15 \
		https://ifconfig.me/ip)
	echo "Discovered IP: $CANARY_SERVER_IP"
else
	echo "IP discovery disabled"
fi

echo ""
echo "================================"
echo ""

echo ""
echo "===== Apply Server Configuration ====="
echo ""

set_lua_string "mysqlHost" "$CANARY_DB_HOST"
set_lua_string "mysqlUser" "$CANARY_DB_USER"
set_lua_string "mysqlPass" "$CANARY_DB_PASSWORD"
set_lua_number "mysqlPort" "$CANARY_DB_PORT"
set_lua_string "mysqlDatabase" "$CANARY_DB_NAME"
set_lua_string "serverName" "$CANARY_SERVER_NAME"
set_lua_string "serverMotd" "Welcome to $CANARY_SERVER_NAME!"
set_lua_string "ip" "$CANARY_SERVER_IP"
set_lua_string "location" "$CANARY_SERVER_LOCATION"
set_lua_string "url" "$CANARY_SERVER_URL"
set_lua_string "ownerName" "$CANARY_OWNER_NAME"
set_lua_string "ownerEmail" "$CANARY_OWNER_EMAIL"
set_lua_number "maxPlayers" "$CANARY_MAX_PLAYERS"
set_lua_number "loginProtocolPort" "$CANARY_LOGIN_PORT"
set_lua_number "gameProtocolPort" "$CANARY_GAME_PORT"
set_lua_number "statusProtocolPort" "$CANARY_STATUS_PORT"
set_lua_number "statusTimeout" "$CANARY_STATUS_TIMEOUT"
set_lua_string "dataPackDirectory" "$CANARY_DATA_PACK"
set_lua_string "mapDownloadUrl" "$CANARY_MAP_URL"
set_lua_string "authType" "$CANARY_AUTH_TYPE"
set_lua_string "coinImagesURL" "$CANARY_COIN_IMAGES_URL"

echo "config.lua updated"

echo ""
echo "================================"
echo ""

echo ""
echo "===== Copy Server Configuration And Data Pack To Shared Folder ====="
echo ""

mkdir -p /data/server
install -m 0644 config.lua /data/server/config.lua
cp -r data/ /data/server/
cp -r "$CANARY_DATA_PACK"/ /data/server/

echo ""
echo "================================"
echo ""

echo ""
echo "===== Start Server ====="
echo ""

ulimit -c unlimited
exec canary
