-- Adaptive Difficulty: the damage you take follows how the run is going.
-- A death eases it by one step; rooms and bosses cleared without dying bring it back, one step at a time.

local S, G = cleria.settings, cleria.game

local enabled = S.get("Enabled", true)
local step = S.get("Step", 10)                -- percent of damage per step
local max_help = S.get("MaxHelp", 50)         -- the most the damage is ever reduced, percent
local rooms_per_step = S.get("RoomsPerStep", 8)
local harder = S.get("Harder", false)         -- may the damage rise above normal on a streak?
local max_harder = 30                         -- percent
local show = S.get("Show", true)

-- The state is outside the saves (cleria.data): a death followed by a reload of an older save still counts.
local st = cleria.json.decode(cleria.data.read("state.json") or "") or {}
st.level = math.tointeger(st.level) or 0      -- > 0: easier by that many steps; < 0: harder
st.rooms = math.tointeger(st.rooms) or 0      -- rooms entered since the last change
local function keep() cleria.data.write("state.json", cleria.json.encode(st)) end

local function lowest() return harder and -(max_harder // math.max(step, 1)) or 0 end
local function highest() return max_help // math.max(step, 1) end
local function factor()
    if not enabled then return 1 end
    local l = math.max(lowest(), math.min(highest(), st.level))
    return 1 - l * step / 100
end
local function describe()
    local f = factor()
    if f == 1 then return "Enemies hit normally" end
    return string.format("Enemies hit at %d%%", math.floor(f * 100 + 0.5))
end
local function move(by, why)
    local before = factor()
    st.level = math.max(lowest(), math.min(highest(), st.level + by))
    st.rooms = 0
    keep()
    if enabled and factor() ~= before then
        cleria.notice(describe() .. " (" .. why .. ")", "Adaptive Difficulty")
        cleria.log(describe() .. " (" .. why .. ")")
    end
end

cleria.events.on("death", function() if enabled then move(1, "you died") end end)
cleria.events.on("boss_defeated", function() if enabled then move(-1, "a boss fell") end end)
cleria.events.on("room_enter", function(e)
    if not enabled or not e.prev_room or e.prev_room == "" or e.prev_room == e.room then return end
    st.rooms = st.rooms + 1
    if st.rooms >= rooms_per_step then move(-1, st.rooms .. " rooms without dying") else keep() end
end)

cleria.combat.add_filter("damage", function(q)
    if q.dir ~= "taken" or q.value <= 0 then return nil end
    local f = factor()
    if f == 1 then return nil end
    return math.max(1, math.floor(q.value * f + 0.5))
end)

cleria.hud.layer("adaptive", function(d)
    if not show or not enabled or not G.in_game() or factor() == 1 then return end
    local s = d.scale
    local text = describe()
    local w = d:text_size(text, {size = 18 * s, font = "cond_medium"})
    local x, y = d.w - w - 38 * s, 14 * s
    d:rect(x, y, w + 24 * s, 32 * s, {color = 0x100F0B, alpha = 0.7, rounding = 4 * s})
    d:text(x + 12 * s, y + 6 * s, text, {size = 18 * s, color = factor() < 1 and "good" or "warn", font = "cond_medium"})
end)

cleria.ui.page("Adaptive Difficulty", function(p)
    p:section("Adaptive Difficulty")
    p:info("Now", enabled and describe() or "Off", {color = factor() < 1 and "good" or (factor() > 1 and "warn" or "value"),
           desc = st.rooms .. " rooms since the last change."})
    local v, ch = p:toggle("Enabled", enabled, "The damage you take follows your deaths. Not a retail option.")
    if ch then enabled = v S.set("Enabled", v) end
    v, ch = p:slider("Step", step, 5, 25, 5, "%.0f%%", "How much one death takes off the damage you receive.")
    if ch then step = math.floor(v + 0.5) S.set("Step", step) end
    v, ch = p:slider("Most help", max_help, 10, 75, 5, "%.0f%%", "The damage is never reduced by more than this.")
    if ch then max_help = math.floor(v + 0.5) S.set("MaxHelp", max_help) end
    v, ch = p:slider("Rooms per step back", rooms_per_step, 1, 30, 1, "%.0f", "Rooms to enter without dying before the damage rises one step. A boss beaten also counts as one step.")
    if ch then rooms_per_step = math.floor(v + 0.5) S.set("RoomsPerStep", rooms_per_step) end
    v, ch = p:toggle("Harder on a streak", harder, "Once back to normal, the same streaks push the damage above normal, up to +" .. max_harder .. "%.")
    if ch then harder = v S.set("Harder", v) move(0, "setting") end
    v, ch = p:toggle("Show in the corner", show, "A line in the top-right corner while the damage is not normal.")
    if ch then show = v S.set("Show", v) end
    if p:button("Back to normal", "Forgets the deaths and the streaks.") then st.level, st.rooms = 0, 0 keep() end
end)

cleria.command("ad", function(a)
    local n = tonumber(a)
    if n then st.level, st.rooms = math.tointeger(n) or 0, 0 keep() end
    cleria.log(string.format("level %d rooms %d factor %.2f: %s", st.level, st.rooms, factor(), describe()))
end)
cleria.log("Adaptive Difficulty loaded: " .. describe())
