-- Read-only asset reference finder for Roblox Studio Command Bar (Edit mode).
-- Does not change any instance, property, Source, permission, or asset.
-- This helper has not been executed in Roblox Studio by the audit.
local targets = {
    ["137554909322431"] = true,
    ["75160593025484"] = true,
    ["136769849825926"] = true,
    ["133285462741466"] = true,
    ["119728152122091"] = true,
    ["114284944645440"] = true,
    ["8578316223"] = true,
    ["137448731583582"] = true,
    ["1014915761"] = true,
    ["14795103410"] = true,
}
local selected, seen, counts = {}, {}, {}
local function report(obj, prop, value, line)
    local matched = {}
    for id in tostring(value):gmatch("%d+") do
        if targets[id] and not matched[id] then
            matched[id] = true
            counts[id] = (counts[id] or 0) + 1
            print("[AssetMatch]", id, obj:GetFullName(), prop, line and ("line " .. line) or "")
            if not seen[obj] then
                seen[obj] = true
                table.insert(selected, obj)
            end
        end
    end
end
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("Sound") then
        report(obj, "SoundId", obj.SoundId)
    elseif obj:IsA("ParticleEmitter") then
        report(obj, "Texture", obj.Texture)
    end
    if obj:IsA("LuaSourceContainer") then
        local ok, source = pcall(function() return obj.Source end)
        if ok then
            local lineNumber = 0
            for line in (source .. "\n"):gmatch("(.-)\n") do
                lineNumber += 1
                report(obj, "Source", line, lineNumber)
            end
        else
            warn("[AssetScan] Source unavailable:", obj:GetFullName())
        end
    end
end
-- Selection is editor UI only; no place data changes.
game:GetService("Selection"):Set(selected)
for id in pairs(targets) do
    print("[AssetCount]", id, counts[id] or 0)
end
print("[AssetScan] Selected matching objects:", #selected)
-- A zero count does NOT exclude encoded/obfuscated or externally loaded assets.
