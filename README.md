# Mechanizex ![Build Status](https://travis-ci.org/gushonorato/mechanizex.svg?branch=master)

Build web scrapers and automate interaction with websites in Elixir with ease! One of Mechanizex's main design goals is to enable developers to easily create concurrent web scrapers without imposing any process architecture. Mechanizex is heavily inspired on [Ruby](https://github.com/sparklemotion/mechanize) version of [Mechanize](https://metacpan.org/release/WWW-Mechanize). It features:

- Follow links
- Populate and submit forms
- Scrape data easily using CSS selectors
- Automatically stores and sends cookies
- Follow redirects and meta http-equiv="refresh"
- Track of the sites that you have visited as a history
- Proxy support
- File upload
- Obey robots.txt

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
