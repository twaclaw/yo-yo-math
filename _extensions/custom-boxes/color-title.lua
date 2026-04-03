function Header(el)
  if el.level == 1 and el.classes:includes("title") then
    -- This is the main title
    -- We can replace its content
  end
  return el
end
