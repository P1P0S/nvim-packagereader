---@diagnostic disable: undefined-global
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local M = {
  opts = {
    cmd = {
      manager = "npm",
    },
  },
}

local show_scripts = function(opts)
  opts = opts or {}
  local filePath = vim.fn.getcwd() .. "\\package.json"
  local file = io.open(filePath, "rb")

  if not file then
    vim.notify("Package.json not found", vim.log.levels.ERROR, { title = "PackageReader" })
    return
  end

  local contents = file:read("*all")
  file:close()

  local data = vim.fn.json_decode(contents)

  if not data["scripts"] then
    vim.notify("Key 'scripts' does not exist.", vim.log.levels.ERROR, { title = "PackageReader" })
    return
  end

  if next(data["scripts"]) == nil then
    vim.notify("Key 'scripts' is empty.", vim.log.levels.WARN, { title = "PackageReader" })
    return
  end

  local script_list = {}
  for key, value in pairs(data["scripts"]) do
    table.insert(script_list, key .. ": " .. value)
  end

  pickers
    .new({
      prompt_title = "Scripts",
      finder = finders.new_table({
        results = script_list,
      }),
      sorter = sorters.get_generic_fuzzy_sorter(),
      initial_mode = "normal",
      attach_mappings = function(prompt_bufnr, map)
        local execute_script = function()
          local selected = actions_state.get_selected_entry(prompt_bufnr)
          local first_word = string.match(selected.value, "%S+")
          local filtered_word = string.gsub(first_word, ":$", "")
          local command = M.opts.cmd.manager .. " run " .. filtered_word
          actions.close(prompt_bufnr)
          vim.api.nvim_command("tabnew | terminal " .. command)
          vim.notify(
            string.format('Command "%s" running in a new tab', command),
            vim.log.levels.INFO,
            { title = "PackageReader" }
          )
        end

        map("i", "<CR>", execute_script)
        map("n", "<CR>", execute_script)

        return true
      end,
    }, opts)
    :find()
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts)
  vim.api.nvim_create_user_command("PackageReader", M.init, {})
end

function M.init()
  show_scripts(require("telescope.themes").get_dropdown())
end

return M
