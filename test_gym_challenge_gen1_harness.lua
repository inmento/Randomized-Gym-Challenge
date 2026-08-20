local callbacks, storage, trainers, maps, npcs, mapScripts = { hooks = {}, events = {} }, {}, {}, {}, {}, {}

package.preload["src.core.GameVersion"] = function()
  return {
    get = function() return "red" end,
    generation = function(id) return (id == "gold" or id == "silver") and 2 or 1 end,
  }
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
  data={ text={}, pokemon={}, items={}, trainer_headers={}, trainerHeader=function(self, mapId, objectIndex)
    self.trainer_headers[mapId] = self.trainer_headers[mapId] or {}
    self.trainer_headers[mapId][objectIndex] = self.trainer_headers[mapId][objectIndex]
      or { battle="BATTLE_" .. mapId .. objectIndex, won="WON_" .. mapId .. objectIndex, after="AFTER_" .. mapId .. objectIndex }
    return self.trainer_headers[mapId][objectIndex]
  end },
  save={ options={ modOptions={} }, flags={}, inventory={}, defeatedTrainers={}, party={ {
    species="BULBASAUR", level=5, hp=7, dvs={}, statExp={}, stats={ hp=20 }, moves={ { id="TACKLE", pp=7 } },
  } } },
  stack={
    push=function(_, box)
      game.lastText = box.text
      game.shownTexts = game.shownTexts or {}
      game.shownTexts[#game.shownTexts + 1] = box.text
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
  ui={ insertStepAfter=function(steps, anchor, row)
    assert(anchor == "name_player")
    local index
    for i, step in ipairs(steps) do if step.id == anchor then index = i; break end end
    table.insert(steps, (index or #steps) + 1, row)
    return steps
  end },
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
      if game.failWarp then return false, "TEST WARP FAILURE" end
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
assert(#callbacks.schema == 14, "challenge option schema changed")
local schemaKeys = {}
for _, row in ipairs(callbacks.schema) do schemaKeys[row.key] = true end
assert(schemaKeys.challenge_progress_action and schemaKeys.challenge_hint_action
  and schemaKeys.abandon_challenge_action and schemaKeys.difficulty_preset,
  "progress, hint, abandon, and preset options are missing")
assert(callbacks.hooks["intro.oak_speech.build"],
  "Gym Challenge did not install the supported post-name opt-in step")
local introSteps = callbacks.hooks["intro.oak_speech.build"](function(steps) return steps end, {
  { id="name_player", kind="name" }, { id="confirm_player_name", kind="say" },
})
assert(introSteps[2] and introSteps[2].id == "gym_challenge_opt_in"
  and introSteps[2].kind == "yesno" and introSteps[2].defaultNo == true,
  "Gym Challenge opt-in was not inserted immediately after player naming")
emit("intro.oak_speech.answered", { step=introSteps[2], value=true })
assert(storage.gym_challenge_opt_in == true and storage.gym_challenge_offer_seen_v2 == true,
  "accepting the post-name Gym Challenge opt-in did not arm the new save")
for mapId, rows in pairs(mapScripts) do
  for _, row in ipairs(rows) do
    for textId in pairs(row.talk or {}) do
      assert(not tostring(textId):match("^TRAINER_"),
        "support trainer " .. tostring(textId) .. " was given a talk override and lost sight-line engagement on " .. tostring(mapId))
    end
  end
end

-- The early opt-in changes no gameplay during the native opening. It is consumed
-- only after the player has a starter, defeated the native Oak's Lab rival, and
-- completed the later Oak's Parcel/Pokédex cutscene.
game.world.map={ id="OAKS_LAB" }
emit("script.ended", { completed=true })
assert(not game.pendingChoice and not storage.gym_challenge_state,
  "Gym Challenge offered before the Oak's Lab rival was defeated")
emit("battle.ended", { result="win", battle={ oppClass="OPP_RIVAL1", trainer={} } })
assert(not game.pendingChoice, "Gym Challenge offered before the native rival script completed")
game.save.flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB = true
emit("script.ended", { completed=true })
assert(not game.pendingChoice,
  "Gym Challenge offered before Oak received the parcel and gave the Pokédex")
game.save.flags.EVENT_OAK_GOT_PARCEL = true
game.save.flags.EVENT_GOT_POKEDEX = true
local oakParcelContext = {}
assert(callbacks.hooks["script.command"], "Gym Challenge did not install the native parcel completion hook")
callbacks.hooks["script.command"](function(ctx, name, args)
  assert(ctx == oakParcelContext and name == "set_flag"
    and args[1] == "EVENT_ROUTE22_RIVAL_WANTS_BATTLE", "wrong native parcel command")
  game.save.flags[args[1]] = true
end, oakParcelContext, "set_flag", { "EVENT_ROUTE22_RIVAL_WANTS_BATTLE" })
assert(not game.pendingChoice, "Gym Challenge offered before the native Oak parcel script finished")
for _, afterScript in ipairs(oakParcelContext.afterScript or {}) do afterScript() end
assert(not game.pendingChoice,
  "Gen 1 Gym Challenge displayed a second Oak prompt instead of consuming the early opt-in")
local state = assert(storage.gym_challenge_state,
  "accepted early opt-in did not start the Gen 1 Gym Challenge after the completed Oak handoff")
assert(state.acceptedPostIntro and state.starterLeveled and state.pendingWarp == nil,
  "accepted Gen 1 challenge did not finalize its starter state")
assert(game.save.party[1].level == 12, "neutral Gen 1 starter was not raised to the first-gym baseline")
assert((game.healCalls or 0) == 0 and game.lastWarp and game.lastWarp.mapId == "PEWTER_CITY",
  "accepted Gen 1 Gym Challenge did not use HP-only recovery and warp to Pewter")
assert(game.save.party[1].hp == game.save.party[1].stats.hp and game.save.party[1].moves[1].pp == 7,
  "accepted Gen 1 Gym Challenge did not restore HP while preserving move PP")
assert(state.lastRoute and state.lastRoute.status == "WARPED" and state.lastRoute.gym == "OPP_BROCK",
  "accepted Gen 1 Gym Challenge did not record its first-gym route status")
assert(game.lastText and game.lastText:find("FIRST GYM: BROCK", 1, true)
  and game.lastText:find("PRESET: MANUAL", 1, true),
  "accepted Gen 1 Gym Challenge did not display its reproducible start summary")
local explained
for _, text in ipairs(game.shownTexts or {}) do
  if text:find("GYM CHALLENGE\nBEGINS NOW!", 1, true) then explained = true; break end
end
assert(explained,
  "accepted Gen 1 Gym Challenge did not explain the challenge before routing to Pewter")

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
-- onVictory callback must offer a player choice. Choosing Yes restores HP only
-- and routes to Cerulean; unrelated trainer wins leave state unchanged because
-- no physical badge is present.
game.save.party[1].hp, game.save.party[1].moves[1].pp = 3, 4
game.save.inventory.BOULDERBADGE = true
local fired = false
for _, row in ipairs(mapScripts.PEWTER_GYM or {}) do
  if row.onVictory then row.onVictory(game, game.world); fired=true end
end
assert(fired and game.pendingChoice, "Gen 1 gym reward did not offer route continuation")
game.pendingChoice(true)
state = storage.gym_challenge_state
assert(state.completed.OPP_BROCK and game.lastWarp.mapId == "CERULEAN_CITY" and (game.healCalls or 0) == 0,
  "Gen 1 physical gym reward did not route to Misty through HP-only recovery")
assert(game.save.party[1].hp == game.save.party[1].stats.hp and game.save.party[1].moves[1].pp == 4,
  "Gen 1 post-gym continuation restored PP instead of HP only")

-- A failed engine warp must never advance native story state or lose the next
-- destination. The challenge pauses with a diagnostic until the player checks
-- status or abandons it deliberately.
game.failWarp = true
game.save.inventory.CASCADEBADGE = true
for _, row in ipairs(mapScripts.CERULEAN_GYM or {}) do if row.onVictory then row.onVictory(game, game.world) end end
assert(game.pendingChoice, "second Gen 1 gym reward did not offer route continuation")
game.pendingChoice(true)
state = storage.gym_challenge_state
assert(state.completed.OPP_MISTY and state.pendingWarp == "OPP_LT_SURGE"
  and state.lastRoute and state.lastRoute.status == "PAUSED",
  "failed Gen 1 route did not preserve a paused diagnostic state")
assert(game.lastWarp.mapId == "CERULEAN_CITY", "failed Gen 1 route changed the player destination")
game.failWarp = false

-- A player who declines the immediate route can heal at a Pokémon Center and
-- later ask the same physical Gym Guide to continue. The deferred path must
-- show the same choice and preserve PP exactly as the immediate path does.
game.save.party[1].hp, game.save.party[1].moves[1].pp = 2, 3
game.world.map = { id="CERULEAN_GYM" }
emit("world.interacted", { mapId="CERULEAN_GYM", kind="npc", target=mistyGuide })
emit("screen.popped", {})
assert(game.pendingChoice, "completed gym guide did not offer deferred route continuation")
game.pendingChoice(true)
state = storage.gym_challenge_state
assert(game.lastWarp.mapId == "VERMILION_CITY" and game.save.party[1].hp == game.save.party[1].stats.hp
  and game.save.party[1].moves[1].pp == 3,
  "Gym Guide continuation did not route with HP-only recovery")

-- The eighth badge routes to the south end of Route 23, before every native
-- badge guard and the Victory Road cave entrance, never directly to the league.
for _, badge in ipairs({ "THUNDERBADGE", "RAINBOWBADGE", "SOULBADGE", "MARSHBADGE", "VOLCANOBADGE", "EARTHBADGE" }) do
  game.save.inventory[badge] = true
end
for _, row in ipairs(mapScripts.VIRIDIAN_GYM or {}) do if row.onVictory then row.onVictory(game, game.world) end end
assert(game.pendingChoice, "eighth badge did not offer the Victory Road handoff")
game.pendingChoice(true)
state = storage.gym_challenge_state
assert(state.phase == "victory_road" and game.lastWarp.mapId == "ROUTE_23"
  and game.lastWarp.x == 7 and game.lastWarp.y == 138,
  "eighth badge did not route to the Route 23 badge-guard approach")

-- Abandoning is confirmation-gated and clears only Gym Challenge state plus
-- its generated plan; native badges, party, and inventory remain untouched.
local savedBadge, savedLevel, savedReward = game.save.inventory.BOULDERBADGE, game.save.party[1].level, game.save.inventory[brockReward]
emit("mod.options_changed", { mod=mod.id, key="abandon_challenge_action", value=true })
assert(game.pendingChoice, "abandon action did not request confirmation")
game.pendingChoice(false)
assert(storage.gym_challenge_state, "declining abandon incorrectly cleared challenge state")
emit("mod.options_changed", { mod=mod.id, key="abandon_challenge_action", value=true })
game.pendingChoice(true)
assert(not storage.gym_challenge_state and not storage.challenge_plan,
  "confirmed abandon did not clear only challenge-owned save state")
assert(game.save.inventory.BOULDERBADGE == savedBadge and game.save.party[1].level == savedLevel
  and game.save.inventory[brockReward] == savedReward,
  "abandon altered native progress, party, or inventory")

-- Gen 1 no longer presents an Oak's Lab fallback prompt on an existing save:
-- the durable decision is made only in the post-name intro step, preventing a
-- missed or duplicate offer after the parcel cutscene.
storage.gym_challenge_offer_seen_v2 = nil
storage.gym_challenge_offer_pending_v2 = nil
storage.gym_challenge_opt_in = nil
game.pendingChoice = nil
game.world.map = { id="OAKS_LAB" }
game.save.flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB = true
game.save.flags.EVENT_OAK_GOT_PARCEL = true
game.save.flags.EVENT_GOT_POKEDEX = true
emit("map.entered", { mapId="OAKS_LAB", map=game.world.map })
assert(not game.pendingChoice and not storage.gym_challenge_state,
  "Gen 1 existing-save re-entry incorrectly displayed the retired Oak prompt")

print("randomized gym challenge Gen 1 hardening, routing, and recovery harness: valid")
