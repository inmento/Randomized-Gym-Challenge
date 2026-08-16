local callbacks, storage, trainers, maps, npcs, mapScripts = { hooks = {}, events = {} }, {}, {}, {}, {}, {}

package.preload["src.core.GameVersion"] = function()
  return { get = function() return "red" end }
end
package.preload["data.scripts.victories"] = function()
  return {
    ["OPP_BROCK#1"]={ badge="BOULDERBADGE" }, ["OPP_MISTY#1"]={ badge="CASCADEBADGE" },
    ["OPP_LT_SURGE#1"]={ badge="THUNDERBADGE" }, ["OPP_ERIKA#1"]={ badge="RAINBOWBADGE" },
    ["OPP_KOGA#1"]={ badge="SOULBADGE" }, ["OPP_SABRINA#1"]={ badge="MARSHBADGE" },
    ["OPP_BLAINE#1"]={ badge="VOLCANOBADGE" }, ["OPP_GIOVANNI#3"]={ badge="EARTHBADGE" },
  }
end
package.preload["src.render.SpriteRenderer"] = function()
  return { setSpriteSheet = function() end }
end
package.preload["src.render.TextBox"] = function()
  return { new=function(_, text, done, opts) return { text=text, done=done, choice=opts and opts.choice } end }
end
package.preload["src.inventory.Bag"] = function()
  return { add=function(save, itemId)
    if save.blockGuideBag then return false end
    save.inventory[itemId] = (save.inventory[itemId] or 0) + 1
    return true
  end }
end

local gyms = {
  { id="OPP_BROCK", map="PEWTER_GYM", party=1 }, { id="OPP_MISTY", map="CERULEAN_GYM", party=1 },
  { id="OPP_LT_SURGE", map="VERMILION_GYM", party=1 }, { id="OPP_ERIKA", map="CELADON_GYM", party=1 },
  { id="OPP_KOGA", map="FUCHSIA_GYM", party=1 }, { id="OPP_SABRINA", map="SAFFRON_GYM", party=1 },
  { id="OPP_BLAINE", map="CINNABAR_GYM", party=1 }, { id="OPP_GIOVANNI", map="VIRIDIAN_GYM", party=3 },
}
for index, gym in ipairs(gyms) do
  trainers[gym.id] = { parties = { [gym.party] = { { species="MON_" .. gym.id, level=9 + index, moves={ "TACKLE" } } } } }
  trainers["NPC_" .. gym.id] = { parties = { [1] = { { species="NPC_MON_" .. gym.id, level=6 + index } } } }
  maps[gym.map] = { label=gym.map, objects={
    { index=1, sprite="SPRITE_" .. gym.id, text="LEADER_" .. gym.id },
    { index=2, sprite="SPRITE_TRAINER", text="TRAINER_" .. gym.id, trainerClass="NPC_" .. gym.id, trainerParty=1 },
    { index=3, sprite="SPRITE_GYM_GUIDE", text="GUIDE_" .. gym.id },
  } }
  npcs[gym.map .. ":1"] = { id="leader:" .. gym.map, def={}, facePlayer=function() end }
  npcs[gym.map .. ":2"] = { id="trainer:" .. gym.map, def={}, facePlayer=function() end }
  npcs[gym.map .. ":3"] = { id="guide:" .. gym.map, def={ index=3, sprite="SPRITE_GYM_GUIDE" }, facePlayer=function() end }
end

local typeRows, monTypes = {}, {}

local options = {
  randomize_leaders=false, randomize_teams=false, randomize_levels=false,
  level_variation=3, preserve_theme=false, enforce_stage=false,
  randomize_moves=false, randomize_held_items=false,
  rebuild_action=false, challenge_log_action=false,
}
local game
game = {
  data={ text={}, pokemon={}, items={}, trainerHeader=function(_, mapId, objectIndex)
    return { battle="BATTLE_" .. mapId .. objectIndex, won="WON_" .. mapId .. objectIndex, after="AFTER_" .. mapId .. objectIndex }
  end },
  save={ options={ modOptions={} }, flags={}, inventory={}, defeatedTrainers={}, party={ {
    species="BULBASAUR", level=5, hp=20, dvs={}, statExp={}, stats={ hp=20 },
  } } },
  stack={
    push=function(_, box)
      if box.choice then game.pendingChoice=box.choice
      elseif box.done then box.done() end
    end,
    pop=function() end,
  },
  world={ map={ id="PALLET_TOWN" } },
}
local function emit(name, payload)
  for _, fn in ipairs(callbacks.events[name] or {}) do fn(payload) end
end
local mod = {
  id="randomized_gym_challenge", game=game,
  options={ define=function(_, schema) callbacks.schema=schema end, get=function(_, key) return options[key] end },
  ui={ insertStepAfter=function(steps, anchor, row) assert(anchor == "name_player"); table.insert(steps, row) end },
  content={
    trainers={ get=function(_, id) return trainers[id] end, each=function() return pairs(trainers) end },
    maps={ get=function(_, id) return maps[id] end },
    pokemon={ get=function(_, id) return { evolutions={}, types=monTypes[id] or {} } end, each=function() return pairs({}) end },
    items={
      get=function(_, id) return { id=id, name=id, index=1 } end,
      each=function() return pairs({}) end,
    },
    sprites={ get=function(_, id) return { id=id } end },
    type_chart={ get=function(_, id) return typeRows[id] end },
    map_scripts={ register=function(_, mapId, row)
      mapScripts[mapId] = mapScripts[mapId] or {}
      table.insert(mapScripts[mapId], row)
    end },
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
      game.world.map={ id=mapId }
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
assert(not callbacks.hooks["intro.oak_speech.build"], "Gym Challenge must not alter Oak's introduction")

-- The offer appears only after the player has a starter, defeats the native
-- Oak's Lab rival, and the native victory script writes its completion flag.
game.world.map={ id="OAKS_LAB" }
emit("script.ended", { completed=true })
assert(not game.pendingChoice and not storage.gym_challenge_state,
  "Gym Challenge offered before the Oak's Lab rival was defeated")
emit("battle.ended", { result="win", battle={ trainer={ classId="RIVAL1" } } })
assert(not game.pendingChoice, "Gym Challenge offered before the native rival script completed")
game.save.flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB = true
emit("script.ended", { completed=true })
assert(game.pendingChoice and not storage.gym_challenge_state,
  "Gen 1 Gym Challenge offer did not wait for the completed Oak's Lab rival battle")
game.pendingChoice(true)
local state = assert(storage.gym_challenge_state, "accepted Gen 1 Gym Challenge did not create state")
assert(state.acceptedPostIntro and state.starterLeveled and state.pendingWarp == nil,
  "accepted Gen 1 challenge did not finalize its starter state")
assert(game.save.party[1].level == 12, "neutral Gen 1 starter was not raised to the first-gym baseline")
assert(game.healCalls == 1 and game.lastWarp and game.lastWarp.mapId == "PEWTER_CITY",
  "accepted Gen 1 Gym Challenge did not heal and warp to Pewter")

-- A non-battling Gym Guide keeps its native talk first, then grants one
-- deterministic, non-junk encouragement item. A full bag leaves the reward
-- unclaimed so the player may retry that guide later.
local brockGuide = npcs["PEWTER_GYM:3"]
emit("world.interacted", { mapId="PEWTER_GYM", kind="npc", target=brockGuide })
emit("screen.popped", {})
state = storage.gym_challenge_state
local brockReward = assert(state.guideRewards.OPP_BROCK, "Gen 1 Gym Guide did not grant an encouragement reward")
assert(game.save.inventory[brockReward] == 1, "Gen 1 Gym Guide reward did not use safe bag insertion")
emit("world.interacted", { mapId="PEWTER_GYM", kind="npc", target=brockGuide })
emit("screen.popped", {})
assert(game.save.inventory[brockReward] == 1, "Gen 1 Gym Guide reward was granted more than once")

game.save.blockGuideBag = true
local mistyGuide = npcs["CERULEAN_GYM:3"]
emit("world.interacted", { mapId="CERULEAN_GYM", kind="npc", target=mistyGuide })
emit("screen.popped", {})
assert(not storage.gym_challenge_state.guideRewards.OPP_MISTY, "full Gen 1 bag incorrectly consumed a Gym Guide reward")
game.save.blockGuideBag = false
emit("world.interacted", { mapId="CERULEAN_GYM", kind="npc", target=mistyGuide })
emit("screen.popped", {})
assert(storage.gym_challenge_state.guideRewards.OPP_MISTY, "Gen 1 Gym Guide reward could not be retried after bag-full")

-- The physical badge appears only after the native gym reward. The registered
-- onVictory callback then heals and routes to Cerulean; unrelated trainer wins
-- leave state unchanged because no physical badge is present.
game.save.inventory.BOULDERBADGE = true
local fired = false
for _, row in ipairs(mapScripts.PEWTER_GYM or {}) do
  if row.onVictory then row.onVictory(game, game.world); fired=true end
end
assert(fired, "Gen 1 gym reward callback was not registered")
state = storage.gym_challenge_state
assert(state.completed.OPP_BROCK and game.lastWarp.mapId == "CERULEAN_CITY" and game.healCalls == 2,
  "Gen 1 physical gym reward did not advance, heal, and route to Misty")

print("randomized gym challenge Gen 1 Gym Challenge prompt, guide rewards, starter, and post-reward routing harness: valid")
