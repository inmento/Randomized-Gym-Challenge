-- Randomized Gym Challenge
-- WIP 0.1.0-alpha.2
-- Gen 1 Recomp mod API 2
--
-- This is intentionally separate from Gym Leader Shuffle.  It uses the same
-- gym-battle seams, but generates a per-save challenge plan instead of merely
-- moving the original leader parties between buildings.

return function(mod)
  local GameVersion = require("src.core.GameVersion")
  local playing = GameVersion.get()
  local isGold = playing == "gold"

  mod.options:define({
    { key="randomize_leaders", label="RANDOMIZE GYM LEADERS", type="toggle", default=false },
    { key="randomize_teams", label="RANDOMIZE TEAM COMPOSITION", type="toggle", default=false },
    { key="randomize_levels", label="RANDOMIZE LEVELS", type="toggle", default=false },
    { key="level_variation", label="LEVEL VARIATION", type="number", default=3, min=1, max=8, step=1 },
    { key="preserve_theme", label="PRESERVE GYM TYPE THEME", type="toggle", default=false },
    { key="enforce_stage", label="ENFORCE EVOLUTION STAGE", type="toggle", default=false },
    { key="randomize_moves", label="RANDOMIZE MOVESETS", type="toggle", default=false },
    { key="randomize_held_items", label="RANDOMIZE HELD ITEMS (GOLD)", type="toggle", default=false },
    { key="rebuild_action", label="REBUILD CHALLENGE (TEST)", type="toggle", default=false },
    { key="challenge_log_action", label="OPEN CHALLENGE LOG", type="toggle", default=false },
  })

  local function clone(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, inner in pairs(value) do out[key] = clone(inner) end
    return out
  end

  -- Keep all generated choices reproducible after save/load.  This is not a
  -- battle RNG replacement: it is only used while writing a challenge plan.
  local MODULUS = 2147483647
  local function hash(text, base)
    local state = math.floor(tonumber(base) or 1) % (MODULUS - 1) + 1
    text = tostring(text or "")
    for i = 1, #text do
      state = (state * 48271 + text:byte(i) + i * 97) % MODULUS
      if state == 0 then state = 1 end
    end
    return state
  end

  local function pick(list, key, seed)
    if type(list) ~= "table" or #list == 0 then return nil end
    return list[(hash(key, seed) % #list) + 1]
  end

  local function shuffle(list, key, seed)
    local out = {}
    for i, value in ipairs(list or {}) do out[i] = value end
    local state = hash(key, seed)
    for i = #out, 2, -1 do
      state = (state * 48271 + 1) % MODULUS
      local j = (state % i) + 1
      out[i], out[j] = out[j], out[i]
    end
    return out
  end

  local function newSeed()
    local now = 1
    if love and love.timer and love.timer.getTime then
      local ok, value = pcall(love.timer.getTime)
      if ok and type(value) == "number" then now = math.floor(value * 1000000) end
    end
    return hash("randomized-gym-challenge:" .. tostring(now), now)
  end

  local GYMS
  if isGold then
    GYMS = {
      { id="FALKNER", name="FALKNER", mapId="VIOLET_GYM", objectIndex=1, scriptKey="56:412f", class=1, member=1, sprite="SPRITE_FALKNER", intro="56:41e0", types={"FLYING"} },
      { id="BUGSY", name="BUGSY", mapId="AZALEA_GYM", objectIndex=1, scriptKey="55:4d96", class=3, member=1, sprite="SPRITE_BUGSY", intro="55:4e83", types={"BUG"} },
      { id="WHITNEY", name="WHITNEY", mapId="GOLDENROD_GYM", objectIndex=1, scriptKey="57:400c", class=2, member=1, sprite="SPRITE_WHITNEY", intro="57:4122", types={"NORMAL"} },
      { id="MORTY", name="MORTY", mapId="ECRUTEAK_GYM", objectIndex=1, scriptKey="52:508f", class=4, member=1, sprite="SPRITE_MORTY", intro="52:516b", types={"GHOST"} },
      { id="CHUCK", name="CHUCK", mapId="CIANWOOD_GYM", objectIndex=1, scriptKey="5d:5304", class=7, member=1, sprite="SPRITE_CHUCK", intro="5d:53ee", types={"FIGHTING"} },
      { id="JASMINE", name="JASMINE", mapId="OLIVINE_GYM", objectIndex=1, scriptKey="51:4110", class=6, member=1, sprite="SPRITE_JASMINE", intro="51:419a", types={"STEEL"} },
      { id="PRYCE", name="PRYCE", mapId="MAHOGANY_GYM", objectIndex=1, scriptKey="51:536e", class=5, member=1, sprite="SPRITE_PRYCE", intro="51:545d", types={"ICE"} },
      { id="CLAIR", name="CLAIR", mapId="BLACKTHORN_GYM_1F", objectIndex=1, scriptKey="53:4024", class=8, member=1, sprite="SPRITE_CLAIR", intro="53:40f3", types={"DRAGON"} },
      { id="BROCK", name="BROCK", mapId="PEWTER_GYM", objectIndex=1, scriptKey="5a:405f", class=17, member=1, sprite="SPRITE_BROCK", intro="5a:40cb", types={"ROCK", "GROUND"} },
      { id="MISTY", name="MISTY", mapId="CERULEAN_GYM", objectIndex=2, scriptKey="54:438a", class=18, member=1, sprite="SPRITE_MISTY", intro="54:45cc", types={"WATER"} },
      { id="LT_SURGE", name="LT. SURGE", mapId="VERMILION_GYM", objectIndex=1, scriptKey="59:4bfc", class=19, member=1, sprite="SPRITE_SURGE", intro="59:4c99", types={"ELECTRIC"} },
      { id="ERIKA", name="ERIKA", mapId="CELADON_GYM", objectIndex=1, scriptKey="5e:5e0b", class=21, member=1, sprite="SPRITE_ERIKA", intro="5e:5ec9", types={"GRASS"} },
      { id="JANINE", name="JANINE", mapId="FUCHSIA_GYM", objectIndex=1, scriptKey="5c:40d3", class=26, member=1, sprite="SPRITE_JANINE", intro="5c:424f", types={"POISON"} },
      { id="SABRINA", name="SABRINA", mapId="SAFFRON_GYM", objectIndex=1, scriptKey="61:40cf", class=35, member=1, sprite="SPRITE_SABRINA", intro="61:4180", types={"PSYCHIC"} },
      { id="BLAINE", name="BLAINE", mapId="SEAFOAM_GYM", objectIndex=1, scriptKey="53:516d", class=46, member=1, sprite="SPRITE_BLAINE", intro="53:51ba", types={"FIRE"} },
      { id="BLUE", name="BLUE", mapId="VIRIDIAN_GYM", objectIndex=1, scriptKey="5f:4002", class=64, member=1, sprite="SPRITE_BLUE", intro="5f:4057", types={"VARIED"} },
    }
  else
    GYMS = {
      { id="OPP_BROCK", name="BROCK", mapId="PEWTER_GYM", objectIndex=1, partyIndex=1, sprite="SPRITE_SUPER_NERD", preBattleText="_PewterGymBrockPreBattleText", adviceText="_PewterGymBrockPostBattleAdviceText", types={"ROCK", "GROUND"} },
      { id="OPP_MISTY", name="MISTY", mapId="CERULEAN_GYM", objectIndex=1, partyIndex=1, sprite="SPRITE_BRUNETTE_GIRL", preBattleText="_CeruleanGymMistyPreBattleText", adviceText="_CeruleanGymMistyTM11ExplanationText", types={"WATER"} },
      { id="OPP_LT_SURGE", name="LT. SURGE", mapId="VERMILION_GYM", objectIndex=1, partyIndex=1, sprite="SPRITE_ROCKER", preBattleText="_VermilionGymLTSurgePreBattleText", adviceText="_VermilionGymLTSurgePostBattleAdviceText", types={"ELECTRIC"} },
      { id="OPP_ERIKA", name="ERIKA", mapId="CELADON_GYM", objectIndex=1, partyIndex=1, sprite="SPRITE_SILPH_WORKER_F", preBattleText="_CeladonGymErikaPreBattleText", adviceText="_CeladonGymErikaPostBattleAdviceText", types={"GRASS"} },
      { id="OPP_KOGA", name="KOGA", mapId="FUCHSIA_GYM", objectIndex=1, partyIndex=1, sprite="SPRITE_KOGA", preBattleText="_FuchsiaGymKogaBeforeBattleText", adviceText="_FuchsiaGymKogaPostBattleAdviceText", types={"POISON"} },
      { id="OPP_SABRINA", name="SABRINA", mapId="SAFFRON_GYM", objectIndex=1, partyIndex=1, sprite="SPRITE_GIRL", preBattleText="_SaffronGymSabrinaText", adviceText="_SaffronGymSabrinaPostBattleAdviceText", types={"PSYCHIC"} },
      { id="OPP_BLAINE", name="BLAINE", mapId="CINNABAR_GYM", objectIndex=1, partyIndex=1, sprite="SPRITE_MIDDLE_AGED_MAN", preBattleText="_CinnabarGymBlainePreBattleText", adviceText="_CinnabarGymBlainePostBattleAdviceText", types={"FIRE"} },
      { id="OPP_GIOVANNI", name="GIOVANNI", mapId="VIRIDIAN_GYM", objectIndex=1, partyIndex=3, sprite="SPRITE_GIOVANNI", preBattleText="_ViridianGymGiovanniPreBattleText", adviceText="_ViridianGymGiovanniPostBattleAdviceText", types={"GROUND"} },
    }
  end

  local BY_ID, BY_MAP, BY_SCRIPT = {}, {}, {}
  for _, gym in ipairs(GYMS) do
    BY_ID[gym.id] = gym
    BY_MAP[gym.mapId] = gym
    if gym.scriptKey then BY_SCRIPT[gym.scriptKey] = gym end
  end

  local function partyForGold(class, member, classId)
    local trainer = mod.content.trainers:get(classId[class] or class)
    if trainer and trainer.parties then return trainer.parties[member] end
    for _, row in ipairs(trainer and trainer.trainers or {}) do
      if row.index == member or row.id == member then return row.party end
    end
    return nil
  end

  local CLASS_ID = {}
  if isGold then
    for id, trainer in mod.content.trainers:each() do
      if type(trainer) == "table" and trainer.index ~= nil then CLASS_ID[trainer.index] = id end
    end
  end

  local VANILLA_PARTIES = {}
  for _, gym in ipairs(GYMS) do
    local party
    if isGold then
      party = partyForGold(gym.class, gym.member, CLASS_ID)
    else
      local trainer = mod.content.trainers:get(gym.id)
      party = trainer and trainer.parties and trainer.parties[gym.partyIndex]
    end
    VANILLA_PARTIES[gym.id] = clone(party or {})
    if #VANILLA_PARTIES[gym.id] == 0 then
      mod.log:error("Randomized Gym Challenge: missing vanilla party for %s", gym.id)
    end
  end

  local PRE_EVOLUTION
  local SPECIES = {}
  local function buildSpeciesIndex()
    if PRE_EVOLUTION then return end
    PRE_EVOLUTION, SPECIES = {}, {}
    for speciesId, pokemon in mod.content.pokemon:each() do
      local dex = tonumber(pokemon and pokemon.dex)
      if type(speciesId) == "string" and dex and dex >= 1 and dex <= (isGold and 251 or 151) then
        SPECIES[#SPECIES + 1] = speciesId
      end
      for _, evolution in ipairs(pokemon and pokemon.evolutions or {}) do
        if evolution.method == "LEVEL" and evolution.species and evolution.level then
          PRE_EVOLUTION[evolution.species] = { species=speciesId, level=evolution.level }
        end
      end
    end
    table.sort(SPECIES)
  end

  local function stageFor(species)
    buildSpeciesIndex()
    local def = mod.content.pokemon:get(species)
    local hasParent = PRE_EVOLUTION[species] ~= nil
    local hasChild = false
    for _, evo in ipairs(def and def.evolutions or {}) do
      if evo.method == "LEVEL" and evo.species then hasChild = true; break end
    end
    if hasParent and hasChild then return "middle" end
    if hasParent or not hasChild then return "final" end
    return "basic"
  end

  local function hasType(species, types)
    if not types or #types == 0 or types[1] == "VARIED" then return true end
    local def = mod.content.pokemon:get(species)
    for _, current in ipairs(def and def.types or {}) do
      for _, wanted in ipairs(types) do
        if current == wanted then return true end
      end
    end
    return false
  end

  local function eligibleSpecies(types, stage)
    buildSpeciesIndex()
    local themed, stageOnly, any = {}, {}, {}
    for _, species in ipairs(SPECIES) do
      any[#any + 1] = species
      if not stage or stageFor(species) == stage then
        stageOnly[#stageOnly + 1] = species
        if hasType(species, types) then themed[#themed + 1] = species end
      end
    end
    if #themed > 0 then return themed end
    if #stageOnly > 0 then return stageOnly end
    return any
  end

  local function levelFor(base, rules, key, seed)
    if not rules.randomize_levels then return base end
    local spread = tonumber(rules.level_variation) or 3
    local delta = (hash("level:" .. key, seed) % (spread * 2 + 1)) - spread
    return math.max(2, math.min(100, (tonumber(base) or 2) + delta))
  end

  local function moveCandidates(species, level)
    local def = mod.content.pokemon:get(species)
    local out, seen = {}, {}
    local function add(moveId)
      if not moveId or seen[moveId] then return end
      local move = mod.content.moves:get(moveId)
      if not move then return end
      seen[moveId] = true
      out[#out + 1] = { id=moveId, damaging=(tonumber(move.power) or 0) > 0 }
    end
    for _, moveId in ipairs(def and def.level1Moves or {}) do add(moveId) end
    for _, row in ipairs(def and def.levelMoves or {}) do
      if (tonumber(row.level) or 1) <= level then add(row.move) end
    end
    for _, row in ipairs(def and def.learnset or {}) do
      if (tonumber(row.level) or 1) <= level then add(row.move) end
    end
    for _, moveId in ipairs({ "TACKLE", "SCRATCH", "POUND", "QUICK_ATTACK", "BITE", "HEADBUTT" }) do add(moveId) end
    return out
  end

  local function generatedMoves(species, level, key, seed)
    local candidates = shuffle(moveCandidates(species, level), "moves:" .. key, seed)
    local out, used = {}, {}
    for _, candidate in ipairs(candidates) do
      if candidate.damaging then out[#out + 1] = candidate.id; used[candidate.id] = true; break end
    end
    for _, candidate in ipairs(candidates) do
      if #out >= 4 then break end
      if not used[candidate.id] then out[#out + 1] = candidate.id; used[candidate.id] = true end
    end
    return #out > 0 and out or nil
  end

  local HELD_ITEMS
  local function heldItemFor(key, seed)
    if not isGold then return nil end
    if not HELD_ITEMS then
      HELD_ITEMS = { false }
      for itemId, item in mod.content.items:each() do
        if type(itemId) == "string" and type(item) == "table"
          and item.heldEffect and item.heldEffect ~= "HELD_NONE"
          and item.keyItem ~= true and item.canToss ~= false
          and item.pocket ~= "KEY_ITEM"
          and not (item.machine and item.machine.kind == "HM") then
          HELD_ITEMS[#HELD_ITEMS + 1] = itemId
        end
      end
      table.sort(HELD_ITEMS, function(a, b) return tostring(a) < tostring(b) end)
    end
    return pick(HELD_ITEMS, "item:" .. key, seed)
  end

  local function currentRules()
    return {
      randomize_leaders=mod.options:get("randomize_leaders") == true,
      randomize_teams=mod.options:get("randomize_teams") == true,
      randomize_levels=mod.options:get("randomize_levels") == true,
      level_variation=math.floor(tonumber(mod.options:get("level_variation")) or 3),
      preserve_theme=mod.options:get("preserve_theme") == true,
      enforce_stage=mod.options:get("enforce_stage") == true,
      randomize_moves=mod.options:get("randomize_moves") == true,
      randomize_held_items=isGold and mod.options:get("randomize_held_items") == true,
    }
  end

  local function buildLeaderMapping(rules, seed)
    local mapping = {}
    for _, gym in ipairs(GYMS) do mapping[gym.id] = gym.id end
    if not rules.randomize_leaders then return mapping end
    local ids = {}
    for i, gym in ipairs(GYMS) do ids[i] = gym.id end
    local shuffled = shuffle(ids, "leaders", seed)
    -- A derangement makes the toggle visibly change every gym, while still
    -- preserving a one-to-one leader assignment for the spoiler log.
    local fixed = true
    local salt = 1
    while fixed and salt < 64 do
      fixed = false
      for i, gym in ipairs(GYMS) do if shuffled[i] == gym.id then fixed = true; break end end
      if fixed then shuffled = shuffle(ids, "leaders:" .. salt, seed); salt = salt + 1 end
    end
    for i, gym in ipairs(GYMS) do mapping[gym.id] = shuffled[i] end
    return mapping
  end

  local function buildParty(gym, visitor, rules, seed)
    local physical = VANILLA_PARTIES[gym.id] or {}
    local source = VANILLA_PARTIES[visitor.id] or physical
    local party, used = {}, {}
    for index, target in ipairs(physical) do
      local sourceMon = source[math.min(index, #source)] or source[1] or target
      local originalSpecies = sourceMon and sourceMon.species or target.species
      local level = levelFor(target.level, rules, gym.id .. ":" .. index, seed)
      local species = originalSpecies
      local speciesChanged = false
      if rules.randomize_teams then
        local stage = rules.enforce_stage and stageFor(target.species) or nil
        local types = rules.preserve_theme and gym.types or nil
        local pool = eligibleSpecies(types, stage)
        local ordered = shuffle(pool, gym.id .. ":species:" .. index, seed)
        species = ordered[1] or species
        if #ordered > 1 then
          for _, candidate in ipairs(ordered) do
            if not used[candidate] then species = candidate; break end
          end
        end
        speciesChanged = species ~= originalSpecies
      elseif rules.enforce_stage then
        local desired = stageFor(target.species)
        local pool = eligibleSpecies(nil, desired)
        if #pool > 0 and stageFor(species) ~= desired then
          local replacement = pick(pool, gym.id .. ":stage:" .. index, seed)
          species = replacement or species
          speciesChanged = species ~= originalSpecies
        end
      end
      if species then used[species] = true end

      -- Start from the imported trainer record. This preserves vanilla moves,
      -- held items, and any future party fields whenever their option is off.
      local entry = clone(sourceMon)
      entry.species, entry.level = species, level
      if speciesChanged then
        entry.moves = nil
        entry.item = nil
      end
      if rules.randomize_moves then
        entry.moves = generatedMoves(species, level, gym.id .. ":" .. index, seed)
      end
      if rules.randomize_held_items then
        local held = heldItemFor(gym.id .. ":" .. index, seed)
        entry.item = held ~= false and held or nil
      end
      party[#party + 1] = entry
    end
    return party
  end

  local function buildPlan()
    local rules = currentRules()
    local seed = newSeed()
    local leaders = buildLeaderMapping(rules, seed)
    local gyms = {}
    for _, gym in ipairs(GYMS) do
      local visitor = BY_ID[leaders[gym.id]] or gym
      gyms[gym.id] = { visitor=visitor.id, party=buildParty(gym, visitor, rules, seed) }
    end
    local plan = { version=1, game=playing, seed=seed, rules=rules, gyms=gyms }
    mod.save:set("challenge_plan", plan)
    mod.log:info("Randomized Gym Challenge: generated a challenge plan for %s", playing)
    return plan
  end

  local function planForSave()
    local plan = mod.save:get("challenge_plan")
    if type(plan) ~= "table" or type(plan.gyms) ~= "table" or plan.game ~= playing then
      return buildPlan()
    end
    return plan
  end

  local function visitorFor(gym, plan)
    local row = plan and plan.gyms and plan.gyms[gym.id]
    return row and BY_ID[row.visitor] or gym
  end

  local function partyForChallenge(gym, plan)
    local row = plan and plan.gyms and plan.gyms[gym.id]
    return row and row.party or VANILLA_PARTIES[gym.id]
  end

  local ACTIONS = { rebuild_action=true, challenge_log_action=true }
  local function resetActions()
    local game = mod.game
    local stored = game and game.save and game.save.options and game.save.options.modOptions
    local active = game and game.mods and game.mods.modOptions
    stored = stored and stored[mod.id]
    active = active and active[mod.id]
    for key in pairs(ACTIONS) do
      if stored then stored[key] = false end
      if active then active[key] = false end
    end
  end

  local function openLog()
    local plan = planForSave()
    local pages = {}
    for index, gym in ipairs(GYMS) do
      local visitor = visitorFor(gym, plan)
      local party = partyForChallenge(gym, plan)
      local first, second = {}, {}
      for slot, mon in ipairs(party or {}) do
        local line = string.format("%s %02d", tostring(mon.species or "?"), tonumber(mon.level) or 0)
        if slot <= 3 then first[#first + 1] = line else second[#second + 1] = line end
      end
      pages[#pages + 1] = string.format("%02d/%02d %s\nLEADER %s", index, #GYMS, gym.name, visitor.name)
      pages[#pages + 1] = table.concat(first, "\n")
      if #second > 0 then pages[#pages + 1] = table.concat(second, "\n") end
    end
    local TextBox = require("src.render.TextBox")
    local game = mod.game
    if game and game.stack then game.stack:push(TextBox.new(game, table.concat(pages, "\f"))) end
  end

  if isGold then
    local function paint(npc, sprite)
      local def = mod.content.sprites:get(sprite)
      if not (npc and def) then return end
      npc.def.sprite = sprite
      if npc.setSpriteDef then npc:setSpriteDef(def) end
    end

    local function applyGoldGym(mapId)
      local gym = BY_MAP[mapId]
      if not gym then return end
      local plan = planForSave()
      local visitor = visitorFor(gym, plan)
      local handle = mod.world:npc(mapId, gym.objectIndex)
      if handle and handle.npc then paint(handle.npc, visitor.sprite) end
    end

    local pendingGym
    mod.hooks:wrap("script.command", function(next, ctx, name, args, command)
      local gym = ctx and BY_SCRIPT[ctx.scriptKey]
      if not gym or not command then return next(ctx, name, args, command) end
      local plan = planForSave()
      local visitor = visitorFor(gym, plan)
      if name == "writetext" and plan.rules.randomize_leaders and command.text == gym.intro then
        local rewritten = clone(command)
        rewritten.text = visitor.intro
        return next(ctx, name, args, rewritten)
      end
      if name == "loadtrainer" and command.class == gym.class and command.member == gym.member then
        pendingGym = { gym=gym, visitor=visitor, class=visitor.class, member=visitor.member }
        if plan.rules.randomize_leaders then
          local rewritten = clone(command)
          rewritten.class, rewritten.member = visitor.class, visitor.member
          return next(ctx, name, args, rewritten)
        end
      end
      return next(ctx, name, args, command)
    end)

    mod.hooks:wrap("trainer.party", function(next, trainerClass, partyIndex, party)
      party = next(trainerClass, partyIndex, party)
      local pending = pendingGym
      if pending and trainerClass == pending.class and partyIndex == pending.member then
        pendingGym = nil
        local replacement = partyForChallenge(pending.gym, planForSave())
        if type(replacement) == "table" and #replacement > 0 then return clone(replacement) end
      end
      return party
    end)

    mod.events:on("map.entered", function(event) applyGoldGym(event and event.mapId) end)
    mod.events:on("game.ready", function(event)
      resetActions()
      local game = event and event.game or mod.game
      if game and game.world and game.world.map then applyGoldGym(game.world.map.id) end
    end)
    mod.events:on("screen.popped", resetActions)
  else
    local SpriteRenderer = require("src.render.SpriteRenderer")
    local function sourceLeaderText(gym)
      local map = mod.content.maps:get(gym.mapId)
      for _, object in ipairs(map and map.objects or {}) do
        if object.index == gym.objectIndex and object.text then return map.label, object.text end
      end
      return nil, nil
    end

    local function leaderSprite(gym)
      local map = mod.content.maps:get(gym.mapId)
      for _, object in ipairs(map and map.objects or {}) do
        if object.index == gym.objectIndex and object.sprite then return object.sprite end
      end
      return gym.sprite
    end

    local function paint(npc, spriteId)
      local def = mod.content.sprites:get(spriteId)
      if not (npc and def) then return end
      npc.def.sprite = spriteId
      npc.sprite = SpriteRenderer.new(def, npc.id)
    end

    local LIVE = {}
    local function retryPhysicalGymTm(game, overworld, gym, done)
      local rewards = require("data.scripts.victories")
      local reward = rewards[gym.id .. "#" .. gym.partyIndex]
      if not (reward and reward.gotFlag) or game.save.flags[reward.gotFlag] then return false end
      if (game.save.inventory and game.save.inventory[reward.item] or 0) > 0 then
        game.save.flags[reward.gotFlag] = true
        return false
      end
      overworld:offerGymTm(reward, done)
      return true
    end

    local function gymTalk(gym)
      return function(game, overworld, npc, done)
        done = done or function() end
        local plan = planForSave()
        local visitor = visitorFor(gym, plan)
        if game.save.defeatedTrainers and game.save.defeatedTrainers[npc.id] then
          if retryPhysicalGymTm(game, overworld, gym, done) then return end
          local TextBox = require("src.render.TextBox")
          game.stack:push(TextBox.new(game, game.data.text[gym.adviceText] or "...", done))
          return
        end
        local TextBox = require("src.render.TextBox")
        local preBattle = plan.rules.randomize_leaders and game.data.text[visitor.preBattleText] or game.data.text[gym.preBattleText]
        if not preBattle then return overworld:engageTrainer(npc, done) end
        game.stack:push(TextBox.new(game, preBattle, function() overworld:engageTrainer(npc, done, nil, true) end))
      end
    end

    for _, gym in ipairs(GYMS) do
      local _, sourceText = sourceLeaderText(gym)
      if sourceText then
        mod.content.map_scripts:register(gym.mapId, { priority=100, talk={ [sourceText]=gymTalk(gym) } })
      else
        mod.log:error("Randomized Gym Challenge: missing leader talk entry for %s", gym.id)
      end
    end

    local function applyGen1Gym(mapId)
      local gym = BY_MAP[mapId]
      if not gym then return end
      local plan = planForSave()
      local visitor = visitorFor(gym, plan)
      local handle = mod.world:npc(mapId, gym.objectIndex)
      local npc = handle and handle.npc
      if not npc then return end
      npc.def.trainerClass = visitor.id
      npc.def.trainerParty = visitor.partyIndex
      paint(npc, plan.rules.randomize_leaders and leaderSprite(visitor) or leaderSprite(gym))
      LIVE[npc.id] = { npc=npc, gym=gym, visitor=visitor }
    end

    local pendingGym
    mod.events:on("map.entered", function(event) applyGen1Gym(event and event.mapId) end)
    mod.events:on("world.trainer_engaged", function(event)
      local record = event and event.npc and LIVE[event.npc.id]
      if record then
        event.npc.def.trainerClass, event.npc.def.trainerParty = record.visitor.id, record.visitor.partyIndex
        pendingGym = record
      end
    end)

    mod.hooks:wrap("trainer.party", function(next, trainerClass, partyIndex, party)
      party = next(trainerClass, partyIndex, party)
      local pending = pendingGym
      if pending and trainerClass == pending.visitor.id and partyIndex == pending.visitor.partyIndex then
        local replacement = partyForChallenge(pending.gym, planForSave())
        if type(replacement) == "table" and #replacement > 0 then return clone(replacement) end
      end
      return party
    end)

    mod.events:on("battle.started", function(event)
      local origin = event and event.battle and event.battle.checkpointOrigin
      local record = origin and LIVE[origin.npcId]
      if record then
        record.npc.def.trainerClass, record.npc.def.trainerParty = record.gym.id, record.gym.partyIndex
      end
      pendingGym = nil
    end)
    mod.events:on("game.ready", function(event)
      resetActions()
      local game = event and event.game or mod.game
      if game and game.world and game.world.map then applyGen1Gym(game.world.map.id) end
    end)
    mod.events:on("screen.popped", resetActions)
  end

  mod.hooks:wrap("save.new_game", function(next, save)
    save = next(save)
    mod.save:set("challenge_plan", nil)
    return save
  end)

  mod.events:on("mod.options_changed", function(event)
    local changed = type(event and event.mod) == "table" and event.mod.id or event and event.mod
    if changed ~= mod.id then return end
    if event.key == "rebuild_action" and event.value then
      mod.save:set("challenge_plan", nil)
      resetActions()
      mod.log:info("Randomized Gym Challenge: next gym access will build a new plan")
    elseif event.key == "challenge_log_action" and event.value then
      resetActions()
      openLog()
    elseif not ACTIONS[event.key] and mod.save:get("challenge_plan") then
      mod.log:info("Randomized Gym Challenge: a plan already exists for this save; use REBUILD CHALLENGE (TEST) after changing rules")
    end
  end)
end
