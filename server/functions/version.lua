MSK.Check = {}

local CheckResourceName = function(repo, resource)
    local name, notify = repo.checkName, false

    if type(resource) == 'table' then
        name = repo.checkName.name
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

MSK.Check.Version = function(repo)
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
exports('CheckVersion', MSK.Check.Version)

setmetatable(MSK.Check, {
    __call = function(self, ...)
        self.Version(...)
    end
})

MSK.Check.Dependency = function(resource, minimumVersion, showMessage)
    local currentVersion = GetResourceMetadata(resource, 'version', 0)
    currentVersion = currentVersion and currentVersion:match('%d+%.%d+%.%d+') or 'unknown'

    if currentVersion ~= minimumVersion then
        local cV = MSK.String.Split(currentVersion, '.')
	    local mV = MSK.String.Split(minimumVersion, '.')
        local errMsg = ("^1Resource %s requires a minimum version of '%s' of resource '%s'! ^5Current Version: ^1%s^0"):format(GetInvokingResource() or GetCurrentResourceName(), minimumVersion, resource, currentVersion)
        
        for i = 1, #cV do
            local current, minimum = tonumber(cV[i]), tonumber(mV[i])

            if current ~= minimum then
                if not current or current < minimum then
                    if showMessage then
                        print(errMsg)
                    end

                    return false, errMsg
                else break end
            end
        end
    end

    return true
end
exports('CheckDependency', MSK.Check.Dependency)