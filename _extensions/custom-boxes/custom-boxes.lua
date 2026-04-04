function Div(div)
  if div.classes:includes("teacher-tip") then
    if quarto.doc.is_format("pdf") then
      -- Wrap content in our custom LaTeX environment
      local blocks = { pandoc.RawBlock("tex", "\\begin{teachertip}") }
      for _, block in ipairs(div.content) do
        table.insert(blocks, block)
      end
      table.insert(blocks, pandoc.RawBlock("tex", "\\end{teachertip}"))
      return blocks
    elseif quarto.doc.is_format("html") then
      -- HTML Handling for Teacher Tip using Quarto Callout
      return quarto.Callout({
        type = "note",
        title = "Parent/Educator Tip",
        content = div.content,
        appearance = "default",
        icon = true
      })
    end
  elseif div.classes:includes("fun-fact") or div.classes:includes("funfact") then
    if quarto.doc.is_format("pdf") then
      local begin_cmd = "\\begin{funfact}"
      if div.attributes["title"] then
        begin_cmd = begin_cmd .. "[" .. div.attributes["title"] .. "]"
      end
      local image = div.attributes["image"] or ""
      
      -- PDF Path Handling:
      -- We receive paths like "../static_images/alien.pdf" relative to the chapter file.
      -- Also sometimes "/static_images/..." (project relative) which fails in LaTeX (absolute path).
      -- For LaTeX build (which usually happens at project/book root), we need "static_images/alien.pdf".
      
      -- Remove leading slash if present
      if image:match("^/") then
        image = image:gsub("^/", "")
      end
      
      -- Remove "../" prefix if present.
      if image:match("^%.%./") then
        image = image:gsub("^%.%./", "")
      end

      local scale = div.attributes["scale"] or "1"
      local width = div.attributes["width"] or "0.65"
      begin_cmd = begin_cmd .. "{" .. image .. "}{" .. scale .. "}{" .. width .. "}"

      local blocks = { pandoc.RawBlock("tex", begin_cmd) }
      for _, block in ipairs(div.content) do
        table.insert(blocks, block)
      end
      table.insert(blocks, pandoc.RawBlock("tex", "\\end{funfact}"))
      return blocks
    elseif quarto.doc.is_format("html") then
        -- HTML Handling for Fun Fact using Quarto Callout
        local title = div.attributes["title"] or "Fun Fact"
        local content = div.content
        
        local image_path = div.attributes["image"]
        if image_path then
            image_path = image_path:gsub("%.pdf$", ".svg")
            
            -- Path adjustment:
            -- If path starts with /, convert to relative path for chapter-level HTML (../path)
            if image_path:match("^/") then
                image_path = "../" .. image_path:gsub("^/", "")
            end
             
            -- Handle existing relative paths (../) by leaving them alone (assuming user knows)
            
            -- PDF logic: width is for TEXT. Default 0.65.
            local text_width_val = tonumber(div.attributes["width"]) or 0.65
            local text_basis = math.floor(text_width_val * 100) .. "%"
            
            local scale_val = tonumber(div.attributes["scale"]) or 1.0
            local img_style_width = math.floor(scale_val * 100) .. "%"
            
            local img = pandoc.Image({}, image_path, title)
            -- Apply scaling to the image itself
            img.attr = pandoc.Attr("", {}, {style = "width: " .. img_style_width .. "; height: auto; max-width: 100%;"})
            
            -- Content Container (Text)
            local content_div = pandoc.Div(div.content)
            -- Text takes the specified width
            content_div.attr = pandoc.Attr("", {}, {style = "flex: 0 0 " .. text_basis .. "; padding-right: 1.5em;"})
            
            -- Image Container
            local img_div = pandoc.Div(pandoc.Para({img}))
            -- Image takes the remaining space
            img_div.attr = pandoc.Attr("", {}, {style = "flex: 1; display: flex; align-items: center; justify-content: center;"})
            
            -- Flex Wrapper
            local wrapper = pandoc.Div({content_div, img_div})
            wrapper.attr = pandoc.Attr("", {}, {style = "display: flex; flex-direction: row; align-items: flex-start;"})
            
            content = { wrapper }
        end
        
        return quarto.Callout({
            type = "tip",
            title = title,
            content = content,
            appearance = "default",
            icon = true
        })
    end
  elseif div.classes:includes("game-theory") or div.classes:includes("gametheory") then
    if quarto.doc.is_format("pdf") then
      local begin_cmd = "\\begin{gametheory}"
      local title = div.attributes["title"] or "Game Theory"
      begin_cmd = begin_cmd .. "[" .. title .. "]"
      
      local image = div.attributes["image"] or ""
      
      -- PDF Path Handling:
      if image:match("^/") then
        image = image:gsub("^/", "")
      end
      if image:match("^%.%./") then
        image = image:gsub("^%.%./", "")
      end

      local scale = div.attributes["scale"] or "1"
      local width = div.attributes["width"] or "0.65"
      begin_cmd = begin_cmd .. "{" .. image .. "}{" .. scale .. "}{" .. width .. "}"

      local blocks = { pandoc.RawBlock("tex", begin_cmd) }
      for _, block in ipairs(div.content) do
        table.insert(blocks, block)
      end
      table.insert(blocks, pandoc.RawBlock("tex", "\\end{gametheory}"))
      return blocks
    elseif quarto.doc.is_format("html") then
        local title = div.attributes["title"] or "Game Theory"
        local content = div.content
        
        -- Logic for Image insertion (similar to fun-fact)
        local image_path = div.attributes["image"]
        if image_path then
            image_path = image_path:gsub("%.pdf$", ".svg")
            if image_path:match("^/") then
                image_path = "../" .. image_path:gsub("^/", "")
            end
            
            local text_width_val = tonumber(div.attributes["width"]) or 0.65
            local text_basis = math.floor(text_width_val * 100) .. "%"
            local scale_val = tonumber(div.attributes["scale"]) or 1.0
            local img_style_width = math.floor(scale_val * 100) .. "%"
            
            local img = pandoc.Image({}, image_path, title)
            img.attr = pandoc.Attr("", {}, {style = "width: " .. img_style_width .. "; height: auto; max-width: 100%;"})
            
            local content_div = pandoc.Div(div.content)
            content_div.attr = pandoc.Attr("", {}, {style = "flex: 0 0 " .. text_basis .. "; padding-right: 1.5em;"})
            
            local img_div = pandoc.Div(pandoc.Para({img}))
            img_div.attr = pandoc.Attr("", {}, {style = "flex: 1; display: flex; align-items: center; justify-content: center;"})
            
            local wrapper = pandoc.Div({content_div, img_div})
            wrapper.attr = pandoc.Attr("", {}, {style = "display: flex; flex-direction: row; align-items: flex-start;"})
            
            content = { wrapper }
        end
        
        -- Using 'warning' type for yellow/orange color in HTML, but customizing title
        -- We disable the default icon and inject a customized dice (kidYellow=#FFCC00) into the title
        local icon_html = "<i class=\"fa-solid fa-dice\" style=\"color: #FFCC00; margin-right: 0.5em;\"></i> "
        if type(title) == "string" then
             -- String concatenation is simpler if title is string
             -- Note: Using a RawInline in a generic string context might not work if title is treated as plain string later
             -- But quarto.Callout title accepts Inlines.
             local display_title = pandoc.List()
             display_title:insert(pandoc.RawInline("html", icon_html))
             display_title:insert(pandoc.Str(title))
             title = display_title
        else
            -- If title is already Inlines (Pandoc AST), prepend raw html
            -- We need to check if title is a List of Inlines or just Inlines? Usually it's a List of Inlines or a String.
             local display_title = pandoc.List()
             display_title:insert(pandoc.RawInline("html", icon_html))
             if title and title.insert then
                display_title:extend(title)
             else
                -- Fallback
                display_title:insert(pandoc.Str(tostring(title)))
             end
             title = display_title
        end

        return quarto.Callout({
            type = "warning",
            title = title,
            content = content,
            appearance = "default",
            icon = false
        })
    end
  elseif div.classes:includes("story-time") or div.classes:includes("storytime") then
    if quarto.doc.is_format("pdf") then
      local begin_cmd = "\\begin{storytime}"
      local title = div.attributes["title"] or "Story Time"
      begin_cmd = begin_cmd .. "[" .. title .. "]"

      local image = div.attributes["image"] or ""

      -- PDF Path Handling:
      if image:match("^/") then
        image = image:gsub("^/", "")
      end
      if image:match("^%.%./") then
        image = image:gsub("^%.%./", "")
      end

      local scale = div.attributes["scale"] or "1"
      local width = div.attributes["width"] or "0.65"
      local ref = div.attributes["ref"] or ""
      begin_cmd = begin_cmd .. "{" .. image .. "}{" .. scale .. "}{" .. width .. "}{" .. ref .. "}"

      local blocks = { pandoc.RawBlock("tex", begin_cmd) }
      for _, block in ipairs(div.content) do
        table.insert(blocks, block)
      end
      table.insert(blocks, pandoc.RawBlock("tex", "\\end{storytime}"))
      return blocks
    elseif quarto.doc.is_format("html") then
        local title = div.attributes["title"] or "Story Time"
        local content = div.content

        -- Logic for Image insertion (same layout as fun-fact / game-theory)
        local image_path = div.attributes["image"]
        local ref = div.attributes["ref"]
        if image_path then
            image_path = image_path:gsub("%.pdf$", ".svg")
            if image_path:match("^/") then
                image_path = "../" .. image_path:gsub("^/", "")
            end

            local text_width_val = tonumber(div.attributes["width"]) or 0.65
            local text_basis = math.floor(text_width_val * 100) .. "%"
            local scale_val = tonumber(div.attributes["scale"]) or 1.0
            local img_style_width = math.floor(scale_val * 100) .. "%"

            local img = pandoc.Image({}, image_path, title)
            img.attr = pandoc.Attr("", {}, {style = "width: " .. img_style_width .. "; height: auto; max-width: 100%;"})

            -- Build image column: image + optional ref caption underneath
            local img_elements = { pandoc.Para({img}) }
            if ref then
                local ref_p = pandoc.Para({pandoc.Str(ref)})
                local ref_div = pandoc.Div(ref_p)
                ref_div.attr = pandoc.Attr("", {"story-time-ref"}, {style = "text-align: center; font-size: 0.8em; color: #6b4d8a; margin-top: 0.3em; font-style: normal;"})
                table.insert(img_elements, ref_div)
            end

            local content_div = pandoc.Div(div.content)
            content_div.attr = pandoc.Attr("", {}, {style = "flex: 0 0 " .. text_basis .. "; padding-right: 1.5em;"})

            local img_div = pandoc.Div(img_elements)
            img_div.attr = pandoc.Attr("", {}, {style = "flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;"})

            local wrapper = pandoc.Div({content_div, img_div})
            wrapper.attr = pandoc.Attr("", {}, {style = "display: flex; flex-direction: row; align-items: flex-start;"})

            content = { wrapper }
        else
            -- No image: append ref as a note at the bottom of the content
            if ref then
                local ref_p = pandoc.Para({pandoc.Str(ref)})
                local ref_div = pandoc.Div(ref_p)
                ref_div.attr = pandoc.Attr("", {"story-time-ref"}, {style = "text-align: center; font-size: 0.8em; color: #6b4d8a; margin-top: 0.5em; font-style: normal;"})
                content = pandoc.List()
                for _, block in ipairs(div.content) do
                    content:insert(block)
                end
                content:insert(ref_div)
            end
        end

        -- Build custom icon with moon + star for bedtime feel
        local icon_html = '<i class="fa-solid fa-moon" style="color: #9B72CF; margin-right: 0.3em;"></i>'
                       .. '<i class="fa-solid fa-star" style="color: #9B72CF; margin-right: 0.5em; font-size: 0.7em;"></i> '
        local display_title = pandoc.List()
        display_title:insert(pandoc.RawInline("html", icon_html))
        display_title:insert(pandoc.Str(title))

        local callout = quarto.Callout({
            type = "important",
            title = display_title,
            content = content,
            appearance = "default",
            icon = false
        })

        -- Wrap in a story-time-callout div for custom CSS targeting
        local outer = pandoc.Div({callout})
        outer.classes:insert("story-time-callout")
        return outer
    end
  elseif div.classes:includes("big-math") then
    local default_size = "30pt"
    if PANDOC_DOCUMENT and PANDOC_DOCUMENT.meta and PANDOC_DOCUMENT.meta["big-math-size"] then
      default_size = pandoc.utils.stringify(PANDOC_DOCUMENT.meta["big-math-size"])
    end
    local size = div.attributes["size"] or default_size
    -- Delegate to font-size-adjust logic
    if quarto.doc.is_format("html") then
      div.attributes["style"] = "font-size: " .. size .. ";" .. (div.attributes["style"] or "")
      return div
    elseif quarto.doc.is_format("pdf") then
      local num_size = tonumber(size:match("%d+")) or 30
      local baselineskip = (num_size * 1.2) .. "pt"
      local blocks = { pandoc.RawBlock("tex", "{\\fontsize{"..size.."}{"..baselineskip.."}\\selectfont ") }
      for _, block in ipairs(div.content) do
        table.insert(blocks, block)
      end
      table.insert(blocks, pandoc.RawBlock("tex", "}"))
      return blocks
    end
  elseif div.classes:includes("font-size-adjust") then
    local size = div.attributes["size"] or "12pt"
    if quarto.doc.is_format("html") then
       -- Apply inline style
       div.attributes["style"] = "font-size: " .. size .. ";" .. (div.attributes["style"] or "")
       return div
    elseif quarto.doc.is_format("pdf") then
       -- Wrap in group with fontsize command
       -- Calculate baselineskip
       local num_size = tonumber(size:match("%d+")) or 12
       local baselineskip = (num_size * 1.2) .. "pt"
       
       local blocks = { pandoc.RawBlock("tex", "{\\fontsize{"..size.."}{"..baselineskip.."}\\selectfont ") }
       for _, block in ipairs(div.content) do
         table.insert(blocks, block)
       end
       table.insert(blocks, pandoc.RawBlock("tex", "}"))
       return blocks
    end
  end
end

-- Also intercept standard Images to fix paths for PDF
function Image(img)
  if quarto.doc.is_format("pdf") then
    -- Remove leading slash (project relative -> relative)
    if img.src:match("^/") then
       img.src = img.src:gsub("^/", "")
    end
    -- Remove ../ (parent relative -> relative)
    if img.src:match("^%.%./") then
       img.src = img.src:gsub("^%.%./", "")
    end
  end
  return img
end
