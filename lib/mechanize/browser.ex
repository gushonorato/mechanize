defmodule Mechanize.Browser do
  @moduledoc """
    Entry point module for every web page interaction using Mechanize. In this module you'll find
    functions to do all kinds of HTTP requests.

    To begin interacting with web pages, first start a new browser:

      iex> browser = Browser.new()
      iex> is_pid(browser)
      true

    You can also start using `start_link/1` and `start/1` functions in case you need more control:

      iex> {:ok, browser} = Browser.start_link()
      iex> is_pid(browser)
      true

      iex> {:ok, browser} = Browser.start()
      iex> is_pid(browser)
      true

    It's possible to configure Mechanize Browser passing configuration parameters to `new/1`,
    `start_link/1` and `start/1` functions:

      Browser.new(redirect_limit: 10)

    See `request!/4` for all available options.

    Finally, after start the browser, it's time to fetch our page:

      %Page{} = Browser.get!(b, "https://www.google.com.br")

  """
  alias Mechanize.Request

  @type t :: pid
  @type response_chain :: [Mechanize.Response.t()]

  defmodule RedirectLimitReachedError do
    defexception [:message]
  end

  @user_agent_aliases %{
    mechanize:
      "Mechanize/#{Mix.Project.config()[:version]} Elixir/#{System.version()} (http://github.com/gushonorato/mechanize/)",
    linux_firefox: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0",
    linux_konqueror: "Mozilla/5.0 (compatible; Konqueror/3; Linux)",
    linux_mozilla: "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624",
    mac_firefox:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:43.0) Gecko/20100101 Firefox/43.0",
    mac_mozilla: "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401",
    mac_safari_4:
      "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10",
    mac_safari:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9",
    windows_chrome:
      "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.125 Safari/537.36",
    windows_ie_6: "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)",
    windows_ie_7:
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
    windows_ie_8:
      "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
    windows_ie_9: "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)",
    windows_ie_10: "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0)",
    windows_ie_11: "Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko",
    windows_edge:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Safari/537.36 Edge/13.10586",
    windows_mozilla:
      "Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6",
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

  @doc """
  Start a new linked Mechanize Browser.

  You can configure the browser using `opts` parameter:

  * `http_adapter` set HTTP adapter used to fetch pages. Defaults to
    `Mechanize.HTTPAdapter.Httpoison` module and it's the only available adapter at the moment.
  * `html_parser` set HTTP adapter used to parse pages. Defaults to `Mechanize.HTMLParser.Floki`
    module and it's the only available parser at the moment.
  * `http_headers` set all default browser headers at once. These headers will be sent on every
    request made by the current started browser. Defaults to
    `[{"user-agent", @user_agent_aliases[:mechanize]}]`. Note that using this options will replace
    all default headers. To append a new header, see `put_http_header/2` or `put_http_header/3`.
  * `follow_redirect` follow HTTP 3xx redirects when `true`. Defaults to `true`.
  * `redirect_limit` set maximun redirects to follow. Defaults to `5`.
  * `follow_meta_refresh` follow `<meta http-equiv="refresh" ...>` tags when `true`.
    Defaults to `false`.

  ## Example

  Start a browser that follows `<meta http-equiv="refresh" ...>`.
    ```
    iex> browser = Browser.new(follow_meta_refresh: true)
    iex> is_pid(browser)
    true
    ```
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {:ok, browser} = start_link(opts)
    browser
  end

  @doc """
  Start a new linked Mechanize Browser, similar to `new/1`, but return `GenServer.on_start()`
  instead.

  Use this function when you need more control. For all available `opts` see `new/1`.

  ## Example

    ```
    iex> {:ok, browser} = Browser.start_link(follow_meta_refresh: true)
    iex> is_pid(browser)
    true
    ```
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__.Server, init_store(opts))
  end

  @doc """
  Start a new unlinked Mechanize Browser, similar to `new/1`. It returns `GenServer.on_start()`
  instead.

  Use this function when you need more control. For all available `opts` see `new/1`.

  ## Example

    ```
    iex> {:ok, browser} = Browser.start(follow_meta_refresh: true)
    iex> is_pid(browser)
    true
    ```
  """
  @spec start(keyword()) :: GenServer.on_start()
  def start(opts \\ []) do
    GenServer.start(__MODULE__.Server, init_store(opts))
  end

  defp merge_default_opts(opts) do
    [
      http_adapter: Mechanize.HTTPAdapter.Httpoison,
      html_parser: Mechanize.HTMLParser.Floki,
      http_headers: [{"user-agent", @user_agent_aliases[:mechanize]}],
      follow_redirect: true,
      redirect_limit: 5,
      follow_meta_refresh: false
    ]
    |> Keyword.merge(opts)
  end

  defp init_store(opts) do
    opts
    |> merge_default_opts()
    |> __MODULE__.Impl.new()
  end

  @doc """
  Changes the HTTP adapter used by the browser and return the browser.

  At the moment, the only available adapter is `Mechanize.HTTPAdapter.Httpoison`.
  """
  @spec put_http_adapter(t(), module()) :: t()
  def put_http_adapter(browser, adapter) do
    :ok = GenServer.cast(browser, {:put_http_adapter, adapter})
    browser
  end

  @doc """
  Returns the HTTP adapter used by the browser.
  """
  @spec get_http_adapter(t()) :: module()
  def get_http_adapter(browser) do
    GenServer.call(browser, {:get_http_adapter})
  end

  @doc """
  Changes the HTML parser used by the browser and return the browser.

  At the moment, the only available parser is `Mechanize.HTMLParser.Floki`.
  """
  @spec put_html_parser(t(), module()) :: t()
  def put_html_parser(browser, parser) do
    :ok = GenServer.cast(browser, {:put_html_parser, parser})
    browser
  end

  @doc """
  Returns the HTML parser used by `browser`.
  """
  @spec get_html_parser(t()) :: module
  def get_html_parser(browser) do
    GenServer.call(browser, {:get_html_parser})
  end

  @doc """
  Configure all HTTP headers of `browser` at once.

  These headers will be sent on every request made by this browser. Note that all current headers
  are replaced. To add a new reader preserving the existing, see `put_http_header/2` and
  `put_http_header/3`.

  ## Example

  ```
  Browser.put_htttp_headers(browser, [
    {"accept", "text/html"},
    {"accept-encoding", "gzip, deflate, br"}
  ])
  ```
  """
  @spec put_http_headers(t(), Header.headers()) :: t()
  def put_http_headers(browser, headers) do
    :ok = GenServer.cast(browser, {:put_http_headers, headers})
    browser
  end

  @doc """
  Returns all `browser` default HTTP headers.

  ## Example
  ```
  [
    {"accept", "text/html"},
    {"accept-encoding", "gzip, deflate, br"}
  ] = Browser.get_http_headers(browser)
  ```
  """
  @spec get_http_headers(t()) :: module
  def get_http_headers(browser) do
    GenServer.call(browser, {:get_http_headers})
  end

  @doc """
  Put a new default header and preserve other existing headers.

  This header will be sent on every requestmade by this browser.

  ## Example

  ```
  Browser.put_http_header(browser, {"accept", "text/html"})
  ```
  """
  @spec put_http_header(t(), Header.header()) :: t()
  def put_http_header(browser, header) do
    :ok = GenServer.cast(browser, {:put_http_header, header})
    browser
  end

  @doc """
  Adds a new default HTTP header to `browser` if not present, otherwise updates the header value.

  This header will be sent on every request made by this `browser`.

  ## Example

  ```
  Browser.put_http_header(browser, "accept", "text/html")
  ```
  """
  @spec put_http_header(t(), String.t(), String.t()) :: t()
  def put_http_header(browser, name, value) do
    :ok = GenServer.cast(browser, {:put_http_header, name, value})
    browser
  end

  @doc """
  Get value of HTTP header form `browser` by its `name`.

  In case of a `browser` having more than one HTTP header with same `name`, this function will
  return the first matched header value.

  ## Example

  ```
  Browser.get_http_header_value(browser, "user-agent")
  ```
  """
  @spec get_http_header_value(t(), String.t()) :: String.t()
  def get_http_header_value(browser, name) do
    GenServer.call(browser, {:get_http_header_value, name})
  end

  @doc """
  Enable/disable 3xx redirect follow.

  ## Examples
  ```
  Browser.put_follow_redirect(browser, true) # Follow 3xx redirects

  Browser.put_follow_redirect(browser, false) # Don't follow 3xx redirects
  ```
  """
  @spec put_follow_redirect(t(), boolean()) :: t()
  def put_follow_redirect(browser, redirect) do
    :ok = GenServer.cast(browser, {:put_follow_redirect, redirect})
    browser
  end

  @doc """
  Return if `browser` is following 3xx redirects.
  """
  @spec follow_redirect?(t()) :: boolean()
  def follow_redirect?(browser) do
    GenServer.call(browser, {:follow_redirect?})
  end

  @doc """
  Put the limit of redirects followed by `browser` on a redirect chain.
  """
  @spec put_redirect_limit(t(), integer()) :: t()
  def put_redirect_limit(browser, limit) do
    :ok = GenServer.cast(browser, {:put_redirect_limit, limit})
    browser
  end

  @doc """
  Return the max number of redirects `browser` will follow on a redirect chain.
  """
  @spec get_redirect_limit(t()) :: integer()
  def get_redirect_limit(browser) do
    GenServer.call(browser, {:get_redirect_limit})
  end

  @doc """
  Adds/updates user-agent header using human-friendly browser aliases.

  ## Example

  ```
  Browser.put_user_agent(browser, :windows_firefox)
  ```
  is the same of using `put_http_header/3` this way:

  ```
  Browser.put_http_header(browser, "user-agent",
    "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0"
  )
  ```
  ## Available aliases

  #{
    @user_agent_aliases
    |> Enum.map(fn {k, v} -> "* `:#{k}` - #{v}" end)
    |> Enum.join("\n")
  }
  """
  @spec put_user_agent(t(), atom()) :: t()
  def put_user_agent(browser, ua_alias) do
    case Map.fetch(@user_agent_aliases, ua_alias) do
      {:ok, user_agent_string} -> put_user_agent_string(browser, user_agent_string)
      :error -> raise ArgumentError, "invalid user agent alias #{ua_alias}"
    end
  end

  @doc """
  Adds an user-agent header if not present, otherwise replaces the previous header value with
  `agent_string`.

  See `put_user_agent/2` for a more convenient way to add/update user-agent header.

  ## Examples

  ```
  Browser.put_user_agent_string(browser,
    "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0"
  )
  ```

  is the same of using `put_http_header/3` this way:

  ```
  Browser.put_http_header(browser, "user-agent",
    "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0"
  )
  ```
  """
  @spec put_user_agent_string(t(), String.t()) :: t()
  def put_user_agent_string(browser, agent_string) do
    :ok = GenServer.cast(browser, {:put_http_header, "user-agent", agent_string})
    browser
  end

  @doc """
  Returns the corresponding user agent string for a given `ua_alias`.

  ## Example

    iex> Browser.get_user_agent_string_from_alias(:windows_firefox)
    "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0"
  """
  @spec get_user_agent_string_from_alias(atom) :: String.t()
  def get_user_agent_string_from_alias(ua_alias) when is_atom(ua_alias) do
    case Map.fetch(@user_agent_aliases, ua_alias) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  @doc """
  Returns user agent string for `browser`.

  This is the same of `Browser.get_http_header_value(browser, "user-agent")`.
  """
  @spec get_user_agent_string(t()) :: String.t()
  def get_user_agent_string(browser) do
    get_http_header_value(browser, "user-agent")
  end

  def current_page(browser) do
    GenServer.call(browser, {:current_page})
  end

  defdelegate resolve_url(page_or_base_url, relative_url), to: __MODULE__.Impl

  @doc """
    Issues a to request the given `url`. See `request!/5` for details.
  """
  @spec get!(t(), String.t(), keyword) :: Mechanize.Page.t()
  def get!(browser, url, opts \\ []) do
    request!(browser, :get, url, "", opts)
  end

  @doc """
    Issues a HEAD request to the given `url`. See `request!/5` for details.
  """
  @spec head!(t(), String.t(), keyword) :: Mechanize.Page.t()
  def head!(browser, url, opts \\ []) do
    request!(browser, :head, url, "", opts)
  end

  @doc """
    Issues a OPTIONS request to the given `url`. See `request!/5` for details.
  """
  @spec options!(t(), String.t(), keyword) :: Mechanize.Page.t()
  def options!(browser, url, opts \\ []) do
    request!(browser, :options, url, "", opts)
  end

  @doc """
    Issues a DELETE request to the given `url`. See `request!/5` for details.
  """
  @spec delete!(t(), String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def delete!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :delete, url, body, opts)
  end

  @doc """
    Issues a PATCH request to the given `url`. See `request!/5` for details.
  """
  @spec patch!(t(), String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def patch!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :patch, url, body, opts)
  end

  @doc """
    Issues a POST request to the given `url`. See `request!/5` for details.
  """
  @spec post!(t(), String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def post!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :post, url, body, opts)
  end

  @doc """
    Issues a PUT request to the given `url`. See `request!/5` for details.
  """
  @spec put!(t(), String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def put!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :put, url, body, opts)
  end

  @doc """
  Issues a HTTP request using `method` to the given `url`.

  If the request does not fail, a `Page` struct is returned, otherwise, it raises
    `Mechanize.HTTPAdapter.NetworkError`.


  This function accepts `opts`:

  * `:headers` - a list of additional headers for this request.
  * `:params` - a list of params to be merged into the `url`.
  * `:options` - a list of request options for this  request.

  ## Examples

  ```
  Browser.request!(browser, :get, "https://www.example.com")
  # GET https://www.example.com
  ```

  Request with custom headers:

  ```
  Browser.request!(browser, :get, "https://www.example.com", "", headers: [
    {"accept", "text/html"}, {"user-agent", "Custom UA"}
  ])
  # GET https://www.example.com
  # Accept: text/html
  # User-agent: Custom UA
  ```

  Request with custom params:

  ```
  Browser.request!(browser, :get, "https://www.example.com", "", params: [
    {"search", "mechanize"}, {"order", "name"}
  ])
  # GET https://www.example.com?search=mechanize&order=name
  ```

  Request with custom options:

  ```
  Browser.request!(browser, :get, "https://www.example.com", "", options: [
    recv_timeout: 500, ssl: [{:versions, [:'tlsv1.2']}
  ])
  # GET https://www.example.com?search=mechanize&order=name
  ```

  """
  @spec request!(t(), :atom, String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def request!(browser, method, url, body \\ "", opts \\ [])

  def request!(browser, method, url, body, opts) do
    {headers, opts} = Keyword.pop(opts, :headers, [])
    {params, _opts} = Keyword.pop(opts, :params, [])
    {options, _opts} = Keyword.pop(opts, :options, [])

    request!(browser, %Request{
      method: method,
      url: url,
      body: body,
      headers: headers,
      params: params,
      options: options
    })
  end

  defp request!(browser, req) do
    GenServer.call(browser, {:request!, req})
  end
end
