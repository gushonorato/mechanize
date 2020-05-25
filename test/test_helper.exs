ExUnit.start()
Application.ensure_all_started(:bypass)

{:ok, files} = File.ls("./test/support")

files
|> Enum.filter(&String.ends_with?(&1, [".ex", ".exs"]))
|> Enum.each(&Code.require_file("support/#{&1}", __DIR__))

import Mox

defmock(Mechanizex.HTMLParser.Custom, for: Mechanizex.HTMLParser)
defmock(Mechanizex.HTTPAdapter.Mock, for: Mechanizex.HTTPAdapter)

defmodule TestHelper do
  def stub_requests(local_path) do
    bypass = Bypass.open()
    browser = Mechanizex.Browser.new()

    Bypass.expect_once(bypass, "GET", local_path, fn conn ->
      "/" <> file_path = conn.request_path
      Plug.Conn.resp(conn, 200, File.read!(file_path))
    end)

    page =
      Mechanizex.Browser.get!(
        browser,
        endpoint_url(bypass, local_path)
      )

    {:ok, %{bypass: bypass, browser: browser, page: page}}
  end

  def endpoint_url(bypass, path \\ ""), do: URI.merge("http://localhost:#{bypass.port}/", path) |> URI.to_string()

  def read_file!(path, map \\ []) do
    contents = File.read!(path)

    Enum.reduce(map, contents, fn {k, v}, acc ->
      String.replace(acc, "\#\{#{Atom.to_string(k)}\}", v)
    end)
  end
end
