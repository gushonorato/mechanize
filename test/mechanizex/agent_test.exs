defmodule Mechanizex.Browser.HTTPShortcutsTest do
  alias Mechanizex.{Request, Response, Page, Browser}

  defmacro __using__(_) do
    [:get, :delete, :options, :patch, :post, :put, :head]
    |> Enum.map(fn method ->
      quote do
        test "#{unquote(method)} delegate to request", %{browser: browser} do
          Mechanizex.HTTPAdapter.Mock
          |> Mox.expect(:request, fn _,
                                     req = %Request{
                                       method: unquote(method),
                                       url: "https://www.seomaster.com.br",
                                       params: params,
                                       headers: headers
                                     } ->
            assert List.keyfind(params, "lero", 0) == {"lero", "lero"}
            assert List.keyfind(headers, "accept", 0) == {"accept", "lero"}
            {:ok, %Page{browser: browser, request: req, response: %Response{}}}
          end)

          apply(Browser, unquote(method), [
            browser,
            "https://www.seomaster.com.br",
            [{"lero", "lero"}],
            [{"accept", "lero"}]
          ])
        end

        test "#{unquote(method)}! delegate to request", %{browser: browser} do
          Mechanizex.HTTPAdapter.Mock
          |> Mox.expect(:request, fn _,
                                     req = %Request{
                                       method: unquote(method),
                                       url: "https://www.seomaster.com.br",
                                       params: params,
                                       headers: headers
                                     } ->
            assert List.keyfind(params, "lero", 0) == {"lero", "lero"}
            assert List.keyfind(headers, "accept", 0) == {"accept", "lero"}
            {:error, %Mechanizex.HTTPAdapter.NetworkError{cause: nil, message: "Never mind"}}
          end)

          assert_raise Mechanizex.HTTPAdapter.NetworkError, fn ->
            apply(Browser, unquote(:"#{method}!"), [
              browser,
              "https://www.seomaster.com.br",
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
  alias Mechanizex.{HTTPAdapter, Request, Response, Page, Browser}
  import Mox
  doctest Mechanizex.Browser

  setup do
    {:ok, browser: start_supervised!({Browser, http_adapter: :mock})}
  end

  setup_all do
    {:ok, default_ua: Browser.user_agent_string!(:mechanizex)}
  end

  describe ".new" do
    test "start a process", %{browser: browser} do
      assert is_pid(browser)
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

  describe "initial headers config" do
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
  end

  describe ".set_http_headers" do
    test "set all headers at once", %{browser: browser} do
      Browser.set_http_headers(browser, [{"content-type", "text/html"}])
      assert Browser.http_headers(browser) == [{"content-type", "text/html"}]
    end

    test "ensure all headers are in lowercase", %{browser: browser} do
      Browser.set_http_headers(browser, [
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

  describe ".http_header" do
    test "default user agent" do
    end
  end

  describe ".set_user_agent_alias" do
    test "set by alias", %{browser: browser} do
      Browser.set_user_agent_alias(browser, :windows_chrome)

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", Browser.user_agent_string!(:windows_chrome)}
             ]
    end

    test "set on init" do
      browser = Browser.new(user_agent_alias: :windows_chrome)

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", Browser.user_agent_string!(:windows_chrome)}
             ]
    end

    test "raise error when invalid alias passed", %{browser: browser} do
      assert_raise Browser.InvalidUserAgentAliasError, fn ->
        Browser.set_user_agent_alias(browser, :windows_chrom)
      end
    end
  end

  describe ".http_adapter" do
    test "configure on init" do
      {:ok, browser} = Browser.start_link(http_adapter: :custom)
      assert Browser.http_adapter(browser) == Mechanizex.HTTPAdapter.Custom
    end

    test "default http adapter" do
      browser = Browser.new()
      assert Browser.http_adapter(browser) == HTTPAdapter.Httpoison
    end
  end

  describe ".set_http_adapter" do
    test "returns browser", %{browser: browser} do
      assert Browser.set_http_adapter(browser, Mechanizex.HTTPAdapter.Custom) == browser
    end

    test "updates http adapter", %{browser: browser} do
      Browser.set_http_adapter(browser, Mechanizex.HTTPAdapter.Custom)
      assert Browser.http_adapter(browser) == Mechanizex.HTTPAdapter.Custom
    end
  end

  describe ".set_html_parser" do
    test "returns mechanizex browser", %{browser: browser} do
      assert Browser.set_html_parser(browser, Mechanizex.HTMLParser.Custom) == browser
    end

    test "updates html parser", %{browser: browser} do
      Browser.set_html_parser(browser, Mechanizex.HTMLParser.Custom)
      assert Browser.html_parser(browser) == Mechanizex.HTMLParser.Custom
    end

    test "html parser option" do
      {:ok, browser} = Browser.start_link(html_parser: :custom)
      assert Browser.html_parser(browser) == Mechanizex.HTMLParser.Custom
    end
  end

  describe ".request!" do
    test "add agent's default http headers on request", %{browser: browser, default_ua: ua} do
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
        {:ok, %Page{browser: browser, request: req, response: %Response{}}}
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: "https://www.seomaster.com.br",
        headers: [{"custom-header", "lero"}]
      })
    end

    test "ignore case on update default http header", %{browser: browser} do
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
        {:ok, %Page{browser: browser, request: req, response: %Response{}}}
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: "https://www.seomaster.com.br",
        headers: [{"custom-header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "ensure downcase of request headers", %{browser: browser} do
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
        {:ok, %Page{browser: browser, request: req, response: %Response{}}}
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: "https://www.seomaster.com.br",
        headers: [{"Custom-Header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "send request parameters", %{browser: browser, default_ua: ua} do
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
        {:ok, %Page{browser: browser, request: req, response: %Response{}}}
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: "https://www.seomaster.com.br",
        params: [{"query", "lero"}, {"start", "100"}]
      })
    end

    test "ensure downcase of response headers", %{browser: browser} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, req ->
        {:ok,
         %Page{
           browser: browser,
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
        Browser.request!(browser, %Request{
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

    test "raise error when connection fail", %{browser: browser} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, _ ->
        {:error, %Mechanizex.HTTPAdapter.NetworkError{cause: nil, message: "Never mind"}}
      end)

      assert_raise Mechanizex.HTTPAdapter.NetworkError, fn ->
        Browser.request!(browser, %Request{
          method: :get,
          url: "https://www.seomaster.com.br"
        })
      end
    end
  end
end
