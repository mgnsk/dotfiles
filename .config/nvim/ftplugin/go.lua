require("file_actions").configureFormatBeforeSave({ lsp_format = "fallback" })
require("file_actions").configureLintAfterSave({ "go", "govet", "golint" })
