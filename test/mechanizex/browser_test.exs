defmodule Mechanizex.BrowserTest do
  use ExUnit.Case, async: true

  alias Mechanizex.{HTTPAdapter, Request, Page, Browser, Header}
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

    test "change default follow redirect option" do
      browser = Browser.new(follow_redirect: false)
      assert Browser.follow_redirect?(browser) == false
    end

    test "default redirect limit is 5", %{browser: browser} do
      assert Browser.redirect_limit(browser) == 5
    end

    test "change redirect limit" do
      browser = Browser.new(redirect_limit: 10)
      assert Browser.redirect_limit(browser) == 10
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

    test "raise if request URL is not absolute", %{browser: browser} do
      assert_raise ArgumentError, "absolute URL needed (not www.google.com)", fn ->
        Browser.request!(browser, %Request{
          method: :get,
          url: "www.google.com"
        })
      end
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
        assert conn.query_string == "query=lero&start=100"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        params: [{"query", "lero"}, {"start", "100"}]
      })
    end

    test "ensure downcase of response headers on redirect chain", %{bypass: bypass, browser: browser} do
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

      assert [{"custom-header", "lero"}, {"foo", "BAR"} | _] = Page.headers(page)
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
        conn
        |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected"))
        |> Plug.Conn.resp(301, "")
      end)

      Bypass.expect_once(bypass, "GET", "/redirected", fn conn ->
        Plug.Conn.resp(conn, 200, "REDIRECT OK")
      end)

      page =
        Browser.request!(browser, %Request{
          method: :get,
          url: endpoint_url(bypass, "/redirect_to")
        })

      assert page.status_code == 200
      assert page.url == endpoint_url(bypass, "/redirected")
      assert page.body == "REDIRECT OK"
    end

    test "do not follow redirect when location header is missing", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, "GET", "/redirect_to", fn conn ->
        Plug.Conn.resp(conn, 301, "")
      end)

      page =
        Browser.request!(browser, %Request{
          method: :get,
          url: endpoint_url(bypass, "/redirect_to")
        })

      assert page.status_code == 301
      assert page.url == endpoint_url(bypass, "/redirect_to")
    end

    test "toggle follow redirects", %{bypass: bypass, browser: browser} do
      Bypass.expect(bypass, "GET", "/redirect_to", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected"))
        |> Plug.Conn.resp(301, "")
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

    test "follow 301, 302, 307 and 308 redirects chains", %{bypass: bypass, browser: browser} do
      step_codes = %{1 => 301, 2 => 302, 3 => 307, 4 => 308}

      1..4
      |> Enum.each(fn step ->
        Bypass.expect_once(bypass, "GET", "/#{step}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/#{step + 1}"))
          |> Plug.Conn.resp(step_codes[step], "")
        end)
      end)

      Bypass.expect_once(bypass, "GET", "/5", fn conn ->
        Plug.Conn.resp(conn, 200, "Page 5")
      end)

      page = Browser.get!(browser, endpoint_url(bypass, "/1"))

      expected_resp_chain = Enum.map(5..1, &endpoint_url(bypass, "/#{&1}"))
      actual_resp_chain = Enum.map(page.response_chain, & &1.url)

      assert expected_resp_chain == actual_resp_chain
    end

    test "301 and 302 redirects change to GET method on new request", %{bypass: bypass, browser: browser} do
      fixtures =
        for status <- [301, 302],
            method <- [:get, :delete, :options, :patch, :post, :put],
            do: {status, method}

      Enum.each(fixtures, fn {status, method} ->
        bypass_method =
          method
          |> Atom.to_string()
          |> String.upcase()

        Bypass.expect_once(bypass, bypass_method, "/redirect_#{status}_#{method}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected_#{status}_#{method}"))
          |> Plug.Conn.resp(status, "")
        end)

        Bypass.expect_once(bypass, "GET", "/redirected_#{status}_#{method}", fn conn ->
          Plug.Conn.resp(conn, 200, "OK")
        end)

        Browser.request!(browser, %Request{
          method: method,
          url: endpoint_url(bypass, "/redirect_#{status}_#{method}")
        })
      end)
    end

    test "301 and 302 redirects preserve HEAD methods on new request", %{bypass: bypass, browser: browser} do
      [301, 302]
      |> Enum.each(fn status ->
        Bypass.expect_once(bypass, "HEAD", "/redirect_head_#{status}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected_head_#{status}"))
          |> Plug.Conn.resp(301, "")
        end)

        Bypass.expect_once(bypass, "HEAD", "/redirected_head_#{status}", fn conn ->
          Plug.Conn.resp(conn, 200, "OK")
        end)

        Browser.request!(browser, %Request{
          method: :head,
          url: endpoint_url(bypass, "/redirect_head_#{status}")
        })
      end)
    end

    test "307 and 308 redirects preserve methods", %{bypass: bypass, browser: browser} do
      fixtures =
        for status <- [307, 308],
            method <- [:get, :head, :delete, :options, :patch, :post, :put],
            do: {status, method}

      Enum.each(fixtures, fn {status, method} ->
        bypass_method =
          method
          |> Atom.to_string()
          |> String.upcase()

        Bypass.expect_once(bypass, bypass_method, "/redirect_#{status}_#{method}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected_#{status}_#{method}"))
          |> Plug.Conn.resp(status, "")
        end)

        Bypass.expect_once(bypass, bypass_method, "/redirected_#{status}_#{method}", fn conn ->
          Plug.Conn.resp(conn, 200, "OK")
        end)

        Browser.request!(browser, %Request{
          method: method,
          url: endpoint_url(bypass, "/redirect_#{status}_#{method}")
        })
      end)
    end

    test "307 and 308 redirects preserve request data", %{bypass: bypass, browser: browser} do
      [307, 308]
      |> Enum.each(fn status ->
        Bypass.expect_once(bypass, "GET", "/redirect_to_#{status}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected_#{status}"))
          |> Plug.Conn.resp(status, "")
        end)

        Bypass.expect_once(bypass, "GET", "/redirected_#{status}", fn conn ->
          assert conn.query_string == "user=gustavo"
          Plug.Conn.resp(conn, 200, "OK")
        end)

        Browser.get!(browser, endpoint_url(bypass, "/redirect_to_#{status}"), [{"user", "gustavo"}])
      end)
    end

    test "301 and 302 redirects does not preserve request data", %{bypass: bypass, browser: browser} do
      [301, 302]
      |> Enum.each(fn status ->
        Bypass.expect_once(bypass, "POST", "/redirect_to_#{status}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected_#{status}"))
          |> Plug.Conn.resp(status, "")
        end)

        Bypass.expect_once(bypass, "GET", "/redirected_#{status}", fn conn ->
          assert conn.query_string == ""
          assert {:ok, "", conn} = Plug.Conn.read_body(conn)
          Plug.Conn.resp(conn, 200, "OK")
        end)

        Browser.post!(browser, endpoint_url(bypass, "/redirect_to_#{status}"), "user=gustavo")
      end)
    end

    test "request helper functions", %{bypass: bypass, browser: browser} do
      [:get!, :head!, :options!, :delete!, :patch!, :post!, :put!]
      |> Enum.each(fn function_name ->
        method =
          function_name
          |> Atom.to_string()
          |> String.upcase()
          |> String.replace("!", "")

        Bypass.expect_once(bypass, method, "/fake_path", fn conn ->
          assert conn.method == method
          assert Plug.Conn.get_req_header(conn, "lero") == ["LERO"]
          assert conn.query_string == "q=10"

          if function_name in [:delete!, :patch!, :post!, :put!] do
            assert {:ok, "BODY", conn} = Plug.Conn.read_body(conn)
          else
            assert {:ok, "", conn} = Plug.Conn.read_body(conn)
          end

          Plug.Conn.resp(conn, 200, "OK")
        end)

        if function_name in [:delete!, :patch!, :post!, :put!] do
          apply(Browser, function_name, [
            browser,
            endpoint_url(bypass, "/fake_path"),
            "BODY",
            [{"q", "10"}],
            [{"LERO", "LERO"}]
          ])
        else
          apply(Browser, function_name, [
            browser,
            endpoint_url(bypass, "/fake_path"),
            [{"q", "10"}],
            [{"LERO", "LERO"}]
          ])
        end
      end)
    end
  end
end
