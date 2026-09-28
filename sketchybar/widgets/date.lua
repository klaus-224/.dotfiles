return {
  name = "date",
  icon = "󰃭",
  label_width = 78,
  update_freq = 60,
  command = "/bin/date '+%d %b %a'",
  parse = function(output)
    if type(output) ~= "string" then return nil end
    local value = output:match("^%s*(.-)%s*$")
    return value ~= "" and value or nil
  end,
  render = function(value)
    return { label = { string = value or "--" } }
  end,
}
