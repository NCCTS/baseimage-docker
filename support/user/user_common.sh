#!/bin/bash

# touch $HOME/.entry_env

rm -rf $HOME/.bash_logout

file_append () {
    echo "$1" >> "$2"
}

file_overwrite () {
    echo "$1" > "$2"
}

file_prepend () {
    local ed_cmd="1i"
    if [ ! -f "$2" ]; then
        touch "$2"
        ed_cmd="a"
    fi
    printf '%s\n' H "$ed_cmd" "$1" . w | ed -s "$2"
}

wrap_call () {
    local file_name=$1
    local base_name=$2
    local op_name=$3
    echo "file_$op_name" ":" "$(basename -- $file_name)" "->" "$my_home/$base_name"
    "file_$op_name" "$(cat $file_name)" "$my_home/$base_name"
}

my_name=$(whoami)
my_home=$(eval echo ~$my_name)

proc_home_files () {
    local home_files=( /docker-build/support/user/home_files/* )
    local over_arr=()
    local prep_arr=()
    local appn_arr=()
    for hf in "${home_files[@]}"; do
        local parts_array=( ${hf//__/ } )
        local file_name=${parts_array[0]}
        local base_name="$(basename -- $file_name | sed 's/dot\./\./')"
        local user_name=${parts_array[1]}
        local op_name=${parts_array[2]}
        if [[ "$user_name" = "$my_name" || "$user_name" = "common" ]]; then
            case "$op_name" in
                overwrite)
                    over_arr+=( $hf $base_name $op_name );;
                prepend)
                    prep_arr+=( $hf $base_name $op_name );;
                append)
                    appn_arr+=( $hf $base_name $op_name );;
            esac
        fi
    done
    op_arr=( over_arr prep_arr appn_arr )
    for oa in "${op_arr[@]}"; do
        eval _oa=( "\${$oa[@]}" )
        for (( i=0; i<${#_oa[@]} ; i+=3 )) ; do
            wrap_call ${_oa[i]} ${_oa[i+1]} ${_oa[i+2]}
        done
    done
}

proc_home_files

git clone --depth 1 https://github.com/michaelsbradleyjr/bash-it.git $HOME/.bash_it

echo will cite | parallel --bibtex
