# Neomacs
a combination of many small projects I have worked on

- zano: fork of cano, rewritten in zig
- imvr/zimv: image viewer based on imv

Overall, this project aims to be everything but a web browser. And you should
(eventually) be able to run a system with only busybox, this, ssh and firefox
installed.

# Devolopment

## Keybinds
I think I should modify the current system to use a chording thing were each
new press is just a pointer dereference to a new key map. Also, I think it
would be cool if key maps optionally returned a target so the yank delete and
replace motions could be generalized to user defined motions. If a target is
returned to the root then it moves there. I think this would be a very small
breaking change for some obscure keys but a net good for things. Although first
I should just implement the basics.
