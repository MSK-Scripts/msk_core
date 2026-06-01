--[[
    IMPORTANT — what does NOT belong here:
    Aliases that have their OWN export in msk_core (e.g.
    'Progressbar', 'TableContains', 'SetTimeout', 'ProgressStop', 'CloseInput',
    'ShowCoords', 'Round', 'Comma', 'Split', ...) are already resolved by the
    generic export proxy in import.lua and do NOT belong here.

    Only aliases WITHOUT their own export belong here, e.g. examples:
        AddTimeout / DelTimeout            -> timeout.Set / timeout.Clear
        Table_Contains / DumpTable         -> table.Contains / table.Dump
        Math.Number                        -> math.Random
        LoadAnimDict / LoadModel           -> request.AnimDict / request.Model
        RegisterCallback / RegisterServerCallback -> callback.Register

    This table is filled module by module in the following batches, as soon as
    the respective module has been ported.

    Format:
    ['<AliasKey>'] = { module = '<moduleFolder>', key = '<key in the module return value>' }
    key = nil  ->  the whole module return value is set as the alias
]]

return {
    -- core modules --
    -- Aliases WITHOUT their own export (module folder case-sensitive, exactly like the API key):
    ['AddTimeout']     = { module = 'Timeout', key = 'Set'        },
    ['DelTimeout']     = { module = 'Timeout', key = 'Clear'      },
    ['Table_Contains'] = { module = 'Table',   key = 'Contains'   },
    ['DumpTable']      = { module = 'Table',   key = 'Dump'       },

    -- Special case: in v2 MSK.Trim has a DIFFERENT (inverted) bool semantic
    -- than the 'Trim' export (= String.Trim). Since the alias takes precedence over
    -- the export proxy, MSK.Trim thus returns the legacy variant, while
    -- exports.msk_core:Trim remains String.Trim.
    ['Trim']           = { module = 'String',  key = 'TrimLegacy' },

    -- Request --
    ['LoadAnimDict']   = { module = 'Request', key = 'AnimDict' },
    ['LoadModel']      = { module = 'Request', key = 'Model'    },

    -- Coords --
    -- MSK.DoesShowCoords -> Coords.Active (on the client there is no export with the
    -- same name; on the server there is, but the alias applies uniformly).
    ['DoesShowCoords']  = { module = 'Coords', key = 'Active' },
}
