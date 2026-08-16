local callbacks, storage, trainers, maps, npcs = { hooks = {}, events = {} }, {}, {}, {}, {}

package.preload["src.core.GameVersion"] = function()
  return { get = function() return "gold" end }
end
package.preload["src.render.TextBox"] = function()
  return { new=function(_, text, done, opts) return { text=text, done=done, choice=opts and opts.choice } end }
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
  if leader.id == "FALKNER" then
    table.insert(maps[leader.map].objects, { index=2, sprite="SPRITE_GYM_GUIDE", scriptKey="56:41bc" })
    npcs[leader.map .. ":2"] = { def={ index=2, sprite="SPRITE_GYM_GUIDE" } }
  end
  npcs[leader.map .. ":" .. objectIndex] = { def = {} }
end

local options = {
  randomize_leaders=false, randomize_teams=false, randomize_levels=false,
  level_variation=3, preserve_theme=false, enforce_stage=false,
  randomize_moves=false, randomize_held_items=false,
  rebuild_action=false, challenge_log_action=false,
  challenge_progress_action=false, challenge_hint_action=false, difficulty_preset="MANUAL",
}
local game
game = {
  data = { pokemon = {}, items = {}, gen2Maps = {} },
  save = { options = { modOptions = {} }, flags={}, player = { badges = {}, kantoBadges = {} }, inventory={}, party={ {
    species="CHIKORITA", level=5, hp=20, dvs={}, statExp={}, stats={ hp=20 },
  } } },
  stack = {
    push=function(_, box)
      if box.choice then game.pendingChoice=box.choice
      elseif box.done then box.done() end
    end,
    pop=function() end,
  },
  world = {
    map={ id="NEW_BARK_TOWN" },
    giveItem=function(_, index)
      if game and game.save.blockGuideBag then return false end
      local id = "ITEM_" .. tostring(index)
      game.save.inventory[id] = (game.save.inventory[id] or 0) + 1
      return true
    end,
    showText=function(_, _, done) if done then done() end end,
  },
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
    items={
      get=function(_, id) return { id=id, name=id, index=7 } end,
      each=function() return pairs({}) end,
    },
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
assert(#callbacks.schema == 13, "challenge option schema changed")
local schemaKeys = {}
for _, row in ipairs(callbacks.schema) do schemaKeys[row.key] = true end
assert(schemaKeys.challenge_progress_action and schemaKeys.challenge_hint_action
  and schemaKeys.difficulty_preset, "progress, hint, and preset options are missing")

assert(not callbacks.hooks["intro.oak_speech.build"], "Gym Challenge must not alter Gold's introduction")

-- Gold receives the offer only after the player has their starter, returns to
-- Elm's Lab, and completes the native Mystery Egg handoff to Elm.
game.world.map={ id="ELMS_LAB" }
game.save.flags.EVENT_GOT_A_POKEMON_FROM_ELM = true
emit("script.ended", { completed=true })
assert(not game.pendingChoice and not storage.gym_challenge_state,
  "Gold Gym Challenge offered before the Mystery Egg was handed to Elm")
game.save.flags.EVENT_GAVE_MYSTERY_EGG_TO_ELM = true
emit("script.ended", { completed=true })
assert(game.pendingChoice and not storage.gym_challenge_state,
  "Gold Gym Challenge did not offer after the Mystery Egg handoff to Elm")
game.pendingChoice(true)
local state = assert(storage.gym_challenge_state, "accepted Gold Gym Challenge did not create per-save state")
assert(state.phase == "johto" and state.acceptedPostIntro and state.starterLeveled,
  "Gold challenge did not begin after the completed Elm milestone")
assert(game.save.party[1].level == 13, "neutral Gold starter was not raised to the first-gym baseline")
assert(game.healCalls == 1 and game.lastWarp and game.lastWarp.mapId == "VIOLET_CITY",
  "accepted Gold Gym Challenge did not heal and warp to Violet City")

-- Falkner's live non-battling Gym Guide grants one weighted encouragement item
-- after the native guide script ends. It is never granted twice.
emit("map.entered", { mapId="VIOLET_GYM", via="warp" })
local falknerGuide = npcs["VIOLET_GYM:2"]
emit("world.interacted", { mapId="VIOLET_GYM", kind="npc", target=falknerGuide })
emit("script.ended", { completed=true })
state = storage.gym_challenge_state
local falknerReward = assert(state.guideRewards.FALKNER, "Gold Gym Guide did not grant its encouragement reward")
assert(game.save.inventory.ITEM_7 == 1, "Gold Gym Guide reward did not use Gold item insertion")
emit("world.interacted", { mapId="VIOLET_GYM", kind="npc", target=falknerGuide })
emit("script.ended", { completed=true })
assert(game.save.inventory.ITEM_7 == 1, "Gold Gym Guide reward was granted more than once")

-- A physical badge becomes visible only after native reward resolution. The
-- next completed script therefore advances from Falkner to Bugsy, not on battle start.
game.save.player.badges.ZEPHYR = true
emit("script.ended", { completed=true })
state = storage.gym_challenge_state
assert(state.completed.FALKNER and game.lastWarp.mapId == "AZALEA_TOWN", "post-reward Gold gym progression did not move to Bugsy")

-- Bugsy's fixture has no Gym Guide object, so the leader fallback grants the
-- same kind of reward before the existing heal-and-warp flow proceeds.
emit("map.entered", { mapId="AZALEA_GYM", via="warp" })
game.save.player.badges.HIVE = true
emit("script.ended", { completed=true })
state = storage.gym_challenge_state
assert(state.guideFallback.BUGSY and state.guideRewards.BUGSY, "Gold guide-less gym did not use the leader fallback reward")
assert(game.save.inventory.ITEM_7 == 2 and game.lastWarp.mapId == "GOLDENROD_CITY", "Gold leader fallback did not award before routing onward")

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

print("randomized gym challenge Gold Gym Challenge opt-in, guide rewards, starter, and Kanto-handoff harness: valid")
