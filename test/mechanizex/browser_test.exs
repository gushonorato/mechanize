defmodule Mechanizex.BrowserTest do
  use ExUnit.Case, async: true

  alias Mechanizex.{Request, Page, Browser, Header}
  import TestHelper
  doctest Mechanizex.Browser

  setup do
    {:ok, %{bypass: Bypass.open()}}
  end

  setup_all do
    {:ok, default_ua: Browser.get_user_agent_string(:mechanizex)}
  end

  describe ".put_http_headers" do
    test "set all headers at once" do
      assert Browser.new()
             |> Browser.put_http_headers([{"content-type", "text/html"}])
             |> Browser.get_http_headers() == [{"content-type", "text/html"}]
    end

    test "ensure all headers are in lowercase" do
      assert Browser.new()
             |> Browser.put_http_headers([
               {"Content-Type", "text/html"},
               {"Custom-Header", "Lero"}
             ])
             |> Browser.get_http_headers() == [
               {"content-type", "text/html"},
               {"custom-header", "Lero"}
             ]
    end
  end

  describe ".put_http_header" do
    test "updates existent header" do
      assert Browser.new()
             |> Browser.put_http_header("user-agent", "Lero")
             |> Browser.get_http_headers() == [
               {"user-agent", "Lero"}
             ]
    end

    test "add new header", %{default_ua: ua} do
      assert Browser.new()
             |> Browser.put_http_header("content-type", "text/html")
             |> Browser.get_http_headers() == [
               {"user-agent", ua},
               {"content-type", "text/html"}
             ]
    end

    test "ensure inserted header is lowecase", %{default_ua: ua} do
      assert Browser.new()
             |> Browser.put_http_header("Content-Type", "text/html")
             |> Browser.get_http_headers() == [
               {"user-agent", ua},
               {"content-type", "text/html"}
             ]
    end
  end

  describe ".put_user_agent" do
    test "set by alias" do
      assert Browser.new()
             |> Browser.put_user_agent(:windows_chrome)
             |> Browser.get_http_headers() == [
               {"user-agent", Browser.get_user_agent_string(:windows_chrome)}
             ]
    end

    @tag :capture_log
    test "raise error when invalid alias passed" do
      Process.flag(:trap_exit, true)

      b = Browser.new()

      b
      |> Browser.put_user_agent(:lero)
      |> :sys.get_state()
      |> catch_exit()

      assert_received {:EXIT, b, {%ArgumentError{message: "invalid user agent alias lero"}, _}}
    end
  end

  describe ".get_user_agent_string" do
    test "get default user agent string" do
      assert Browser.get_user_agent_string(Browser.new()) == Browser.get_user_agent_string(:mechanizex)
    end
  end

  describe ".put_http_adapter" do
    test "returns browser" do
      assert is_pid(Browser.put_http_adapter(Browser.new(), Mechanizex.HTTPAdapter.Custom))
    end

    test "updates http adapter" do
      assert Browser.new()
             |> Browser.put_http_adapter(Mechanizex.HTTPAdapter.Custom)
             |> Browser.get_http_adapter() == Mechanizex.HTTPAdapter.Custom
    end
  end

  describe ".put_html_parser" do
    test "returns mechanizex browser" do
      assert is_pid(Browser.put_html_parser(Browser.new(), Mechanizex.HTMLParser.Custom))
    end

    test "updates html parser" do
      assert Browser.new()
             |> Browser.put_html_parser(Mechanizex.HTMLParser.Custom)
             |> Browser.get_html_parser() == Mechanizex.HTMLParser.Custom
    end
  end

  describe ".put_follow_redirect" do
    test "update browser follow redirect to true and false" do
      browser = Browser.new()
      assert Browser.follow_redirect?(browser) == true

      browser = Browser.put_follow_redirect(browser, false)
      assert Browser.follow_redirect?(browser) == false

      assert browser
             |> Browser.put_follow_redirect(true)
             |> Browser.follow_redirect?() == true
    end
  end

  describe ".request!" do
    test "get request content", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "OK PAGE")
      end)

      page =
        Browser.request!(Browser.new(), %Request{
          method: :get,
          url: endpoint_url(bypass)
        })

      assert Page.body(page) == "OK PAGE"
    end

    test "send correct methods", %{bypass: bypass} do
      browser = Browser.new()

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

    @tag :capture_log
    test "raise if request URL is not absolute" do
      Process.flag(:trap_exit, true)
      b = Browser.new()

      b
      |> Browser.get!("www.google.com")
      |> catch_exit()

      assert_received {:EXIT, b, {%ArgumentError{message: "absolute URL needed (not www.google.com)"}, _}}
    end

    test "merge header with browser's default headers on all redirect chain", %{
      bypass: bypass,
      default_ua: ua
    } do
      expected_headers = [
        {"custom-header", "lero"},
        {"host", "localhost:#{bypass.port}"},
        {"user-agent", ua}
      ]

      Bypass.expect_once(bypass, "GET", "/redirect_to", fn conn ->
        assert conn.req_headers == expected_headers

        conn
        |> Plug.Conn.put_resp_header("location", endpoint_url(bypass, "/redirected"))
        |> Plug.Conn.resp(301, "OK")
      end)

      Bypass.expect_once(bypass, "GET", "/redirected", fn conn ->
        assert conn.req_headers == expected_headers
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(Browser.new(), %Request{
        method: :get,
        url: endpoint_url(bypass, "/redirect_to"),
        headers: [{"custom-header", "lero"}]
      })
    end

    test "ignore case on update default http header on all redirect chain", %{bypass: bypass} do
      expected_headers = [
        {"custom-header", "lero"},
        {"host", "localhost:#{bypass.port}"},
        {"user-agent", "Gustabot"}
      ]

      Bypass.expect_once(bypass, "GET", "/redirect_to", fn conn ->
        assert conn.req_headers == expected_headers

        conn
        |> Plug.Conn.put_resp_header("location", endpoint_url(bypass, "/redirected"))
        |> Plug.Conn.resp(301, "")
      end)

      Bypass.expect_once(bypass, "GET", "/redirected", fn conn ->
        assert conn.req_headers == expected_headers

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(Browser.new(), %Request{
        method: :get,
        url: endpoint_url(bypass, "/redirect_to"),
        headers: [{"custom-header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "ensure downcase of request headers on all redirect chain", %{bypass: bypass} do
      expected_headers = [
        {"custom-header", "lero"},
        {"host", "localhost:#{bypass.port}"},
        {"user-agent", "Gustabot"}
      ]

      Bypass.expect_once(bypass, "GET", "/redirect_to", fn conn ->
        assert conn.req_headers == expected_headers

        conn
        |> Plug.Conn.put_resp_header("location", endpoint_url(bypass, "/redirected"))
        |> Plug.Conn.resp(301, "")
      end)

      Bypass.expect_once(bypass, "GET", "/redirected", fn conn ->
        assert conn.req_headers == expected_headers
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(Browser.new(), %Request{
        method: :get,
        url: endpoint_url(bypass, "/redirect_to"),
        headers: [{"Custom-Header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "send request parameters", %{bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.query_string == "query=lero&start=100"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(Browser.new(), %Request{
        method: :get,
        url: endpoint_url(bypass),
        params: [{"query", "lero"}, {"start", "100"}]
      })
    end

    @tag :capture_log
    test "raise error when connection fail", %{bypass: bypass} do
      Process.flag(:trap_exit, true)
      Bypass.down(bypass)

      url = endpoint_url(bypass)
      b = Browser.new()

      b
      |> Browser.get!(url)
      |> catch_exit()

      assert_received {:EXIT, b,
                       {%Mechanizex.HTTPAdapter.NetworkError{
                          cause: %{reason: :econnrefused},
                          url: url
                        }, _}}
    end

    test "follow simple redirect", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/redirect_to", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected"))
        |> Plug.Conn.resp(301, "")
      end)

      Bypass.expect_once(bypass, "GET", "/redirected", fn conn ->
        Plug.Conn.resp(conn, 200, "REDIRECT OK")
      end)

      page =
        Browser.request!(Browser.new(), %Request{
          method: :get,
          url: endpoint_url(bypass, "/redirect_to")
        })

      assert page.status_code == 200
      assert page.url == endpoint_url(bypass, "/redirected")
      assert page.body == "REDIRECT OK"
    end

    test "do not follow redirect when location header is missing", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/redirect_to", fn conn ->
        Plug.Conn.resp(conn, 301, "")
      end)

      page =
        Browser.request!(Browser.new(), %Request{
          method: :get,
          url: endpoint_url(bypass, "/redirect_to")
        })

      assert page.status_code == 301
      assert page.url == endpoint_url(bypass, "/redirect_to")
    end

    test "toggle follow redirects", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/redirect_to", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected"))
        |> Plug.Conn.resp(301, "")
      end)

      Bypass.expect_once(bypass, "GET", "/redirected", fn conn ->
        Plug.Conn.resp(conn, 200, "REDIRECT OK")
      end)

      browser = Browser.new()
      Browser.put_follow_redirect(browser, false)
      page = Browser.get!(browser, endpoint_url(bypass, "/redirect_to"))
      assert page.status_code == 301
      assert Header.get_value(Page.headers(page), "location") == endpoint_url(bypass, "/redirected")

      Browser.put_follow_redirect(browser, true)
      page = Browser.get!(browser, endpoint_url(bypass, "/redirect_to"))
      assert page.status_code == 200
    end

    @tag :capture_log
    test "raise if max redirect loop exceeded", %{bypass: bypass} do
      b = Browser.new()

      1..6
      |> Enum.each(fn n ->
        Bypass.expect_once(bypass, "GET", "/#{n}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/#{n + 1}"))
          |> Plug.Conn.resp(301, "")
        end)
      end)

      Process.flag(:trap_exit, true)

      b
      |> Browser.get!(endpoint_url(bypass, "/1"))
      |> catch_exit()

      assert_received {:EXIT, b, {%Browser.RedirectLimitReachedError{message: "Redirect limit of 5 reached"}, _}}
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

    test "follow 301, 302, 307 and 308 redirects chains", %{bypass: bypass} do
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

      page = Browser.get!(Browser.new(), endpoint_url(bypass, "/1"))

      expected_resp_chain = Enum.map(5..1, &endpoint_url(bypass, "/#{&1}"))
      actual_resp_chain = Enum.map(page.response_chain, & &1.url)

      assert expected_resp_chain == actual_resp_chain
    end

    test "301 and 302 redirects change to GET method on new request", %{bypass: bypass} do
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

        Browser.request!(Browser.new(), %Request{
          method: method,
          url: endpoint_url(bypass, "/redirect_#{status}_#{method}")
        })
      end)
    end

    test "301 and 302 redirects preserve HEAD methods on new request", %{bypass: bypass} do
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

        Browser.request!(Browser.new(), %Request{
          method: :head,
          url: endpoint_url(bypass, "/redirect_head_#{status}")
        })
      end)
    end

    test "307 and 308 redirects preserve methods", %{bypass: bypass} do
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

        Browser.request!(Browser.new(), %Request{
          method: method,
          url: endpoint_url(bypass, "/redirect_#{status}_#{method}")
        })
      end)
    end

    [307, 308]
    |> Enum.each(fn status ->
      test "#{status} redirects preserve request data", %{bypass: bypass} do
        Bypass.expect_once(bypass, "GET", "/redirect_to_#{unquote(status)}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected_#{unquote(status)}"))
          |> Plug.Conn.resp(unquote(status), "")
        end)

        Bypass.expect_once(bypass, "GET", "/redirected_#{unquote(status)}", fn conn ->
          assert conn.query_string == "user=gustavo"
          Plug.Conn.resp(conn, 200, "OK")
        end)

        Browser.get!(Browser.new(), endpoint_url(bypass, "/redirect_to_#{unquote(status)}"),
          params: [{"user", "gustavo"}]
        )
      end
    end)

    [301, 302]
    |> Enum.each(fn status ->
      test "#{status} redirects does not preserve request data", %{bypass: bypass} do
        Bypass.expect_once(bypass, "POST", "/redirect_to_#{unquote(status)}", fn conn ->
          conn
          |> Plug.Conn.put_resp_header("Location", endpoint_url(bypass, "/redirected_#{unquote(status)}"))
          |> Plug.Conn.resp(unquote(status), "")
        end)

        Bypass.expect_once(bypass, "GET", "/redirected_#{unquote(status)}", fn conn ->
          assert conn.query_string == ""
          assert {:ok, "", conn} = Plug.Conn.read_body(conn)
          Plug.Conn.resp(conn, 200, "OK")
        end)

        Browser.post!(Browser.new(), endpoint_url(bypass, "/redirect_to_#{unquote(status)}"), "user=gustavo")
      end
    end)

    test "do not follow meta-refresh as default", %{bypass: bypass} do
      resp_body = read_file!("test/htdocs/meta_refresh.html", url: endpoint_url(bypass, "/refreshed"))

      Bypass.expect_once(bypass, "GET", "/do_not_refresh", fn conn ->
        Plug.Conn.resp(conn, 200, resp_body)
      end)

      browser = Browser.new()
      page = Browser.get!(browser, endpoint_url(bypass, "/do_not_refresh"))

      assert page.status_code == 200
      assert page.body == resp_body
    end

    [200, 300, 404]
    |> Enum.each(fn status ->
      test "follow meta-refresh on status code #{status}", %{bypass: bypass} do
        Bypass.expect_once(bypass, "GET", "/refresh", fn conn ->
          resp_body = read_file!("test/htdocs/meta_refresh.html", url: endpoint_url(bypass, "/refreshed"))
          Plug.Conn.resp(conn, unquote(status), resp_body)
        end)

        Bypass.expect_once(bypass, "GET", "/refreshed", fn conn ->
          Plug.Conn.resp(conn, 200, "OK")
        end)

        browser = Browser.new(follow_meta_refresh: true)
        page = Browser.get!(browser, endpoint_url(bypass, "/refresh"))

        assert page.status_code == 200
        assert page.body == "OK"
      end
    end)

    test "follow meta-refresh with relative url", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/refresh", fn conn ->
        resp_body = read_file!("test/htdocs/meta_refresh.html", url: "/refreshed")
        Plug.Conn.resp(conn, 200, resp_body)
      end)

      Bypass.expect_once(bypass, "GET", "/refreshed", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      browser = Browser.new(follow_meta_refresh: true)
      page = Browser.get!(browser, endpoint_url(bypass, "/refresh"))

      assert page.status_code == 200
      assert page.body == "OK"
    end

    test_http_delegates([:get!, :head!, :options!], fn {function_name, http_method} ->
      test ".#{function_name} with headers and params", %{bypass: bypass} do
        browser = Browser.new()

        Bypass.expect_once(bypass, unquote(http_method), "/fake_path", fn conn ->
          assert conn.method == unquote(http_method)
          assert Plug.Conn.get_req_header(conn, "lero") == ["LERO"]
          assert conn.query_string == "q=10"
          assert {:ok, "", conn} = Plug.Conn.read_body(conn)

          Plug.Conn.resp(conn, 200, "OK")
        end)

        apply(Browser, unquote(function_name), [
          browser,
          endpoint_url(bypass, "/fake_path"),
          [params: [{"q", "10"}], headers: [{"LERO", "LERO"}]]
        ])
      end
    end)

    test_http_delegates([:delete!, :patch!, :post!, :put!], fn {function_name, http_method} ->
      test ".#{function_name} with headers and params", %{bypass: bypass} do
        browser = Browser.new()

        Bypass.expect_once(bypass, unquote(http_method), "/fake_path", fn conn ->
          assert conn.method == unquote(http_method)
          assert Plug.Conn.get_req_header(conn, "lero") == ["LERO"]
          assert conn.query_string == "q=10"
          assert {:ok, "BODY", conn} = Plug.Conn.read_body(conn)

          Plug.Conn.resp(conn, 200, "OK")
        end)

        apply(Browser, unquote(function_name), [
          browser,
          endpoint_url(bypass, "/fake_path"),
          "BODY",
          [params: [{"q", "10"}], headers: [{"LERO", "LERO"}]]
        ])
      end
    end)
  end
end
