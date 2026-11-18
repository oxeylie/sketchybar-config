local mod = {}

-- Setup
function mod.setup(bar,icons,palette)
  mod.config = {
    artw_height  = bar.config.height - 8,
    info_width   = 80,
    title_margin = bar.config.height / 3.2,
  }

  mod.properties = {
    artwork = {
      position = "q",

      drawing = false,
      padding_left  = 2,

      updates = true,

      icon = {
        padding_right = 0,
        padding_left  = 0,
        color         = palette.text.muted,
        align         = "center",
      },

      label = { drawing = false },

      background = { 
        drawing = true,
        image = {
          border_width  = 1,
          corner_radius = 4,
          border_color  = palette.bar.border,
        }
      }
    },
    title = {
      position = "q",

      drawing = false,

      y_offset      = (bar.config.height / 2) - mod.config.title_margin,
      padding_left  = -mod.config.info_width,
      padding_right = 0,

      icon = { drawing = false },

      label = { 
        max_chars = mod.config.info_width / 5.5,
        align     = "right",
        width     = mod.config.info_width,
        font      = { size = 10.0, style = "Semibold" },
      },

      background = { height = 8 }
    },
    subtitle = {
      position = "q",

      drawing = false,

      y_offset      = -(bar.config.height / 2) + mod.config.title_margin,
      padding_left  = 0,
      padding_right = 0,
      
      icon = { drawing = false },

      label = { 
        color     = palette.text.subtle,
        max_chars = mod.config.info_width / 5.5,
        align     = "right",
        width     = -mod.config.info_width,
        font      = { size = 9.0, style = "Semibold" },
      },

      background = { height = 8 }
    }
  } 

  mod.event_name = "media_update"

  mod.state = {
    last_pid  = nil,
    play_refc = 0,
    last_play = nil,
  }

  return mod
end

local function loadStream(event_name)
  sbar.exec([[
    #SKETCHYBAR_MEDIA_STREAM#

    lastpid=$(cat ${TMPDIR}/sketchybar/media_pids 2> /dev/null || echo 0);

    if ps -p $lastpid -o command= | grep '#SKETCHYBAR_MEDIA_STREAM#' > /dev/null; then 
      kill -9 $(pgrep -P $lastpid) $lastpid
    fi;
    
    mkdir -p ${TMPDIR}/sketchybar;
    echo $$ > ${TMPDIR}/sketchybar/media_pids;
    
    ]] .. execs.media_control .. [[ stream | \
    while IFS= read -r line; do 
      sketchybar --trigger ]] .. event_name .. [[ "INFO=$line"
    done
    ]], function (result,exit_code) 
      log("media-stream","Exited with code: " .. exit_code)
    end)
end

local function mediaDecode(artwork,title,subtitle,separator,icons)
  return function (env)
    if env.INFO.payload and next(env.INFO.payload) then 
      separator.addRef("media")

      if env.INFO.payload.processIdentifier then 
        mod.state.last_pid = env.INFO.payload.processIdentifier
      end

      if env.INFO.payload.playing ~= nil and env.INFO.payload.playing ~= mod.state.last_play then
        mod.state.last_play = env.INFO.payload.playing
        mod.state.play_refc = mod.state.play_refc + 1
        
        artwork:set({ icon = { string = env.INFO.payload.playing and icons.player.pause or icons.player.play }})
        
        sbar.delay(5,function (env) 
          mod.state.play_refc = mod.state.play_refc - 1
          if mod.state.play_refc == 0 then artwork:set({ icon = { string = "" }}) end
        end)
      end

      if env.INFO.payload.title then
        title:set({ drawing = true }) 
        title:set({ label = env.INFO.payload.title })
      end

      if env.INFO.payload.artist then
        subtitle:set({ drawing = true })
        subtitle:set({ label = env.INFO.payload.artist .. (
          (env.INFO.payload.album and env.INFO.payload.album ~= "") and (" - " .. env.INFO.payload.album) or ""
        )})
      end

      if env.INFO.payload.artworkData then
        artwork:set({ drawing = true }) 
        sbar.exec([[
          #mkdir -p ${TMPDIR}/sketchybar
          tmp_file=$(mktemp ${TMPDIR}/sketchybar/cover.XXXXXXXXXX)

          echo "]] .. env.INFO.payload.artworkData .. [[" | base64 -d >$tmp_file

          type=$(]] .. execs.identify .. [[ -ping -format '%m' $tmp_file)

          case $type in
          "JPEG")
			  	  ext=jpg
			  	  ;;
			    "PNG")
			  	  ext=png
			  	  ;;
          *)
            ext=jpeg
            ]] .. execs.magick .. [[ $tmp_file jpeg:$tmp_file
          esac

          size=$(]] .. execs.identify .. [[ -ping -format '%h,%w' $tmp_file)

			    mv $tmp_file $tmp_file.$ext

          printf "%s,%s" "$tmp_file.$ext" $size
          ]], function (result,exit_code) 
          local path, height, width = table.unpack(strSplit(result,","))
          local scale = mod.config.artw_height / height

          artwork:set({ 
            icon = { width = width * scale },
            background = { image = { string = path,
                                     scale  = scale }}
          })

          sbar.exec("sleep 0.5; rm -rf \"".. path .."\"")
        end)
      end

    elseif mod.state.last_pid then
      sbar.exec("ps -p " .. mod.state.last_pid ,function (result,exit_code) 
        if exit_code > 0 then 
          separator.dropRef("media")
          artwork:set({ drawing = false }) 
          title:set({ drawing = false }) 
          subtitle:set({ drawing = false }) 
        end
      end)
    end

  end
end 

local function hoverToggle(items)
  return function (env)
    for _,v in pairs(items) do
      v:set({ scroll_texts = (env.SENDER == "mouse.entered")})
    end
  end
end

-- Load
function mod.load(separator, icons)
  mod.artwork  = sbar.add("item", mod.properties.artwork)
  mod.title    = sbar.add("item", mod.properties.title)
  mod.subtitle = sbar.add("item", mod.properties.subtitle)

  sbar.add("event",mod.event_name)
  mod.artwork:subscribe(mod.event_name,mediaDecode(mod.artwork,mod.title,mod.subtitle,separator,icons))

  mod.artwork:subscribe("mouse.clicked", function (env) 
    sbar.exec(execs.media_control .. " toggle-play-pause")
  end)

  local display_player = function (env) 
    sbar.exec("if ! " .. execs.menubar .. " item select " .. menu_items.media_player.app .. " " .. menu_items.media_player.id .. "; then " ..
		execs.menubar .. " item select " .. menu_items.live_player.app .. " " .. menu_items.live_player.id .. "; fi" ) 
  end

  mod.title   :subscribe("mouse.clicked",display_player)
  mod.subtitle:subscribe("mouse.clicked",display_player)

  mod.title   :subscribe({"mouse.entered","mouse.exited"},hoverToggle({mod.title,mod.subtitle}))
  mod.subtitle:subscribe({"mouse.entered","mouse.exited"},hoverToggle({mod.title,mod.subtitle}))

  loadStream(mod.event_name)

  return mod
end

return mod
