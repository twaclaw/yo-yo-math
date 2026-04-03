-- Map of twemoji names to Unicode characters
local emoji_map = {
  woman_police_officer = "👮‍♀️",
  cat = "🐈",
  dog = "🐕",
  dragon = "🐉",
  cat_face = "🐱",
  koala = "🐨",
  dog_face = "🐶",
  honeybee = "🐝",
  panda = "🐼",
  frog = "🐸",
  chicken = "🐔",
  shark = "🦈",
  rocket = "🚀",
  taco = "🌮",
  moon = "🌕",
  apple = "🍎",
  shrug = "🤷",
  game_die = "🎲",
  rabbit = "🐇",
  people_with_bunny_ears = "👯",
  lion = "🦁",
  elephant = "🐘",
  giraffe = "🦒",
  monkey = "🐒",
  orangutan = "🦧",
  rooster= "🐓",
  monkey_face = "🐵",
  taurus = "♉",
  gemini = "♊",
  book = "📖",
  thinking = "🤔",
  wink = "😉",
  exploding_head = "🤯",
  partying_face = "🥳",
  hot_beverage = "☕",
  star = "⭐",
  love_letter = "💌",
  turtle = "🐢",
  house = "🏠",
  school = "🏫",
  station = "🚉",
  carousel_horse = "🎠",
  playground_slide = "🛝",
  globe_showing_Americas = "🌎",
  sun_with_face = "🌞",
  top_hat = "🎩",
  fire_engine = "🚒",
  baby_chick = "🐤",
  swan="🦢",
  black_cat="🐈‍⬛",
  pig="🐖",
  cow="🐄",
  check_mark_button="✅",
  white_question_mark="❔",
  puzzle_piece="🧩",
  
  -- Add more here as needed
}

-- Repeat a string n times
local function str_rep(s, n)
  local result = ""
  for _ = 1, n do
    result = result .. s
  end
  return result
end

function Span(el)
  if el.classes:includes("twemoji") then
    -- Get the emoji name from the content (assuming it's just text like "cat")
    local emoji_name = pandoc.utils.stringify(el.content)
    -- Optional attributes:
    --   height="2em"       → emoji size
    --   raisebox="-0.3em" → vertical offset (PDF: \raisebox, HTML: vertical-align)
    --   reps="3"           → number of repetitions (default 1)
    local height   = el.attributes["height"]
    local raisebox = el.attributes["raisebox"]
    local reps     = tonumber(el.attributes["reps"]) or 1
    local latex_emoji_name = emoji_name:gsub("_", " ")

    if FORMAT:match("latex") or FORMAT:match("beamer") then
      local base
      if height then
        base = "\\twemoji[height=" .. height .. "]{" .. latex_emoji_name .. "}"
      else
        base = "\\twemoji{" .. latex_emoji_name .. "}"
      end
      if raisebox then
        base = "\\raisebox{" .. raisebox .. "}{" .. base .. "}"
      end
      return pandoc.RawInline("latex", str_rep(base, reps))

    elseif FORMAT:match("html") then
      local unicode_char = emoji_map[emoji_name]
      if unicode_char then
        local style = ""
        if height then style = style .. "font-size:" .. height .. ";" end
        local span
        if style ~= "" then
          span = '<span style="' .. style .. '">' .. unicode_char .. '</span>'
        else
          span = unicode_char
        end
        return pandoc.RawInline("html", str_rep(span, reps))
      else
        return el
      end

    else
      return el
    end
  end
end

function Math(el)
  -- Supported patterns inside math expressions:
  --   [name]{.twemoji}                    → default size
  --   [name:SIZE]{.twemoji}               → explicit height, e.g. [cat:2em]{.twemoji}
  --   [name:SIZE:RAISEBOX]{.twemoji}      → height + vertical offset
  --   [name:SIZE:RAISEBOX:REPS]{.twemoji} → height + offset + repetition count
  --
  -- SIZE    : any LaTeX dimension (2em, 24pt, 1.5cm …)  — must not contain ':'
  -- RAISEBOX: vertical offset (e.g. -0.3em)              — must not contain ':'
  -- REPS    : integer repetition count (default 1)
  --
  -- In PDF:  \raisebox{RAISEBOX}{\twemoji[height=SIZE]{name}}
  -- In HTML: \style{font-size:SIZE;vertical-align:RAISEBOX}{char}

  local pattern_full   = "%[([%w_]+):([^:%]]+):([^:%]]+):(%d+)%]{%.twemoji}"
  local pattern_raised = "%[([%w_]+):([^:%]]+):([^:%]]+)%]{%.twemoji}"
  local pattern_sized  = "%[([%w_]+):([^:%]]+)%]{%.twemoji}"
  local pattern        = "%[([%w_]+)%]{%.twemoji}"

  if el.text:find(pattern_full) or el.text:find(pattern_raised) or
     el.text:find(pattern_sized) or el.text:find(pattern) then
    local new_text = el.text

    -- 1. Full: name:SIZE:RAISEBOX:REPS
    new_text = new_text:gsub(pattern_full, function(name, size, raisebox, reps_str)
      local reps = tonumber(reps_str) or 1
      if FORMAT:match("latex") or FORMAT:match("beamer") then
        local latex_name = name:gsub("_", " ")
        local base = "\\raisebox{" .. raisebox .. "}{\\twemoji[height=" .. size .. "]{" .. latex_name .. "}}"
        return str_rep(base, reps)
      elseif FORMAT:match("html") then
        local char = emoji_map[name] or name
        local unit = "\\style{font-size:" .. size .. "}{" .. char .. "}"
        return str_rep(unit, reps)
      else
        return name
      end
    end)

    -- 2. Raised: name:SIZE:RAISEBOX
    new_text = new_text:gsub(pattern_raised, function(name, size, raisebox)
      if FORMAT:match("latex") or FORMAT:match("beamer") then
        local latex_name = name:gsub("_", " ")
        return "\\raisebox{" .. raisebox .. "}{\\twemoji[height=" .. size .. "]{" .. latex_name .. "}}"
      elseif FORMAT:match("html") then
        local char = emoji_map[name] or name
        return "\\style{font-size:" .. size .. "}{" .. char .. "}"
      else
        return name
      end
    end)

    -- 3. Sized: name:SIZE
    new_text = new_text:gsub(pattern_sized, function(name, size)
      if FORMAT:match("latex") or FORMAT:match("beamer") then
        local latex_name = name:gsub("_", " ")
        return "\\twemoji[height=" .. size .. "]{" .. latex_name .. "}"
      elseif FORMAT:match("html") then
        local char = emoji_map[name] or name
        return "\\style{font-size:" .. size .. "}{" .. char .. "}"
      else
        return name
      end
    end)

    -- 4. Plain: name
    new_text = new_text:gsub(pattern, function(name)
      if FORMAT:match("latex") or FORMAT:match("beamer") then
        local latex_name = name:gsub("_", " ")
        return "\\twemoji{" .. latex_name .. "}"
      elseif FORMAT:match("html") then
        local char = emoji_map[name]
        return char or name
      else
        return name
      end
    end)

    el.text = new_text
    return el
  end
end
