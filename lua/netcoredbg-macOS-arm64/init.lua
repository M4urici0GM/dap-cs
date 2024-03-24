-- myplugin/init.lua
local M = {}


local function get_plugin_directory()
    local str = debug.getinfo(1, "S").source:sub(2)
    str = str:match("(.*/)")               -- Get the directory of the current file
    return str:gsub("/[^/]+/[^/]+/$", "/") -- Go up two directories
end

local plugin_directory = get_plugin_directory()
local netcoredbg_path = plugin_directory .. 'netcoredbg/netcoredbg'

M.setup = function(dap)
    dap.adapters.coreclr = {
        type = 'executable',
        command = netcoredbg_path,
        args = { '--interpreter=vscode' }
    }

    local function dotnet_build_project ()
        local default_path = vim.fn.getcwd() .. '/'
        if vim.g['dotnet_last_proj_path'] ~= nil then
            default_path = vim.g['dotnet_last_proj_path']
        end

        local path = vim.fn.input('Path to your *proj file', default_path, 'file')
        vim.g['dotnet_last_proj_path'] = path
        local cmd = 'dotnet build -c Debug ' .. path .. ' > /dev/null'
        print('')
        print('Cmd to execute: ' .. cmd)
        local f = os.execute(cmd)
        if f == 0 then
            print('\nBuild: ✔️ ')
        else
            print('\nBuild: ❌ (code: ' .. f .. ')')
        end
    end

    local  function dotnet_get_dll_path ()
        local request = function()
            return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/', 'file')
        end

        if vim.g['dotnet_last_dll_path'] == nil then
            vim.g['dotnet_last_dll_path'] = request()
        else
            if vim.fn.confirm('Do you want to change the path to dll?\n' .. vim.g['dotnet_last_dll_path'], '&yes\n&no', 2) == 1 then
                vim.g['dotnet_last_dll_path'] = request()
            end
        end

        return vim.g['dotnet_last_dll_path']
    end



    dap.configurations.cs = {
        {
            type = 'coreclr',
            name = 'NetCoreDbg: Launch',
            request = 'launch',
            cwd = '${fileDirname}',
            console = "integratedTerminal",
            args = { "--interpreter=cli" },
            program = function()
                if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
                    dotnet_build_project()
                end

                return dotnet_get_dll_path()
            end,
            env = {
                ASPNETCORE_ENVIRONMENT = function()
                    return vim.fn.input("ASPNETCORE_ENVIRONMENT: ", "Development")
                end,
                ASPNETCORE_URL = function()
                    return vim.fn.input("ASPNETCORE_URL: ", "http://localhost:5000")
                end,
            }
        },
    }
end

return M
