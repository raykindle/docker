#!/bin/bash
/usr/bin/expect <<EOF
set timeout -1
set passwd simon
spawn jupyter notebook password
expect {
    "password:" {send "$passwd\n"; exp_continue}
    "password:" {send "$passwd\n"; exp_continue}
}
EOF
