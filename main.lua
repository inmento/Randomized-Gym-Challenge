-- Randomized Gym Challenge
-- Release 1.1.3
-- Gen 1 Recomp mod API 2
--
-- This is intentionally separate from Gym Leader Shuffle.  It uses the same
-- gym-battle seams, but generates a per-save challenge plan instead of merely
-- moving the original leader parties between buildings.

return function(mod)
  local GameVersion = require("src.core.GameVersion")
  local playing = GameVersion.get()
  local isGold = playing == "gold"
  local function crystal251Active()
    if isGold or type(mod.find) ~= "function" then return false end
    local ok, handle = pcall(mod.find, mod, "CRYSTAL_251")
    local exports = ok and type(handle) == "table" and handle.exports or nil
    return type(exports) == "table" and tonumber(exports.dexSize) == 251
  end

  -- A merged content provider may extend the available roster. This helper
  -- only sets the upper bound; candidate collection still requires a complete
  -- live species record and never rewrites its authored data.
  local function liveDexLimit()
    local fallback = isGold and 251 or 151
    local constants = mod.content and mod.content.constants
    if type(constants) == "table" and type(constants.get) == "function" then
      local ok, value = pcall(constants.get, constants, "dexSize")
      value = ok and tonumber(value) or nil
      if value and value >= fallback then return math.floor(value) end
    end
    if crystal251Active() then return math.max(fallback, 251) end
    return fallback
  end

  mod.options:define({
    { key="randomize_leaders", label="SHUFFLE LEADERS", type="toggle", default=false },
    { key="randomize_teams", label="SHUFFLE TEAMS", type="toggle", default=false },
    { key="randomize_levels", label="RANDOMIZE LEVELS", type="toggle", default=false },
    { key="level_variation", label="LEVEL VARIATION", type="number", default=3, min=1, max=8, step=1 },
    { key="preserve_theme", label="MATCH GYM TYPE", type="toggle", default=false },
    { key="enforce_stage", label="MATCH EVO STAGE", type="toggle", default=false },
    { key="randomize_moves", label="SHUFFLE MOVESETS", type="toggle", default=false },
    { key="randomize_held_items", label="GOLD HELD ITEMS", type="toggle", default=false },
    { key="rebuild_action", label="REBUILD (TEST)", type="toggle", default=false },
    { key="challenge_log_action", label="CHALLENGE LOG", type="toggle", default=false },
    { key="challenge_progress_action", label="PROGRESS LOG", type="toggle", default=false },
    { key="challenge_hint_action", label="NEXT GYM HINT", type="toggle", default=false },
    { key="abandon_challenge_action", label="END GYM CHALLENGE", type="toggle", default=false },
    { key="difficulty_preset", label="DIFFICULTY PRESET", type="choice", default="MANUAL",
      choices={ {"MANUAL","MANUAL"}, {"STORY FRIENDLY","STORY_FRIENDLY"},
        {"CHALLENGE","CHALLENGE"}, {"CHAOS","CHAOS"} } },
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

  -- Gym Challenge is intentionally stored separately from the generated
  -- battle plan. The plan can be rebuilt for testing without erasing a
  -- player’s accepted challenge, earned gyms, or routing state.
  local GYM_CHALLENGE_KEY = "gym_challenge_state"
  -- `gym_challenge_opt_in` belonged to the retired intro prompt. Keep it only
  -- so older pre-stable saves can be cleaned up; milestone offers use new keys.
  local GYM_CHALLENGE_PROMPT_KEY = "gym_challenge_opt_in"
  local GYM_CHALLENGE_OFFERED_KEY = "gym_challenge_offer_seen_v2"
  local GYM_CHALLENGE_PENDING_KEY = "gym_challenge_offer_pending_v2"

  local GYM_TELEPORTS = isGold and {
    FALKNER={ mapId="VIOLET_CITY", x=18, y=17 },
    BUGSY={ mapId="AZALEA_TOWN", x=10, y=15 },
    WHITNEY={ mapId="GOLDENROD_CITY", x=24, y=7 },
    MORTY={ mapId="ECRUTEAK_CITY", x=6, y=27 },
    JASMINE={ mapId="OLIVINE_CITY", x=10, y=11 },
    CHUCK={ mapId="CIANWOOD_CITY", x=8, y=43 },
    PRYCE={ mapId="MAHOGANY_TOWN", x=6, y=13 },
    CLAIR={ mapId="BLACKTHORN_CITY", x=18, y=11 },
    BROCK={ mapId="PEWTER_CITY", x=16, y=17 },
    MISTY={ mapId="CERULEAN_CITY", x=30, y=23 },
    LT_SURGE={ mapId="VERMILION_CITY", x=10, y=19 },
    ERIKA={ mapId="CELADON_CITY", x=10, y=29 },
    JANINE={ mapId="FUCHSIA_CITY", x=8, y=27 },
    SABRINA={ mapId="SAFFRON_CITY", x=34, y=3 },
    BLAINE={ mapId="ROUTE_20", x=38, y=7 },
    BLUE={ mapId="VIRIDIAN_CITY", x=32, y=7 },
  } or {
    OPP_BROCK={ mapId="PEWTER_CITY", x=16, y=18 },
    OPP_MISTY={ mapId="CERULEAN_CITY", x=30, y=20 },
    OPP_LT_SURGE={ mapId="VERMILION_CITY", x=12, y=20 },
    OPP_ERIKA={ mapId="CELADON_CITY", x=12, y=28 },
    OPP_KOGA={ mapId="FUCHSIA_CITY", x=5, y=28 },
    OPP_SABRINA={ mapId="SAFFRON_CITY", x=34, y=4 },
    OPP_BLAINE={ mapId="CINNABAR_ISLAND", x=18, y=4 },
    OPP_GIOVANNI={ mapId="VIRIDIAN_CITY", x=32, y=8 },
  }

  local GOLD_BADGE_KEYS = {
    FALKNER="ZEPHYR", BUGSY="HIVE", WHITNEY="PLAIN", MORTY="FOG",
    JASMINE="MINERAL", CHUCK="STORM", PRYCE="GLACIER", CLAIR="RISING",
    BROCK="BOULDER", MISTY="CASCADE", LT_SURGE="THUNDER", ERIKA="RAINBOW",
    JANINE="SOUL", SABRINA="MARSH", BLAINE="VOLCANO", BLUE="EARTH",
  }

  local function challengeState()
    local state = mod.save:get(GYM_CHALLENGE_KEY)
    return type(state) == "table" and state or nil
  end

  local function challengeActive()
    local state = challengeState()
    return state and state.enabled == true and state.game == playing and state or nil
  end

  local challengePhaseGyms, planForSave

  local function saveChallenge(state)
    state.version = 1
    state.game = playing
    state.completed = state.completed or {}
    state.guideRewards = state.guideRewards or {}
    state.guideFallback = state.guideFallback or {}
    state.guideQuantities = state.guideQuantities or {}

    mod.save:set(GYM_CHALLENGE_KEY, state)
    return state
  end

  -- Gym Challenge encouragement rewards are deliberately curated rather than
  -- drawn from the entire item table. They never use key items, HMs, TMs, or
  -- low-value filler; the later a physical gym sits in its challenge phase,
  -- the more weight moves toward recovery and premium training supplies.
  local GUIDE_REWARD_WEIGHTS = isGold and {
    { id="POTION", weights={18,5,1} }, { id="SUPER_POTION", weights={14,14,5} },
    { id="HYPER_POTION", weights={3,14,14} }, { id="FULL_RESTORE", weights={0,2,8} },
    { id="FULL_HEAL", weights={5,7,8} }, { id="REVIVE", weights={3,8,10} },
    { id="MAX_REVIVE", weights={0,1,3} }, { id="ETHER", weights={2,5,7} },
    { id="ELIXIR", weights={0,2,5} }, { id="RARE_CANDY", weights={0,1,3} },
    { id="BERRY_JUICE", weights={8,4,1} }, { id="GOLD_BERRY", weights={3,7,8} },
    { id="MYSTERYBERRY", weights={2,4,5} }, { id="MIRACLEBERRY", weights={1,3,4} },
    { id="HP_UP", weights={0,2,3} }, { id="PROTEIN", weights={0,2,3} },
    { id="IRON", weights={0,2,3} }, { id="CARBOS", weights={0,2,3} },
    { id="CALCIUM", weights={0,2,3} },
  } or {
    { id="POTION", weights={18,5,1} }, { id="SUPER_POTION", weights={14,14,5} },
    { id="HYPER_POTION", weights={3,14,14} }, { id="FULL_RESTORE", weights={0,2,8} },
    { id="FULL_HEAL", weights={5,7,8} }, { id="REVIVE", weights={3,8,10} },
    { id="MAX_REVIVE", weights={0,1,3} }, { id="ETHER", weights={2,5,7} },
    { id="ELIXIR", weights={0,2,5} }, { id="RARE_CANDY", weights={0,1,3} },
  }

  local function guideRewardTier(gym, state)
    local phase = challengePhaseGyms(state)
    for index, row in ipairs(phase) do
      if row.id == gym.id then return math.min(3, math.floor((index - 1) * 3 / #phase) + 1) end
    end
    return 1
  end

  local function guideRewardFor(gym, state)
    local tier, total, entries = guideRewardTier(gym, state), 0, {}
    for _, row in ipairs(GUIDE_REWARD_WEIGHTS) do
      local item = mod.content.items:get(row.id)
      local weight = tonumber(row.weights[tier]) or 0
      if item and weight > 0 then
        total = total + weight
        entries[#entries + 1] = { id=row.id, limit=total }
      end
    end
    if total == 0 then return nil end
    local plan = planForSave()
    local roll = (hash("gym-guide-reward:" .. gym.id, plan.seed) % total) + 1
    for _, entry in ipairs(entries) do if roll <= entry.limit then return entry.id end end
    return entries[#entries].id
  end

  local function guideQuantityFor(gym, state, itemId)
    local tier = guideRewardTier(gym, state)
    local repeated = { POTION=true, SUPER_POTION=true, HYPER_POTION=true, FULL_HEAL=true,
      BERRY_JUICE=true, GOLD_BERRY=true, MYSTERYBERRY=true, MIRACLEBERRY=true }
    if repeated[itemId] and tier >= 2 then return tier == 3 and 2 or 1 end
    return 1
  end

  local function grantGuideReward(game, itemId, quantity)
    local item = itemId and mod.content.items:get(itemId)
    if not (game and game.save and item) then return false end
    if isGold then
      local world = game.world
      return world and world.giveItem and world:giveItem(item.index, quantity or 1) == true or false
    end
    -- Bag.add mirrors native Gen 1 slot and stack limits; it is never loaded on
    -- Gold, where inventory pockets use the Gold world implementation above.
    local Bag = require("src.inventory.Bag")
    return Bag.add(game.save, itemId, quantity or 1, game.data) == true
  end

  local function claimGuideReward(game, gym)
    local state = challengeActive()
    if not (state and gym) then return nil, "inactive" end
    if state.guideRewards and state.guideRewards[gym.id] then return state.guideRewards[gym.id], "claimed" end
    local itemId = guideRewardFor(gym, state)
    if not itemId then return nil, "unavailable" end
    local quantity = guideQuantityFor(gym, state, itemId)
    if not grantGuideReward(game, itemId, quantity) then return nil, "bag_full" end
    state.guideRewards[gym.id] = itemId
    state.guideQuantities[gym.id] = quantity
    saveChallenge(state)
    return itemId, "granted", quantity
  end

  local function rewardItemName(itemId)
    local item = itemId and mod.content.items:get(itemId)
    return (item and item.name) or tostring(itemId or "ITEM")
  end

  local function showChallengeText(game, text, done)
    done = done or function() end
    if isGold and game and game.world and game.world.showText then
      game.world:showText(text, done)
      return
    end
    local TextBox = require("src.render.TextBox")
    if game and game.stack then game.stack:push(TextBox.new(game, text, done)) else done() end
  end

  local function showChallengeChoice(game, text, onChoice)
    onChoice = onChoice or function() end
    local TextBox = require("src.render.TextBox")
    if game and game.stack then
      game.stack:push(TextBox.new(game, text, nil, { choice=onChoice, defaultNo=true }))
    else
      onChoice(false)
    end
  end

  local function guideEncouragementText(gym, itemId, status, quantity)
    if status == "bag_full" then
      return "THE GYM FEELS\nTOUGH TODAY.\fMAKE ROOM IN YOUR BAG\nAND TALK TO ME AGAIN!"
    end
    if status == "claimed" then
      return "THE GYM STILL LOOKS\nTOUGH.\fSTAY CAREFUL, TRAINER!"
    end
    local count = (quantity and quantity > 1) and (" x" .. tostring(quantity)) or ""
    return "THE GYM FEELS\nTOUGH TODAY.\fBE CAREFUL, TRAINER!\fTAKE THIS WITH YOU:\n" .. rewardItemName(itemId) .. count .. "!"
  end

  challengePhaseGyms = function(state)
    if not isGold then return GYMS end
    local out, startAt, endAt = {}, state and state.phase == "kanto" and 9 or 1,
      state and state.phase == "kanto" and 16 or 8
    for index = startAt, endAt do out[#out + 1] = GYMS[index] end
    return out
  end

  local function badgeOwned(game, gym)
    if not (game and game.save and gym) then return false end
    if isGold then
      local player = game.save.player or {}
      local store = (GOLD_BADGE_KEYS[gym.id] == "BOULDER" or GOLD_BADGE_KEYS[gym.id] == "CASCADE"
        or GOLD_BADGE_KEYS[gym.id] == "THUNDER" or GOLD_BADGE_KEYS[gym.id] == "RAINBOW"
        or GOLD_BADGE_KEYS[gym.id] == "SOUL" or GOLD_BADGE_KEYS[gym.id] == "MARSH"
        or GOLD_BADGE_KEYS[gym.id] == "VOLCANO" or GOLD_BADGE_KEYS[gym.id] == "EARTH")
        and player.kantoBadges or player.badges
      return type(store) == "table" and store[GOLD_BADGE_KEYS[gym.id]] == true
    end
    local victories = require("data.scripts.victories")
    local reward = victories[gym.id .. "#" .. gym.partyIndex]
    return reward and game.save.inventory and game.save.inventory[reward.badge] == true
  end

  local function typeMultiplier(attacker, defender)
    local row = attacker and defender and mod.content.type_chart:get(attacker .. ">" .. defender)
    return tonumber(row and row.multiplier) or 10
  end

  local function hasAdvantage(attackingTypes, defendingTypes)
    for _, attack in ipairs(attackingTypes or {}) do
      for _, defend in ipairs(defendingTypes or {}) do
        if typeMultiplier(attack, defend) >= 20 then return true end
      end
    end
    return false
  end

  local function starterLevelFor(species)
    local firstGym = GYMS[1]
    local party = VANILLA_PARTIES[firstGym.id] or {}
    local baseline = 5
    for _, mon in ipairs(party) do baseline = math.max(baseline, tonumber(mon.level) or 5) end
    local starter = mod.content.pokemon:get(species) or {}
    local starterWins = hasAdvantage(starter.types, firstGym.types)
    local gymWins = hasAdvantage(firstGym.types, starter.types)
    if gymWins then return math.min(100, baseline + 5) end
    if starterWins then return math.max(2, baseline - 2) end
    return math.min(100, baseline + 2)
  end

  local function nextChallengeGym(state, game)
    for _, gym in ipairs(challengePhaseGyms(state)) do
      if not state.completed[gym.id] and not badgeOwned(game, gym) then return gym end
    end
    return nil
  end

  local function setRouteStatus(state, status, gym, reason)
    if not state then return end
    state.lastRoute = {
      status=status,
      gym=gym and gym.id or nil,
      reason=reason,
      phase=state.phase,
    }
  end

  local function queueGymWarp(state, gym)
    if not state then return false end
    if not (gym and GYM_TELEPORTS[gym.id]) then
      setRouteStatus(state, "PAUSED", gym, "NO VALID NEXT GYM DESTINATION")
      return false
    end
    state.pendingWarp = gym.id
    setRouteStatus(state, "QUEUED", gym, "WAITING FOR NATIVE SCRIPT")
    return true
  end

  local function warpQueuedGym()
    local state = challengeActive()
    local gym = state and state.pendingWarp and BY_ID[state.pendingWarp]
    local target = gym and GYM_TELEPORTS[gym.id]
    if not target then
      if state then
        state.pendingWarp = nil
        setRouteStatus(state, "PAUSED", gym, "NO VALID NEXT GYM DESTINATION")
        saveChallenge(state)
      end
      return false
    end
    state.pendingWarp = nil
    saveChallenge(state)
    local ok, err = mod.world:warpTo(target.mapId, target.x, target.y, "up", { arrive="teleport" })
    if not ok then
      state.pendingWarp = gym.id
      setRouteStatus(state, "PAUSED", gym, "WARP FAILED")
      saveChallenge(state)
      mod.log:warn("Gym Challenge warp failed for %s: %s", gym.id, tostring(err))
      return false
    end
    setRouteStatus(state, "WARPED", gym, "ARRIVED AT NEXT GYM")
    saveChallenge(state)
    return true
  end

  local function healChallengeParty(onDone)
    -- `nurseHeal` is the Mod API's cross-generation recovery operation. Its
    -- callback runs after the engine has restored the party, allowing a queued
    -- warp to happen only after the complete native heal sequence finishes.
    onDone = onDone or function() end
    local ok = mod.world:nurseHeal(onDone)
    if not ok then onDone() end
  end

  local function expForLevel(growthRate, level)
    if growthRate == "SLIGHTLY_FAST" then
      return math.max(0, math.floor((3 * level ^ 3) / 4) + 10 * level ^ 2 - 30)
    elseif growthRate == "SLIGHTLY_SLOW" then
      return math.max(0, math.floor((3 * level ^ 3) / 4) + 20 * level ^ 2 - 70)
    elseif growthRate == "MEDIUM_SLOW" then
      return math.max(0, math.floor((6 * level ^ 3) / 5) - 15 * level ^ 2 + 100 * level - 140)
    elseif growthRate == "FAST" then
      return math.floor((4 * level ^ 3) / 5)
    elseif growthRate == "SLOW" then
      return math.floor((5 * level ^ 3) / 4)
    end
    return level ^ 3
  end

  local function recalculateStarterStats(speciesDef, level, dvs, statExp)
    local stats = {}
    for _, key in ipairs({ "hp", "attack", "defense", "speed", "special" }) do
      local base = (speciesDef.baseStats and speciesDef.baseStats[key]) or 1
      local dv = (dvs and dvs[key]) or 0
      local ev = math.floor(math.min(255, math.ceil(math.sqrt((statExp and statExp[key]) or 0))) / 4)
      stats[key] = math.floor(((base + dv) * 2 + ev) * level / 100) + (key == "hp" and level + 10 or 5)
    end
    return stats
  end

  local function levelAcceptedStarter(game, state)
    local party = game and game.save and game.save.party
    local starter = type(party) == "table" and party[1] or nil
    local speciesDef = starter and mod.content.pokemon:get(starter.species) or nil
    if type(starter) ~= "table" or not speciesDef then return false end

    local level = starterLevelFor(starter.species)
    local oldMaxHp = starter.stats and starter.stats.hp or starter.hp or 1
    local hpLost = math.max(0, oldMaxHp - (tonumber(starter.hp) or oldMaxHp))
    starter.dvs = starter.dvs or { hp=0, attack=0, defense=0, speed=0, special=0 }
    starter.statExp = starter.statExp or { hp=0, attack=0, defense=0, speed=0, special=0 }
    starter.level = level
    starter.exp = expForLevel(speciesDef.growthRate, level)
    starter.stats = recalculateStarterStats(speciesDef, level, starter.dvs, starter.statExp)
    starter.hp = math.max(1, starter.stats.hp - hpLost)
    state.starterLeveled = true
    return true
  end

  local function activeRuleNames(rules)
    local names = {}
    local labels = {
      randomize_leaders="LEADERS", randomize_teams="TEAMS", randomize_levels="LEVELS",
      preserve_theme="THEMES", enforce_stage="STAGES", randomize_moves="MOVES",
      randomize_held_items="ITEMS",
    }
    for key, label in pairs(labels) do if rules and rules[key] then names[#names + 1] = label end end
    table.sort(names)
    return #names > 0 and table.concat(names, ", ") or "VANILLA RULES"
  end

  local function challengeStartSummary(state, firstGym)
    local rules = planForSave().rules or {}
    return "GYM CHALLENGE READY!\fFIRST GYM: " .. tostring(firstGym and firstGym.name or "UNKNOWN")
      .. "\nPRESET: " .. tostring(rules.preset or "MANUAL")
      .. "\nRULES: " .. activeRuleNames(rules)
  end

  local function beginAcceptedChallenge(game)
    if challengeActive() then return false end
    local state = saveChallenge({
      enabled=true,
      phase=isGold and "johto" or "kanto",
      completed={},
      acceptedPostIntro=true,
    })
    if not levelAcceptedStarter(game, state) then
      setRouteStatus(state, "PAUSED", nil, "NATIVE STARTER NOT READY")
      saveChallenge(state)
      mod.log:warn("Gym Challenge could not locate the native starter after the milestone")
      return false, state
    end
    local firstGym = nextChallengeGym(state, game)
    if not queueGymWarp(state, firstGym) then
      saveChallenge(state)
      return false, state, firstGym
    end
    saveChallenge(state)
    return true, state, firstGym
  end

  local function offerChallengeAtMilestone(game)
    if challengeActive() or mod.save:get(GYM_CHALLENGE_OFFERED_KEY) then return false end
    mod.save:set(GYM_CHALLENGE_OFFERED_KEY, true)
    showChallengeChoice(game, "YOU HAVE CLEARED THE\nOPENING TRIAL!\fWILL YOU TAKE THE\nGYM CHALLENGE?", function(yes)
      if not yes then return end
      showChallengeText(game, "GYM CHALLENGE\nACCEPTED!", function()
        local started, state, firstGym = beginAcceptedChallenge(game)
        if not started then
          showChallengeText(game, "CHALLENGE ROUTING\nIS PAUSED.\fOPEN PROGRESS HISTORY\nFOR THE STATUS.")
          return
        end
        showChallengeText(game, challengeStartSummary(state, firstGym), function()
          healChallengeParty(function() warpQueuedGym() end)
        end)
      end)
    end)
    return true
  end

  local function postIntroMilestoneReady(game)
    local flags = game and game.save and game.save.flags or {}
    local map = game and game.world and game.world.map
    local mapId = map and map.id
    if isGold then
      return mapId == "ELMS_LAB" and flags.EVENT_GAVE_MYSTERY_EGG_TO_ELM == true
    end
    return mapId == "OAKS_LAB" and mod.save:get(GYM_CHALLENGE_PENDING_KEY) == true
      and flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB == true
  end

  local PRE_EVOLUTION
  local SPECIES = {}
  local function buildSpeciesIndex()
    if PRE_EVOLUTION then return end
    PRE_EVOLUTION, SPECIES = {}, {}
    local maxDex = liveDexLimit()
    for speciesId, pokemon in mod.content.pokemon:each() do
      local dex = tonumber(pokemon and pokemon.dex)
      if type(speciesId) == "string" and dex and dex >= 1 and dex <= maxDex
          and type(pokemon.baseStats) == "table" then
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
    local preset = mod.options:get("difficulty_preset") or "MANUAL"
    local rules = {
      randomize_leaders=mod.options:get("randomize_leaders") == true,
      randomize_teams=mod.options:get("randomize_teams") == true,
      randomize_levels=mod.options:get("randomize_levels") == true,
      level_variation=math.floor(tonumber(mod.options:get("level_variation")) or 3),
      preserve_theme=mod.options:get("preserve_theme") == true,
      enforce_stage=mod.options:get("enforce_stage") == true,
      randomize_moves=mod.options:get("randomize_moves") == true,
      randomize_held_items=isGold and mod.options:get("randomize_held_items") == true,
      preset=preset,
    }
    if preset == "STORY_FRIENDLY" then
      rules.randomize_levels, rules.level_variation = true, 1
    elseif preset == "CHALLENGE" then
      rules.randomize_leaders, rules.randomize_teams, rules.randomize_levels = true, true, true
      rules.level_variation, rules.preserve_theme, rules.enforce_stage = 3, true, true
      rules.randomize_moves = true
      rules.randomize_held_items = isGold
    elseif preset == "CHAOS" then
      rules.randomize_leaders, rules.randomize_teams, rules.randomize_levels = true, true, true
      rules.level_variation, rules.preserve_theme, rules.enforce_stage = 8, false, false
      rules.randomize_moves = true
      rules.randomize_held_items = isGold
    end
    return rules
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

  planForSave = function()
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

  local ACTIONS = {
    rebuild_action=true, challenge_log_action=true, challenge_progress_action=true,
    challenge_hint_action=true, abandon_challenge_action=true,
  }
  local pendingGuideReward
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

  local function abandonChallenge()
    local game, state = mod.game, challengeActive()
    if not state then
      showChallengeText(game, "NO GYM CHALLENGE\nIS ACTIVE.")
      return
    end
    showChallengeChoice(game, "ABANDON THIS GYM\nCHALLENGE SAVE?\fNATIVE BADGES, STORY,\nPARTY, AND ITEMS STAY.", function(yes)
      if not yes then
        showChallengeText(game, "GYM CHALLENGE\nCONTINUES.")
        return
      end
      pendingGuideReward = nil
      mod.save:set(GYM_CHALLENGE_KEY, nil)
      mod.save:set("challenge_plan", nil)
      mod.log:info("Randomized Gym Challenge: active challenge and generated plan cleared by player")
      showChallengeText(game, "GYM CHALLENGE\nABANDONED.\fNATIVE GAME FLOW\nCONTINUES.")
    end)
  end

  local function openProgressHistory()
    local game, state = mod.game, challengeActive()
    if not state then showChallengeText(game, "NO GYM CHALLENGE\nIS ACTIVE.") return end
    local lines = { isGold and ("GYM CHALLENGE " .. string.upper(state.phase or "JOHTO")) or "GYM CHALLENGE" }
    lines[#lines + 1] = crystal251Active() and "CRYSTAL 251: READY" or "CRYSTAL 251: NOT ACTIVE"
    local last = state.lastRoute or {}
    local routeTarget = last.gym and ((BY_ID[last.gym] and BY_ID[last.gym].name) or last.gym) or "NONE"
    lines[#lines + 1] = "ROUTE: " .. tostring(last.status or "IDLE") .. "\nTARGET: " .. routeTarget
    if last.reason then lines[#lines + 1] = "STATUS: " .. tostring(last.reason) end
    for _, gym in ipairs(challengePhaseGyms(state)) do
      local nextGym = nextChallengeGym(state, game)
      local status = state.completed[gym.id] and "DONE" or (nextGym and nextGym.id == gym.id and "NEXT" or "WAIT")
      local reward = state.guideRewards[gym.id]
      local rewardText = reward and (rewardItemName(reward) .. " x" .. tostring(state.guideQuantities[gym.id] or 1)) or "PENDING"
      lines[#lines + 1] = string.format("%s %s\n%s", status, gym.name, rewardText)
    end
    showChallengeText(game, table.concat(lines, "\f"))
  end

  local function showNextGymHint()
    local game, state = mod.game, challengeActive()
    local gym = state and nextChallengeGym(state, game)
    if not gym then
      showChallengeText(game, state and "NO MORE GYMS\nIN THIS PHASE." or "NO GYM CHALLENGE\nIS ACTIVE.")
      return
    end
    local last = state.lastRoute or {}
    local suffix = last.status == "PAUSED" and ("\fROUTING PAUSED:\n" .. tostring(last.reason or "CHECK PROGRESS HISTORY")) or ""
    showChallengeText(game, "YOUR NEXT CHALLENGE:\n" .. gym.name .. "\n" .. gym.mapId .. suffix)
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

  -- The challenge offer is intentionally not injected into Oak's introduction.
  -- It is presented only after the native starter-and-rival milestone in Gen 1
  -- or the native Mystery Egg handoff to Elm in Gold.

  local function completeEarnedGyms(game)
    local state = challengeActive()
    if not state then return false end
    local completedGym
    for _, gym in ipairs(challengePhaseGyms(state)) do
      if not state.completed[gym.id] and badgeOwned(game, gym) then
        state.completed[gym.id] = true
        completedGym = gym
        mod.log:info("Gym Challenge completed physical gym %s", gym.id)
      end
    end
    if not completedGym then return false end

    local nextGym = nextChallengeGym(state, game)
    if nextGym then
      state.warpAfterScript = queueGymWarp(state, nextGym)
      if not state.warpAfterScript then
        mod.log:warn("Gym Challenge routing paused after %s because no valid next destination exists", completedGym.id)
      end
    elseif isGold and state.phase == "johto" then
      -- The first league remains a native story segment. Champion victory later
      -- unlocks the post-credits Continue checkpoint; no Kanto warp occurs yet.
      state.phase = "league1"
      state.warpAfterScript = false
      state.teleportEnabled = false
    elseif isGold and state.phase == "kanto" then
      -- The second league is also native. After the final Kanto gym, the player
      -- continues naturally to the second Elite Four and Champion.
      state.phase = "league2"
      state.warpAfterScript = false
      state.teleportEnabled = false
    else
      state.phase = "complete"
      state.warpAfterScript = false
      state.teleportEnabled = false
      state.completionNoticePending = true
    end
    saveChallenge(state)
    return completedGym
  end

  local function offerGoldLeaderFallback(game, gym, onDone)
    onDone = onDone or function() end
    local state = challengeActive()
    if not (isGold and state and state.guideFallback and state.guideFallback[gym.id]
      and not (state.guideRewards and state.guideRewards[gym.id])) then
      onDone()
      return
    end
    local itemId, status, quantity = claimGuideReward(game, gym)
    if status ~= "granted" then
      onDone()
      return
    end
    showChallengeText(game, "THE LEADER LEAVES\nA PARTING GIFT!\fTAKE THIS WITH YOU:\n"
      .. rewardItemName(itemId) .. ((quantity and quantity > 1) and (" x" .. quantity) or "") .. "!", onDone)
  end

  local function advanceChallengeAfterReward(game, overworld)
    local completedGym = completeEarnedGyms(game)
    if not completedGym then return false end
    local state = challengeActive()
    if state and state.completionNoticePending then
      state.completionNoticePending = false
      saveChallenge(state)
      showChallengeText(game, "GYM CHALLENGE COMPLETE!\nALL PHYSICAL GYMS CLEARED.\fTHE NATIVE LEAGUE STORY\nREMAINS YOUR NEXT STEP.")
      return true
    end
    if state and state.warpAfterScript and state.teleportEnabled ~= false then
      local function continueRoute()
        state.warpAfterScript = false
        saveChallenge(state)
        healChallengeParty(function() warpQueuedGym() end)
      end
      if isGold then offerGoldLeaderFallback(game, completedGym, continueRoute) else continueRoute() end
      return true
    end
    return true
  end

  -- The guide is identified from the live interaction target rather than a
  -- coordinate table. Native Gym Guide dialogue runs first; the extra
  -- encouragement box is shown only after that native interaction completes.
  pendingGuideReward = nil
  local function guideForInteraction(event)
    local gym = event and BY_MAP[event.mapId]
    local npc = event and event.kind == "npc" and event.target
    local def = npc and npc.def
    if not (gym and def and def.index ~= gym.objectIndex and def.sprite == "SPRITE_GYM_GUIDE") then return nil end
    if def.trainer or def.trainerClass then return nil end
    return gym
  end

  local function deliverGuideReward(game, gym, done)
    done = done or function() end
    local itemId, status, quantity = claimGuideReward(game, gym)
    if status == "inactive" or status == "unavailable" then done(); return end
    local text = guideEncouragementText(gym, itemId, status, quantity)
    showChallengeText(game, text, done)
  end

  mod.events:on("world.interacted", function(event)
    local state = challengeActive()
    local gym = state and guideForInteraction(event)
    if gym and not (state.guideRewards and state.guideRewards[gym.id]) then
      pendingGuideReward = { gym=gym, game=mod.game }
    end
  end)

  mod.events:on("script.ended", function(event)
    if not (event and event.completed) then return end
    local milestoneGame = mod.game
    if postIntroMilestoneReady(milestoneGame)
      and not challengeActive() and not mod.save:get(GYM_CHALLENGE_OFFERED_KEY) then
      if not isGold then mod.save:set(GYM_CHALLENGE_PENDING_KEY, nil) end
      offerChallengeAtMilestone(milestoneGame)
      return
    end
    if isGold and pendingGuideReward then
      local pending = pendingGuideReward
      pendingGuideReward = nil
      deliverGuideReward(pending.game, pending.gym)
      return
    end
    local state = challengeActive()
    if not state then return end
    local game = mod.game
    if state.warpAfterScript then
      -- The native starter/reward script has completed. Heal through the
      -- engine command, then move to the already chosen physical gym.
      state.warpAfterScript = false
      saveChallenge(state)
      healChallengeParty(function() warpQueuedGym() end)
      return
    end
    advanceChallengeAfterReward(game, game and game.world)
  end)

  mod.events:on("battle.ended", function(event)
    local battle = event and event.battle
    if not isGold then
      local game = mod.game
      local map = game and game.world and game.world.map
      local trainer = battle and battle.trainer or {}
      local classId = trainer.classId or trainer.class or trainer.id
      if event and event.result == "win" and map and map.id == "OAKS_LAB"
        and (classId == "RIVAL1" or classId == "OPP_RIVAL1" or classId == "RIVAL") then
        -- The native exit script writes EVENT_BATTLED_RIVAL_IN_OAKS_LAB after
        -- this event. `script.ended` below waits for that completed script.
        mod.save:set(GYM_CHALLENGE_PENDING_KEY, true)
      end
      return
    end

    local state = challengeActive()
    if not (state and (state.phase == "league1" or state.phase == "league2")
      and event.result == "win" and battle and battle.trainer
      and (battle.trainer.classId or battle.trainer.class) == "CHAMPION") then return end
    state.championDefeated = true
    state.teleportEnabled = false
    if state.phase == "league2" then
      state.phase = "complete"
      state.completionNoticePending = true
    end
    saveChallenge(state)
  end)

  mod.events:on("map.entered", function(event)
    local state = challengeActive()
    if not state then return end
    -- Gold's first Hall of Fame returns to the title screen. The next Continue
    -- must preserve the native post-game spawn and ask before restarting Gym
    -- Challenge routing for Kanto.
    if isGold and state.phase == "league1" and state.championDefeated
      and event and event.mapId == "NEW_BARK_TOWN" and event.via == "boot" then
      state.championDefeated = false
      state.teleportEnabled = false
      state.phase = "awaiting_kanto_opt_in"
      saveChallenge(state)
      showChallengeChoice(mod.game,
        "THE FIRST LEAGUE IS\nCOMPLETE.\fCONTINUE THE GYM\nCHALLENGE IN KANTO?",
        function(yes)
          if not yes then
            showChallengeText(mod.game, "KANTO CHALLENGE\nNOT STARTED.\fYOU CAN CONTINUE\nNATIVELY.")
            saveChallenge(state)
            return
          end
          state.phase = "kanto"
          state.teleportEnabled = true
          local nextGym = nextChallengeGym(state, mod.game)
          if nextGym and queueGymWarp(state, nextGym) then
            saveChallenge(state)
            showChallengeText(mod.game, "KANTO CHALLENGE\nACCEPTED!\fTHE NEXT GYM\nIS AHEAD.", function()
              healChallengeParty(function() warpQueuedGym() end)
            end)
          else
            state.phase = "awaiting_kanto_opt_in"
            state.teleportEnabled = false
            setRouteStatus(state, "PAUSED", nextGym, "NO VALID KANTO DESTINATION")
            saveChallenge(state)
            showChallengeText(mod.game, "KANTO ROUTING\nIS PAUSED.\fOPEN PROGRESS HISTORY\nFOR THE STATUS.")
          end
        end)
    end
  end)

  mod.events:on("screen.popped", function()
    if not isGold and pendingGuideReward then
      local pending = pendingGuideReward
      pendingGuideReward = nil
      deliverGuideReward(pending.game, pending.gym)
      return
    end
  end)

  if isGold then
    local function paint(npc, sprite)
      local def = mod.content.sprites:get(sprite)
      if not (npc and def) then return end
      npc.def.sprite = sprite
      if npc.setSpriteDef then npc:setSpriteDef(def) end
    end

    local GOLD_GUIDE_OBJECTS = {}
    for _, gym in ipairs(GYMS) do
      local map = mod.content.maps:get(gym.mapId)
      for arrayIndex, object in ipairs(map and map.objects or {}) do
        local objectIndex = object.index or arrayIndex
        if objectIndex ~= gym.objectIndex and object.sprite == "SPRITE_GYM_GUIDE"
          and not object.trainer and not object.trainerClass then
          GOLD_GUIDE_OBJECTS[gym.id] = { mapId=gym.mapId, objectIndex=objectIndex }
          break
        end
      end
    end

    local function applyGoldGym(mapId)
      local gym = BY_MAP[mapId]
      if not gym then return end
      local plan = planForSave()
      local visitor = visitorFor(gym, plan)
      local handle = mod.world:npc(mapId, gym.objectIndex)
      if handle and handle.npc then paint(handle.npc, visitor.sprite) end

      -- Most Gold gyms expose a native Gym Guide. Seafoam and any future map
      -- without a live guide use the post-leader fallback instead, so every
      -- Gym Challenge stop still offers exactly one encouragement reward.
      local state = challengeActive()
      if state and not (state.guideRewards and state.guideRewards[gym.id]) then
        local guide = GOLD_GUIDE_OBJECTS[gym.id]
        local guideHandle = guide and mod.world:npc(guide.mapId, guide.objectIndex)
        if not (guideHandle and guideHandle.npc) then
          state.guideFallback[gym.id] = true
          saveChallenge(state)
        end
      end
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
      if crystal251Active() then mod.log:info("Randomized Gym Challenge: Crystal 251 detected; using imported live registries") end
      if game and game.world and game.world.map then applyGoldGym(game.world.map.id) end
    end)
    mod.events:on("screen.popped", resetActions)
  else
    local SpriteRenderer = require("src.render.SpriteRenderer")

    -- Gen 1 statues are a live engine table keyed by the physical gym map.
    -- Project only the visiting leader name; the city and physical badge stay
    -- native. Gold has no equivalent hidden-event statue path.
    local projectGymStatues
    do
      local ok, statues = pcall(require, "data.scripts.gyms")
      if ok and type(statues) == "table" then
        local baseNames = {}
        for _, gym in ipairs(GYMS) do
          baseNames[gym.mapId] = statues[gym.mapId] and statues[gym.mapId].leader
        end
        projectGymStatues = function(plan)
          for _, physical in ipairs(GYMS) do
            local visitor = plan and plan.rules and plan.rules.randomize_leaders
              and visitorFor(physical, plan) or physical
            local statue = statues[physical.mapId]
            if statue then statue.leader = baseNames[visitor.mapId] or visitor.name end
          end
        end
      else
        mod.log:warn("Randomized Gym Challenge: Gen 1 gym statues unavailable")
      end
    end

    local function sourceLeaderText(gym)
      local map = mod.content.maps:get(gym.mapId)
      for _, object in ipairs(map and map.objects or {}) do
        if object.index == gym.objectIndex and object.text then return map.label, object.text end
      end
      return nil, nil
    end

    -- Build trainer records from imported map data rather than carrying a ROM
    -- coordinate table. The source roster stays tied to the visiting leader’s
    -- original gym; the destination record supplies the physical level curve.
    local GYM_TRAINERS_BY_GYM, LIVE_GYM_TRAINERS = {}, {}
    for _, physicalGym in ipairs(GYMS) do
      local records = {}
      local map = mod.content.maps:get(physicalGym.mapId)
      for arrayIndex, object in ipairs(map and map.objects or {}) do
        local objectIndex = object.index or arrayIndex
        if objectIndex ~= physicalGym.objectIndex and object.trainerClass and object.trainerParty then
          local trainer = mod.content.trainers:get(object.trainerClass)
          local party = trainer and trainer.parties and trainer.parties[object.trainerParty]
          if party and #party > 0 then
            records[#records + 1] = {
              key=physicalGym.id .. ":" .. tostring(objectIndex), gymId=physicalGym.id,
              mapId=physicalGym.mapId, objectIndex=objectIndex,
              trainerClass=object.trainerClass, trainerParty=object.trainerParty,
              sprite=object.sprite, text=object.text, vanillaParty=clone(party),
            }
          end
        end
      end
      GYM_TRAINERS_BY_GYM[physicalGym.id] = records
    end

    local function sourceGymTrainer(destination, plan)
      if not (plan and plan.rules and plan.rules.randomize_leaders) then return destination end
      local visitor = visitorFor(BY_ID[destination.gymId], plan)
      local source = GYM_TRAINERS_BY_GYM[visitor.id] or {}
      if #source == 0 then return destination end
      return pick(source, "support:" .. destination.key, plan.seed) or destination
    end

    local function supportTrainerParty(destination, source, gym, plan)
      local party, used = {}, {}
      for index, target in ipairs(destination.vanillaParty or {}) do
        local sourceMon = (source.vanillaParty or {})[math.min(index, #(source.vanillaParty or {}))]
          or (source.vanillaParty or {})[1] or target
        local level = levelFor(target.level, plan.rules, "support:" .. destination.key .. ":" .. index, plan.seed)
        local species, changed = sourceMon.species, false
        if plan.rules.randomize_teams then
          local stage = plan.rules.enforce_stage and stageFor(target.species) or nil
          local types = plan.rules.preserve_theme and gym.types or nil
          local ordered = shuffle(eligibleSpecies(types, stage), "support:" .. destination.key .. ":species:" .. index, plan.seed)
          species = ordered[1] or species
          for _, candidate in ipairs(ordered) do
            if not used[candidate] then species = candidate; break end
          end
          changed = species ~= sourceMon.species
        end
        used[species] = true
        local entry = clone(sourceMon)
        entry.species, entry.level = species, level
        if changed then entry.moves, entry.item = nil, nil end
        if plan.rules.randomize_moves then
          entry.moves = generatedMoves(species, level, "support:" .. destination.key .. ":" .. index, plan.seed)
        end
        party[#party + 1] = entry
      end
      return party
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
      -- The engine schedules onVictory beneath the native leader reward flow.
      -- `advanceChallengeAfterReward` still verifies physical badge ownership,
      -- so a normal gym-trainer victory cannot advance the challenge.
      mod.content.map_scripts:register(gym.mapId, {
        priority=90,
        onVictory=function(game, overworld)
          if challengeActive() then advanceChallengeAfterReward(game, overworld) end
        end,
      })
    end

    local function supportTrainerTalk(destination)
      return function(game, overworld, npc, done)
        done = done or function() end
        local plan = planForSave()
        local source = sourceGymTrainer(destination, plan)
        local header = game and game.data and game.data.trainerHeader
          and game.data:trainerHeader(source.mapId, source.objectIndex)
        local text = game and game.data and game.data.text or {}
        if npc and npc.facePlayer and overworld and overworld.player then npc:facePlayer(overworld.player) end
        if game.save.defeatedTrainers and game.save.defeatedTrainers[npc.id] then
          local after = header and header.after and text[header.after]
          if after then
            local TextBox = require("src.render.TextBox")
            game.stack:push(TextBox.new(game, after, done))
          else
            done()
          end
          return
        end
        local battleText = header and header.battle and text[header.battle]
        local wonText = header and header.won and text[header.won]
        local function engage() overworld:engageTrainer(npc, done, wonText, battleText ~= nil) end
        if battleText then
          local TextBox = require("src.render.TextBox")
          game.stack:push(TextBox.new(game, battleText, engage))
        else
          engage()
        end
      end
    end

    for _, records in pairs(GYM_TRAINERS_BY_GYM) do
      for _, trainer in ipairs(records) do
        if trainer.text then
          mod.content.map_scripts:register(trainer.mapId, {
            priority=110, talk={ [trainer.text]=supportTrainerTalk(trainer) },
          })
        end
      end
    end

    local function applySupportTrainers(gym, plan)
      for _, destination in ipairs(GYM_TRAINERS_BY_GYM[gym.id] or {}) do
        local handle = mod.world:npc(gym.mapId, destination.objectIndex)
        local npc = handle and handle.npc
        if npc then
          local source = sourceGymTrainer(destination, plan)
          npc.def.trainerClass, npc.def.trainerParty = source.trainerClass, source.trainerParty
          paint(npc, source.sprite or destination.sprite)
          LIVE_GYM_TRAINERS[npc.id] = { npc=npc, gym=gym, destination=destination, source=source }
        end
      end
    end

    local function applyGen1Gym(mapId)
      local gym = BY_MAP[mapId]
      if not gym then return end
      local plan = planForSave()
      if projectGymStatues then projectGymStatues(plan) end
      local visitor = visitorFor(gym, plan)
      local handle = mod.world:npc(mapId, gym.objectIndex)
      local npc = handle and handle.npc
      if not npc then return end
      npc.def.trainerClass = visitor.id
      npc.def.trainerParty = visitor.partyIndex
      paint(npc, plan.rules.randomize_leaders and leaderSprite(visitor) or leaderSprite(gym))
      LIVE[npc.id] = { npc=npc, gym=gym, visitor=visitor }
      applySupportTrainers(gym, plan)
    end

    local pendingGym
    mod.events:on("map.entered", function(event) applyGen1Gym(event and event.mapId) end)
    mod.events:on("world.trainer_engaged", function(event)
      local record = event and event.npc and LIVE[event.npc.id]
      if record then
        event.npc.def.trainerClass, event.npc.def.trainerParty = record.visitor.id, record.visitor.partyIndex
        pendingGym = record
        return
      end
      local support = event and event.npc and LIVE_GYM_TRAINERS[event.npc.id]
      if support then
        event.npc.def.trainerClass, event.npc.def.trainerParty = support.source.trainerClass, support.source.trainerParty
        pendingGym = { support=true, record=support }
      end
    end)

    mod.hooks:wrap("trainer.party", function(next, trainerClass, partyIndex, party)
      party = next(trainerClass, partyIndex, party)
      local pending = pendingGym
      if pending and pending.support then
        local record = pending.record
        if trainerClass == record.source.trainerClass and partyIndex == record.source.trainerParty then
          local replacement = supportTrainerParty(record.destination, record.source, record.gym, planForSave())
          if type(replacement) == "table" and #replacement > 0 then return clone(replacement) end
        end
      elseif pending and trainerClass == pending.visitor.id and partyIndex == pending.visitor.partyIndex then
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
      local support = origin and LIVE_GYM_TRAINERS[origin.npcId]
      if support then
        support.npc.def.trainerClass, support.npc.def.trainerParty = support.destination.trainerClass, support.destination.trainerParty
      end
      pendingGym = nil
    end)
    mod.events:on("game.ready", function(event)
      resetActions()
      local game = event and event.game or mod.game
      if crystal251Active() then mod.log:info("Randomized Gym Challenge: Crystal 251 detected; using imported live registries") end
      if game and game.world and game.world.map then applyGen1Gym(game.world.map.id) end
    end)
    mod.events:on("screen.popped", resetActions)
  end

  mod.events:on("game.ready", function()
    -- The prior build could activate a challenge during Oak's introduction. Clear
    -- only incomplete states from that retired flow; earned-gym progress is
    -- preserved if a player somehow progressed before installing this fix.
    local state = challengeState()
    if state and not state.acceptedPostIntro and next(state.completed or {}) == nil then
      mod.save:set(GYM_CHALLENGE_KEY, nil)
    end
    mod.save:set(GYM_CHALLENGE_PROMPT_KEY, nil)
    mod.save:set(GYM_CHALLENGE_PENDING_KEY, nil)
  end)

  mod.hooks:wrap("save.new_game", function(next, save)
    save = next(save)
    mod.save:set("challenge_plan", nil)
    mod.save:set(GYM_CHALLENGE_KEY, nil)
    mod.save:set(GYM_CHALLENGE_PROMPT_KEY, nil)
    mod.save:set(GYM_CHALLENGE_OFFERED_KEY, nil)
    mod.save:set(GYM_CHALLENGE_PENDING_KEY, nil)
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
    elseif event.key == "challenge_progress_action" and event.value then
      resetActions()
      openProgressHistory()
    elseif event.key == "challenge_hint_action" and event.value then
      resetActions()
      showNextGymHint()
    elseif event.key == "abandon_challenge_action" and event.value then
      resetActions()
      abandonChallenge()
    elseif not ACTIONS[event.key] and mod.save:get("challenge_plan") then
      mod.log:info("Randomized Gym Challenge: a plan already exists for this save; use REBUILD CHALLENGE (TEST) after changing rules")
    end
  end)
end
