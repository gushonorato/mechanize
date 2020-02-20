defmodule Mechanizex.Browser.HTTPShortcutsTest do
  alias Mechanizex.{Browser, Page}
  import TestHelper

  defmacro __using__(_) do
    [:get, :delete, :options, :patch, :post, :put, :head]
    |> Enum.map(fn method ->
      quote do
        test "#{unquote(method)}! delegate to request", %{bypass: bypass, browser: browser} do
          Bypass.down(bypass)

          assert_raise Mechanizex.HTTPAdapter.NetworkError, fn ->
            apply(Browser, unquote(:"#{method}!"), [
              browser,
              endpoint_url(bypass),
              [{"lero", "lero"}],
              [{"accept", "lero"}]
            ])
          end
        end
      end
    end)
  end
end

defmodule Mechanizex.BrowserTest do
  use ExUnit.Case, async: true
  use Mechanizex.Browser.HTTPShortcutsTest
  alias Mechanizex.{HTTPAdapter, Request, Page, Browser}
  import TestHelper
  doctest Mechanizex.Browser

  setup do
    {:ok, %{bypass: Bypass.open(), browser: Browser.new()}}
  end

  setup_all do
    {:ok, default_ua: Browser.user_agent_string(:mechanizex)}
  end

  describe ".new" do
    test "start a process", %{browser: browser} do
      assert is_pid(browser)
    end

    test "redirects are followed by default", %{browser: browser} do
      assert Browser.follow_redirect?(browser) == true
    end

    test "change defaul follow redirect option" do
      browser = Browser.new(follow_redirect: false)
      assert Browser.follow_redirect?(browser) == false
    end

    test "default max redirect loop is 5", %{browser: browser} do
      assert Browser.max_redirect(browser) == 5
    end

    test "change max redirect loop option" do
      browser = Browser.new(max_redirect: 10)
      assert Browser.max_redirect(browser) == 10
    end

    test "load headers from mix config", %{browser: browser, default_ua: ua} do
      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua}
             ]
    end

    test "init parameters overrides mix config", %{default_ua: ua} do
      browser = Browser.new(http_headers: [{"custom-header", "value"}])

      assert Browser.http_headers(browser) == [
               {"custom-header", "value"},
               {"user-agent", ua}
             ]
    end

    test "ensure headers are always in downcase", %{default_ua: ua} do
      browser = Browser.new(http_headers: [{"Custom-Header", "value"}])

      assert Browser.http_headers(browser) == [
               {"custom-header", "value"},
               {"user-agent", ua}
             ]
    end

    test "configure user agent" do
      browser = Browser.new(user_agent_alias: :windows_chrome)

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", Browser.user_agent_string(:windows_chrome)}
             ]
    end

    test "configure http adapter" do
      browser = Browser.new(http_adapter: :custom)
      assert Browser.http_adapter(browser) == Mechanizex.HTTPAdapter.Custom
    end

    test "default http adapter" do
      browser = Browser.new()
      assert Browser.http_adapter(browser) == HTTPAdapter.Httpoison
    end
  end

  describe ".start_link" do
    test "start a process" do
      {:ok, browser} = Mechanizex.Browser.start_link()
      assert is_pid(browser)
    end

    test "start a different browser on each call" do
      {:ok, browser1} = Browser.start_link()
      {:ok, browser2} = Browser.start_link()

      refute browser1 == browser2
    end
  end

  describe ".put_http_headers" do
    test "set all headers at once", %{browser: browser} do
      Browser.put_http_headers(browser, [{"content-type", "text/html"}])
      assert Browser.http_headers(browser) == [{"content-type", "text/html"}]
    end

    test "ensure all headers are in lowercase", %{browser: browser} do
      Browser.put_http_headers(browser, [
        {"Content-Type", "text/html"},
        {"Custom-Header", "Lero"}
      ])

      assert Browser.http_headers(browser) == [
               {"content-type", "text/html"},
               {"custom-header", "Lero"}
             ]
    end
  end

  describe ".put_http_header" do
    test "updates existent header", %{browser: browser} do
      Browser.put_http_header(browser, "user-agent", "Lero")

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", "Lero"}
             ]
    end

    test "add new header if doesnt'", %{browser: browser, default_ua: ua} do
      Browser.put_http_header(browser, "content-type", "text/html")

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua},
               {"content-type", "text/html"}
             ]
    end

    test "ensure inserted header is lowecase", %{browser: browser, default_ua: ua} do
      Browser.put_http_header(browser, "Content-Type", "text/html")

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua},
               {"content-type", "text/html"}
             ]
    end
  end

  describe ".put_user_agent_alias" do
    test "set by alias", %{browser: browser} do
      Browser.put_user_agent_alias(browser, :windows_chrome)

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", Browser.user_agent_string(:windows_chrome)}
             ]
    end

    test "raise error when invalid alias passed", %{browser: browser} do
      assert_raise ArgumentError, ~r/Invalid user agent/, fn ->
        Browser.put_user_agent_alias(browser, :lero)
      end
    end
  end

  describe ".put_http_adapter" do
    test "returns browser", %{browser: browser} do
      assert Browser.put_http_adapter(browser, Mechanizex.HTTPAdapter.Custom) == browser
    end

    test "updates http adapter", %{browser: browser} do
      Browser.put_http_adapter(browser, Mechanizex.HTTPAdapter.Custom)
      assert Browser.http_adapter(browser) == Mechanizex.HTTPAdapter.Custom
    end
  end

  describe ".put_html_parser" do
    test "returns mechanizex browser", %{browser: browser} do
      assert Browser.put_html_parser(browser, Mechanizex.HTMLParser.Custom) == browser
    end

    test "updates html parser", %{browser: browser} do
      Browser.put_html_parser(browser, Mechanizex.HTMLParser.Custom)
      assert Browser.html_parser(browser) == Mechanizex.HTMLParser.Custom
    end

    test "html parser option" do
      browser = Browser.new(html_parser: :custom)
      assert Browser.html_parser(browser) == Mechanizex.HTMLParser.Custom
    end
  end

  describe ".update_follow_redirect" do
    test "update browser follow redirect to true and false", %{browser: browser} do
      assert Browser.follow_redirect?(browser) == true

      Browser.update_follow_redirect(browser, false)
      assert Browser.follow_redirect?(browser) == false

      Browser.update_follow_redirect(browser, true)
      assert Browser.follow_redirect?(browser) == true
    end
  end

  describe ".enable_follow_redirect" do
    test "update browser options to follow redirects", %{browser: browser} do
      browser
      |> Browser.update_follow_redirect(false)
      |> Browser.enable_follow_redirect()

      assert Browser.follow_redirect?(browser) == true
    end
  end

  describe ".disable_follow_redirect" do
    test "update browser options to not follow redirects", %{browser: browser} do
      browser
      |> Browser.update_follow_redirect(true)
      |> Browser.disable_follow_redirect()

      assert Browser.follow_redirect?(browser) == false
    end
  end

  describe ".request!" do
    test "get request content", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, "GET", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "OK PAGE")
      end)

      page =
        Browser.request!(browser, %Request{
          method: :get,
          url: endpoint_url(bypass)
        })

      assert Page.body(page) == "OK PAGE"
    end

    test "send correct methods", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, "GET", "/", fn conn ->
        assert conn.method == "GET"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass)
      })

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        assert conn.method == "POST"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :post,
        url: endpoint_url(bypass)
      })
    end

    test "merge header with browser's default headers", %{bypass: bypass, browser: browser, default_ua: ua} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.req_headers == [
                 {"custom-header", "lero"},
                 # the header "foo" comes from config/test.exs
                 {"foo", "bar"},
                 {"host", "localhost:#{bypass.port}"},
                 {"user-agent", ua}
               ]

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        headers: [{"custom-header", "lero"}]
      })
    end

    test "ignore case on update default http header", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.req_headers == [
                 {"custom-header", "lero"},
                 # the header "foo" comes from config/test.exs
                 {"foo", "bar"},
                 {"host", "localhost:#{bypass.port}"},
                 {"user-agent", "Gustabot"}
               ]

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        headers: [{"custom-header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "ensure downcase of request headers", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.req_headers == [
                 {"custom-header", "lero"},
                 # the header "foo" comes from config/test.exs
                 {"foo", "bar"},
                 {"host", "localhost:#{bypass.port}"},
                 {"user-agent", "Gustabot"}
               ]

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        headers: [{"Custom-Header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "send request parameters", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, fn conn ->
        assert Plug.Conn.fetch_query_params(conn).params == %{
                 "query" => "lero",
                 "start" => "100"
               }

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        params: [{"query", "lero"}, {"start", "100"}]
      })
    end

    test "ensure downcase of response headers", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, fn conn ->
        conn
        |> Plug.Conn.merge_resp_headers([{"Custom-Header", "lero"}, {"FOO", "BAR"}])
        |> Plug.Conn.resp(200, "OK")
      end)

      page =
        Browser.request!(browser, %Request{
          method: :get,
          url: endpoint_url(bypass)
        })

      assert [{"custom-header", "lero"}, {"foo", "BAR"} | _] = page.response.headers
    end

    test "raise error when connection fail", %{bypass: bypass, browser: browser} do
      Bypass.down(bypass)

      assert_raise Mechanizex.HTTPAdapter.NetworkError, fn ->
        Browser.request!(browser, %Request{
          method: :get,
          url: endpoint_url(bypass)
        })
      end
    end

    test "follow simple redirect", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, "GET", "/redirect_to", fn conn ->
        redirect_location =
          bypass
          |> endpoint_url("/redirected")
          |> URI.to_string()

        conn
        |> Plug.Conn.merge_resp_headers([{"Location", redirect_location}])
        |> Plug.Conn.resp(301, "")
      end)

      Bypass.expect_once(bypass, "GET", "/redirected", fn conn ->
        Plug.Conn.resp(conn, 200, "REDIRECT OK")
      end)

      req = %Request{
        method: :get,
        url: endpoint_url(bypass, "/redirect_to")
      }

      page = Browser.request!(browser, req)

      assert Page.response_code(page) == 200
      assert Page.body(page) == "REDIRECT OK"
    end

    @tag :skip
    test "disable redirects"
      end)

      Bypass.expect_once(bypass, "GET", "/redirected", fn conn ->
        Plug.Conn.resp(conn, 200, "REDIRECT OK")
      end)

      Browser.disable_follow_redirect(browser)
      page = Browser.get!(browser, endpoint_url(bypass, "/redirect_to"))
      assert page.status_code == 301
      assert Header.get(Page.headers(page), "location") == endpoint_url(bypass, "/redirected")

      Browser.enable_follow_redirect(browser)
      page = Browser.get!(browser, endpoint_url(bypass, "/redirect_to"))
      assert page.status_code == 200
    end

    test "raise if max redirect loop exceeded", %{browser: browser, bypass: bypass} do
      1..6
      |> Enum.each(fn n ->
        Bypass.expect_once(bypass, "GET", "/#{n}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/#{n + 1}"))
          |> Plug.Conn.resp(301, "")
        end)
      end)

      assert_raise Mechanizex.Browser.RedirectLimitReachedError,
                   "Redirect limit of #{Browser.redirect_limit(browser)} reached",
                   fn ->
                     Browser.get!(browser, endpoint_url(bypass, "/1"))
                   end
    end

    test "change redirect limit to above", %{bypass: bypass} do
      1..5
      |> Enum.each(fn n ->
        Bypass.expect_once(bypass, "GET", "/#{n}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/#{n + 1}"))
          |> Plug.Conn.resp(301, "")
        end)
      end)

      Bypass.expect_once(bypass, "GET", "/6", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      browser = Browser.new(redirect_limit: 6)
      page = Browser.get!(browser, endpoint_url(bypass, "/1"))
      assert page.status_code == 200
    end

    @tag :skip
    test "301 redirect must preserve only HEAD and GET methods"

    @tag :skip
    test "302 redirect must preserve only HEAD and GET methods"

    @tag :skip
    test "307 redirect must preserve method"

    @tag :skip
    test "308 redirect must preserve method"
  end
end
