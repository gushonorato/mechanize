defmodule Mechanize.Browser do
  @moduledoc """
    Entry point module for every web page interaction using Mechanize.

    ## Examples

    To begin interacting with web pages, first start a new browser:

      ```
      iex> browser = Browser.new()
      iex> is_pid(browser)
      true
      ```
  """

  alias Mechanize.{Page, Request}

  defmodule RedirectLimitReachedError do
    defexception [:message]
  end

  def new(fields \\ []) do
    {:ok, browser} = start_link(fields)
    browser
  end

  def start_link(fields \\ []) do
    GenServer.start_link(__MODULE__.Server, __MODULE__.Impl.new(fields))
  end

  def start(fields \\ []) do
    GenServer.start(__MODULE__.Server, __MODULE__.Impl.new(fields))
  end

  def put_http_adapter(browser, adapter) do
    :ok = GenServer.cast(browser, {:put_http_adapter, adapter})
    browser
  end

  def get_http_adapter(browser) do
    GenServer.call(browser, {:get_http_adapter})
  end

  def put_html_parser(browser, parser) do
    :ok = GenServer.cast(browser, {:put_html_parser, parser})
    browser
  end

  def get_html_parser(browser) do
    GenServer.call(browser, {:get_html_parser})
  end

  def put_http_headers(browser, headers) do
    :ok = GenServer.cast(browser, {:put_http_headers, headers})
    browser
  end

  def get_http_headers(browser) do
    GenServer.call(browser, {:get_http_headers})
  end

  def put_http_header(browser, header) do
    :ok = GenServer.cast(browser, {:put_http_header, header})
    browser
  end

  def put_http_header(browser, key, value) do
    :ok = GenServer.cast(browser, {:put_http_header, key, value})
    browser
  end

  def get_http_header_value(browser, key) do
    GenServer.call(browser, {:get_http_header_value, key})
  end

  def put_follow_redirect(browser, value) do
    :ok = GenServer.cast(browser, {:put_follow_redirect, value})
    browser
  end

  def follow_redirect?(browser) do
    GenServer.call(browser, {:follow_redirect?})
  end

  def put_redirect_limit(browser, limit) do
    :ok = GenServer.cast(browser, {:put_redirect_limit, limit})
    browser
  end

  def get_redirect_limit(browser) do
    GenServer.call(browser, {:get_redirect_limit})
  end

  def put_user_agent(browser, ua_alias) do
    :ok = GenServer.cast(browser, {:put_user_agent, ua_alias})
    browser
  end

  def put_user_agent_string(browser, agent_string) do
    :ok = GenServer.cast(browser, {:put_user_agent_string, agent_string})
    browser
  end

  def get_user_agent_string(ua_alias) when is_atom(ua_alias) do
    __MODULE__.Impl.get_user_agent_string(ua_alias)
  end

  def get_user_agent_string(browser) do
    GenServer.call(browser, {:get_user_agent_string})
  end

  def get!(browser, url, opts \\ []) do
    request!(browser, :get, url, "", opts)
  end

  def head!(browser, url, opts \\ []) do
    request!(browser, :head, url, "", opts)
  end

  def options!(browser, url, opts \\ []) do
    request!(browser, :options, url, "", opts)
  end

  def delete!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :delete, url, body, opts)
  end

  def patch!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :patch, url, body, opts)
  end

  def post!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :post, url, body, opts)
  end

  def put!(browser, url, body \\ "", opts \\ []) do
    request!(browser, :put, url, body, opts)
  end

  def request!(browser, method, url, body \\ "", opts \\ []) do
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

  def request!(browser, req) do
    GenServer.call(browser, {:request!, req})
  end

  def follow_url(browser, %Page{} = page, url) do
    follow_url(browser, page.url, url)
  end

  def follow_url(browser, base_url, url) do
    GenServer.call(browser, {:follow_url, base_url, url})
  end
end
