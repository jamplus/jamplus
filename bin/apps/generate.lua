package.path = (debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. "/../scripts/?.lua;" .. package.path
require 'Generate'
