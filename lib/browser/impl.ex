defmodule Mechanizex.Browser.Impl do
  alias Mechanizex.{Request, Page, Header}
  alias Mechanizex.Page.Link

  @user_agent_aliases %{
    mechanizex:
      "Mechanizex/#{Mix.Project.config()[:version]} Elixir/#{System.version()} (http://github.com/gushonorato/mechanizex/)",
    linux_firefox: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0",
    linux_konqueror: "Mozilla/5.0 (compatible; Konqueror/3; Linux)",
    linux_mozilla: "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624",
    mac_firefox: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:43.0) Gecko/20100101 Firefox/43.0",
    mac_mozilla: "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401",
    mac_safari_4:
      "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10",
    mac_safari:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9",
    windows_chrome:
      "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.125 Safari/537.36",
    windows_ie_6: "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)",
    windows_ie_7: "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
    windows_ie_8:
      "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
    windows_ie_9: "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)",
    windows_ie_10: "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0)",
    windows_ie_11: "Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko",
    windows_edge:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Safari/537.36 Edge/13.10586",
    windows_mozilla: "Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6",
    windows_firefox: "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0",
    iphone:
      "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B5110e Safari/601.1",
    ipad:
      "Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1",
    android:
      "Mozilla/5.0 (Linux; Android 5.1.1; Nexus 7 Build/LMY47V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.76 Safari/537.36",
    googlebot: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
    googlebot_mobile:
      "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.96 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  }

  defstruct http_adapter: Mechanizex.HTTPAdapter.Httpoison,
            html_parser: Mechanizex.HTMLParser.Floki,
            http_headers: [{"user-agent", @user_agent_aliases[:mechanizex]}],
            follow_redirect: true,
            redirect_limit: 5,
            follow_meta_refresh: false

  @opaque t :: %__MODULE__{
            http_adapter: any(),
            html_parser: any(),
            http_headers: keyword(),
            follow_redirect: boolean(),
            redirect_limit: integer(),
            follow_meta_refresh: boolean()
          }

  def new(fields \\ []) do
    struct(%__MODULE__{}, fields)
  end

  def put_http_adapter(browser, adapter), do: %__MODULE__{browser | http_adapter: adapter}
  def get_http_adapter(browser), do: browser.http_adapter

  def put_html_parser(browser, parser), do: %__MODULE__{browser | html_parser: parser}
  def get_html_parser(browser), do: browser.html_parser

  def put_http_headers(browser, headers), do: %__MODULE__{browser | http_headers: Header.normalize(headers)}
  def get_http_headers(browser), do: browser.http_headers

  def put_http_header(browser, {key, value}) do
    put_http_header(browser, key, value)
  end

  def put_http_header(browser, key, value) do
    %__MODULE__{browser | http_headers: Header.put(browser.http_headers, key, value)}
  end

  def get_http_header_value(browser, key), do: Header.get_value(browser.http_headers, key)

  def put_follow_redirect(browser, value), do: %__MODULE__{browser | follow_redirect: value}
  def follow_redirect?(browser), do: browser.follow_redirect

  def put_redirect_limit(browser, limit), do: %__MODULE__{browser | redirect_limit: limit}
  def get_redirect_limit(browser), do: browser.redirect_limit

  def put_user_agent(browser, ua_alias) do
    case Map.fetch(@user_agent_aliases, ua_alias) do
      {:ok, user_agent_string} -> put_user_agent_string(browser, user_agent_string)
      :error -> raise ArgumentError, "invalid user agent alias #{ua_alias}"
    end
  end

  def put_user_agent_string(browser, agent_string) do
    put_http_header(browser, "user-agent", agent_string)
  end

  def get_user_agent_string(ua_alias) when is_atom(ua_alias) do
    case Map.fetch(@user_agent_aliases, ua_alias) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  def get_user_agent_string(browser) do
    get_http_header_value(browser, "user-agent")
  end

  def get!(browser, url, params \\ [], headers \\ []) do
    request!(browser, %Request{
      method: :get,
      url: url,
      params: params,
      headers: headers
    })
  end

  def head!(browser, url, params \\ [], headers \\ []) do
    request!(browser, %Request{
      method: :head,
      url: url,
      params: params,
      headers: headers
    })
  end

  def options!(browser, url, params \\ [], headers \\ []) do
    request!(browser, %Request{
      method: :options,
      url: url,
      params: params,
      headers: headers
    })
  end

  def delete!(browser, url, body \\ "", params \\ [], headers \\ []) do
    request!(browser, %Request{
      method: :delete,
      url: url,
      params: params,
      body: body,
      headers: headers
    })
  end

  def patch!(browser, url, body \\ "", params \\ [], headers \\ []) do
    request!(browser, %Request{
      method: :patch,
      url: url,
      params: params,
      body: body,
      headers: headers
    })
  end

  def post!(browser, url, body \\ "", params \\ [], headers \\ []) do
    request!(browser, %Request{
      method: :post,
      url: url,
      params: params,
      body: body,
      headers: headers
    })
  end

  def put!(browser, url, body \\ "", params \\ [], headers \\ []) do
    request!(browser, %Request{
      method: :put,
      url: url,
      params: params,
      body: body,
      headers: headers
    })
  end

  def request!(browser, req) do
    check_request_url!(req)
    resp_chain = request!(browser, req, 0)

    last_response = List.first(resp_chain)

    page = %Page{
      response_chain: resp_chain,
      status_code: last_response.code,
      body: last_response.body,
      url: last_response.url,
      browser: browser,
      parser: get_html_parser(browser)
    }

    maybe_follow_meta_refresh(browser, page)
  end

  defp maybe_follow_meta_refresh(%__MODULE__{follow_meta_refresh: false}, page), do: page

  defp maybe_follow_meta_refresh(%__MODULE__{follow_meta_refresh: true}, page) do
    case Page.meta_refresh(page) do
      nil ->
        page

      {_delay, nil} ->
        page

      {delay, url} ->
        Process.sleep(delay * 1000)
        Link.follow(page, url)
    end
  end

  defp check_request_url!(%Request{} = req) do
    if !String.match?(req.url, ~r/^http(s)?:\/\//) do
      raise ArgumentError, "absolute URL needed (not #{req.url})"
    end
  end

  defp request!(browser, req, redirect_count) do
    req
    |> Request.normalize()
    |> merge_default_headers(browser)
    |> perform_request!(browser)
    |> maybe_follow_redirect(req, browser, redirect_count)
  end

  defp merge_default_headers(req, browser) do
    %Request{req | headers: Header.merge(get_http_headers(browser), req.headers)}
  end

  defp perform_request!(req, browser) do
    get_http_adapter(browser).request!(req)
  end

  defp maybe_follow_redirect(res, _req, %__MODULE__{follow_redirect: false}, _count) do
    [res]
  end

  defp maybe_follow_redirect(res, req, %__MODULE__{follow_redirect: true} = browser, count) do
    if res.location do
      follow_redirect(req, res, browser, count)
    else
      [res]
    end
  end

  defp follow_redirect(req, res, browser, redirect_count) do
    cond do
      redirect_count >= get_redirect_limit(browser) ->
        raise Mechanizex.Browser.RedirectLimitReachedError, "Redirect limit of #{get_redirect_limit(browser)} reached"

      res.code in 307..308 ->
        new_req = Map.put(req, :url, res.location)

        request!(browser, new_req, redirect_count + 1) ++ [res]

      res.code in 300..399 ->
        method = if req.method == :head, do: :head, else: :get

        new_req =
          req
          |> Map.put(:url, res.location)
          |> Map.put(:method, method)
          |> Map.put(:params, [])

        request!(browser, new_req, redirect_count + 1) ++ [res]
    end
  end
end
