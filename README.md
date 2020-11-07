# Mechanize [![Build Status](https://travis-ci.org/gushonorato/mechanize.svg?branch=master)](https://travis-ci.org/gushonorato/mechanize) [![Coverage Status](https://coveralls.io/repos/github/gushonorato/mechanize/badge.svg?branch=master)](https://coveralls.io/github/gushonorato/mechanize?branch=master)

Build web scrapers and automate interaction with websites in Elixir with ease!

One of Mechanize's main design goals is to enable developers to easily create concurrent web scrapers without the computing cost of using headless browsers. Mechanize is heavily inspired on [Ruby](https://github.com/sparklemotion/mechanize) version of [Mechanize](https://metacpan.org/release/WWW-Mechanize). It features:

- Follow hyperlinks
- Scrape data easily using CSS selectors
- Populate and submit forms
- Follow and tracks 3xx redirects
- Follow meta-refresh
- Automatically stores and sends cookies (TODO)
- Proxy support (TODO)
- Track of the sites that you have visited as a history (TODO)
- File upload (TODO)
- Obey robots.txt (TODO)

## Installation

> **Warning:** This library is in active development and probably will have changes in the public API. Use it carefully in production systems.

The package can be installed by adding `mechanize` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mechanize, "~> 0.1"}
  ]
end
```

## Getting started

This guide will teach you how to do the most basic tasks using Mechanize like fetch pages, click links, fill out and submit
forms and scrape data.

### Fetching a page

First you'll have to start Mechanize:

```elixir
alias Mechanize.Browser

browser = Browser.new()
```

Or using a more verbose alternative:

```elixir
{:ok, browser} = Browser.start_link()
```

Now we'll use the browser we've started to fetch a page.  Let's fetch Google
with our mechanize browser:

```elixir
page = Browser.get!(browser, "https://www.google.com")
```

What just happened?  We told mechanize to go pick up Google's main page.
Mechanize followed any redirects that Google may have sent. The browser gave us back a page that we can use to scrape data, find links to click, or find forms to fill out.

Next, let's try finding some links to click.

### Finding Links

Mechanize returns a page struct whenever you get a page, post, or submit a
form. Now that we've fetched Google's homepage, let's try listing all of the links:

```elixir
alias Mechanize.Page
alias Mechanize.Page.Element

page
|> Page.links()
|> Enum.each(fn link ->
  IO.puts Element.text(link)
end)
```

We can list the links, but Mechanize gives a few shortcuts to help us find a
link to click on.  Let's say we wanted to click the link whose text is 'News'. Normally, we would have to do this:

```elixir
alias Mechanize.Page
alias Mechanize.Page.Element
alias Mechanize.Page.Link

page
|> Page.links()
|> Enum.filter(fn link -> Element.text(link) == "News" end)
|> List.first()
|> Link.click!()
```

But Mechanize gives us a shortcut.  Instead we can do this:

```elixir
alias Mechanize.Page
alias Mechanize.Page.Link

page
|> Page.link_with(text: "News")
|> Link.click!()
```

Or even shorter, with just one line:

```elixir
alias Mechanize.Page

Page.click_link!(page, text: "News")
```

You're probably thinking "there could be multiple links with that text!", and you would be correct!  If you use the plural form, you can access the list. If you wanted to click on the second news link, you could do this:

```elixir
alias Mechanize.Page

  page
  |> Page.links_with(text: "News")
  |> Enum.at(1)
```

We can even find a link matching its href with some regular expression:

```elixir
alias Mechanize.Page

Page.link_with(page, href: ~r/something/)
```

Or chain them together to find a link with certain text and certain href:

```elixir
alias Mechanize.Page

Page.link_with(page, text: 'News', href: "/news")
```

Now that we know how to find and click links, let's try something more complicated like filling out a form.

### Filling out forms

Let's continue with our Google example.

If we look at the html of the page, we can see that there is one form named 'f', that has a couple buttons and a few fields. You can see this by saving the page in a file and opening it in your favorite text editor.

```elixir
File.write!("google.html", page)
```

Now that we know the name of the form, let's fetch it off the page:

```elixir
form = Page.form_with(name: "f")
```

So let's set the form field named 'q' on the form to 'elixir mechanize':

```elixir
Form.fill_text(form, name: "q", with: keyword)
```

Now we can submit the form and 'press' the submit button and print the results:

```elixir
Form.click_button!(form, text: "Google Search")
```

What we just did was equivalent to putting text in the search field and
clicking the 'Google Search' button.

Another way to do that is typing in the text field and hitting the return button. We can also simulate that by using `submit` function instead of `click_button`:

```elixir
Form.submit!(form)
```

Let's take a look at the code all together:

```elixir
alias Mechanize.{Browser, Page, Form}

b = Browser.new(follow_meta_refresh: true)
    |> Browser.put_user_agent(:mac_safari)

b
|> Browser.get!("https://www.google.com")
|> Page.form_with(name: "f")
|> Form.fill_text(name: "q", with: "elixir mechanize")
|> Form.submit!() # or Form.click_button!(form, text: "Google Search")
```

Before we go on to screen scraping, let's take a look at forms a little more
in depth.  Unless you want to skip ahead!

### Advanced Form techniques

In this section, I want to touch on using the different types in input fields
possible with a form.  Password and textarea fields can be treated just like
text input fields.  Select fields are very similar to text fields, but they
have many options associated with them.  If you select one option, mechanize
will de-select the other options (unless it is a multi select!).

For example, let's select an `option` with text "Option 1" on a `select` with `name="select1"`.

```elixir
Form.select(form, name: "select1", option: "Option 1")
```

We can also select an `option` by an attribute, in this case we'll select by `value` attribute:

```elixir
Form.select(form, name: "select1", option: [value: "1"])
```

Or select the third option of a `select` (note that Mechanize uses a zero-based index):

```elixir
Form.select(form, name: "select1", option: 2)
```

Now let's take a look at `checkboxes` and `radio buttons`.  To select a `checkbox`, just check it like this:

```elixir
Form.check_checkbox(form, name: "box", value: "yes")
```

`Radio buttons` are very similar to `checkboxes`, but they know how to uncheck other `radio buttons` of the same name. Just check a `radio button` like you would a `checkbox`:

```elixir
Form.check_radio_button(form, name: "box", value: "yes")
```

### Scraping Data

After you have used Mechanize to navigate to the page that you need to scrape, then scrape it using `Page.search/2` function:

```elixir
browser
|> Browser.get!('http://example.com/')
|> Page.search("p.posted")
```

## Example

### Google (Print results from SERP)

```elixir
alias Mechanize.{Browser, Page, Form}
alias Mechanize.Page.Element

b =
  Browser.new(follow_meta_refresh: true)
  |> Browser.put_user_agent(:mac_safari)

initial_page = Browser.get!(b, "https://google.com")

serp =
  initial_page
  |> Page.form_with(name: "f")
  |> Form.fill_text(name: "q", with: keyword)
  |> Form.submit!()

serp
|> Page.search(".kCrYT > a .vvjwJb") # Selects each search result element
|> Enum.map(&Element.text/1) # Extracts search result title text
|> Enum.with_index(1)
|> Enum.each(fn {result, index} -> IO.puts("#{index}. #{result}") end)
```

## Author
Copyright © 2020 by Gustavo Honorato (gustavohonorato@gmail.com)

## License
This library is distributed under the MIT license. Please see the LICENSE file.
