-- Neovim Configuration
-- Add /home/user/firefox_bookmarks.log to the calendar thing





vim.cmd('colorscheme evening')  -- Or another installed colorscheme

-- General Settings
vim.opt.mouse = 'a'                 -- Enable mouse support
vim.opt.number = true               -- Enable line numbers
vim.opt.clipboard = 'unnamedplus'   -- Use system clipboard
vim.opt.tabstop = 4                 -- Number of spaces tabs count for
vim.opt.shiftwidth = 4              -- Number of spaces for each indent
vim.opt.expandtab = true            -- Convert tabs to spaces
vim.opt.smarttab = true             -- Smarter tab handling
vim.cmd('syntax on')
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.history = 10000
vim.opt.statusline = "%F %m %r %= %l:%c %p%%"
vim.opt.laststatus = 2              -- Force always visible





---- User commands
vim.api.nvim_create_user_command("Source", function(opts)
  local file = opts.args
  if file == "" then
      -- source init.lua
    file = vim.env.MYVIMRC or (vim.fn.stdpath("config") .. "/init.lua")
  elseif file == "%" then
      -- source current file
    file = vim.api.nvim_buf_get_name(0)
  end

  if vim.fn.filereadable(file) == 0 then
    return print("Source: no such file → " .. file)
  end

  vim.cmd("source " .. vim.fn.fnameescape(file))
  print("Sourced → " .. file)
end, { nargs = "?", complete = "file" })




---- Autocommands
-- Status column, old
 vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "CursorMoved" }, {
     callback = function()
         -- Check if the buffer is not read-only
         if not vim.bo.readonly then
             -- Define highlight groups for absolute and relative numbers
             vim.api.nvim_set_hl(0, "LineNr", { fg = "#808080" }) -- Gray for relative numbers
             vim.api.nvim_set_hl(0, "LineNrAbsolute", { fg = "#b085f5"})
 
             -- Set the statuscolumn for non-read-only files
             vim.opt.statuscolumn = '%#LineNr#%{v:relnum?v:relnum:""}%#LineNrAbsolute#%{v:relnum?"":v:lnum} '
         else
             -- Optionally clear or reset the statuscolumn for read-only files
             vim.opt.statuscolumn = ""
         end
     end,
 })
--






-- Save last opened file with its date to last_opened.txt
 vim.api.nvim_create_autocmd("BufReadPost", {
     callback = function()
         local date = os.date("%b %d, %Y") -- Format the current date
         local file_path = vim.fn.shellescape(vim.fn.expand("<afile>:p"))
         os.execute(string.format("sed -i '1i%s' /home/user/.config/nvim/last_opened.txt", date .. " " .. file_path))
     end,
 })





-- Show day of week on dated current line in last_opened.txt
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = { "/home/user/.config/nvim/last_opened.txt", "/home/user/.config/mpv/last_watched.txt", "/home/user/firefox_bookmarks.log"},
  callback = function()
    local function weekday_bar()
      local line = vim.api.nvim_get_current_line()

      -- Search the entire line, not cursor-relative
      local month_str, day, year = line:match("([A-Za-z]+)%s+(%d%d?),%s*(%d%d%d%d)")
      if not (month_str and day and year) then return "" end

      local month_map = {
        Jan=1, Feb=2, Mar=3, Apr=4, May=5, Jun=6,
        Jul=7, Aug=8, Sep=9, Oct=10, Nov=11, Dec=12
      }
      local month = month_map[month_str]
      if not month then return "" end

      local time = os.time{year=year, month=month, day=tonumber(day)}
      if not time then return "" end

      local wday = os.date("*t", time).wday
      local days = {"mon", "tue", "wed", "thur", "fri", "sat", "sun"}

      local bar = ""
      for i, d in ipairs(days) do
        if (wday == 1 and i == 7) or (wday > 1 and i == wday - 1) then
          bar = bar .. string.upper(d) .. "  "
        else
          bar = bar .. d .. "  "
        end
      end
      return bar
    end

    vim.b.weekday_bar = weekday_bar
    vim.api.nvim_win_set_option(0, "statusline", "%f  %{v:lua.vim.b.weekday_bar()} %=%l,%c")
  end,
})
-- Prevent cut-off's in wraps
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "wrap",
  callback = function()
    if vim.wo.wrap then
      vim.wo.linebreak = true
    end
  end,
})




---- Vim-Plug
-- Alias for vim-plug functions
local Plug = vim.fn['plug#']

-- Begin plugin management
vim.fn['plug#begin']('~/.config/nvim/plugged')

-- Plugin definitions
Plug('glacambre/firenvim', { ['do'] = 'call firenvim#install(0)' }) -- Post-install command for firenvim
Plug('vim-utils/vim-man') -- Plugin to enhance man-page reading
Plug('machakann/vim-sandwich') -- Plugin to case or uncase text
Plug('ptdewey/pendulum-nvim') -- Plugin to monitor opened file stats
Plug('folke/which-key.nvim') -- Plugin to show key hints
Plug('lervag/vimtex') -- PLugin to edit latex documents and preview changes in realtime (configuration needed)
Plug('junegunn/limelight.vim') -- Plugin for line region spotlighting
-- Install recognition note: source ~/.config/nvim/init.lua
Plug('jbyuki/instant.nvim') -- Plugin for realtime collab
-- End plugin management
vim.fn['plug#end']()
-- Post install plugin setup:
--
require("pendulum").setup({
    log_file = vim.fn.expand("~/.config/nvim/plugged/pendulum-nvim/pendulum-log.csv"), -- Specify desired path    
    timeout_len = 300, -- Pause logging after 5 minutes idle
    timer_len = 60, -- Check activity every 1 minute
    gen_reports = false,
})
--
require("which-key").setup({
  -- your configuration comes here
  delay=1600,
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
})
--
local perl = require("perl")

vim.api.nvim_create_user_command("Perl",       function() perl.new_group()             end, {})
vim.api.nvim_create_user_command("PerlJump",   function(o) perl.jump_named_group(vim.fn.split(o.args, [[\s+]])) end, {nargs="+"})
vim.api.nvim_create_user_command("PerlList",   function() perl.list_groups()           end, {})
vim.api.nvim_create_user_command("PerlResume", function() perl.resume_last_view()      end, {})

vim.keymap.set("n", [[\P]], function() vim.cmd("Perl")       end)
vim.keymap.set("n", [[\p]], function() vim.cmd("PerlResume") end)
--


-- Configuration settings for the installed plug-ins
--
-- Firenvim
vim.g.firenvim_config = {
    globalSettings = { alt = "all" },
    localSettings = {
        [".*"] = {
            cmdline  = "neovim",
            content  = "text",
            priority = 0,
            selector = "textarea",
            takeover = "never"
        }
    }
}
vim.api.nvim_create_autocmd("UIEnter", { -- Set resize window size
    callback = function()
        if vim.g.started_by_firenvim then
            vim.cmd("set lines=18 columns=80")
        end
    end,
})
--






---- Input functions
--

-- Add commandline argument to open file as Ansi-formatting neovim pager
vim.api.nvim_create_user_command("Term", function(args)
    local buf = vim.api.nvim_get_current_buf()
    local b = vim.api.nvim_create_buf(false, true)
    local chan = vim.api.nvim_open_term(b, {})
    vim.api.nvim_chan_send(chan, table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    vim.api.nvim_win_set_buf(0, b)
end, {})
-- call with  ex. 'kitty @ get-text --extent=all --ansi | bat --color=always > page_tmp && cat page_tmp | nvim +Term'



-- Insert Big funny text
vim.api.nvim_create_user_command("Figlet", function()
  local input = vim.fn.input("Enter text for ASCII banner: ")
  if input == "" then return end

  local handle = io.popen("figlet " .. vim.fn.shellescape(input))
  local result = handle:read("*a")
  handle:close()

  -- Split by newline to insert properly
  local lines = {}
  for line in result:gmatch("[^\n]+") do
    table.insert(lines, line)
  end

  vim.api.nvim_put(lines, "l", true, true)
end, {})



---- Shortcut Functions 
--
local function ToggleBreakIndent()
  print("ToggleBreakIndent called!")  -- Debug message
  if vim.o.breakindent then
    vim.o.breakindent = false
    print("breakindent disabled")
  else
    vim.o.breakindent = true
    print("breakindent enabled")
  end
end

--local function ToggleBreakIndent()
--  if vim.o.breakindent then
--    vim.o.breakindent = false
--    print("breakindent disabled")
--  else
--    vim.o.breakindent = true
--    print("breakindent enabled")
--  end
--end


local fg = nil
vim.api.nvim_create_user_command("Blueify", function()
    local hl = vim.api.nvim_get_hl_by_name("Normal", true)
    fg = fg or hl.foreground or 0xFFFFFF -- Fallback to white if undefined
    vim.api.nvim_set_hl(0, "Normal", { fg = hl.foreground == 0x9CDCFE and fg or 0x9CDCFE })
end, {})






-- This might be optimized by seeing if logic from OpenThing can improve parsing; it's possible openthing be modularized into functions which
-- serve a specific opening method associated with particular matching methodologies, and maybe OpenThing would be some underlying parsing method
-- Also, I know that mpv really really struggles with attaching, for some reason, to new instances when attempting to be launched without short
-- breaks in between, video links. It seems to stall or lag, and I don't have a good solution for that yet.
function OpenMpvFromLine()
  local mpv_socket = "/tmp/mpvsocket"
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file ~= "/home/user/.config/mpv/last_watched.txt" then
    print("This function only works in: last_watched.txt")
    return
  end

  local line = vim.api.nvim_get_current_line()

  -- Local file case
  local _, _, path = line:find("^%a+ %d+,%s+%d+%s+%d+:%d+:%d+%s+(%S.+)$")
  if path and vim.loop.fs_stat(path) then
    os.execute(string.format("nohup mpv '%s' > /dev/null 2>&1 &", path))
    return
  end

  -- FIFO-style tlds feed
  local domain, series, media = line:match("/tmp/([%w]+)__([%w_]+)__[^']+__([^']+)'")
  if domain and series and media then
    if domain == "ancientfaith" then
      local feed_url = string.format("https://feeds.%s.com/%s", domain, series)
      local cmd = string.format("tlds -url '%s' '%s' &", feed_url, media)
      os.execute(cmd)
      return
    else
      print("Domain not yet supported: " .. domain)
      return
    end
  end

  -- Structured log line
  local _, _, _, _, title, domain, creator, id =
    line:find("^(%a+ %d+,%s+%d+)%s+(%d+:%d+:%d+)%s+'(.-)'%s+(%S+)%s+(.-)%s+(%S+)$")

  if not (domain and id) then
    print("Malformed line: " .. line)
    return
  end

  local url
  if domain == "youtube" then
    url = "https://www.youtube.com/watch?v=" .. id
  elseif domain == "rumble" then
    url = "https://rumble.com/" .. id
  elseif domain == "odysee" then
    url = "https://odysee.com/" .. id
  elseif domain == "twitter" then
    url = "https://twitter.com/i/status/" .. id
  elseif domain == "facebook" then
    url = "https://www.facebook.com/watch/?v=" .. id
  elseif domain == "dailymotion" then
    url = "https://www.dailymotion.com/video/" .. id
  else
    print("No handler for domain: " .. domain)
    return
  end

  -- Check if same video is already playing
  local check_cmd = [[
    echo '{ "command": ["get_property", "path"] }' | socat - /tmp/mpvsocket 2>/dev/null | jq -r .data
  ]]
  local handle = io.popen(check_cmd)
  local current_path = handle and handle:read("*a"):gsub("%s+$", "")
  if handle then handle:close() end

  if current_path then
    local current_id = current_path:match("v=([%w_-]+)")
    if current_id and current_id == id then
      os.execute("notify-send 'mpv' 'This video is currently playing on the desktop'")
      local confirm = os.execute("zenity --question --text='This video is already playing. Open it again anyway?'")
      if confirm ~= 0 then
        print("Canceled by user.")
        return
      end
    end
  end

  -- Open with mpv
  os.execute(string.format("nohup mpv --input-ipc-server='%s' '%s' > /dev/null 2>&1 &", mpv_socket, url))
end




--OLDER "GOOD" FUNCTION:

----function OpenMpvFromLine() -- https://chatgpt.com/c/67f41cb9-8608-800b-80dc-b6fa81e98695
----  local current_file = vim.api.nvim_buf_get_name(0)
----  if current_file ~= "/home/user/.config/mpv/last_watched.txt" then
----    print("This function only works in: last_watched.txt")
----    return
----  end
----
----  local line = vim.api.nvim_get_current_line()
----
----  -- Check if it's a simple local file entry: <date> <time>  <full path>
----  local _, _, path = line:find("^%a+ %d+,%s+%d+%s+%d+:%d+:%d+%s+(%S.+)$")
----  if path and vim.loop.fs_stat(path) then
----    os.execute(string.format("nohup mpv '%s' > /dev/null 2>&1 &", path))
----    return
----  end
----
----  -- Check for a tlds-generated named FIFO path (e.g. /tmp/ancientfaith__series__title__mediaid)
----  local domain, series, media = line:match("/tmp/([%w]+)__([%w_]+)__[^']+__([^']+)'")
----  if domain and series and media then
----    if domain == "ancientfaith" then
----      local feed_url = string.format("https://feeds.%s.com/%s", domain, series)
----      local cmd = string.format("tlds -url '%s' '%s' &", feed_url, media)
----      os.execute(cmd)
----      return
----    else
----      print("Domain not yet supported: " .. domain)
----      return
----    end
----  end
----
----  -- Otherwise, try to parse a structured online video log line
----  local _, _, _, _, title, domain, creator, id =
----    line:find("^(%a+ %d+,%s+%d+)%s+(%d+:%d+:%d+)%s+'(.-)'%s+(%S+)%s+(.-)%s+(%S+)$")
----
----  if not (domain and id) then
----    print("Malformed line: " .. line)
----    return
----  end
----
----  local url
----  if domain == "youtube" then
----    url = "https://www.youtube.com/watch?v=" .. id
----  elseif domain == "rumble" then
----    url = "https://rumble.com/" .. id
----  elseif domain == "odysee" then
----    url = "https://odysee.com/" .. id
----  elseif domain == "twitter" then
----    url = "https://twitter.com/i/status/" .. id
----  elseif domain == "facebook" then
----    url = "https://www.facebook.com/watch/?v=" .. id
----  elseif domain == "dailymotion" then
----    url = "https://www.dailymotion.com/video/" .. id
----  else
----    print("No handler for domain: " .. domain)
----    return
----  end
----
----  os.execute(string.format("nohup mpv '%s' > /dev/null 2>&1 &", url))
----end
----
----
-- for opening selectedurl and openselected file see https://chatgpt.com/c/687e7f99-ac18-800b-b3ff-43db2c81090c for better selection.

-- function OpenSelectedUrl()
--     local word = vim.fn.expand("<cWORD>")
--     local url = word:match("https?://[^%s%>%\"%)']+")
--     if url then
--         os.execute("xdg-open " .. url .. " &")
--     else
--         print("No valid URL under cursor")
--     end
-- end
-- 
-- 
-- function OpenSelectedFile()
--     local file = vim.fn.getline("'<"):sub(vim.fn.col("'<"), vim.fn.col("'>")):gsub("%s+", "")
--     if vim.fn.filereadable(file) == 1 then
--         vim.cmd("edit " .. vim.fn.fnameescape(file))
--     else
--         print("File does not exist: " .. file)
--     end
-- end




-- ===== Inline *italic*, **bold**, __underline__, ~~strike~~ renderer =====
-- No Treesitter. Toggle with <leader>me.
  -- NOTE: These custom highlight groups (MdItalic, MdBold, etc.)
  -- are redefined after every :colorscheme to preserve extmark visuals.
  -- In current setup, these must be restored after any theme change,
  -- as typical Vim colorschemes clear or overwrite them.
  -- This makes md_emph *coupled* to theme switching logic elsewhere.
local function trim_edges(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
                 :gsub('^[\'"()<>%[%],]+', ""):gsub('[\'"()<>%[%],]+$', "")
end
local function stat(p) return vim.loop.fs_stat(p) end
-- OpenThing defined here to allow working inside of something I guess? ask chatgpt
function OpenThing()
  local candidates = {
    vim.fn.expand("<cfile>"),
    vim.fn.expand("<cWORD>"),
  }
  for _, raw in ipairs(candidates) do
    local text = trim_edges(raw or "")
    if text ~= "" then
      -- URL?
      local url = text:match("https?://[^%s>%\"')]+")
      if url then
        vim.fn.jobstart({ "xdg-open", url }, { detach = true })
        return
      end
      -- file[:ln[:col]]
      local file, ln, col = text:match("^([^:]+):?(%d*):?(%d*)$")
      file = trim_edges(file)
      if file ~= "" and stat(file) then
        vim.cmd("edit " .. vim.fn.fnameescape(file))
        if ln ~= "" then
          vim.api.nvim_win_set_cursor(0, { tonumber(ln), (tonumber(col) or 1) - 1 })
        end
        return
      end
    end
  end
  vim.notify("No URL or file under cursor", vim.log.levels.INFO)
end
do
  local NS         = vim.api.nvim_create_namespace("md_emph")
  local PRIORITY   = 180
  local METHOD     = "conceal"   -- "conceal" | "overlay"
  local OVERLAY_CH = ""          -- used when METHOD == "overlay"
  local watchers      = {}       -- bufnr -> attached?
  local saved_conc_lv = {}       -- winid -> old conceallevel
  -- fallback HL groups
  vim.api.nvim_set_hl(0, "MdItalic",    { italic = true })
  vim.api.nvim_set_hl(0, "MdBold",      { bold = true })
  vim.api.nvim_set_hl(0, "MdUnderline", { underline = true })
  vim.api.nvim_set_hl(0, "MdStrike",    { strikethrough = true })
  -- longest-first
  local SPECS = {
    { marker = "**", len = 2, hl = "MdBold"      },
    { marker = "__", len = 2, hl = "MdUnderline" },
    { marker = "~~", len = 2, hl = "MdStrike"    },
    { marker = "*",  len = 1, hl = "MdItalic"    },
  }
  local function escaped(line, pos)
    if pos <= 1 then return false end
    local back = 0
    for j = pos - 1, 1, -1 do
      if line:sub(j,j) == "\\" then back = back + 1 else break end
    end
    return back % 2 == 1
  end
  -- returns spans { {s,e,hl} } (1-based) and markers {col,...} (1-based)
  local function scan_line(line)
    local spans, markers = {}, {}
    local stacks = { ["**"] = {}, ["__"] = {}, ["~~"] = {}, ["*"] = {} }

    local i, n = 1, #line
    while i <= n do
      if not escaped(line, i) then
        local hit
        for _, sp in ipairs(SPECS) do
          if line:sub(i, i + sp.len - 1) == sp.marker then
            hit = sp
            break
          end
        end
        if hit then
          local stack = stacks[hit.marker]
          if #stack > 0 then
            local open_i = table.remove(stack)
            local s = open_i + hit.len
            local e = i - 1
            if s <= e then
              table.insert(spans, { s, e, hit.hl })
              for off = 0, hit.len - 1 do
                table.insert(markers, open_i + off)
                table.insert(markers, i + off)
              end
            end
          else
            table.insert(stack, i)
          end
          i = i + hit.len
        else
          i = i + 1
        end
      else
        i = i + 1
      end
    end
    return spans, markers
  end
  local function apply_spans(buf, lnum, spans)
    for _, s in ipairs(spans) do
      local sc = s[1] - 1
      local ec = s[2]
      vim.api.nvim_buf_set_extmark(buf, NS, lnum, sc, {
        end_row  = lnum,
        end_col  = ec,
        hl_group = s[3],
        priority = PRIORITY,
      })
    end
  end
  local function apply_markers(buf, lnum, cols)
    if #cols == 0 then return end
    local conceal = (METHOD == "conceal")
    for _, c1 in ipairs(cols) do
      local c0 = c1 - 1
      local opts = {
        end_row  = lnum,
        end_col  = c0 + 1,
        priority = PRIORITY + 1,
      }
      if conceal then
        opts.conceal = OVERLAY_CH
      else
        opts.virt_text     = { { OVERLAY_CH, "" } }
        opts.virt_text_pos = "overlay"
      end
      vim.api.nvim_buf_set_extmark(buf, NS, lnum, c0, opts)
    end
  end
  local function rescan(buf, first, last)
    vim.api.nvim_buf_clear_namespace(buf, NS, first, last + 1)
    local lines = vim.api.nvim_buf_get_lines(buf, first, last + 1, false)
    for i, line in ipairs(lines) do
      local spans, markers = scan_line(line)
      if #spans > 0 or #markers > 0 then
        local lnum = first + i - 1
        apply_spans(buf, lnum, spans)
        apply_markers(buf, lnum, markers)
      end
    end
  end
  local function enable(buf, win)
    if watchers[buf] then return end
    if METHOD == "conceal" then
      saved_conc_lv[win] = vim.api.nvim_get_option_value("conceallevel", { win = win })
      vim.api.nvim_set_option_value("conceallevel", 2, { win = win })
    end
    rescan(buf, 0, vim.api.nvim_buf_line_count(buf) - 1)

    watchers[buf] = vim.api.nvim_buf_attach(buf, false, {
      on_lines = function(_, b, _, first, last, added)
        local new_last = first + added - 1
        rescan(b, first, math.max(last, new_last))
      end,
      on_detach = function()
        watchers[buf] = nil
      end,
    })
    vim.b[buf].md_emph_enabled = true
  end
  local function disable(buf, win)
    if not watchers[buf] then return end
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
    pcall(vim.api.nvim_buf_detach, buf)
    watchers[buf] = nil
    if METHOD == "conceal" and saved_conc_lv[win] ~= nil then
      vim.api.nvim_set_option_value("conceallevel", saved_conc_lv[win], { win = win })
      saved_conc_lv[win] = nil
    end
    vim.b[buf].md_emph_enabled = false
  end
  function _G.MdEmphToggle()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if vim.b[buf].md_emph_enabled then
      disable(buf, win)
    else
      enable(buf, win)
    end
  end
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      vim.api.nvim_set_hl(0, "MdItalic",    { italic = true })
      vim.api.nvim_set_hl(0, "MdBold",      { bold = true })
      vim.api.nvim_set_hl(0, "MdUnderline", { underline = true })
      vim.api.nvim_set_hl(0, "MdStrike",    { strikethrough = true })
      -- explicitly rescan buffers with highlighting enabled
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.b[buf].md_emph_enabled then
          local last = vim.api.nvim_buf_line_count(buf) - 1
          rescan(buf, 0, last)
        end
      end
    end,
  })
  vim.keymap.set("n", "<leader>me", _G.MdEmphToggle, { desc = "Toggle inline md formatting" })
  _G.md_emph_rescan = rescan
end





vim.api.nvim_create_user_command('Time', function()
  local time = os.date('%b %d, %Y %H:%M:%S')
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, col) .. time .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)
end, {})




-- Dedicated quick folding/unfolding mode
-- not sure if it works perfectly, just made it
-- toggle with \fm, exit with `exit`, \fm, or <Esc>)
local Fold_Mode = {}
local echo = function(msg) vim.api.nvim_echo({{msg, "ModeMsg"}}, false, {}) end

function Fold_Mode.off()
  if not vim.b.fold_mode_on then return echo("Fold Mode already OFF") end
  vim.b.fold_mode_on = false
  for _,k in ipairs{"a","o","c","O","C","r","R","m","M","n","p","=","exit","<Esc>"} do
    pcall(vim.keymap.del,"n",k,{buffer=true})
  end
  echo("FOLD MODE OFF")
end
function Fold_Mode.on()
  if vim.b.fold_mode_on then return echo("Fold Mode already ON") end
  vim.b.fold_mode_on = true
  if vim.wo.foldmethod ~= "marker" then vim.wo.foldmethod = "marker" end
  local opts, map = {silent=true, buffer=true}, vim.keymap.set
  map("n","a","za",opts)       -- toggle fold under cursor
  map("n","A","zA",opts)       -- toggle recursively under cursor
  map("n","o","zo",opts)       -- open (non-recursive)
  map("n","c","zc",opts)       -- close (non-recursive)
  map("n","O","zO",opts)       -- open recursively
  map("n","C","zC",opts)       -- close recursively
  map("n","r","zr",opts)       -- open more globally
  map("n","R","zR",opts)       -- open all
  map("n","m","zm",opts)       -- close more globally
  map("n","M","zM",opts)       -- close all
  map("n","n","]z",opts)       -- next fold edge
  map("n","p","[z",opts)       -- prev fold edge
  map("n","=","zx",opts)       -- recompute folds
  map("n","exit",fm_off,opts)  -- exit via `exit`
  map("n","<Esc>",fm_off,opts) -- exit via <Esc>
end
function Fold_Mode.toggle()
  if vim.b.fold_mode_on then Fold_Mode.off() else Fold_Mode.on() end
end




-- Center current line in the buffer window
local cc=false
local NSP=vim.api.nvim_create_namespace('CCPad')
local NSL=vim.api.nvim_create_namespace('CCLine')
local _CC_bot_extra=0
local _CC_top_extra=0
-- highlight group: whole current line black on light blue bg
local function set_cc_hls()
  vim.api.nvim_set_hl(0,'CCLineHL',{ fg='#000000', bg='#b0e0ff', nocombine=true })
end
set_cc_hls()
local function is_float(win) return (vim.api.nvim_win_get_config(win).relative or "")~="" end
local function line_bg(buf,row)
  vim.api.nvim_buf_clear_namespace(buf,NSL,0,-1)
  vim.api.nvim_buf_set_extmark(buf,NSL,row,0,{
    line_hl_group='CCLineHL',end_row=row,priority=300
  })
end
local function apply_pad(buf)
  local winh=vim.api.nvim_win_get_height(0)
  local center=math.floor(winh/2)
  local cur=vim.api.nvim_win_get_cursor(0)[1]
  local first=vim.fn.line('w0')
  local last=vim.fn.line('w$')
  local nlines=vim.api.nvim_buf_line_count(buf)
  local need_top=((first==1) and math.max(0,center-(cur-1)) or 0)+_CC_top_extra
  local need_bot=((last==nlines) and math.max(0,center-(last-cur)) or 0)+_CC_bot_extra
  local function mkpad(n) local t={}; for _=1,n do t[#t+1]={{" "}} end; return t end
  vim.api.nvim_buf_clear_namespace(buf,NSP,0,-1)
  if need_top>0 then
    vim.api.nvim_buf_set_extmark(buf,NSP,0,0,{virt_lines=mkpad(need_top),virt_lines_above=true,priority=200})
  end
  if need_bot>0 then
    vim.api.nvim_buf_set_extmark(buf,NSP,math.max(0,nlines-1),0,{virt_lines=mkpad(need_bot),virt_lines_above=false,priority=200})
  end
end
local function recenter()
  if vim.fn.mode():find('i') then return end
  vim.cmd('normal! zz')
end
local function refresh()
  if not cc or is_float(0) then return end
  local buf=vim.api.nvim_get_current_buf()
  local row=vim.api.nvim_win_get_cursor(0)[1]-1
  apply_pad(buf)
  recenter()
  line_bg(buf,row)
end
function ToggleCenteredCursor()
  local buf=vim.api.nvim_get_current_buf()
  if cc then
    cc=false
    _CC_bot_extra=0;_CC_top_extra=0
    pcall(vim.api.nvim_del_augroup_by_name,'CCAU')
    pcall(vim.keymap.del,'n','j',{buffer=buf})
    pcall(vim.keymap.del,'n','k',{buffer=buf})
    vim.opt.scrolloff=0
    vim.api.nvim_buf_clear_namespace(buf,NSP,0,-1)
    vim.api.nvim_buf_clear_namespace(buf,NSL,0,-1)
    return
  end
  cc=true
  _CC_bot_extra=0;_CC_top_extra=0
  pcall(vim.api.nvim_del_augroup_by_name,'CCAU')
  set_cc_hls()
  vim.opt.scrolloff=0
  refresh()
  vim.keymap.set('n','k',function()
    local cur=vim.api.nvim_win_get_cursor(0)[1]
    local first=vim.fn.line('w0')
    if cur==1 and first==1 then _CC_top_extra=_CC_top_extra+1 end
    vim.cmd('normal! k')
    local n=vim.api.nvim_buf_line_count(0)
    local after=vim.api.nvim_win_get_cursor(0)[1]
    if _CC_bot_extra>0 and cur==n and after<n then _CC_bot_extra=_CC_bot_extra-1 end
    refresh()
  end,{buffer=buf,silent=true,nowait=true})
  vim.keymap.set('n','j',function()
    local cur=vim.api.nvim_win_get_cursor(0)[1]
    local n=vim.api.nvim_buf_line_count(0)
    local first=vim.fn.line('w0')
    if cur==n then _CC_bot_extra=_CC_bot_extra+1 end
    if first==1 and _CC_top_extra>0 then _CC_top_extra=_CC_top_extra-1 end
    vim.cmd('normal! j')
    refresh()
  end,{buffer=buf,silent=true,nowait=true})
  local grp=vim.api.nvim_create_augroup('CCAU',{clear=true})
  vim.api.nvim_create_autocmd({'CursorMoved','WinScrolled'},{group=grp,callback=refresh})
  vim.api.nvim_create_autocmd('ColorScheme',{group=grp,callback=function()set_cc_hls();refresh()end})
  vim.api.nvim_create_autocmd({'WinEnter','BufEnter'},{
    group=grp,callback=function()
      if not cc then return end
      if is_float(vim.api.nvim_get_current_win()) then
        vim.api.nvim_buf_clear_namespace(buf,NSL,0,-1)
        return
      end
      set_cc_hls()
      refresh()
    end
  })
end




-- Interactive colorscheme previewer and picker
local function preview_colorschemes_popup()
  local colorschemes = vim.fn.getcompletion("", "color")
  local width  = 30
  local height = math.min(#colorschemes, vim.o.lines - 4)
  local row    = math.ceil((vim.o.lines  - height) / 2)
  local col    = math.ceil((vim.o.columns - width)  / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width    = width,
    height   = height,
    row      = row,
    col      = col,
    style    = "minimal",
    border   = "rounded",
    zindex   = 50,
    focusable = true,
  })

  vim.api.nvim_set_option_value("winhighlight",
    "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel",
    { win = win })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, colorschemes)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local group = vim.api.nvim_create_augroup("PreviewColorsGroup", { clear = true })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = buf,
    callback = function()
      local line  = vim.api.nvim_win_get_cursor(win)[1]
      local theme = colorschemes[line]
      if theme then
        local ok, err = pcall(vim.cmd, "colorscheme " .. theme)
        if not ok then
          vim.notify("Failed to load '" .. theme .. "': " .. err, vim.log.levels.WARN)
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(win),
    callback = function()
      vim.schedule(function()
        vim.api.nvim_set_hl(0, "MdItalic",    { italic = true })
        vim.api.nvim_set_hl(0, "MdBold",      { bold = true })
        vim.api.nvim_set_hl(0, "MdUnderline", { underline = true })
        vim.api.nvim_set_hl(0, "MdStrike",    { strikethrough = true })

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].md_emph_enabled then
            local last = vim.api.nvim_buf_line_count(buf) - 1
            if last >= 0 then
              _G.md_emph_rescan(buf, 0, last)
            end
          end
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufHidden", "BufWipeout" }, {
    group = group,
    buffer = buf,
    callback = function()
      vim.api.nvim_del_augroup_by_name("PreviewColorsGroup")
    end,
  })

  local opts = { buffer = buf, noremap = true, silent = true }
  vim.keymap.set("n", "q", "<cmd>close<CR>", opts)
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", opts)
end
-- NOTE: If theme patching or a Lua override mechanism is adopted upstream,
-- all md_emph-related restoration logic here can be removed.
vim.api.nvim_create_user_command("PreviewColorschemes", preview_colorschemes_popup, {})





-- test 3 of double popup buffer Put in init.lua or lua/yourmod/sub_bank.lua and require it.
-- === :%s memory bank popup (drop-in) =====================================

local SUB_MEM_NS = vim.api.nvim_create_namespace("SubMemBank")
local SUB_MEM_STATE = { bank_buf=nil, bank_win=nil, hist_buf=nil, hist_win=nil, bottom_open=false }
local SUB_MEM_FILE = vim.fn.stdpath("config") .. "/.fav_commands"

local function smb_read_file(path)
  local f = io.open(path, "r")
  if not f then return {} end
  local t = {}
  for line in f:lines() do if line ~= "" then t[#t+1] = line end end
  f:close(); return t
end

local function smb_write_file(path, lines)
  local f = assert(io.open(path, "w"))
  for _, l in ipairs(lines) do f:write(l .. "\n") end
  f:close()
end

local function smb_buf_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

local function smb_set_lines(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or {})
end

local function smb_uniq(list)
  local out, seen = {}, {}
  for _, v in ipairs(list) do
    if not seen[v] then seen[v]=true; out[#out+1]=v end
  end
  return out
end

local function smb_get_sub_hist()
  local total = vim.fn.histnr("cmd")
  local seen, out = {}, {}
  for i = total, 1, -1 do
    local cmd = vim.fn.histget("cmd", i)
    if cmd ~= "" and (cmd:match("^%%s") or cmd:match("^:%%s")) and not seen[cmd] then
      seen[cmd] = true; out[#out+1] = cmd
    end
  end
  return out
end

local function smb_save_bank()
  if SUB_MEM_STATE.bank_buf and vim.api.nvim_buf_is_valid(SUB_MEM_STATE.bank_buf) then
    smb_write_file(SUB_MEM_FILE, smb_uniq(smb_buf_lines(SUB_MEM_STATE.bank_buf)))
  end
end

local function smb_close_popup()
  if SUB_MEM_STATE.hist_win and vim.api.nvim_win_is_valid(SUB_MEM_STATE.hist_win) then pcall(vim.api.nvim_win_close, SUB_MEM_STATE.hist_win, true) end
  if SUB_MEM_STATE.bank_win and vim.api.nvim_win_is_valid(SUB_MEM_STATE.bank_win) then pcall(vim.api.nvim_win_close, SUB_MEM_STATE.bank_win, true) end
  for _, b in ipairs({SUB_MEM_STATE.hist_buf, SUB_MEM_STATE.bank_buf}) do
    if b and vim.api.nvim_buf_is_valid(b) then pcall(vim.api.nvim_buf_delete, b, {force=true}) end
  end
  SUB_MEM_STATE = { bank_buf=nil, bank_win=nil, hist_buf=nil, hist_win=nil, bottom_open=false }
end

local function smb_highlight_hist(idx)
  if SUB_MEM_STATE.hist_buf and vim.api.nvim_buf_is_valid(SUB_MEM_STATE.hist_buf) then
    vim.api.nvim_buf_add_highlight(SUB_MEM_STATE.hist_buf, SUB_MEM_NS, "Visual", idx, 0, -1)
  end
end

local function smb_add_to_bank(line)
  if not line or line == "" then return end
  if not (SUB_MEM_STATE.bank_buf and vim.api.nvim_buf_is_valid(SUB_MEM_STATE.bank_buf)) then return end
  local cur = smb_buf_lines(SUB_MEM_STATE.bank_buf)
  local seen = {}
  for _, l in ipairs(cur) do seen[l]=true end
  if not seen[line] then cur[#cur+1]=line; smb_set_lines(SUB_MEM_STATE.bank_buf, cur); smb_save_bank() end
end

-- run command; show normal output for :%s, only swallow E486
local function smb_run_and_close(cmdline)
  local s = (cmdline or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("^:", "")
  smb_close_popup()
  if s == "" then return end

  if s:match("^%%s") then
    local ok, err = pcall(vim.cmd, s)
    if not ok then
      if err and err:match("E486") then
        vim.notify("Pattern not found", vim.log.levels.WARN, { title = "SubMemoryBank" })
      elseif err then
        vim.notify(err:gsub("\n.*", ""), vim.log.levels.ERROR, { title = "SubMemoryBank" })
      end
    end
    return
  end

  local ok, err = pcall(vim.cmd, s)
  if not ok and err then
    vim.notify(err:gsub("\n.*", ""), vim.log.levels.ERROR, { title = "SubMemoryBank" })
  end
end

-- bottom opener (handles number/table row/col)
local function smb_open_bottom()
  if SUB_MEM_STATE.bottom_open then
    if SUB_MEM_STATE.hist_win and vim.api.nvim_win_is_valid(SUB_MEM_STATE.hist_win) then
      vim.api.nvim_set_current_win(SUB_MEM_STATE.hist_win)
    end
    return
  end

  local function cfg_num(v)
    if type(v) == "number" then return v end
    if type(v) == "table" then return v[false] or v[1] or 0 end
    return 0
  end

  local width = math.floor(vim.o.columns * 0.7)
  local h_bot = math.max(6, math.floor(vim.o.lines * 0.25))
  local top_conf = vim.api.nvim_win_get_config(SUB_MEM_STATE.bank_win)
  local col = cfg_num(top_conf.col)
  local row = cfg_num(top_conf.row) + (top_conf.height or 10) + 1

  SUB_MEM_STATE.hist_buf = vim.api.nvim_create_buf(false, true)
  SUB_MEM_STATE.hist_win = vim.api.nvim_open_win(SUB_MEM_STATE.hist_buf, false, {
    relative = "editor",
    width = width,
    height = h_bot,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })

  vim.bo[SUB_MEM_STATE.hist_buf].buftype = "nofile"
  vim.bo[SUB_MEM_STATE.hist_buf].bufhidden = "wipe"
  vim.bo[SUB_MEM_STATE.hist_buf].modifiable = true
  vim.bo[SUB_MEM_STATE.hist_buf].filetype = "SubMemHist"

  local bank_set = {}
  for _, l in ipairs(smb_buf_lines(SUB_MEM_STATE.bank_buf)) do bank_set[l] = true end
  local hist = {}
  for _, l in ipairs(smb_get_sub_hist()) do if not bank_set[l] then hist[#hist+1] = l end end
  smb_set_lines(SUB_MEM_STATE.hist_buf, hist)

  vim.keymap.set("n", "<CR>", function()
    local idx = vim.api.nvim_win_get_cursor(SUB_MEM_STATE.hist_win)[1]
    local line = hist[idx]; if not line then return end
    smb_add_to_bank(line)
    vim.api.nvim_buf_add_highlight(SUB_MEM_STATE.hist_buf, SUB_MEM_NS, "Visual", idx-1, 0, -1)
  end, { buffer = SUB_MEM_STATE.hist_buf, nowait = true, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    if SUB_MEM_STATE.bank_win and vim.api.nvim_win_is_valid(SUB_MEM_STATE.bank_win) then
      vim.api.nvim_set_current_win(SUB_MEM_STATE.bank_win)
    end
  end, { buffer = SUB_MEM_STATE.hist_buf, nowait = true, silent = true })

  SUB_MEM_STATE.bottom_open = true
  vim.api.nvim_set_current_win(SUB_MEM_STATE.hist_win)
end

-- autosave the bank buffer to ~/.config/nvim/.fav_commands
local function smb_ensure_autosave(bank_buf)
  local gid = vim.api.nvim_create_augroup("SubMemBankAutosave", { clear = false })
  vim.api.nvim_clear_autocmds({ group = gid, buffer = bank_buf })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave", "BufWritePost" }, {
    group = gid,
    buffer = bank_buf,
    callback = function()
      if SUB_MEM_STATE.bank_buf and vim.api.nvim_buf_is_valid(SUB_MEM_STATE.bank_buf) then
        -- de-dupe, keep non-empty, then write
        local lines = vim.api.nvim_buf_get_lines(SUB_MEM_STATE.bank_buf, 0, -1, false)
        local seen, uniq = {}, {}
        for _, l in ipairs(lines) do
          if l ~= "" and not seen[l] then seen[l] = true; uniq[#uniq+1] = l end
        end
        local f = assert(io.open(SUB_MEM_FILE, "w"))
        for _, l in ipairs(uniq) do f:write(l .. "\n") end
        f:close()
      end
    end,
  })
end

function _SUB_MEMORY_BANK_OPEN()
  smb_close_popup()

  -- load persisted bank (if file exists)
  local bank_lines = {}
  if vim.fn.filereadable(SUB_MEM_FILE) == 1 then
    bank_lines = smb_read_file(SUB_MEM_FILE)
  end

  -- top window
  local width = math.floor(vim.o.columns * 0.7)
  local h_top = math.max(8, math.floor(vim.o.lines * 0.3))
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - (h_top + 8)) / 2)

  SUB_MEM_STATE.bank_buf = vim.api.nvim_create_buf(false, true)
  SUB_MEM_STATE.bank_win = vim.api.nvim_open_win(SUB_MEM_STATE.bank_buf, true, {
    relative="editor", width=width, height=h_top, col=col, row=row,
    style="minimal", border="rounded", title=":%s Memory Bank", title_pos="center",
  })
  vim.bo[SUB_MEM_STATE.bank_buf].buftype = "nofile"
  vim.bo[SUB_MEM_STATE.bank_buf].bufhidden = "wipe"
  vim.bo[SUB_MEM_STATE.bank_buf].modifiable = true
  vim.bo[SUB_MEM_STATE.bank_buf].filetype = "SubMemBank"
  smb_set_lines(SUB_MEM_STATE.bank_buf, bank_lines)
  smb_ensure_autosave(SUB_MEM_STATE.bank_buf)

  -- ONLY in top buffer:
  vim.keymap.set("n", "h", smb_open_bottom, {buffer=SUB_MEM_STATE.bank_buf, nowait=true, silent=true})

  vim.keymap.set("n", "<CR>", function()
    local lnum = vim.api.nvim_win_get_cursor(SUB_MEM_STATE.bank_win)[1]
    local line = (vim.api.nvim_buf_get_lines(SUB_MEM_STATE.bank_buf, lnum-1, lnum, false)[1] or "")
    smb_run_and_close(line)
  end, {buffer=SUB_MEM_STATE.bank_buf, nowait=true, silent=true})

  vim.keymap.set("n", "<Esc>", smb_close_popup, {buffer=SUB_MEM_STATE.bank_buf, nowait=true, silent=true})
end

vim.api.nvim_create_user_command("SubMemoryBank", _SUB_MEMORY_BANK_OPEN, {})
-- optional mapping:
-- vim.keymap.set("n", "<leader>sm", ":SubMemoryBank<CR>", {silent=true, desc=":%s memory bank"})



-- Input / Output functions
-- Optional: set this\/ in your config to pin a device
vim.g.kdeconnect_device_id = ""

local function _kde_find_device()
  local id = vim.g.kdeconnect_device_id
  if id and id ~= "" then return id end
  local lines = vim.fn.systemlist("kdeconnect-cli --list-devices --id-only")
  for _, l in ipairs(lines or {}) do
    if l and l ~= "" then return l end
  end
  return nil
end

local function _basename_no_ext(p)
  local base = vim.fn.fnamemodify(p, ":t")
  local root = vim.fn.fnamemodify(base, ":r")
  return (root == "" and base) or root
end

local function _ext(p)
  return vim.fn.fnamemodify(p, ":e"):lower()
end

local function _write_buf_to(path)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local ok, err = pcall(function()
    local f = assert(io.open(path, "w"))
    f:write(table.concat(lines, "\n"))
    f:write("\n")
    f:close()
  end)
  return ok, err
end

function _G.kde_send()
  local buf = 0
  local file = vim.api.nvim_buf_get_name(buf)

  if file == "" then
    vim.notify("kde-send: buffer has no filename.", vim.log.levels.WARN)
    return
  end

  local dev = _kde_find_device()
  if not dev then
    vim.notify("kde-send: no KDE Connect device found (pair or set g:kdeconnect_device_id).",
      vim.log.levels.ERROR)
    return
  end

  local send_path = file
  local is_txt = (_ext(file) == "txt")
  local modified = vim.bo[buf].modified

  -- Decide source to send
  if modified then
    -- Ask user: send modified buffer?
    local ans = vim.fn.input("kde-send: buffer has unsaved changes. Send current buffer contents? [y/N]: ")
    if not ans or ans == "" then
      vim.notify("kde-send: cancelled.", vim.log.levels.INFO)
      return
    end
    ans = ans:lower()
    if not (ans == "y" or ans == "yes") then
      vim.notify("kde-send: cancelled.", vim.log.levels.INFO)
      return
    end
    -- Always write to /tmp/<name>.txt for modified buffers
    local tmp = "/tmp/" .. _basename_no_ext(file) .. ".txt"
    local ok, err = _write_buf_to(tmp)
    if not ok then
      vim.notify("kde-send: failed to stage buffer → " .. tmp .. ": " .. tostring(err),
        vim.log.levels.ERROR)
      return
    end
    send_path = tmp
  else
    -- Unmodified: if not .txt, stage a .txt copy in /tmp
    if not is_txt then
      local tmp = "/tmp/" .. _basename_no_ext(file) .. ".txt"
      local cp_code = vim.fn.system({'/usr/bin/env','cp','-f','--',file,tmp})
      if vim.v.shell_error ~= 0 then
        vim.notify("kde-send: cp failed staging → " .. tmp, vim.log.levels.ERROR)
        return
      end
      send_path = tmp
    else
      -- .txt and unmodified: send file directly
      if vim.loop.fs_stat(file) == nil then
        vim.notify("kde-send: file not found on disk.", vim.log.levels.ERROR)
        return
      end
      send_path = file
    end
  end

  -- Send
  local cmd = { "kdeconnect-cli", "-d", dev, "--share", send_path }
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("kde-send: sent → " .. send_path, vim.log.levels.INFO)
      else
        vim.notify("kde-send: failed (exit " .. code .. ") for " .. send_path, vim.log.levels.ERROR)
      end
    end,
  })
end

vim.api.nvim_create_user_command("KdeSend", function() _G.kde_send() end, {})






local function ReplaceLineWithOllama()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1      -- 0-based
  local cur = vim.api.nvim_get_current_line()
  local prompt = "SYSTEM: Act as a problem solver for the following context in the style of Saint Theophan the Recluse in his revision of Unseen Warfare, answering in only one sentence without new lines:\n" .. cur

  vim.system(
    { "ollama", "run", "llama3.2", "--keepalive", "24h" },
    { stdin = prompt, text = true },
    function(res)
      vim.schedule(function()
        if res.code ~= 0 then
          return vim.notify("Ollama error: " .. (res.stderr or "unknown"), vim.log.levels.ERROR)
        end
        -- split stdout to lines, trim trailing blank lines
        local out = res.stdout:gsub("\r", "")
        local lines = {}
        for s in (out .. "\n"):gmatch("(.-)\n") do table.insert(lines, s) end
        while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
        if #lines == 0 then lines = { "" } end

        -- replace exactly the current line with the output (can be multi-line)
        vim.api.nvim_buf_set_lines(0, row, row + 1, false, lines)
      end)
    end
  )
end




function OpenParentDirectory()
  if vim.bo.filetype == "netrw" then
    vim.cmd("bd!")  -- close netrw if already open
    return
  end
  local path = vim.fn.expand("%:p:h")
  if path == "" then return end
  vim.cmd("Ex " .. vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  vim.defer_fn(function()
    if vim.bo[buf].filetype == "netrw" then
      vim.keymap.set("n", "<Esc>", "<cmd>bd!<CR>", { buffer = buf, silent = true })
    end
  end, 30)
end




---- Keybinds for functions
vim.g.mapleader = "\\" -- make "\" var: <Leader>


-- '<Tab>' -> ToggleBreakIndent()
vim.keymap.set('n', '<Leader><Tab>', ToggleBreakIndent, { noremap = true, silent = true })

-- 'm' -> OpenMpvFromLine() (just have cursor on line)
vim.keymap.set("n", "<Leader>m", OpenMpvFromLine, { noremap = true, silent = true })

-- 'o' -> OpenThing() (runs on cursor hover in normal mode)
vim.keymap.set("n", "<Leader>o", OpenThing, { noremap = true, silent = true, desc = "Open URL/file under cursor" })

-- 'me' -> _G.MdEmphToggle

-- 'th' -> PreviewColorschemes()
vim.keymap.set("n", "<leader>th", "<cmd>PreviewColorschemes<CR>", { noremap = true, silent = true })

-- Virtual motion aka structural whitespace extension
vim.keymap.set("n", "<leader>vm", require("virtual_motion").toggle, { desc = "Toggle virtual motion" })

-- 'cc' -> ToggleCenteredCursor()
vim.keymap.set('n','<leader>cc',ToggleCenteredCursor,opts)

-- 'fm' -> Fold_Mode.toggle()
vim.keymap.set("n","<leader>fm",Fold_Mode.toggle,{silent=true})

-- '/' -> ReplaceLineWithOllama()
vim.keymap.set("n", "<leader>/", ReplaceLineWithOllama,
  { noremap = true, silent = true, desc = "Replace line with Ollama output" })

-- 'e' -> OpenParentDirectory()
vim.keymap.set({"n","v"}, "<leader>e", OpenParentDirectory, {desc="Open parent dir in netrw"})


----- Notes on functionality:

--[[
NOTE ON HIGHLIGHT GROUPS AND THEME SWITCHING:

Currently, markdown emphasis (md_emph) extmarks rely on custom highlight groups.
These groups are wiped out by most :colorscheme commands (especially VimL schemes).
To restore rendering, popup code forcibly reapplies highlight groups and triggers a rescan after theme switch.

GOAL FOR THE FUTURE:
Decouple md_emph from popup and theme preview logic, either by using a Lua colorscheme with highlight overrides,
or by patching VimL schemes to preserve these highlight groups natively.
]]

