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
  trainers[leader.id] = { index = leader.class, parties = { [1] = { {
    species = "MON_" .. leader.id, level = 10 + index, moves = { "TACKLE" },
  } } } }
  maps[leader.map] = { objects = { { index = objectIndex, sprite = "SPRITE_" .. leader.id } } }
  npcs[leader.map .. ":" .. objectIndex] = { def = {} }
end

local options = {
  randomize_leaders=false, randomize_teams=false, randomize_levels=false,
  level_variation=3, preserve_theme=false, enforce_stage=false,
  randomize_moves=false, randomize_held_items=false,
  rebuild_action=false, challenge_log_action=false,
}
local game = {
  data = { pokemon = {}, items = {}, gen2Maps = {} },
  save = { options = { modOptions = {} }, player = { badges = {}, kantoBadges = {} } },
  stack = { push=function() end, pop=function() end },
}
local function emit(name, payload)
  for _, fn in ipairs(callbacks.events[name] or {}) do fn(payload) end
end
local mod = {
  id="randomized_gym_challenge", game=game,
  options={ define=function(_, schema) callbacks.schema=schema end, get=function(_, key) return options[key] end },
  ui={ insertStepAfter=function(steps, anchor, row)
    assert(anchor == "name_player", "Gym Challenge prompt must follow naming")
    table.insert(steps, row)
  end },
  content={
    trainers={ get=function(_, id) return trainers[id] end, each=function() return pairs(trainers) end },
    maps={ get=function(_, id) return maps[id] end },
    pokemon={ get=function(_, id) return { evolutions={}, types={} } end, each=function() return pairs({}) end },
    items={ each=function() return pairs({}) end },
    sprites={ get=function(_, id) return { id=id } end },
    type_chart={ get=function() return nil end },
  },
  save={ get=function(_, key) return storage[key] end, set=function(_, key, value) storage[key]=value end },
  world={
    npc=function(_, mapId, index) return { npc=npcs[mapId .. ":" .. tostring(index)] } end,
    nurseHeal=function(_, done)
      game.healCalls = (game.healCalls or 0) + 1
      if done then done() end
      return true
    end,
    warpTo=function(_, mapId, x, y, facing, opts)
      game.lastWarp={ mapId=mapId, x=x, y=y, facing=facing, opts=opts }
      return true
    end,
  },
  hooks={ wrap=function(_, name, fn) callbacks.hooks[name]=fn end },
  events={ on=function(_, name, fn) callbacks.events[name]=callbacks.events[name] or {}; table.insert(callbacks.events[name], fn) end },
  log={ info=function() end, warn=function() end, error=function() end },
}

assert(loadfile("main.lua"))()(mod)
assert(#callbacks.schema == 10, "challenge option schema changed")

-- The shared post-name prompt stores only an affirmative answer. It must be
-- injected before an intro starts and leave the new save unmodified until the
-- intro actually finishes.
local steps = callbacks.hooks["intro.oak_speech.build"](function(current) return current end, { { id="name_player" } }, {})
assert(steps[2].id == "gym_challenge_opt_in" and steps[2].kind == "yesno", "Gym Challenge prompt was not inserted after player naming")
emit("intro.oak_speech.answered", { saveKey="gym_challenge_opt_in", value=true })
emit("intro.oak_speech.finished", {})
local state = assert(storage.gym_challenge_state, "accepted Gym Challenge did not create per-save state")
assert(state.phase == "johto" and state.starterRoutePending, "Gold challenge did not begin in the Johto starter phase")

-- The first map event routes to native Elm’s Lab. No undocumented Gold event
-- flag is written; the actual starter script remains responsible for completion.
emit("map.entered", { mapId="NEW_BARK_TOWN", via="boot" })
assert(game.lastWarp and game.lastWarp.mapId == "ELMS_LAB", "accepted Gold Gym Challenge did not route to Elm's Lab")
state = storage.gym_challenge_state
assert(state.awaitingStarter and not state.starterLeveled, "native Gold starter state was not armed")

-- Falkner's highest vanilla level is 11 in this fixture. A neutral starter is
-- therefore set to 13, then native script completion heals and warps to Violet.
local given
callbacks.hooks["script.command"](function(_, _, _, command) given=command; return command end,
  { scriptKey="60:40c6" }, "givepoke", {}, { species="CHIKORITA", level=5 })
assert(given and given.level == 13, "neutral Gym Challenge starter level was not first-gym baseline plus two")
state = storage.gym_challenge_state
assert(state.starterLeveled and state.pendingWarp == "FALKNER", "Gold starter handoff did not queue the first gym")
emit("script.ended", { completed=true })
assert(game.healCalls == 1 and game.lastWarp.mapId == "VIOLET_CITY", "starter completion did not heal and warp to the first gym")

-- A physical badge becomes visible only after native reward resolution. The
-- next completed script therefore advances from Falkner to Bugsy, not on battle start.
game.save.player.badges.ZEPHYR = true
emit("script.ended", { completed=true })
state = storage.gym_challenge_state
assert(state.completed.FALKNER and game.lastWarp.mapId == "AZALEA_TOWN", "post-reward Gold gym progression did not move to Bugsy")

-- The first Champion win remains entirely native through induction and credits.
-- Kanto routing occurs only on the saved post-credits Continue boot in New Bark.
state.phase, state.championDefeated, state.completed = "league1", false, {}
storage.gym_challenge_state = state
emit("battle.ended", { result="win", battle={ trainer={ classId="CHAMPION" } } })
emit("map.entered", { mapId="HALL_OF_FAME", via="warp" })
state = storage.gym_challenge_state
assert(state.phase == "league1" and state.championDefeated, "Gold Kanto phase started before the native Hall of Fame sequence completed")
emit("map.entered", { mapId="NEW_BARK_TOWN", via="boot" })
state = storage.gym_challenge_state
assert(state.phase == "kanto" and game.lastWarp.mapId == "PEWTER_CITY", "post-credits Continue did not begin the Gold Kanto gym phase")

print("randomized gym challenge Gold Gym Challenge opt-in, starter, reward, and Kanto-handoff harness: valid")
