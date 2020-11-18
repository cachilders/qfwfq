-- qfwfq
-- a password is the sequencer
--
-- enc 1 = bpm
-- enc 2 = password index
-- enc 3 = change character
-- key 2 = set random password
-- key 3 = run / halt

ASCII = {
  MIN = 32,
  MAX = 122
}
STEPS = 16
BLANK_Y = 55
HACK_Y = 37
POS_Y = 60
STEP_Y = 40
STD_W = 8

engine.name = "PolyPerc"

function init()
  screen.font_face(2)
  run = false
  glyphs = {}
  pwd = {}
  hack = {
    cypher = {},
    solution = {}
  }
  next_glyph = 2
  oct = 4
  pos = 1
  step = 1
  bpm = 120
  shift = false
  counter = metro.init(_step, _time())

  math.randomseed(os.time())

  for i=1, ASCII.MAX - ASCII.MIN do
    glyphs[i] = ASCII.MIN + i - 1
  end

  for i=1, 16 do
    pwd[i] = 1
    hack.solution[i] = 1
    hack.cypher[i] = 1
  end

  redraw()
end

function _set_rnd_pwd()
  for i=1, 16 do
    pwd[i] = math.random(1, #glyphs)
  end

  redraw()
end

function _blanks()
  local x = 2

  for i=1, 16 do
    screen.move(x, BLANK_Y)
    screen.level(2)
    screen.line(x + 5, BLANK_Y)
    x = x + 8
  end

  screen.stroke()
end

function _time()
  return 60 / bpm
end

function _pos_dot()
  screen.move(pos * 8 - 4, POS_Y)
  screen.text('.')
end

function _step_dot()
  local level = pwd[step] == hack.solution[step] and 15 or 1

  screen.level(level)
  screen.move(step * 8 - 4, STEP_Y)
  screen.text('.')
end

function _offset_x(x, glyph)
  local glyph_w = screen.text_extents(glyph)
  local offset = STD_W - glyph_w

  return x + glyph_w + offset
end

function _next_cypher()
  for i=16, 2, -1 do
    hack.cypher[i] = hack.cypher[i-1]
  end

  hack.cypher[1] = next_glyph

  next_glyph = next_glyph < #glyphs and next_glyph + 1 or 1
  -- next_glyph = math.random(1, #glyphs)
end

function _step()
  counter.time = _time()

  _next_cypher()

  step = step < 16 and step + 1 or 1

  redraw()

  _play_note()
end

function _midi_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end

function _play_note()
  local note = pwd[step] == hack.solution[step] and glyphs[hack.solution[step]] or glyphs[1]

  engine.hz(_midi_to_hz(note))
end

function enc(e, d)
  if shift then
    e = e + 3
  end

  if e == 1 then
    bpm = util.clamp(bpm + d, 20, 240)
  elseif e == 2 then
    pos = util.clamp(pos + d, 1, 16)
  elseif e == 3 then
    pwd[pos] = util.clamp(pwd[pos] + d, 1, #glyphs)
  end
  
  redraw()
end

function key(k, z)
  if k == 1 and z == 1 then
    shift = true
  elseif k == 1 and z == 0 then
    shift = false
  end
  
  if k == 2 and z == 0 then
    _set_rnd_pwd()
  elseif k == 3 and z == 0 and run == false then
    run = true
    counter:start()
  elseif k == 3 and z == 0 and run then
    run = false
    counter:stop()
    step = 0
  end
end

function redraw()
  local x = 3
  local y = 6
  
  screen.clear()
  screen.level(3)
  screen.move(x, y)
  screen.text('BPM:  ' .. bpm)
  
  _blanks()
  _pos_dot()
  _step_dot()
  
  for i=1, 16 do
    local glyph = glyphs[pwd[i]]
    
    if hack.cypher[i] == pwd[i] then
      hack.solution[i] = hack.cypher[i]
    elseif  hack.solution[i] ~= pwd[i] then
      hack.solution[i] = glyphs[1]
    end
  
    local i_solved = pwd[i] == hack.solution[i]
    local hack_glyph = i_solved and glyphs[1] or glyphs[hack.cypher[i]]
    local level = i_solved and 15 or 1
    
    screen.level(level)
    screen.move(x, BLANK_Y - 4)
    screen.text(string.char(glyph))
    screen.move(x, HACK_Y - 4)
    screen.text(string.char(hack_glyph))
    x = _offset_x(x, glyph)
  end
  
  screen.stroke()
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
