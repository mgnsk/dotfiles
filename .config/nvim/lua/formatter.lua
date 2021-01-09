require "format".setup {
    ["*"] = {
        {
            cmd = {
                -- remove trailing whitespace
                "sed -i 's/[ \t]*$//'"
            }
        }
    },
    css = {
        {
            cmd = {
                "prettier -w"
            }
        }
    },
    scss = {
        {
            cmd = {
                "prettier -w"
            }
        }
    },
    glsl = {
        {
            cmd = {
                "clang-format -i"
            }
        }
    },
    go = {
        {
            cmd = {
                "gofumports -w"
            }
        }
    },
    html = {
        {
            cmd = {
                "prettier -w"
            }
        }
    },
    json = {
        {
            cmd = {
                "prettier -w"
            }
        }
    },
    javascript = {
        {
            cmd = {
                "prettier -w"
            }
        }
    },
    typescript = {
        {
            cmd = {
                "prettier -w"
            }
        }
    },
    lua = {
        {
            cmd = {
                "luafmt -w replace"
            }
        }
    },
    proto = {
        {
            cmd = {
                "clang-format -i"
            }
        }
    },
    rust = {
        {
            cmd = {
                "rustfmt"
            }
        }
    },
    sh = {
        {
            cmd = {
                "shfmt -w"
            }
        }
    },
    yaml = {
        {
            cmd = {
                "prettier -w"
            }
        }
    },
    markdown = {
        {
            cmd = {
                "prettier -w"
            }
        }
    }
}

vim.api.nvim_exec(
    [[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.css,*.scss,*.vert,*.tesc,*.tese,*.geom,*.frag,*.comp,*.glsl,*go,*.html,*.json,*.js,*.md,*.ts,*.lua,*.proto,*.rs,*.sh,*.yml,*.yaml call fns#Format()
augroup END
]],
    true
)
