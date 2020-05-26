defmodule Mechanizex.Browser do
  alias Mechanizex.Request

  defmodule RedirectLimitReachedError do
    defexception [:message]
  end

  def new(fields \\ []) do
    {:ok, browser} = GenServer.start_link(__MODULE__.Server, __MODULE__.Impl.new(fields))
    browser
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
    GenServer.call(browser, {:request!, req})
  end
end
