local filename = arg[1]
loadfile(arg[1])(select(2, table.unpack(arg)))
