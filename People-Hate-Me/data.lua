require("prototypes.people")
require("prototypes.gore")
require("prototypes.settlements")
require("prototypes.positions")

local bottles = require("prototypes.bottles")
bottles.dress_goo()
bottles.dress_streams(bottles.chosen_landing())
