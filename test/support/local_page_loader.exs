defmodule Mechanizex.Test.Support.LocalPageLoader do
  alias Mechanizex.{Request, Response, Page, Browser}

  def get(browser, url) do
    %Page{
      response: %Response{
        body: read_html_file(url),
        headers: [],
        code: 200,
        url: url
      },
      request: %Request{
        method: :get,
        url: url
      },
      browser: browser,
      parser: Browser.html_parser(browser)
    }
  end

  defp read_html_file(url) do
    url
    |> String.replace_prefix("https://htdocs.local/", "")
    |> File.read()
    |> elem(1)
  end
end
