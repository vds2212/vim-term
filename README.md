# Vim-Term
A terminal Vim/Neovim plugin

## Introduction

The `terminal` command of Vim is powerful and you can achieve a lot by using the right option.
But the default has a number of flaws.

- If you didn't quit all the terminal processes Vim doesn't let you quit (the `++kill=kill` option)
- If the only Window is the terminal window when you quit it Vim doesn't quite (the `++close` option)

It is rather clumsy to:
- Reuse an existing terminal when it has been hided
- Start a terminal vertically with a given number of columns

## Commands

The plugin introduces the following commands:
- Terminal
- TermList
- TermGo

The `Terminal` command mimic the `terminal` command.
It can be used to start a terminal or to start a command in a terminal.
- It creates a Terminal in the current working directory
- It execute the command if a command has been specified
- The terminal window is vertical it with is determined by the `g:term_width` value (default to 100)
- The terminal window with is fixed (it doesn't resize automatically)

The `TermList` list all the active terminal buffer listing:
- Its buffer index
- Its name (the working directory of the terminal at its creation)

The `TermGo` activate or create a terminal buffer.

A terminal buffer can be identified by:
- A name (the working directory of the terminal at its creation)
- The buffer index

## Mappings

The plugin introduces the following mapping:
- `<Plug>(TermToggle)` that toggle on/off the terminal window.

## Requirements

Tested on Vim >= 8.2 and Neovim >= 0.8.3


## Installation

For [vim-plug](https://github.com/junegunn/vim-plug) users:
```vim
Plug 'vds2212/vim-term'
```

## Similar Projects

[neoterm](https://github.com/kassio/neoterm)

