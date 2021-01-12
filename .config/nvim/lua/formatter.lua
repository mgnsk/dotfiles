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
    dockerfile = {
        {
            cmd = {
                "dockerfile_format"
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
    sql = {
        {
            cmd = {
                "~/.tools/js/sql_format.mjs"
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
  autocmd BufWritePost *.css,*.scss,*.vert,*.tesc,*.tese,*.geom,*.frag,*.comp,*.glsl,*Dockerfile,*go,*.html,*.json,*.js,*.mjs,*.md,*.ts,*.lua,*.proto,*.rs,*.sh,*.sql,*.yml,*.yaml call fns#Format()
augroup END
]],
    true
)
