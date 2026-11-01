local mod = {}

-- Setup
function mod.setup(palette)
  mod.config = { -- global config, can be accessed by items
    margin  = 5,
    height  = 34,
    padding = 12,
    border  = true 
  }

  if tonumber(os_version[1]) < 26 then -- for macos versions previous to Tahoe
    mod.config.radius = 13
	elseif tonumber(os_version[1]) == 26 then 
    mod.config.radius = 15
	elseif tonumber(os_version[1]) >= 27 then
    mod.config.radius = 14
	end 

  if config.bar_look == "compact" then
    mod.config.radius = 0
    mod.config.margin = 0
    mod.config.height = 30
    mod.config.border = false
  end

  -- Defaults
  mod.properties = {
    height   = mod.config.height,
  	y_offset = mod.config.margin,
  	margin   = mod.config.margin,
  	position = "top",

  	topmost = true,
  	sticky  = true,

  	padding_left  = 0, -- Set to 0 since logo updates padding itself
  	padding_right = mod.config.padding,

  	notch_width   = config.notch_width,
  	border_width  = mod.config.border and 1 or 0 ,
  	corner_radius = mod.config.radius,
    
  	border_color = palette.bar.border,
    color        = palette.bar.background,
  	blur_radius  = 14
  }

  return mod
end


function mod.load() 
  sbar.bar(mod.properties)
end

return mod
