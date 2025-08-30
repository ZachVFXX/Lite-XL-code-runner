-- mod-version:3

-----------------------------------------------------------------------
-- NAME       : runner
-- DESCRIPTION: Plugin to run current file in integrated terminal
-- AUTHOR     : Zach / LiteXL
-- GOALS      : Execute Python file in project venv via LiteXL terminal
-----------------------------------------------------------------------

-- Import required modules
local core = require "core"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"
local common = require "core.common"

-- Try to load the terminal plugin
local terminal_ok = pcall(require, "plugins.terminal")

-- Plugin configuration
config.plugins.runner = {}

-- Function to get current working directory as base path
local function get_base_path()
  if core.project_dir then
    return core.project_dir
  end
  local doc = core.active_view and core.active_view.doc
  if doc and doc.filename then
    return common.dirname(doc.filename)
  end
  return "."
end

-- Function to detect platform and set appropriate paths
local function get_platform_config()
  local is_windows = package.config:sub(1,1) == '\\'
  return {
    venv_path = is_windows and ".venv/Scripts" or ".venv/bin",
    python_exe = is_windows and "python.exe" or "python",
    activate_script = is_windows and "activate.bat" or "activate",
    is_windows = is_windows
  }
end

-- Set default configuration
local platform_config = get_platform_config()
config.plugins.runner.base_path = get_base_path()
config.plugins.runner.venv_path = platform_config.venv_path
config.plugins.runner.python_exe = platform_config.python_exe
config.plugins.runner.activate_script = platform_config.activate_script

-- Function to get current file path
local function get_current_file_path()
  local doc = core.active_view and core.active_view.doc
  return (doc and doc.filename) or nil
end

-- Function to execute runner command in terminal
local function run_in_terminal()
  local current_file = get_current_file_path()
  if not current_file then
    core.error("No active file found")
    return
  end
  if not terminal_ok then
    core.error("Terminal plugin not found. Please install: lpm install terminal")
    return
  end

  -- Build paths
  local base_path = config.plugins.runner.base_path
  local activate_script = base_path .. "/" .. config.plugins.runner.venv_path .. "/" .. config.plugins.runner.activate_script
  local python_exe = base_path .. "/" .. config.plugins.runner.venv_path .. "/" .. config.plugins.runner.python_exe

  -- Build the command
  local cmd
  if platform_config.is_windows then
    cmd = string.format('%s & %s %s', activate_script, python_exe, current_file)
  else
    cmd = string.format('source %s && %s %s', activate_script, python_exe, current_file)
  end

  command.perform("terminal:execute", cmd)
end

-- Register command
command.add("core.docview", {
  ["runner:run"] = run_in_terminal,
})

-- Key binding
keymap.add {
  ["ctrl+alt+p"] = "runner:run",
}
