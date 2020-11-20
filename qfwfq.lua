-- qfwfq
-- the password is the sequence
--
-- enc 1 = bpm (internal)
-- enc 2 = password index
-- enc 3 = change character
-- key 2 = set random password
-- key 3 = run / halt
--
-- a sixteen character sequence
-- is set manually or at random
-- and the script attempts to
-- match it by sliding a ribbon
-- of guesses across it.
--
-- when a match is made the
-- solution is locked until it
-- no longer matches.
--
-- matched positions are played
-- as notes, ASCII code mapped
-- directly to note information.
--
-- unmatched positions play
-- as the space character (32).
--
-- v1.0.0 @notester
-- llllllll.co/t/qfwfq

m_util = require 'musicutil'
engine.name = "PolyPerc"

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
  shift = false
  counter = metro.init(take_step, get_time())

  math.randomseed(os.time())
  m = midi.connect()

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

function enc(e, d)
  if shift then
    e = e + 3
  end

  if e == 1 then
    if params:get('clock_source') == 1 then
      params:delta("clock_tempo", d)
    end
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
    set_rnd_pwd()
  elseif k == 3 and z == 0 and run == false then
    run = true
    counter:start()
  elseif k == 3 and z == 0 and run then
    run = false
    counter:stop()
    step = 0
  end
end

function get_time()
  return 60 / params:get('clock_tempo')
end

function set_rnd_pwd()
  for i=1, 16 do
    pwd[i] = math.random(1, #glyphs)
  end

  redraw()
end

function draw_blanks()
  local x = 2

  for i=1, 16 do
    screen.move(x, BLANK_Y)
    screen.level(5)
    screen.line(x + 5, BLANK_Y)
    x = x + 8
  end

  screen.stroke()
end

function draw_cursor_dot()
  screen.move(pos * 8 - 4, POS_Y)
  screen.text('.')
end

function draw_step_dot()
  local level = pwd[step] == (hack.solution[step]) and 15 or 5

  screen.level(level)
  screen.move(step * 8 - 4, STEP_Y)
  screen.text('.')
end

function get_pos_x_offset(x, glyph)
  local glyph_w = screen.text_extents(glyph)
  local offset = STD_W - glyph_w

  return x + glyph_w + offset
end

function shift_cypher()
  for i=16, 2, -1 do
    hack.cypher[i] = hack.cypher[i-1]
  end

  hack.cypher[1] = next_glyph

  next_glyph = (next_glyph < #glyphs) and next_glyph + 1 or 1
  -- next_glyph = math.random(1, #glyphs)
end

function take_step()
  counter.time = get_time()

  shift_cypher()

  step = (step < 16) and step + 1 or 1

  redraw()

  play_note()
end

function play_note()
  local is_solved = pwd[step] == hack.solution[step]
  local note = (is_solved) and glyphs[hack.solution[step]] or glyphs[1]
  local velocity = (is_solved) and 127 or 0

  engine.amp(velocity / 127)
  engine.hz(m_util.note_num_to_freq(note))
  m:note_on(note, velocity)
end

function redraw()
  local x = 3
  local y = 6
  
  screen.clear()
  screen.level(7)
  screen.move(x, y)
  screen.text('BPM:  ' .. params:get('clock_tempo'))
  
  draw_blanks()
  draw_cursor_dot()
  draw_step_dot()
  
  for i=1, 16 do
    local glyph = glyphs[pwd[i]]
    
    if hack.cypher[i] == pwd[i] then
      hack.solution[i] = hack.cypher[i]
    elseif  hack.solution[i] ~= pwd[i] then
      hack.solution[i] = 1
    end
  
    local i_solved = pwd[i] == hack.solution[i]
    local hack_glyph = (i_solved) and glyphs[1] or glyphs[hack.cypher[i]]
    local level = (i_solved) and 15 or 5

    screen.level(level)
    screen.move(x, BLANK_Y - 4)
    screen.text(string.char(glyph))
    screen.move(x, HACK_Y - 4)
    screen.text(string.char(hack_glyph))
    x = get_pos_x_offset(x, glyph)
  end
  
  screen.stroke()
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
