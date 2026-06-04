require("file_actions").configureFormatBeforeSave({ lsp_format = "fallback" })

local revive = require("lint").linters.revive
revive.cmd = "revive_custom"
revive.ignore_exitcode = true

require("file_actions").configureLintAfterSave({ "revive" }) -- TODO: vet
