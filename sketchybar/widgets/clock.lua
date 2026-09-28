return {
  name = "clock",
  update_freq = 30,
  command = "/bin/date '+%a %d %b %H:%M'",
  parse = function(output)
    if type(output) ~= "string" then return nil end
    local value = output:match("^%s*(.-)%s*$")
    return value ~= "" and value or nil
  end,
  render = function(value)
    return { label = { string = value or "" } }
  end,
}
