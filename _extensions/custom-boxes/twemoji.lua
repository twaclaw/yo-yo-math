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
  snake="🐍",
  unicorn="🦄",
  ghost="👻",
  brick="🧱",
  input_numbers="🔢",
  abacus="🧮",
  pirate_flag="🏴‍☠️",
  parrot="🦜",
  check_mark_button="✅",
  white_question_mark="❔",
  puzzle_piece="🧩",
  hotel="🏨",
  door="🚪",
  window="🪟",
  triangular_ruler="📐",
  running_shoe="👟",
  socks="🧦",
  waving_hand="👋",
  light_bulb="💡",
  chocolate_bar="🍫",
  scissors="✂️",
  scroll="📜",
  man_biking = "🚴‍♂️",
  person_biking = "🚴‍♀️",
  woman_biking = "🚴‍♀️",
  red_circle = "🔴",
  white_large_square = "⬜",
  red_triangle_pointed_up = "🔺",
  tokyo_tower = "🗼",
  pizza = "🍕",
  ice_cream = "🍨",
  musical_note = "🎵",

  
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

-- Convert a Unicode emoji string to a Twemoji SVG URL.
-- ZWJ sequences keep FE0F; simple emojis strip it.
local function emoji_to_twemoji_url(emoji_str)
  local codes = {utf8.codepoint(emoji_str, 1, -1)}
  local has_zwj = false
  for _, c in ipairs(codes) do
    if c == 0x200D then has_zwj = true; break end
  end
  local parts = {}
  for _, c in ipairs(codes) do
    if not has_zwj and c == 0xFE0F then
      -- skip variation selector for non-ZWJ sequences
    else
      table.insert(parts, string.format("%x", c))
    end
  end
  return "https://cdn.jsdelivr.net/gh/jdecked/twemoji@latest/assets/svg/"
    .. table.concat(parts, "-") .. ".svg"
end

-- Build an <img> tag for a Twemoji SVG.
local function emoji_to_img(emoji_str, height, raisebox)
  local url = emoji_to_twemoji_url(emoji_str)
  local style = "height:" .. (height or "1.2em") .. ";"
  if raisebox then
    style = style .. "vertical-align:" .. raisebox .. ";"
  else
    style = style .. "vertical-align:middle;"
  end
  return '<img src="' .. url .. '" alt="' .. emoji_str
    .. '" style="' .. style .. '" draggable="false" />'
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
        local img = emoji_to_img(unicode_char, height, raisebox)
        return pandoc.RawInline("html", str_rep(img, reps))
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
  -- In HTML: Twemoji SVG <img> tags (replaces the Math element entirely
  --          when the whole expression is emoji-only inside \text{})

  local pattern_full   = "%[([%w_]+):([^:%]]+):([^:%]]+):(%d+)%]{%.twemoji}"
  local pattern_raised = "%[([%w_]+):([^:%]]+):([^:%]]+)%]{%.twemoji}"
  local pattern_sized  = "%[([%w_]+):([^:%]]+)%]{%.twemoji}"
  local pattern        = "%[([%w_]+)%]{%.twemoji}"

  if el.text:find(pattern_full) or el.text:find(pattern_raised) or
     el.text:find(pattern_sized) or el.text:find(pattern) then

    -------------------------------------------------------------------
    -- HTML: try to replace the entire Math element with <img> tags.
    -- All current usages wrap emoji in  $\text{...}$  so we unwrap,
    -- substitute every twemoji pattern with an img tag, and – if
    -- nothing else remains – return a RawInline instead of Math.
    -------------------------------------------------------------------
    if FORMAT:match("html") then
      local inner = el.text:match("^\\text{(.*)}$")
      if inner then
        local html_result = ""
        local remaining = inner

        remaining = remaining:gsub(pattern_full, function(name, size, raisebox, reps_str)
          local reps = tonumber(reps_str) or 1
          local char = emoji_map[name] or name
          html_result = html_result .. str_rep(emoji_to_img(char, size, raisebox), reps)
          return ""
        end)
        remaining = remaining:gsub(pattern_raised, function(name, size, raisebox)
          local char = emoji_map[name] or name
          html_result = html_result .. emoji_to_img(char, size, raisebox)
          return ""
        end)
        remaining = remaining:gsub(pattern_sized, function(name, size)
          local char = emoji_map[name] or name
          html_result = html_result .. emoji_to_img(char, size)
          return ""
        end)
        remaining = remaining:gsub(pattern, function(name)
          local char = emoji_map[name]
          if char then
            html_result = html_result .. emoji_to_img(char)
            return ""
          end
          return name
        end)

        if remaining:match("^%s*$") then
          return pandoc.RawInline("html", html_result)
        end
      end

      -- Fallback for mixed math+emoji: embed Unicode (best-effort)
      local new_text = el.text
      new_text = new_text:gsub(pattern_full, function(name, size, raisebox, reps_str)
        local reps = tonumber(reps_str) or 1
        local char = emoji_map[name] or name
        return str_rep("\\style{font-size:" .. size .. "}{" .. char .. "}", reps)
      end)
      new_text = new_text:gsub(pattern_raised, function(name, size, raisebox)
        local char = emoji_map[name] or name
        return "\\style{font-size:" .. size .. "}{" .. char .. "}"
      end)
      new_text = new_text:gsub(pattern_sized, function(name, size)
        local char = emoji_map[name] or name
        return "\\style{font-size:" .. size .. "}{" .. char .. "}"
      end)
      new_text = new_text:gsub(pattern, function(name)
        local char = emoji_map[name]
        return char or name
      end)
      el.text = new_text
      return el
    end

    -------------------------------------------------------------------
    -- LaTeX / Beamer
    -------------------------------------------------------------------
    if FORMAT:match("latex") or FORMAT:match("beamer") then
      local new_text = el.text

      new_text = new_text:gsub(pattern_full, function(name, size, raisebox, reps_str)
        local reps = tonumber(reps_str) or 1
        local latex_name = name:gsub("_", " ")
        local base = "\\raisebox{" .. raisebox .. "}{\\twemoji[height=" .. size .. "]{" .. latex_name .. "}}"
        return str_rep(base, reps)
      end)

      new_text = new_text:gsub(pattern_raised, function(name, size, raisebox)
        local latex_name = name:gsub("_", " ")
        return "\\raisebox{" .. raisebox .. "}{\\twemoji[height=" .. size .. "]{" .. latex_name .. "}}"
      end)

      new_text = new_text:gsub(pattern_sized, function(name, size)
        local latex_name = name:gsub("_", " ")
        return "\\twemoji[height=" .. size .. "]{" .. latex_name .. "}"
      end)

      new_text = new_text:gsub(pattern, function(name)
        local latex_name = name:gsub("_", " ")
        return "\\twemoji{" .. latex_name .. "}"
      end)

      el.text = new_text
      return el
    end
  end
end
