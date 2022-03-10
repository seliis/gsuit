do
    local gsuit  = {}
    gsuit.indent = 2
    gsuit.socket = nil
    gsuit.net = {
        addr = "127.0.0.1",
        port = "8080",
        inst = nil
    }
    gsuit.debug = {
        mode = true,
        file = nil
    }

    function gsuit.connSocket()
        local dir = lfs.currentdir()
        package.path = string.format("%s;%s%s", package.path, dir, "/LuaSocket/?.lua")
        package.cpath = string.format("%s;%s%s", package.cpath, dir, "/LuaSocket/?.dll")
        gsuit.socket = require("socket")
        local ran, _ = pcall(
            function()
                gsuit.net.inst = gsuit.socket.try(gsuit.socket.connect(gsuit.net.addr, gsuit.net.port))
                gsuit.net.inst:setoption("tcp-nodelay", true)
            end
        )
        if ran then
            gsuit.print("Socket Connected")
        else
            gsuit.print("Socket Server Not Exist")
        end
    end

    function gsuit.disconnSocket()
        if gsuit.net.inst then
            gsuit.print("Socket Disconnected")
            gsuit.net.inst:close()
        else
            gsuit.print("Socket Server Not Exist")
        end
    end

    function gsuit.send(data)
        if gsuit.debug.mode and gsuit.debug.file then
            gsuit.print(data)
        end
        if gsuit.net.inst then
            gsuit.socket.try(gsuit.net.inst:send(data))
        end
    end

    function gsuit.print(content, inspect)
        local function print_data(data, indent, type)
            local space = ""; for i = 1, indent do space = space .. " " end
            gsuit.debug.file:write(string.format("%s%s\n", space, data))
        end
        local function print_dict(dict, indent, key)
            if key then
                print_data(key .. " = {", indent)
            else
                print_data("{", indent)
            end
            for k, v in pairs(dict) do
                local t = type(v); if t == "table" then
                    print_dict(v, indent + gsuit.indent, k)
                else
                    if inspect then
                        print_data(k .. " = " .. t .. " " .. tostring(v), indent + gsuit.indent)
                    else
                        print_data(k .. " = " .. tostring(v), indent + gsuit.indent)
                    end
                end
            end
            print_data("}", indent)
        end
        gsuit.debug.file:write("[GSUIT]: ")
        local dtype = type(content); if dtype == "table" then
            print_dict(content, 0)
        else
            if inspect then
                print_data(dtype .. " " .. tostring(content), 0)
            else
                print_data(tostring(content), 0)
            end
        end
    end

    function gsuit.round(num, dec)
        local mul = 10 ^ (dec or 0)
        return math.floor(num * mul + 0.5) / mul
    end

    function gsuit.getG(vector)
        if vector then
            return gsuit.round(math.sqrt(vector.x^2 + vector.y^2 + vector.z^2), 3)
        else
            return 0
        end
    end

    function LuaExportStart()
        if gsuit.debug.mode and not gsuit.debug.file then
            gsuit.debug.file = io.open(lfs.writedir() .. "Scripts/gsuit/debug.log", "w")
        end
        gsuit.connSocket()
        gsuit.send("Open")
    end

    function LuaExportAfterNextFrame()
        local acc = LoGetAccelerationUnits()
        gsuit.send(gsuit.getG(acc))
    end

    function LuaExportStop()
        gsuit.send("Dismiss")
        gsuit.disconnSocket()
        if gsuit.debug.mode and gsuit.debug.file then
            gsuit.debug.file:close()
            gsuit.debug.file = nil
        end
    end
end