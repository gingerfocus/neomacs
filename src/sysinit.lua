_G.vim = neomacs

local home = os.getenv("HOME")
local neomacsPath = home .. "/.local/share/neomacs/share/pkgs"

package.path =  neomacsPath .. "/?/init.lua;"
package.path = neomacsPath .. "/?/lua/?.lua;" .. package.path
package.path = "?.lua;" .. package.path

-- package.path = home .. "/dev/neomacs/config/lua/?.lua;" .. package.path
package.path = home .. "/.config/neomacs/lua/?.lua;" .. package.path

-- require(home .. "/dev/neomacs/config/init")
require(home .. "/.config/neomacs/init")
