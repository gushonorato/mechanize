defmodule Mechanizex.Browser.HTTPShortcuts do
  alias Mechanizex.Request

  defmacro __using__(_) do
    [:get, :delete, :options, :patch, :post, :put, :head]
    |> Enum.map(fn method ->
      quote do
        def unquote(:"#{method}!")(browser, url, params \\ [], headers \\ [])

        def unquote(:"#{method}!")(browser, %URI{} = uri, params, headers) do
          request!(browser, %Request{method: unquote(method), url: URI.to_string(uri), headers: headers, params: params})
        end

        def unquote(:"#{method}!")(browser, url, params, headers) do
          request!(browser, %Request{method: unquote(method), url: url, headers: headers, params: params})
        end
      end
    end)
  end
end

defmodule Mechanizex.Browser do
  use Agent
  use Mechanizex.Browser.HTTPShortcuts
  alias Mechanizex.{HTTPAdapter, HTMLParser, Request, Response, Page, Header}

  @user_agent_aliases [
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
  ]

  @default_options [
    http_adapter: :httpoison,
    html_parser: :floki,
    http_headers: [],
    user_agent_alias: :mechanizex,
    follow_redirect: true,
    max_redirect: 5
  ]

  defstruct [:http_adapter, :html_parser, :http_headers, :follow_redirect, :max_redirect]

  @type t :: %__MODULE__{
          http_adapter: any(),
          html_parser: any(),
          http_headers: keyword(),
          follow_redirect: boolean(),
          max_redirect: integer()
        }

  defmodule InvalidUserAgentAliasError do
    defexception [:message]
  end

  @spec start_link() :: {:error, any()} | {:ok, pid()}
  def start_link() do
    Agent.start_link(fn -> %__MODULE__{} end)
  end

  @spec new(list()) :: pid()
  def new(options \\ []) do
    {:ok, browser} = __MODULE__.start_link()
    init(browser, options)
  end

  defp init(browser, options) do
    options =
      @default_options
      |> Keyword.merge(Application.get_all_env(:mechanizex))
      |> Keyword.merge(options)

    browser
    |> put_http_adapter(HTTPAdapter.adapter(options[:http_adapter]))
    |> put_html_parser(HTMLParser.parser(options[:html_parser]))
    |> update_follow_redirect(options[:follow_redirect])
    |> put_max_redirect(options[:max_redirect])
    |> put_http_headers(options[:http_headers])
    |> put_user_agent_alias(options[:user_agent_alias])
  end

  def http_adapter(browser) do
    Agent.get(browser, fn state -> state.http_adapter end)
  end

  def put_http_adapter(browser, adapter) do
    Agent.update(browser, &Map.put(&1, :http_adapter, adapter))
    browser
  end

  def html_parser(browser) do
    Agent.get(browser, fn state -> state.html_parser end)
  end

  def put_html_parser(browser, parser) do
    Agent.update(browser, &Map.put(&1, :html_parser, parser))
    browser
  end

  def http_headers(browser) do
    Agent.get(browser, fn state -> state.http_headers end)
  end

  def put_http_headers(browser, headers) do
    Agent.update(browser, &Map.put(&1, :http_headers, Header.normalize(headers)))
    browser
  end

  def put_http_header(browser, h, v) do
    {h, _} = header = Header.normalize({h, v})

    Agent.update(browser, fn state ->
      %__MODULE__{state | http_headers: List.keystore(state.http_headers, h, 0, header)}
    end)

    browser
  end

  def put_user_agent_alias(browser, user_agent_alias) do
    put_http_header(browser, "user-agent", user_agent_string(user_agent_alias))
  end

  def update_follow_redirect(browser, follow) do
    :ok = Agent.update(browser, fn state -> %__MODULE__{state | follow_redirect: follow} end)
    browser
  end

  def enable_follow_redirect(browser) do
    update_follow_redirect(browser, true)
  end

  def disable_follow_redirect(browser) do
    update_follow_redirect(browser, false)
  end

  def follow_redirect?(browser) do
    Agent.get(browser, fn state -> state.follow_redirect end)
  end

  def put_max_redirect(browser, max_redirect) do
    :ok = Agent.update(browser, fn state -> %__MODULE__{state | max_redirect: max_redirect} end)
    browser
  end

  def max_redirect(browser) do
    Agent.get(browser, fn state -> state.max_redirect end)
  end

  def user_agent_string(user_agent_alias) do
    case @user_agent_aliases[user_agent_alias] do
      nil ->
        raise ArgumentError,
          message: "Invalid user agent alias \"#{user_agent_alias}\""

      user_agent_string ->
        user_agent_string
    end
  end

  def request!(browser, req) do
    resp_chain = request!(browser, req, 0)

    %Page{
      request: req,
      response: List.first(resp_chain),
      browser: browser,
      parser: html_parser(browser)
    }
  end

  defp request!(browser, req, redirect_count) do
    req
    |> Request.normalize_headers()
    |> merge_default_headers(browser)
    |> perform_request(browser)
    |> Response.normalize_headers()
    |> maybe_follow_redirect(req, browser, redirect_count)
  end

  defp merge_default_headers(req, browser) do
    %Request{req | headers: Header.merge(http_headers(browser), req.headers)}
  end

  defp perform_request(req, browser) do
    http_adapter(browser).request!(req)
  end

  defp maybe_follow_redirect(res, req, browser, redirect_count) do
    cond do
      redirect_count > max_redirect(browser) ->
        raise "Too many redirects (max #{max_redirect(browser)})"

      follow_redirect?(browser) and res.code in 300..399 ->
        location = Header.get(res.headers, "location")
        new_req = %Request{req | method: :get, url: location, params: []}
        request!(browser, new_req, redirect_count + 1) ++ [res]

      true ->
        [Response.normalize_headers(res)]
    end
  end
end
