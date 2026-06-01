local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Check = {}

if IS_CORE then
    local function CheckResourceName(repo, resource)
        local notify = false

        if type(repo.checkName) == 'table' then
            notify = repo.checkName.notify
        end

        print(("[^2%s^0] [^3WARNING^0] ^3This resource should not be renamed! This can lead to errors. Please rename it to '%s'"):format(resource, repo.name))

        if notify and resource ~= repo.name then
            CreateThread(function()
                while true do
                    Wait(5000)
                    print(("[^2%s^0] [^3WARNING^0] ^3This resource should not be renamed! This can lead to errors. Please rename it to '%s'"):format(resource, repo.name))
                end
            end)
        end
    end

    function Check.Version(repo)
        assert(repo and type(repo) == "table", "repo must be a table on function MSK.Check.Version")
        assert(repo.author, "parameter author must be a string on function MSK.Check.Version")
        assert(repo.name, "parameter name must be a string on function MSK.Check.Version")

        local resource = GetInvokingResource() or GetCurrentResourceName()
        local currentVersion = GetResourceMetadata(resource, 'version', 0)
        local api = ("https://api.github.com/repos/%s/%s/releases/latest"):format(repo.author, repo.name)

        if currentVersion then
            currentVersion = currentVersion:match('%d+%.%d+%.%d+')
        end

        if not currentVersion then
            return print(("[^1ERROR^0] ^1Unable to find current version of resource %s^0"):format(resource))
        end

        SetTimeout(1000, function()
            if repo.checkName then
                CheckResourceName(repo, resource)
            end

            PerformHttpRequest(api, function(status, response, headers)
                if status ~= 200 then
                    return print(("[^2msk_core^0] [^1ERROR^0] ^1Versioncheck failed for repository %s! Http Error: %s^0"):format(repo.name, status))
                end

                response = json.decode(response)
                if response.prerelease then return end

                local latestVersion = response.tag_name:match('%d+%.%d+%.%d+')

                if not latestVersion then
                    return print(("[^2msk_core^0] [^1ERROR^0] ^1Versioncheck failed for repository %s! Unable to find latest version (received %s)^0"):format(repo.name, latestVersion))
                end

                if latestVersion == currentVersion then
                    return repo.print and print(("[^2%s^0] ^2✓ Resource is Up to Date^0 - ^5Current Version: ^2%s^0"):format(resource, currentVersion))
                end

                local cV = MSK.String.Split(currentVersion, '.')
                local lV = MSK.String.Split(latestVersion, '.')

                for i = 1, #cV do
                    local current, latest = tonumber(cV[i]), tonumber(lV[i])

                    if current ~= latest then
                        if current < latest then
                            return print(("[^2msk_core^0] [^3Update Available^0] ^3An Update is available for %s! ^0[^5Current Version: ^1%s^0 - ^5Latest Version: ^2%s^0]\r\n[^2msk_core^0]^5 Download:^4 %s ^0"):format(resource, currentVersion, latestVersion, repo.download or response.html_url))
                        else
                            if repo.print then
                                print(("[^2%s^0] [^3WARNING^0] ^3Higher Version detected than latest version! ^0[^5Current Version: ^3%s^0 - ^5Latest Version: ^2%s^0]"):format(resource, currentVersion, latestVersion))
                            end
                            break
                        end
                    end
                end
            end, 'GET')
        end)
    end
    exports('CheckVersion', Check.Version)

    function Check.Dependency(resource, minimumVersion, showMessage)
        local currentVersion = GetResourceMetadata(resource, 'version', 0)
        currentVersion = currentVersion and currentVersion:match('%d+%.%d+%.%d+') or 'unknown'

        if currentVersion ~= minimumVersion then
            local cV = MSK.String.Split(currentVersion, '.')
            local mV = MSK.String.Split(minimumVersion, '.')
            local errMsg = ("^1resource %s requires minimum version '%s' of resource '%s'! (current version: %s)^0"):format(GetInvokingResource() or GetCurrentResourceName(), minimumVersion, resource, currentVersion)

            for i = 1, #cV do
                local current, minimum = tonumber(cV[i]), tonumber(mV[i])

                if current ~= minimum then
                    if not current or current < minimum then
                        if showMessage then
                            MSK.Logging('error', errMsg)
                        end
                        return false, errMsg
                    else
                        break
                    end
                end
            end
        end

        return true
    end
    exports('CheckDependency', Check.Dependency)

    MSK.Check = setmetatable(Check, {
        __call = function(self, ...) return self.Version(...) end
    })

    ----------------------------------------------------------------------------
    -- Auto check for msk_core itself
    ----------------------------------------------------------------------------
    local AUTHOR, NAME, FILE = "MSK-Scripts", "VERSIONS", "Lib.json"
    local RESOURCE_NAME = "msk_core"
    local NAME_COLORED = "[^2" .. GetCurrentResourceName() .. "^0]"
    local GITHUB_API = "https://raw.githubusercontent.com/%s/%s/main/%s"
    local DOWNLOAD = "https://github.com/%s/%s/releases/latest"

    SetTimeout(1000, function()
        if RESOURCE_NAME ~= GetCurrentResourceName() then
            CreateThread(function()
                while true do
                    print(("%s [^3WARNING^0] ^3This resource should not be renamed! This can lead to errors. Please rename it to '%s'"):format(NAME_COLORED, RESOURCE_NAME))
                    Wait(5000)
                end
            end)
        end

        PerformHttpRequest(GITHUB_API:format(AUTHOR, NAME, FILE), function(status, response, headers)
            if status ~= 200 then
                return print(("%s [^1ERROR^0] ^1Version Check failed! Http Error: %s^0"):format(NAME_COLORED, status))
            end

            response = json.decode(response)
            local latestVersion = response[1].version
            local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)

            if currentVersion == latestVersion then
                return Config.VersionChecker and print(("%s ^2✓ Resource is Up to Date^0 - ^5Current Version: ^2%s^0"):format(NAME_COLORED, currentVersion))
            end

            local cV = MSK.String.Split(currentVersion, '.')
            local lV = MSK.String.Split(latestVersion, '.')

            for i = 1, #cV do
                local current, latest = tonumber(cV[i]), tonumber(lV[i])

                if current ~= latest then
                    if current < latest then
                        print(("%s [^3Update Available^0] ^3An Update is available for %s! ^0[^5Current Version: ^1%s^0 - ^5Latest Version: ^2%s^0]\r\n%s ^5Download:^4 %s ^0"):format(NAME_COLORED, RESOURCE_NAME, currentVersion, latestVersion, NAME_COLORED, DOWNLOAD:format(AUTHOR, RESOURCE_NAME)))

                        for j = 1, #response do
                            if response[j].version == currentVersion then break end

                            if response[j].changelogs then
                                print(("%s [^3Changelogs v%s^0]"):format(NAME_COLORED, response[j].version))

                                for k = 1, #response[j].changelogs do
                                    print(('%s %s'):format(NAME_COLORED, response[j].changelogs[k]))
                                end
                            end
                        end

                        break
                    else
                        if Config.VersionChecker then
                            print(("%s ^3Beta Version detected! ^0[^5Current Version: ^3%s^0 - ^5Latest Version: ^2%s^0] - ^3You can ignore this message!^0"):format(NAME_COLORED, currentVersion, latestVersion))
                        end
                        break
                    end
                end
            end
        end)
    end)

    return MSK.Check
else
    function Check.Version(...) return exports.msk_core:CheckVersion(...) end
    function Check.Dependency(...) return exports.msk_core:CheckDependency(...) end

    return setmetatable(Check, {
        __call = function(self, ...) return self.Version(...) end
    })
end
