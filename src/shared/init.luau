--!strict
-- Shared module index
-- Exports all core modules for easy access

local Shared = {}

-- Core framework
Shared.ServiceRegistry = require(script.Core.ServiceRegistry)
Shared.BaseService = require(script.Core.BaseService)
Shared.BaseController = require(script.Core.BaseController)
Shared.RemoteEventHandler = require(script.Core.RemoteEventHandler)

-- Utilities
Shared.TableUtils = require(script.Utils.TableUtils)

-- Constants
Shared.GameConstants = require(script.Constants.GameConstants)

-- Types
Shared.CardTypes = require(script.Types.CardTypes)
Shared.AudioTypes = require(script.Types.AudioTypes)
Shared.EffectsTypes = require(script.Types.EffectsTypes)

-- Data
Shared.CardDatabase = require(script.Data.CardDatabase)
Shared.AnimeCharacters = require(script.Data.AnimeCharacters)

-- Export
return Shared 