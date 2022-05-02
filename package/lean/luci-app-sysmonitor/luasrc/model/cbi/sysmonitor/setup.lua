
local m, s
local global = 'sysmonitor'
local uci = luci.model.uci.cursor()

m = Map("sysmonitor",translate("System Monitor"))

m:append(Template("sysmonitor/status"))

s = m:section(TypedSection, "sysmonitor", translate("System Settings"))
s.anonymous = true

o=s:option(Flag,"enable", translate("Enable"))
o.rmempty=false

o=s:option(Flag,"bbr", translate("BBR Enable"))
o.rmempty=false

o=s:option(Flag,"ddns", translate("ddns daemon"))
o.rmempty=false

o = s:option(Value, "homeip", translate("Home IP Address"))
--o.description = translate("IP for Home(192.168.1.1)")
o.datatype = "or(host)"
o.rmempty = false

o = s:option(Value, "vpnip", translate("VPN IP Address"))
--o.description = translate("IP for VPN Server(192.168.1.110)")
o.datatype = "or(host)"
o.rmempty = false

o=s:option(Flag,"config", translate("Keep config"))
o.rmempty=false

o = s:option(Value, translate("firmware"), translate("Firmware Address"))
--o.description = translate("Firmeware download Address)")
o.default = "https://github.com/softeduscn/Actions-openwrt-4300/releases/download/WNDR-4300/openwrt-ath79-nand-netgear_wndr4300-squashfs-sysupgrade.bin"
o.rmempty = false

return m
