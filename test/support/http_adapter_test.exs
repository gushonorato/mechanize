defmodule Mechanizex.HTTPAdapterTest do
  defmacro __using__(options) do
    quote do
      use ExUnit.Case, async: true
      import Mechanizex.HTTPAdapterTest

      setup do
        {:ok, bypass: Bypass.open(), agent: Mechanizex.Agent.new()}
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
    alias Mechanizex.{Request, Page}

    quote do
      test "simple #{unquote(method_name)}", %{bypass: bypass, agent: agent, adapter: adapter} do
        Bypass.expect(bypass, fn conn ->
          assert conn.method == unquote(method_name)
          assert conn.request_path == "/fake_path"
          Plug.Conn.resp(conn, 200, "Lero")
        end)

        {:ok, page} =
          adapter.request(agent, %Request{method: unquote(method), url: endpoint_url(bypass.port)})

        assert Page.response_code(page) == 200

        case unquote(:method) do
          :head -> assert Page.body(page) == ""
          _ -> assert Page.body(page) == "Lero"
        end
      end

      test "simple #{unquote(method_name)} with error", %{
        bypass: bypass,
        agent: agent,
        adapter: adapter
      } do
        Bypass.down(bypass)

        {:error, error} =
          adapter.request(agent, %Request{method: unquote(method), url: endpoint_url(bypass.port)})

        assert error.message =~ ~r/connection refused/i
      end

      test "retrieve request from page using #{unquote(method_name)}", %{
        bypass: bypass,
        agent: agent,
        adapter: adapter
      } do
        Bypass.expect(bypass, fn conn -> Plug.Conn.resp(conn, 200, "Lero") end)
        req = %Request{method: unquote(method), url: endpoint_url(bypass.port)}

        {:ok, page} = adapter.request(agent, req)

        assert page.request == req
      end

      test "request params using #{unquote(method_name)}", %{
        bypass: bypass,
        agent: agent,
        adapter: adapter
      } do
        Bypass.expect(bypass, fn conn ->
          assert conn.query_string == "query=%C3%A1rvore+pau+brasil&page=1"
          Plug.Conn.resp(conn, 200, "Lero")
        end)

        {:ok, _} =
          adapter.request(agent, %Request{
            method: unquote(method),
            url: endpoint_url(bypass.port),
            params: [{"query", "árvore pau brasil"}, {"page", "1"}]
          })
      end

      test "request headers using #{unquote(method_name)}", %{
        bypass: bypass,
        agent: agent,
        adapter: adapter
      } do
        Bypass.expect(bypass, fn conn ->
          assert [{_, "text/html"}] =
                   Enum.filter(conn.req_headers, fn {k, _} -> k =~ ~r/content-type/i end)

          assert [{_, "Gustabot"}] =
                   Enum.filter(conn.req_headers, fn {k, _} -> k =~ ~r/user-agent/i end)

          Plug.Conn.resp(conn, 200, "Lero")
        end)

        {:ok, _} =
          adapter.request(agent, %Request{
            method: unquote(method),
            url: endpoint_url(bypass.port),
            headers: [{"User-Agent", "Gustabot"}, {"content-type", "text/html"}]
          })
      end

      test "handle received headers using #{unquote(method_name)}", %{
        bypass: bypass,
        agent: agent,
        adapter: adapter
      } do
        Bypass.expect(bypass, fn conn ->
          conn
          |> Plug.Conn.resp(301, "Lero")
          |> Plug.Conn.put_resp_header("Location", "https://www.seomaster.com.br")
        end)

        {:ok, page} =
          adapter.request(agent, %Request{method: unquote(method), url: endpoint_url(bypass.port)})

        assert [{_, "https://www.seomaster.com.br"}] =
                 Enum.filter(page.response.headers, fn {k, _} -> k =~ ~r/location/i end)
      end
    end
  end
end
