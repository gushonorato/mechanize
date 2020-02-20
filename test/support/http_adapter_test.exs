defmodule Mechanizex.HTTPAdapterTest do
  defmacro __using__(options) do
    quote do
      use ExUnit.Case, async: true
      import Mechanizex.HTTPAdapterTest

      setup do
        {:ok, bypass: Bypass.open()}
      end

      @moduletag unquote(options)

      test_http_methods(unquote(options[:methods]))
    end
  end

  defp method_name(method) do
    method
    |> Atom.to_string()
    |> String.upcase()
  end

  def endpoint_url(port), do: "http://localhost:#{port}/fake_path"

  defmacro test_http_methods(methods) do
    methods
    |> Enum.reject(&(&1 == :head))
    |> Enum.map(&gen_test(method_name(&1), &1))
  end

  defp gen_test(method_name, method) do
    alias Mechanizex.Request

    quote do
      test "simple #{unquote(method_name)}", %{bypass: bypass, adapter: adapter} do
        Bypass.expect(bypass, fn conn ->
          assert conn.method == unquote(method_name)
          assert conn.request_path == "/fake_path"
          Plug.Conn.resp(conn, 200, "Lero")
        end)

        res = adapter.request!(%Request{method: unquote(method), url: endpoint_url(bypass.port)})

        assert res.code == 200

        case unquote(:method) do
          :head -> assert res.body == ""
          _ -> assert res.body == "Lero"
        end
      end

      test "simple #{unquote(method_name)} with error", %{bypass: bypass, adapter: adapter} do
        Bypass.down(bypass)

        assert_raise Mechanizex.HTTPAdapter.NetworkError, ~r/connection refused/i, fn ->
          adapter.request!(%Request{method: unquote(method), url: endpoint_url(bypass.port)})
        end
      end

      test "request params using #{unquote(method_name)}", %{bypass: bypass, adapter: adapter} do
        Bypass.expect(bypass, fn conn ->
          assert conn.query_string == "query=%C3%A1rvore+pau+brasil&page=1"
          Plug.Conn.resp(conn, 200, "Lero")
        end)

        adapter.request!(%Request{
          method: unquote(method),
          url: endpoint_url(bypass.port),
          params: [{"query", "árvore pau brasil"}, {"page", "1"}]
        })
      end

      test "request headers using #{unquote(method_name)}", %{bypass: bypass, adapter: adapter} do
        Bypass.expect(bypass, fn conn ->
          assert [{_, "text/html"}] = Enum.filter(conn.req_headers, fn {k, _} -> k =~ ~r/content-type/i end)

          assert [{_, "Gustabot"}] = Enum.filter(conn.req_headers, fn {k, _} -> k =~ ~r/user-agent/i end)

          Plug.Conn.resp(conn, 200, "Lero")
        end)

        adapter.request!(%Request{
          method: unquote(method),
          url: endpoint_url(bypass.port),
          headers: [{"User-Agent", "Gustabot"}, {"content-type", "text/html"}]
        })
      end

      test "handle received headers using #{unquote(method_name)}", %{bypass: bypass, adapter: adapter} do
        Bypass.expect(bypass, fn conn ->
          conn
          |> Plug.Conn.resp(301, "Lero")
          |> Plug.Conn.put_resp_header("Location", "https://www.seomaster.com.br")
        end)

        res = adapter.request!(%Request{method: unquote(method), url: endpoint_url(bypass.port)})

        assert [{_, "https://www.seomaster.com.br"}] = Enum.filter(res.headers, fn {k, _} -> k =~ ~r/location/i end)
      end
    end
  end
end
