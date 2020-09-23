Cell = {}

function Cell:new(x, y, g)
  local c = setmetatable({}, { __index = Cell })
  c.x = x ~= nil and x or 0
  c.y = y ~= nil and y or 0
  c.generation = g ~= nil and g or 0
  c.structure_name = structures:first() -- typically HIVE
  c.id = "cell-" .. fn.id() -- unique identifier for this cell
  c.index = fn.index(c.x, c.y) -- location on the grid
  c.flag = false -- multipurpse flag used through the keeper:collision() lifecycle
  c.save_keys = {}
  c.menu_getters = {}
  c.menu_setters = {}
  bearing_mixin.init(self)
  capacity_mixin.init(self)
  channel_mixin.init(self)
  charge_mixin.init(self)
  clockwise_mixin.init(self)
  crow_out_mixin.init(self)
  crumble_mixin.init(self)
  deflect_mixin.init(self)
  device_mixin.init(self)
  docs_stub_mixin.init(self)
  drift_mixin.init(self)
  duration_mixin.init(self)
  er_mixin.init(self)
  level_mixin.init(self)
  metabolism_mixin.init(self)
  network_mixin.init(self)
  notes_mixin.init(self)
  offset_mixin.init(self)
  operator_mixin.init(self)
  ports_mixin.init(self)
  probability_mixin.init(self)
  pulses_mixin.init(self)
  range_mixin.init(self)
  resilience_mixin.init(self)
  state_index_mixin.init(self)
  structure_stub_mixin.init(self)
  territory_mixin.init(self)
  topography_mixin.init(self)
  turing_mixin.init(self)
  velocity_mixin.init(self)
  --[[ walk softly and carry a big stick
       aka measure twice cut once
       aka shit got spooky when i had params floating the init()s ]]
  c.setup_bearing(c)
  c.setup_capacity(c)
  c.setup_channel(c)
  c.setup_charge(c)
  c.setup_clockwise(c)
  c.setup_crow_out(c)
  c.setup_crumble(c)
  c.setup_deflect(c)
  c.setup_device(c)
  c.setup_docs_stub(c)
  c.setup_drift(c)
  c.setup_duration(c)
  c.setup_er(c)
  c.setup_level(c)
  c.setup_metabolism(c)
  c.setup_network(c)
  c.setup_notes(c)
  c.setup_offset(c)
  c.setup_operator(c)
  c.setup_ports(c)
  c.setup_probability(c)
  c.setup_pulses(c)
  c.setup_range(c)
  c.setup_resilience(c)
  c.setup_state_index(c)
  c.setup_structure_stub(c)
  c.setup_territory(c)
  c.setup_topography(c)
  c.setup_turing(c)
  c.setup_velocity(c)
  return c
end

function Cell:register_save_key(key)
  table.insert(self.save_keys, key)
end

function Cell:get_save_keys()
  return self.save_keys
end

function Cell:register_menu_setter(key, setter)
  self.menu_setters[key] = setter
end

function Cell:register_menu_getter(key, getter)
  self.menu_getters[key] = getter
end

function Cell:set_attribute_value(key, value)
  if self.menu_setters[key] ~= nil then
    self.menu_setters[key](self, value)
  else
    print("Error: No match for cell attribute " .. key)
  end
end

function Cell:get_menu_value_by_attribute(a)
  if self.menu_getters[a] ~= nil then
    return self.menu_getters[a]
  end
end

function Cell:is(name)
  return self.structure_name == name
end

function Cell:has(name)
  return fn.table_has(self:get_attributes(), name)
end

function Cell:get_attributes()
  return structures:get_structure_attributes(self.structure_name)
end

function Cell:change(name)
  local match = false
  for k, v in pairs(structures:all_enabled()) do
    if v.name == name then
      self:set_structure_by_name(name)
      match = true
    end
  end
  if not match then
    self:set_structure_by_name(structures:first())
  end
end

function Cell:set_structure_by_name(name)
  self.structure_name = name
  self:change_checks()
end

function Cell:prepare_for_paste(x, y, g)
  self.x = x
  self.y = y
  self.generation = g
  self.id = "cell-" .. fn.id()
  self.index = fn.index(self.x, self.y)
  self.flag = false
  self:set_available_ports()
end

function Cell:menu_items()
  local items = fn.deep_copy(self:get_attributes())
  items = self:inject_notes_into_menu(items)
  return items
end

--[[
from here out we get into what is essentially "descendent class behaviors"
since all cells can change structures at any time, it makes no sense to
actually implement classes for each one. that would result in lots of
creating and destroying objects for no real benefit other than having these
behaviors encapsulated in their own classes. and as of writing this
theres  only ~40 lines of code below...
]]

-- to keep traits reasonably indempotent, even though the have to interact with one another
function Cell:callback(method)
  if method == "set_state_index" then
    if self:is("CRYPT") then s:crypt_load(self.state_index) end
  elseif method == "set_metabolism" then
    if self:has("PULSES") and self.pulses > self.metabolism then self.pulses = self.metabolism end
    if self:is("DOME") then self:set_er() end
  elseif method == "set_pulses" then
    if self:is("DOME") then self:set_er() end
  elseif method == "set_bearing" then
    if self:is("WINDFARM") then self:close_all_ports() self:open_port(self:get_bearing_cardinal()) end
  end
end

-- sometimes when a cell changes, attributes need to be cleaned up
function Cell:change_checks()
  local max_state_index = self:is("CRYPT") and 6 or 8
  self:set_max_state_index(max_state_index)

  if self:is("DOME") then
    self:set_er()

  elseif self:is("SHRINE") 
    or self:is("AVIARY")
    or self:is("SPOMENIK") then 
      self:set_note_count(1)
      self:setup_notes(1)

  elseif self:is("TOPIARY") 
    or self:is("CASINO") 
    or self:is("FOREST") 
    or self:is("AUTON") then
        self:set_note_count(8)
        self:setup_notes(8)

  elseif self:is("CRYPT") then
    self:set_state_index(1) 
    self:cycle_state_index(0)

  elseif self:is("KUDZU") then
    self:set_metabolism(params:get("kudzu_metabolism"))
    self:set_resilience(params:get("kudzu_resilience"))
    self:set_crumble(params:get("kudzu_crumble"))

  elseif self:is("WINDFARM") then
    self:close_all_ports()
    self:open_port(self:get_bearing_cardinal())

  end
end

-- all signals are "spawned" but only under certain conditions
function Cell:is_spawning()
  if self:is("DOME") and self.metabolism ~= 0 then
    return self.er[fn.cycle((counters:this_beat() - self.offset) % self.metabolism, 0, self.metabolism)]
  elseif self:is("MAZE") and self.metabolism ~= 0 then
    return self.turing[fn.cycle((counters:this_beat() - self.offset) % self.metabolism, 0, self.metabolism)]
  elseif self:is("SOLARIUM") and self.flag then
    return true
  elseif self:is("HIVE") or self:is("RAVE") or self:is("WINDFARM") then
    return self:inverted_metabolism_check()
  end
end

-- does this cell need to do anything to boot up this beat?
function Cell:setup()
      if self:is("RAVE") and self:is_spawning() then self:drugs()
  elseif self:is("MAZE") then self:set_turing()
  elseif self:is("SOLARIUM") then self:compare_capacity_and_charge()
  elseif self:is("MIRAGE") then self:shall_we_drift_today()
  elseif self:is("BANK") then self:annual_report()
  elseif self:is("INSTITUTION") then self:has_crumbled()
  elseif self:is("KUDZU") then self:close_all_ports() self:lifecycle()
  end
end

-- does this cell need to do any cleanup activities?
function Cell:teardown()
  if self:is("SOLARIUM") and self.flag == true then
    self.flag = false
    self:invert_ports()
  elseif self:is("WINDFARM") and self:inverted_metabolism_check() then
    local direction = self:get_clockwise() and 1 or -1
    self:cycle_bearing(direction)
  end
end

-- for kudzu
function Cell:lifecycle()
  if not self:inverted_metabolism_check() then return end
  if (math.random(0, 99) > self.resilience) then
    self.crumble = self.crumble - 1
    self:has_crumbled()
  end
end

-- for institutions & kudzu
function Cell:has_crumbled()
  if self.crumble <= 0 then
    keeper:delete_cell(self.id, true, false)
    if keeper.selected_cell_id == self.id then
      keeper:deselect_cell()
    end
    if self:is("INSTITUTION") then self:burst() end
  end
end

-- for institutions
function Cell:burst()
  keeper:create_signal(self.x, self.y - 1, "n", "now")
  keeper:create_signal(self.x + 1, self.y, "e", "now")
  keeper:create_signal(self.x, self.y + 1, "s", "now")
  keeper:create_signal(self.x - 1, self.y, "w", "now")
end

-- for mirages
function Cell:shall_we_drift_today()
  if not self:inverted_metabolism_check() then return end
      if self.drift == 1 then self:move(fn.coin() == 0 and "n" or "s")
  elseif self.drift == 2 then self:move(fn.coin() == 0 and "e" or "w")
  elseif self.drift == 3 then self:move(self.cardinals[math.random(1, 4)])
  end
end

-- for mirages
function Cell:move(direction)
  if not fn.table_find(self.cardinals, direction) then return end
      if direction == "n" and fn.is_cell_vacant(self.x, self.y - 1) then self.y = self.y - 1
  elseif direction == "s" and fn.is_cell_vacant(self.x, self.y + 1) then self.y = self.y + 1
  elseif direction == "e"  and fn.is_cell_vacant(self.x + 1, self.y) then self.x = self.x + 1
  elseif direction == "w"  and fn.is_cell_vacant(self.x - 1, self.y) then self.x = self.x - 1
  end
  self.index = fn.index(self.x, self.y)
  self:set_available_ports()
  if keeper.selected_cell_id == self.id then
    keeper:select_cell(self.x, self.y)
  end
end

-- for solariums
function Cell:compare_capacity_and_charge()
  if self.charge >= self.capacity then
    self.flag = true
    self:set_charge(0)
    self:invert_ports()
  end
end

-- for raves
-- turn on, tune in, drop out... close all the ports, then flip coins to open them
function Cell:drugs()
  self.ports = {}
  for i = 1,4 do
    if fn.coin() == 1 then
      self:open_port(self.cardinals[i])
    end
  end
end
 