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

      iex> {:ok, browser} = Browser.start()
      iex> is_pid(browser)

    It's possible to configure Mechanize Browser passing configuration parameters to `new/1`,
    `start_link/1` and `start/1` functions:

      iex> Browser.new(redirect_limit: 10)

    See `request!/4` for all available options.

    Finally, after start the browser, it's time to fetch our page:

      %Page{} = Browser.get!(b, "https://www.google.com.br")

  """

  alias Mechanize.{Page, Request}

  defmodule RedirectLimitReachedError do
    defexception [:message]
  end

  @spec new(keyword()) :: pid
  def new(opts \\ []) do
    {:ok, browser} = start_link(opts)
    browser
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__.Server, __MODULE__.Impl.new(opts))
  end

  @spec start(keyword()) :: GenServer.on_start()
  def start(opts \\ []) do
    GenServer.start(__MODULE__.Server, __MODULE__.Impl.new(opts))
  end

  @spec put_http_adapter(pid, module) :: pid
  def put_http_adapter(browser, adapter) do
    :ok = GenServer.cast(browser, {:put_http_adapter, adapter})
    browser
  end

  @spec get_http_adapter(pid) :: module
  def get_http_adapter(browser) do
    GenServer.call(browser, {:get_http_adapter})
  end

  @spec put_html_parser(pid, module) :: pid
  def put_html_parser(browser, parser) do
    :ok = GenServer.cast(browser, {:put_html_parser, parser})
    browser
  end

  @spec get_html_parser(pid) :: module
  def get_html_parser(browser) do
    GenServer.call(browser, {:get_html_parser})
  end

  @spec put_http_headers(pid, Header.headers()) :: pid
  def put_http_headers(browser, headers) do
    :ok = GenServer.cast(browser, {:put_http_headers, headers})
    browser
  end

  @spec get_http_headers(pid) :: module
  def get_http_headers(browser) do
    GenServer.call(browser, {:get_http_headers})
  end

  @spec put_http_header(pid, Header.header()) :: pid
  def put_http_header(browser, header) do
    :ok = GenServer.cast(browser, {:put_http_header, header})
    browser
  end

  @spec put_http_header(pid, String.t(), String.t()) :: pid
  def put_http_header(browser, key, value) do
    :ok = GenServer.cast(browser, {:put_http_header, key, value})
    browser
  end

  @spec get_http_header_value(pid, String.t()) :: String.t()
  def get_http_header_value(browser, key) do
    GenServer.call(browser, {:get_http_header_value, key})
  end

  @spec put_follow_redirect(pid, boolean) :: pid
  def put_follow_redirect(browser, value) do
    :ok = GenServer.cast(browser, {:put_follow_redirect, value})
    browser
  end

  @spec follow_redirect?(pid) :: boolean
  def follow_redirect?(browser) do
    GenServer.call(browser, {:follow_redirect?})
  end

  @spec put_redirect_limit(pid, integer) :: pid
  def put_redirect_limit(browser, limit) do
    :ok = GenServer.cast(browser, {:put_redirect_limit, limit})
    browser
  end

  @spec get_redirect_limit(pid) :: integer
  def get_redirect_limit(browser) do
    GenServer.call(browser, {:get_redirect_limit})
  end

  @spec put_user_agent(pid, atom) :: pid
  def put_user_agent(browser, ua_alias) do
    :ok = GenServer.cast(browser, {:put_user_agent, ua_alias})
    browser
  end

  @spec put_user_agent_string(pid, String.t()) :: pid
  def put_user_agent_string(browser, agent_string) do
    :ok = GenServer.cast(browser, {:put_user_agent_string, agent_string})
    browser
  end

  @spec get_user_agent_string(atom) :: String.t()
  def get_user_agent_string(ua_alias) when is_atom(ua_alias) do
    __MODULE__.Impl.get_user_agent_string(ua_alias)
  end

  @spec get_user_agent_string(pid) :: String.t()
  def get_user_agent_string(browser) do
    GenServer.call(browser, {:get_user_agent_string})
  end

  @spec head!(pid, String.t(), keyword) :: Mechanize.Page.t()
  def get!(browser, url, opts \\ []) do
    request!(browser, :get, url, "", opts)
  end

  @spec head!(pid, String.t(), keyword) :: Mechanize.Page.t()
  def head!(browser, url, opts \\ []) do
    request!(browser, :head, url, "", opts)
  end

  @spec options!(pid, String.t(), keyword) :: Mechanize.Page.t()
  def options!(browser, url, opts \\ []) do
    request!(browser, :options, url, "", opts)
  end

  @spec delete!(pid, String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def delete!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :delete, url, body, opts)
  end

  @spec patch!(pid, String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def patch!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :patch, url, body, opts)
  end

  @spec post!(pid, String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def post!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :post, url, body, opts)
  end

  @spec put!(pid, String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def put!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :put, url, body, opts)
  end

  @spec request!(pid, :atom, String.t(), String.t() | {atom, any}, keyword) :: Mechanize.Page.t()
  def request!(browser, method, url, body \\ "", opts \\ [])

  def request!(browser, method, url, body, opts) do
    {headers, opts} = Keyword.pop(opts, :headers, [])
    {params, _opts} = Keyword.pop(opts, :params, [])

    request!(browser, %Request{
      method: method,
      url: url,
      body: body,
      headers: headers,
      params: params
    })
  end

  defp request!(browser, req) do
    GenServer.call(browser, {:request!, req})
  end

  @spec follow_url(pid, %Page{}, String.t()) :: %Page{}
  def follow_url(browser, %Page{} = page, url) do
    follow_url(browser, page.url, url)
  end

  @spec follow_url(pid, String.t(), String.t()) :: %Page{}
  def follow_url(browser, base_url, url) do
    GenServer.call(browser, {:follow_url, base_url, url})
  end
end
