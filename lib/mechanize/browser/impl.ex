defmodule Mechanize.Browser.Impl do
  @moduledoc false

  alias Mechanize.{Page, Header, Request}

  defstruct [
    :http_adapter,
    :html_parser,
    :http_headers,
    :follow_redirect,
    :redirect_limit,
    :follow_meta_refresh,
    :current_page
  ]

  @opaque t :: %__MODULE__{
            http_adapter: any(),
            html_parser: any(),
            http_headers: keyword(),
            follow_redirect: boolean(),
            redirect_limit: integer(),
            follow_meta_refresh: boolean(),
            current_page: Page.t()
          }

  def new(opts \\ []) do
    %__MODULE__{}
    |> put_http_adapter(opts[:http_adapter])
    |> put_html_parser(opts[:html_parser])
    |> put_http_headers(opts[:http_headers])
    |> put_follow_redirect(opts[:follow_redirect])
    |> put_redirect_limit(opts[:redirect_limit])
    |> put_follow_meta_refresh(opts[:follow_meta_refresh])
  end

  def put_http_adapter(browser, adapter), do: %__MODULE__{browser | http_adapter: adapter}
  def get_http_adapter(browser), do: browser.http_adapter

  def put_html_parser(browser, parser), do: %__MODULE__{browser | html_parser: parser}
  def get_html_parser(browser), do: browser.html_parser

  def put_http_headers(browser, headers),
    do: %__MODULE__{browser | http_headers: Header.normalize(headers)}

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

  def put_follow_meta_refresh(browser, value), do: %__MODULE__{browser | follow_meta_refresh: value}
  def follow_meta_refresh?(browser), do: browser.follow_meta_refresh

  def current_page(browser) do
    browser.current_page
  end

  def request!(browser, req) do
    check_request_url!(req)

    browser
    |> request!(req, 0)
    |> create_current_page(browser)
    |> maybe_follow_meta_refresh()
  end

  defp maybe_follow_meta_refresh(%__MODULE__{follow_meta_refresh: false} = browser), do: browser

  defp maybe_follow_meta_refresh(%__MODULE__{follow_meta_refresh: true} = browser) do
    page = browser.current_page

    case Page.meta_refresh(page) do
      nil ->
        browser

      {_delay, nil} ->
        browser

      {delay, url} ->
        follow_meta_refresh(browser, delay, url)
    end
  end

  def resolve_url(nil, _url) do
    raise ArgumentError, "page_or_base_url is nil"
  end

  def resolve_url(%Page{} = page, url) do
    resolve_url(page.url, url)
  end

  def resolve_url(base_url, url) do
    base_url
    |> URI.merge(url || "")
    |> URI.to_string()
  end

  defp follow_meta_refresh(browser, delay, url) do
    Process.sleep(delay * 1000)
    request!(browser, %Request{method: :get, url: resolve_url(browser.current_page, url)})
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
        raise Mechanize.Browser.RedirectLimitReachedError,
              "Redirect limit of #{get_redirect_limit(browser)} reached"

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

  defp create_current_page([response | _] = response_chain, browser) do
    %__MODULE__{
      browser
      | current_page: %Page{
          response_chain: response_chain,
          status_code: response.code,
          content: response.body,
          url: response.url,
          parser: get_html_parser(browser),
          browser: self()
        }
    }
  end
end
