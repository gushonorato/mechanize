defmodule Mechanizex.AgentTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{HTTPAdapter, Request, Response, Page}
  import Mox
  doctest Mechanizex.Agent

  setup do
    {:ok, agent: start_supervised!({Mechanizex.Agent, http_adapter: :mock})}
  end

  setup_all do
    {:ok, default_ua: Mechanizex.Agent.user_agent_string!(:mechanizex)}
  end

  describe ".new" do
    test "start a process", %{agent: agent} do
      assert is_pid(agent)
    end
  end

  describe ".start_link" do
    test "start a process" do
      {:ok, agent} = Mechanizex.Agent.start_link()
      assert is_pid(agent)
    end

    test "start a different agent on each call" do
      {:ok, agent1} = Mechanizex.Agent.start_link()
      {:ok, agent2} = Mechanizex.Agent.start_link()

      refute agent1 == agent2
    end
  end

  describe "initial headers config" do
    test "load headers from mix config", %{agent: agent, default_ua: ua} do
      assert Mechanizex.Agent.http_headers(agent) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua}
             ]
    end

    test "init parameters overrides mix config", %{default_ua: ua} do
      agent = Mechanizex.Agent.new(http_headers: [{"custom-header", "value"}])

      assert Mechanizex.Agent.http_headers(agent) == [
               {"custom-header", "value"},
               {"user-agent", ua}
             ]
    end

    test "ensure headers are always in downcase", %{default_ua: ua} do
      agent = Mechanizex.Agent.new(http_headers: [{"Custom-Header", "value"}])

      assert Mechanizex.Agent.http_headers(agent) == [
               {"custom-header", "value"},
               {"user-agent", ua}
             ]
    end
  end

  describe ".set_http_headers" do
    test "set all headers at once", %{agent: agent} do
      Mechanizex.Agent.set_http_headers(agent, [{"content-type", "text/html"}])
      assert Mechanizex.Agent.http_headers(agent) == [{"content-type", "text/html"}]
    end

    test "ensure all headers are in lowercase", %{agent: agent} do
      Mechanizex.Agent.set_http_headers(agent, [
        {"Content-Type", "text/html"},
        {"Custom-Header", "Lero"}
      ])

      assert Mechanizex.Agent.http_headers(agent) == [
               {"content-type", "text/html"},
               {"custom-header", "Lero"}
             ]
    end
  end

  describe ".put_http_header" do
    test "updates existent header", %{agent: agent} do
      Mechanizex.Agent.put_http_header(agent, "user-agent", "Lero")

      assert Mechanizex.Agent.http_headers(agent) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", "Lero"}
             ]
    end

    test "add new header if doesnt'", %{agent: agent, default_ua: ua} do
      Mechanizex.Agent.put_http_header(agent, "content-type", "text/html")

      assert Mechanizex.Agent.http_headers(agent) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua},
               {"content-type", "text/html"}
             ]
    end

    test "ensure inserted header is lowecase", %{agent: agent, default_ua: ua} do
      Mechanizex.Agent.put_http_header(agent, "Content-Type", "text/html")

      assert Mechanizex.Agent.http_headers(agent) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua},
               {"content-type", "text/html"}
             ]
    end
  end

  describe ".http_header" do
    test "default user agent" do
    end
  end

  describe ".set_user_agent_alias" do
    test "set by alias", %{agent: agent} do
      Mechanizex.Agent.set_user_agent_alias(agent, :windows_chrome)

      assert Mechanizex.Agent.http_headers(agent) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", Mechanizex.Agent.user_agent_string!(:windows_chrome)}
             ]
    end

    test "set on init" do
      agent = Mechanizex.Agent.new(user_agent_alias: :windows_chrome)

      assert Mechanizex.Agent.http_headers(agent) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", Mechanizex.Agent.user_agent_string!(:windows_chrome)}
             ]
    end

    test "raise error when invalid alias passed", %{agent: agent} do
      assert_raise Mechanizex.Agent.InvalidUserAgentAlias, fn ->
        Mechanizex.Agent.set_user_agent_alias(agent, :windows_chrom)
      end
    end
  end

  describe ".http_adapter" do
    test "configure on init" do
      {:ok, agent} = Mechanizex.Agent.start_link(http_adapter: :custom)
      assert Mechanizex.Agent.http_adapter(agent) == Mechanizex.HTTPAdapter.Custom
    end

    test "default http adapter" do
      agent = Mechanizex.Agent.new()
      assert Mechanizex.Agent.http_adapter(agent) == HTTPAdapter.Httpoison
    end
  end

  describe ".set_http_adapter" do
    test "returns agent", %{agent: agent} do
      assert Mechanizex.Agent.set_http_adapter(agent, Mechanizex.HTTPAdapter.Custom) == agent
    end

    test "updates http adapter", %{agent: agent} do
      Mechanizex.Agent.set_http_adapter(agent, Mechanizex.HTTPAdapter.Custom)
      assert Mechanizex.Agent.http_adapter(agent) == Mechanizex.HTTPAdapter.Custom
    end
  end

  describe ".set_html_parser" do
    test "returns mechanizex agent", %{agent: agent} do
      assert Mechanizex.Agent.set_html_parser(agent, Mechanizex.HTMLParser.Custom) == agent
    end

    test "updates html parser", %{agent: agent} do
      Mechanizex.Agent.set_html_parser(agent, Mechanizex.HTMLParser.Custom)
      assert Mechanizex.Agent.html_parser(agent) == Mechanizex.HTMLParser.Custom
    end

    test "html parser option" do
      {:ok, agent} = Mechanizex.Agent.start_link(html_parser: :custom)
      assert Mechanizex.Agent.html_parser(agent) == Mechanizex.HTMLParser.Custom
    end
  end

  describe ".request!" do
    test "add agent's default http headers on request", %{agent: agent, default_ua: ua} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :get,
                               url: "https://www.seomaster.com.br",
                               headers: [
                                 {"custom-header", "lero"},
                                 {"foo", "bar"},
                                 {"user-agent", ^ua}
                               ]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      Mechanizex.Agent.request!(agent, %Request{
        method: :get,
        url: "https://www.seomaster.com.br",
        headers: [{"custom-header", "lero"}]
      })
    end

    test "ignore case on update default http header", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :get,
                               url: "https://www.seomaster.com.br",
                               headers: [
                                 {"custom-header", "lero"},
                                 {"user-agent", "Gustabot"},
                                 {"foo", "bar"}
                               ]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      Mechanizex.Agent.request!(agent, %Request{
        method: :get,
        url: "https://www.seomaster.com.br",
        headers: [{"custom-header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "ensure downcase of request headers", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :get,
                               url: "https://www.seomaster.com.br",
                               headers: [
                                 {"custom-header", "lero"},
                                 {"user-agent", "Gustabot"},
                                 {"foo", "bar"}
                               ]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      Mechanizex.Agent.request!(agent, %Request{
        method: :get,
        url: "https://www.seomaster.com.br",
        headers: [{"Custom-Header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "send request parameters", %{agent: agent, default_ua: ua} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :get,
                               url: "https://www.seomaster.com.br",
                               params: [
                                 {"query", "lero"},
                                 {"start", "100"}
                               ],
                               headers: [
                                 {"foo", "bar"},
                                 {"user-agent", ^ua}
                               ]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      Mechanizex.Agent.request!(agent, %Request{
        method: :get,
        url: "https://www.seomaster.com.br",
        params: [{"query", "lero"}, {"start", "100"}]
      })
    end

    test "ensure downcase of response headers", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, req ->
        {:ok,
         %Page{
           agent: agent,
           request: req,
           response: %Response{
             body: [],
             headers: [
               {"Custom-Header", "lero"},
               {"User-Agent", "Gustabot"},
               {"FOO", "BAR"}
             ],
             code: 200,
             url: "https://www.seomaster.com.br"
           }
         }}
      end)

      page =
        Mechanizex.Agent.request!(agent, %Request{
          method: :get,
          url: "https://www.seomaster.com.br",
          headers: [{"Custom-Header", "lero"}, {"User-Agent", "Gustabot"}]
        })

      assert page.response.headers == [
               {"custom-header", "lero"},
               {"user-agent", "Gustabot"},
               {"foo", "BAR"}
             ]
    end
  end
end
