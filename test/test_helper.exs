ExUnit.start()
Application.ensure_all_started(:bypass)

{:ok, files} = File.ls("./test/support")

files
|> Enum.filter(&String.ends_with?(&1, [".ex", ".exs"]))
|> Enum.each(&Code.require_file("support/#{&1}", __DIR__))

import Mox

defmock(Mechanize.HTMLParser.Custom, for: Mechanize.HTMLParser)
defmock(Mechanize.HTTPAdapter.Mock, for: Mechanize.HTTPAdapter)

defmodule TestHelper do
  def stub_requests(local_path) do
    bypass = Bypass.open()
    browser = Mechanize.Browser.new()

    Bypass.expect_once(bypass, "GET", local_path, fn conn ->
      "/" <> file_path = conn.request_path
      Plug.Conn.resp(conn, 200, File.read!(file_path))
    end)

    page =
      Mechanize.Browser.get!(
        browser,
        endpoint_url(bypass, local_path)
      )

    {:ok, %{bypass: bypass, browser: browser, page: page}}
  end

  def test_http_delegates(function_names, func) do
    function_names
    |> Enum.map(fn function_name ->
      http_method =
        function_name
        |> Atom.to_string()
        |> String.replace("!", "")
        |> String.upcase()

      {function_name, http_method}
    end)
    |> Enum.each(func)
  end

  def endpoint_url(bypass, path \\ ""), do: URI.merge("http://localhost:#{bypass.port}/", path) |> URI.to_string()

  def read_file!(path, map \\ []) do
    contents = File.read!(path)

    Enum.reduce(map, contents, fn {k, v}, acc ->
      String.replace(acc, "\#\{#{Atom.to_string(k)}\}", v)
    end)
  end
end
