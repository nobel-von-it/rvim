vim.g.mapleader=' '

local vk = vim.keymap
local vo = vim.opt
local vc = vim.cmd
local vfn = vim.fn
local va = vim.api

local opts = { silent = true, noremap = true }

-- block with commands
vk.set('i', 'jk', '<ESC>', opts)
vk.set('n', '<leader>n', vc.nohl, opts)
vk.set('n', '<leader>e', vc.Ex, opts)
vk.set('n', '<leader>y', '"+y', opts)

-- Tabs and buffers
vk.set('n', ']b', vc.BufferNext, opts)
vk.set('n', '[b', vc.BufferPrev, opts)
vk.set('n', '<leader>x', vc.BufferClose, opts)

va.nvim_create_autocmd("BufWritePre", {
  pattern = '*.rs',
  callback = function ()
    vc.RustFmt()
  end
})



-- block with options
vo.number=true
vo.relativenumber=true
vo.cursorline=true

vo.shiftwidth=2
vo.tabstop=2
vo.scrolloff=8
vo.expandtab=true
vo.ruler=true
vo.smarttab=true
vo.autoindent=true
vo.lazyredraw=true

vo.ignorecase=true
vo.smartcase=true
vo.swapfile = false
vo.backup = false

local lazypath = vfn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vfn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vo.rtp:prepend(lazypath)

require'lazy'.setup{
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require'telescope'.setup{}
      local bi = require'telescope.builtin'
      vk.set('n', '<leader>ff', bi.find_files, {})
      vk.set('n', '<leader>fg', bi.live_grep, {})
      vk.set('n', '<leader>g', function()
        bi.grep_string({search = vfn.input('Grep > ')})
      end, {})
    end
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'nvim_treesitter#foedexpr()'
      require'nvim-treesitter.configs'.setup{
        ensure_installed = {
          'vimdoc', 'rust', 'c', 'lua', 'html', 'css', 'bash'
        },
        sync_install = false,
        auto_install = true,
        indent = {
          enable = true
        },
        highlight = {
          enable = true,
          disable = function(lang, buf)
            local max_size = 100 * 1014
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_size then
              return true
            end
          end,
        },
      }
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/nvim-cmp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "j-hui/fidget.nvim",
    },
    config = function()
      local cmp = require'cmp'
      local cmpl = require'cmp_nvim_lsp'
      local capabilities = vim.tbl_deep_extend(
        'force',
        {},
        vim.lsp.protocol.make_client_capabilities(),
        cmpl.default_capabilities()
      )

      require'fidget'.setup{}
      require'mason'.setup{}
      require'mason-lspconfig'.setup{
        ensure_installed = {
          'lua_ls',
          'rust_analyzer',
          'gopls',
          'clangd',
        },
        handlers = {
          function (sn)
            if sn == 'rust_analyzer' or sn == 'rust-analyzer' then
              return
            end
            require'lspconfig'[sn].setup {
              capabilities = capabilities
            }
          end,
        }
      }

      local select = {behavior = cmp.SelectBehavior.Select}

      cmp.setup{
        snippet = {
          expand = function(args)
            require'luasnip'.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert{
          ['<C-p>'] = cmp.mapping.select_prev_item(select),
          ['<C-n>'] = cmp.mapping.select_next_item(select),
          ['<C-y>'] = cmp.mapping.confirm({select = true}),
          ['<CR>'] = cmp.mapping.confirm({select = true}),
          ['<C-Space>'] = cmp.mapping.complete(),
        },
        sources = cmp.config.sources{
          {name = 'nvim_lsp'},
          {name = 'luasnip'},
          {name = 'buffer'},
          {name = 'path'},
        }
      }
      vim.diagnostic.config{
        float = {
          focusable = false,
          style = 'minimal',
          border = 'rounded',
          source = 'always',
          header = '',
          prefix = '',
        }
      }
    end
  },
  {
    'mrcjkb/rustaceanvim',
    version = '^5', -- Recommended
    lazy = false, -- This plugin is already lazy
    config = function ()
      vim.g.rustaceanvim = {
        tools = {
          formatter = {
            command = 'cargo',
            args = {'fmt', '--', '--emit=files'}
          },
          hover_actions = {
            auto_focus = true,
          },
          inlayHints = {
            bindingModeHints = {
              enable = false,
            },
            chainingHints = {
              enable = true,
            },
            closingBraceHints = {
              enable = true,
              minLines = 25,
            },
            closureReturnTypeHints = {
              enable = "never",
            },
            lifetimeElisionHints = {
              enable = "never",
              useParameterNames = false,
            },
            maxLength = 25,
            parameterHints = {
              enable = true,
            },
            reborrowHints = {
              enable = "never",
            },
            renderColons = true,
            typeHints = {
              enable = true,
              hideClosureInitialization = false,
              hideNamedConstructor = false,
            },
          }
        },
        server = {
          on_attach = function (_, bufnr)
            local opt = {silent = true, buffer = bufnr}
            vk.set('n', '<leader>a', function ()
              vc.RustLsp('codeAction')
            end, opt)
            vk.set('n', '<leader>h', function ()
              vc.RustLsp({'hover', 'actions'})
            end, opt)
            vk.set('n', '<leader>re', function ()
              vc.RustLsp('explainError')
            end, opt)
          end,
          settings = {
            ['rust-analyzer'] = {
              checkOnSave = {
                enable = true,
                command = 'clippy'
              },
              procMarcro ={
                enable = true
              },
              diagnostic = {
                enable = true,
              }
            }
          }
        }
      }
    end
  },
  {
    'saecki/crates.nvim',
    tag = 'stable',
    config = function()
      local crates = require"crates"

      vk.set("n", "<leader>ct", crates.toggle, opts)
      vk.set("n", "<leader>cr", crates.reload, opts)

      vk.set("n", "<leader>cv", crates.show_versions_popup, opts)
      vk.set("n", "<leader>cf", crates.show_features_popup, opts)
      vk.set("n", "<leader>cd", crates.show_dependencies_popup, opts)

      vk.set("n", "<leader>cu", crates.update_crate, opts)
      vk.set("v", "<leader>cu", crates.update_crates, opts)
      vk.set("n", "<leader>ca", crates.update_all_crates, opts)
      vk.set("n", "<leader>cU", crates.upgrade_crate, opts)
      vk.set("v", "<leader>cU", crates.upgrade_crates, opts)
      vk.set("n", "<leader>cA", crates.upgrade_all_crates, opts)

      vk.set("n", "<leader>cx", crates.expand_plain_crate_to_inline_table, opts)
      vk.set("n", "<leader>cX", crates.extract_crate_into_table, opts)

      vk.set("n", "<leader>cH", crates.open_homepage, opts)
      vk.set("n", "<leader>cR", crates.open_repository, opts)
      vk.set("n", "<leader>cD", crates.open_documentation, opts)
      vk.set("n", "<leader>cC", crates.open_crates_io, opts)
      vk.set("n", "<leader>cL", crates.open_lib_rs, opts)

      crates.setup{}
    end,
  },
  {
    "MysticalDevil/inlay-hints.nvim",
    event = "LspAttach",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("inlay-hints").setup()
    end
  },
  {
    'romgrk/barbar.nvim',
    dependencies = {
      'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
      'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    },
    init = function() vim.g.barbar_auto_setup = true end,
    opts = {
      -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
      -- animation = true,
      -- insert_at_start = true,
      -- …etc.
    },
    version = '^1.0.0', -- optional: only update when a new 1.x version is released
  },
  {
    'numToStr/Comment.nvim',
    lazy = false,
    config = function ()
      require'Comment'.setup{}
    end
  },
  {
    'echasnovski/mini.pairs',
    config = true,
  },
  {
    "Exafunction/codeium.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    config = function()
        require("codeium").setup({
        })
    end
  },
}

