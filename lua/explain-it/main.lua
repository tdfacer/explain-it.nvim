-- local D = require "explain-it.util.debug"

-- -- internal methods
-- local ExplainIt = {}

-- -- state
-- local S = {
--   -- Boolean determining if the plugin is enabled or not.
--   enabled = false,
-- }

-- ---Toggle the plugin by calling the `enable`/`disable` methods respectively.
-- ---@private
-- function ExplainIt.toggle()
--   if S.enabled then
--     return ExplainIt.disable()
--   end

--   return ExplainIt.enable()
-- end

-- ---Initializes the plugin.
-- ---@private
-- function ExplainIt.enable()
--   if S.enabled then
--     return S
--   end

--   S.enabled = true

--   return S
-- end

-- ---Disables the plugin and reset the internal state.
-- ---@private
-- function ExplainIt.disable()
--   if not S.enabled then
--     return S
--   end

--   -- reset the state
--   S = {
--     enabled = false,
--   }

--   return S
-- end

-- return ExplainIt
