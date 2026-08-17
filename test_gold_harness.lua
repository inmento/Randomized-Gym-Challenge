local callbacks, storage, trainers, maps, npcs = { hooks = {}, events = {} }, {}, {}, {}, {}

package.preload["src.core.GameVersion"] = function()
  return { get = function() return "gold" end }
end

local leaders = {
  { id="FALKNER", map="VIOLET_GYM", class=1 }, { id="BUGSY", map="AZALEA_GYM", class=3 },
  { id="WHITNEY", map="GOLDENROD_GYM", class=2 }, { id="MORTY", map="ECRUTEAK_GYM", class=4 },
  { id="CHUCK", map="CIANWOOD_GYM", class=7 }, { id="JASMINE", map="OLIVINE_GYM", class=6 },
  { id="PRYCE", map="MAHOGANY_GYM", class=5 }, { id="CLAIR", map="BLACKTHORN_GYM_1F", class=8 },
  { id="BROCK", map="PEWTER_GYM", class=17 }, { id="MISTY", map="CERULEAN_GYM", class=18 },
  { id="LT_SURGE", map="VERMILION_GYM", class=19 }, { id="ERIKA", map="CELADON_GYM", class=21 },
  { id="JANINE", map="FUCHSIA_GYM", class=26 }, { id="SABRINA", map="SAFFRON_GYM", class=35 },
  { id="BLAINE", map="SEAFOAM_GYM", class=46 }, { id="BLUE", map="VIRIDIAN_GYM", class=64 },
}
for index, leader in ipairs(leaders) do
  local objectIndex = leader.id == "MISTY" and 2 or 1
  trainers[leader.id] = {
    index = leader.class,
    parties = { [1] = { {
      species = "MON_" .. leader.id, level = 10 + index, item = "BERRY",
      moves = { "TACKLE", "GROWL" }, dvs = { attack = index, defense = index },
      form = "ORIGINAL_FORM", customFutureField = { token = leader.id },
    } } },
  }
  maps[leader.map] = { objects = { { index = objectIndex, sprite = "SPRITE_" .. leader.id } } }
  npcs[leader.map .. ":" .. objectIndex] = { def = {} }
end

local options = {
  randomize_leaders = false, randomize_teams = false, randomize_levels = false,
  level_variation = 3, preserve_theme = false, enforce_stage = false,
  randomize_moves = false, randomize_held_items = false,
  rebuild_action = false, challenge_log_action = false,
}
local game = {
  data = { pokemon = {}, items = {}, gen2Maps = {} },
  save = { options = { modOptions = {} } },
  stack = { push = function() end, pop = function() end },
}
local mod = {
  id = "randomized_gym_challenge", game = game,
  options = {
    define = function(_, schema) callbacks.schema = schema end,
    get = function(_, key) return options[key] end,
  },
  content = {
    trainers = { get = function(_, id) return trainers[id] end, each = function() return pairs(trainers) end },
    maps = { get = function(_, id) return maps[id] end },
    pokemon = { get = function() return { evolutions = {}, types = {} } end, each = function() return pairs({}) end },
    items = { each = function() return pairs({}) end },
    sprites = { get = function(_, id) return { id = id } end },
  },
  save = { get = function(_, key) return storage[key] end, set = function(_, key, value) storage[key] = value end },
  world = {
    npc = function(_, mapId, index) return { npc = npcs[mapId .. ":" .. tostring(index)] } end,
  },
  hooks = { wrap = function(_, name, fn) callbacks.hooks[name] = fn end },
  events = { on = function(_, name, fn) callbacks.events[name] = fn end },
  log = { info = function() end, warn = function() end, error = function() end },
}

assert(loadfile("main.lua"))()(mod)
assert(#callbacks.schema == 14, "current challenge option schema was not registered")

-- Entering the first leader battle initializes one immutable, Gold-specific
-- plan. With all randomization rules off, every imported party field must
-- remain available to the battle engine unchanged.
local dispatched
callbacks.hooks["script.command"](function(_, _, _, command)
  dispatched = command
  return command
end, { scriptKey = "56:412f" }, "loadtrainer", {}, { class = 1, member = 1 })
assert(dispatched and dispatched.class == 1 and dispatched.member == 1,
  "disabled Gold leader randomization changed the native battle command")
local plan = assert(storage.challenge_plan, "Gold challenge plan was not created")
assert(plan.game == "gold" and plan.rules.randomize_held_items == false,
  "Gold plan metadata is invalid")
local count = 0
for _ in pairs(plan.gyms) do count = count + 1 end
assert(count == 16, "Gold challenge plan does not include all sixteen gyms")

local party = callbacks.hooks["trainer.party"](function(_, _, base) return base end,
  1, 1, { { species = "BASE", level = 1 } })
local mon = assert(party[1], "Gold challenge did not supply a party")
assert(mon.species == "MON_FALKNER" and mon.level == 11,
  "disabled Gold challenge rules changed base species or level")
assert(mon.item == "BERRY" and mon.moves[1] == "TACKLE" and mon.moves[2] == "GROWL",
  "legacy party-preservation check failed for vanilla held item or moves")
assert(mon.dvs.attack == 1 and mon.form == "ORIGINAL_FORM" and mon.customFutureField.token == "FALKNER",
  "legacy party-preservation check failed for nonstandard or future party fields")

-- Returned challenge parties must be deep copies; battle mutations cannot
-- corrupt the save's generated plan or change a later encounter.
mon.moves[1] = "MUTATED"
mon.customFutureField.token = "MUTATED"
callbacks.hooks["script.command"](function(_, _, _, command) return command end,
  { scriptKey = "56:412f" }, "loadtrainer", {}, { class = 1, member = 1 })
local repeatParty = callbacks.hooks["trainer.party"](function(_, _, base) return base end,
  1, 1, { { species = "BASE", level = 1 } })
assert(repeatParty[1].moves[1] == "TACKLE" and repeatParty[1].customFutureField.token == "FALKNER",
  "Gold challenge plan was mutated by a previous battle")

print("randomized gym challenge Gold sixteen-gym and party-preservation harness: valid")
