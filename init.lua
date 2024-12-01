vim.g.mapleader = ' '
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local vk = vim.keymap
local vo = vim.opt
local vc = vim.cmd
local vfn = vim.fn
local va = vim.api
local vl = vim.lsp

local opts = { silent = true, noremap = true }

-- block with commands
vk.set('i', 'jk', '<ESC>', opts)
vk.set('n', '<leader>n', vc.nohl, opts)
vk.set('n', '<leader>y', '"+y', opts)

-- Tabs and buffers
-- vk.set('n', ']b', vc.BufferNext, opts)
-- vk.set('n', '[b', vc.BufferPrev, opts)
-- vk.set('n', '<leader>x', vc.BufferClose, opts)
vk.set('n', 'C-k', function()
  vc("silent! lua vim.lsp.buf.code_action({ only = {'source.fixAll'} })")
end, opts)
vk.set('n', '<leader>e', vc.NvimTreeOpen, opts)
vk.set('n', '<leader>g', vc.Neogit, opts)

-- Map <Tab> in visual mode to insert a tab at the beginning of each line
va.nvim_set_keymap('v', '<Tab>', ':<C-u>exec "\'<,\'>normal! I\\t"<CR>', opts)
va.nvim_set_keymap('v', '<S-Tab>', ':<C-u>exec "\'<,\'>normal! x"<CR>', opts)



-- block with options
vo.number = true
vo.relativenumber = true
vo.cursorline = true
vo.timeoutlen = 200

vo.shiftwidth = 2
vo.tabstop = 2
vo.scrolloff = 12
vo.expandtab = true
vo.ruler = true
vo.smarttab = true
vo.autoindent = true
vo.lazyredraw = true

vo.ignorecase = true
vo.smartcase = true
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

require 'lazy'.setup {
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require 'telescope'.setup {}
      local bi = require 'telescope.builtin'
      vk.set('n', '<leader>ff', bi.find_files, {})
      vk.set('n', '<leader>fg', function()
        bi.grep_string({ search = vfn.input('Grep > ') })
      end, {})
    end
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'nvim_treesitter#foedexpr()'
      require 'nvim-treesitter.configs'.setup {
        ensure_installed = {
          'vimdoc', 'rust', 'c', 'lua', 'html', 'css', 'bash', 'go', 'javascript', 'cpp'
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
      local cmp = require 'cmp'
      local cmpl = require 'cmp_nvim_lsp'
      local capabilities = vim.tbl_deep_extend(
        'force',
        {},
        vl.protocol.make_client_capabilities(),
        cmpl.default_capabilities()
      )

      require 'fidget'.setup {}
      require 'mason'.setup {}
      require 'mason-lspconfig'.setup {
        ensure_installed = {
          'lua_ls',
          'rust_analyzer',
          'gopls',
          'clangd',
          'tsserver',
          'html',
          'cssls',
          'jdtls',
          'elixirls',
          'phpactor',
          'dockerls',
          'graphql',
          'jsonls',
          'perlnavigator',
          'pyright',
          'yamlls',
          'volar',
        },
        handlers = {
          function(sn)
            require 'lspconfig'[sn].setup {
              capabilities = capabilities,
              on_attach = function(_, bufnr)
                -- Format and run Clippy before saving the file
                va.nvim_create_autocmd("BufWritePre", {
                  buffer = bufnr,
                  callback = function()
                    vl.buf.format()
                  end,
                })
              end,
              -- Add Clippy as a checker
              settings = {
                ["rust-analyzer"] = {
                  checkOnSave = {
                    command = "clippy"
                  }
                }
              }
            }
          end,
        }
      }

      local select = { behavior = cmp.SelectBehavior.Select }
      vc [[autocmd BufWritePre * lua vim.lsp.buf.format()]]

      for _, method in ipairs({ 'textDocument/diagnostic', 'workspace/diagnostic' }) do
        local default_diagnostic_handler = vl.handlers[method]
        vl.handlers[method] = function(err, result, context, config)
          if err ~= nil and err.code == -32802 then
            return
          end
          return default_diagnostic_handler(err, result, context, config)
        end
      end


      cmp.setup {
        snippet = {
          expand = function(args)
            require 'luasnip'.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-p>'] = cmp.mapping.select_prev_item(select),
          ['<C-n>'] = cmp.mapping.select_next_item(select),
          ['<C-y>'] = cmp.mapping.confirm({ select = true }),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
        },
        sources = cmp.config.sources {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        }
      }
      vim.diagnostic.config {
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
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup()
      vk.set('n', '<leader>aj', vc.GoAddTag, opts)
      vk.set('n', '<leader>cj', vc.GoClearTag, opts)
      vk.set('n', '<leader>at', vc.GoAddTest, opts)
      vk.set('n', '<leader>ie', vc.GoIfErr, opts)
      vk.set('n', '<leader>fw', vc.GoFillSwitch, opts)
      vk.set('n', '<leader>ft', vc.GoFillStruct, opts)
    end,
    event = { "CmdlineEnter" },
    ft = { "go", 'gomod' },
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },
  { 'akinsho/toggleterm.nvim', version = "*", config = function()
    require("toggleterm").setup()
    vk.set('n', '<C-/>', ":ToggleTerm direction=float<CR>", opts)
    vk.set('t', '<C-/>', "<C-\\><C-n>:ToggleTerm direction=float<CR>", opts)
  end },
  {
    "MysticalDevil/inlay-hints.nvim",
    event = "LspAttach",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("inlay-hints").setup()
    end
  },
  -- {
  --   'romgrk/barbar.nvim',
  --   dependencies = {
  --     'lewis6991/gitsigns.nvim',     -- OPTIONAL: for git status
  --     'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  --   },
  --   init = function() vim.g.barbar_auto_setup = true end,
  --   opts = {
  --     -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
  --     -- animation = true,
  --     -- insert_at_start = true,
  --     -- …etc.
  --   },
  --   version = '^1.0.0', -- optional: only update when a new 1.x version is released
  -- },
  {
    'numToStr/Comment.nvim',
    lazy = false,
    config = function()
      require 'Comment'.setup {}
    end
  },
  {
    'echasnovski/mini.pairs',
    config = true,
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      "sindrets/diffview.nvim",        -- optional - Diff integration
      -- Only one of these is needed, not both.
      "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua",              -- optional
    },
    config = true
  },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, config = function()
    vc.colorscheme("catppuccin")
  end },
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
  -- add this to the file where you setup your other plugins:
  -- {
  --   "monkoose/neocodeium",
  --   event = "VeryLazy",
  --   config = function()
  --     local neocodeium = require("neocodeium")
  --     neocodeium.setup()
  --     vk.set("i", "<Tab>", neocodeium.accept)
  --   end,
  -- },

  -- {
  --   'luozhiya/fittencode.nvim',
  --   config = function()
  --     require('fittencode').setup()
  --   end,
  -- },
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require "nvim-tree".setup {
        view = {
          width = 30,
        },
        filters = {
          dotfiles = true,
        }
      }
    end,
  },
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  }
}
