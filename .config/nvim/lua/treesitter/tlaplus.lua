local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.tlaplus = {
    install_info = {
        url = "~/.tools/nvim/tree-sitter-tlaplus",
        files = {"src/parser.c", "src/scanner.cc"}
    },
    filetype = "tla"
}
