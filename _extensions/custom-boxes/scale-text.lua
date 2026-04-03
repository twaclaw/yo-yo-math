--- scale-text.lua
--- Usage: [content]{.scale factor="2"}
--- PDF: \scalebox{2}{content}
--- HTML: <span style="font-size:2em">content</span>

function Span(el)
  if not el.classes:includes("scale") then
    return el
  end

  local factor = el.attributes["factor"] or "1.5"

  if FORMAT == "latex" or FORMAT == "pdf" then
    local content = pandoc.write(pandoc.Pandoc({pandoc.Plain(el.content)}), "latex")
    return pandoc.RawInline("latex", "\\scalebox{" .. factor .. "}{" .. content .. "}")
  else
    el.attributes["style"] = (el.attributes["style"] or "") ..
      "font-size:" .. factor .. "em;"
    el.classes = el.classes:filter(function(c) return c ~= "scale" end)
    return el
  end
end
