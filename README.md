# Mechanizex [![Build Status](https://travis-ci.org/gushonorato/mechanizex.svg?branch=master)](https://travis-ci.org/gushonorato/mechanizex) [![Coverage Status](https://coveralls.io/repos/github/gushonorato/mechanizex/badge.svg?branch=master)](https://coveralls.io/github/gushonorato/mechanizex?branch=master)

Build web scrapers and automate interaction with websites in Elixir with ease! One of Mechanizex's main design goals is to enable developers to easily create concurrent web scrapers without imposing any process architecture. Mechanizex is heavily inspired on [Ruby](https://github.com/sparklemotion/mechanize) version of [Mechanize](https://metacpan.org/release/WWW-Mechanize). It features:

- Follow hyperlinks
- Scrape data easily using CSS selectors
- Populate and submit forms (WIP)
- Automatically stores and sends cookies (TODO)
- Follow redirects and meta http-equiv="refresh" (TODO)
- Track of the sites that you have visited as a history (TODO)
- Proxy support (TODO)
- File upload (TODO)
- Obey robots.txt (TODO)

## Installation

> **Warning:** This library is in active development and probably will have changes in the public API. It is not currently recommended to use it on production systems.

The package can be installed by adding `mechanizex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mechanizex, github: "gushonorato/mechanizex"}
  ]
end
```

## Authors
Copyright © 2019 by Gustavo Honorato (gustavohonorato@gmail.com)

## License
This library is distributed under the MIT license. Please see the LICENSE file.
