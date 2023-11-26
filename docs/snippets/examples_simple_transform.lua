//! [Adding dependencies]
local source = 'source.txt'
local destination = 'destination.txt'

-- all -> destination.txt -> source.txt
jam.Depends('all', destination, source)
jam.Clean('clean', destination)
//! [Adding dependencies]

