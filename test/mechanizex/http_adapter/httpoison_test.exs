defmodule Mechanizex.HTTPAdapter.HTTPoisonTest do
  use ExUnit.Case, async: true
  alias Mechanizex.HTTPAdapter.Httpoison, as: Adapter
  alias Mechanizex.{Request, Page}

  setup do
    {:ok, bypass: Bypass.open(), agent: Mechanizex.Agent.new()}
  end

  test "simple GET", %{bypass: bypass, agent: agent} do
    Bypass.expect(bypass, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/fake_path"
      Plug.Conn.resp(conn, 200, "Lero")
    end)

    {:ok, page} = Adapter.request(agent, %Request{method: :get, url: endpoint_url(bypass.port)})

    assert Page.response_code(page) == 200
    assert Page.body(page) == "Lero"
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/fake_path"
end
