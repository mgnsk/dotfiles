require("file_actions").configureFormatBeforeSave({ "goimports" })
require("file_actions").configureLintAfterSave({ "go", "govet", "golint" })
