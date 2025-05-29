#!/bin/sh

case "$1" in
    "clean" | "c")
        rm -r zig-out
        ;;
    "develop" | "dev" | "d")
        [ -n "$TMUX" ] || (echo "Must be run in tmux" && exit 1)

        tmux splitw -d -h -p 30 -c "$PWD" 'tail -f neomacs.log'
        # tmux splitw -d -t 1 './mk.sh serve'
        ;;
    "" | *)
        echo "usage: $0 clean|devolop"
        exit 1
        ;;
esac

