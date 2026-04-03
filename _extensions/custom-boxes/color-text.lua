function Span(el)
  if FORMAT == "latex" or FORMAT == "pdf" then
    local style = el.attributes["style"]
    if style then
      local color = style:match("color:%s*#(%x+)")
      if color then
        return pandoc.RawInline("latex", "\\textcolor[HTML]{" .. color .. "}{" .. pandoc.utils.stringify(el) .. "}")
      end
    end
  end
  return el
end
