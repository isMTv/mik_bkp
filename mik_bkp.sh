#!/usr/bin/env bash
# ./mik_bkp full_bkp
ROUTERS=( 172.16.1.1 172.16.2.1 172.16.3.1 172.17.4.1 172.17.5.1 )
WHAT_BKP="${1:?}" # full_bkp, rsc_bkp;
EXEC_PARALLEL_HOSTS="15"
DELAY="15s"
PROJECT="core"
BACKUP_COUNT="2" # count + 1 (new bkp)
LOGIN="username"
PRIV_KEY="/root/.ssh/username_rsa"

# - #
BACKUP_DIR="$(dirname "$(readlink -f "$0")")/$PROJECT"
FULL_DIR="${BACKUP_DIR}/$(date +%Y)/$(date +%m)/$(date +%d)"
CUR_DATE="$(date +%d-%m-%Y)"
LOG_FILE="${PROJECT}.log"
# - #

# Condition for checking the existence of a directory and cleaning it;
if [ -d "${BACKUP_DIR:?}" ]; then
    for old_bkp in "${ROUTERS[@]}"; do
        find "${BACKUP_DIR:?}" -maxdepth 4 -type f -name "${old_bkp}@*.backup" -printf '%T@ %p\n' | sort -n | awk '{print $2}' | head -n -"$BACKUP_COUNT" | xargs rm -f
        find "${BACKUP_DIR:?}" -maxdepth 4 -type f -name "${old_bkp}@*.rsc" -printf '%T@ %p\n' | sort -n | awk '{print $2}' | head -n -"$BACKUP_COUNT" | xargs rm -f
    done
    # find empty dir and specific size .log;
    find "${BACKUP_DIR:?}"/* -maxdepth 3 -type d -empty -delete
    find "${BACKUP_DIR:?}" -maxdepth 1 -name "*.log" -size +10k -exec rm -f {} \;
fi

# Condition for checking Backup dir;
[ -d "${FULL_DIR:?}" ] || mkdir -p "$FULL_DIR"

# Logger;
function logger () {
    echo -e "[$(date "+%H:%M:%S")] - [$cur_stage]: $1" | tee -a "$BACKUP_DIR/$LOG_FILE"
}

echo >> "$BACKUP_DIR/$LOG_FILE"
cur_stage="start_bkp"
logger "--- $PROJECT: $WHAT_BKP - [$CUR_DATE] ---"

# Connect via SSH;
app_ssh () {
    app_ssh_err="$(ssh -f -i "${PRIV_KEY}" -o ConnectTimeout=5 "${LOGIN}"@"${r}" "$1" 2>&1)"
}

# Connect via SCP;
app_scp () {
    app_scp_err="$(scp -i "${PRIV_KEY}" -o ConnectTimeout=5 "${LOGIN}"@"${r}":"${cmd_stage_2}" "$1" 2>&1)"
}

# What Backup CMD;
what_bkp () {
    if [ "$WHAT_BKP" = "full_bkp" ]; then
        bkp_name="${r}@${board_name}-(${arc_name})-v${cur_fw}.backup"
        cmd_stage_1="/system backup save name=\"${bkp_name}\""
        cmd_stage_2="${bkp_name}"
        cmd_stage_3="/file remove \"${bkp_name}\""
    elif [ "$WHAT_BKP" = "rsc_bkp" ]; then
        bkp_name="${r}@${board_name}-(${arc_name})-v${cur_fw}.rsc"
        cmd_stage_1="/export compact file=\"${bkp_name}\""
        cmd_stage_2="${bkp_name}"
        cmd_stage_3="/file remove \"${bkp_name}\""
    fi
}

# Create backup;
bkp () {
    # (app_ssh "/system backup save name=$r.backup" && app_scp "/mnt/data/smb/private/mik_bkp/" && app_ssh "/file remove \"$r.backup\"") &
    # awk '/1/,/3/ {print $0}' = 1,2,3 | awk '/1|3/ {print $0}' = 1,3
    (if app_ssh "/system resource print ; /system routerboard print"; then
        item_routerboard="$(echo "${app_ssh_err}" | awk '/architecture-name:|board-name:|current-firmware:/ {print $2}' | uniq | sed 's/\r//g')"
        read -d "\n" arc_name board_name cur_fw <<< "${item_routerboard}"
        err_app_ssh="false" ; cur_stage="item_routerboard" ; logger "[OK] - Host ${r}!"
        what_bkp
        if app_ssh "$cmd_stage_1"; then
            err_app_ssh="false" ; cur_stage="create_bkp" ; logger "[OK] - Host ${r}!"
            if app_scp "$FULL_DIR"; then
                err_app_scp="false" ; cur_stage="download_bkp" ; logger "[OK] - Host ${r}!"
                if app_ssh "${cmd_stage_3}"; then
                    err_app_ssh="false" ; cur_stage="remove_bkp" ; logger "[OK] - Host ${r}!"
                else
                    err_app_ssh="true" ; cur_stage="remove_bkp" ; logger "${app_ssh_err}"
                fi
            else
                err_app_scp="true" ; cur_stage="download_bkp" ; logger "${app_scp_err}"
            fi
        else
            err_app_ssh="true" ; cur_stage="create_bkp" ; logger "${app_ssh_err}"
        fi
    else
        err_app_ssh="true" ; cur_stage="item_routerboard" ; logger "${app_ssh_err}"
    fi) &
}

iteration="0"
for r in "${ROUTERS[@]}"; do
    # when to sleep;
    if [ "$iteration" = "$EXEC_PARALLEL_HOSTS" ]; then iteration="0" ; sleep "$DELAY" ; fi
    # one of the conditions must be true;
    bkp ; if [[ "$err_app_ssh" = "true" || "$err_app_scp" = "true" ]] ; then continue ; fi
    # only if the bkp is successful;
    ((iteration+=1))
done
