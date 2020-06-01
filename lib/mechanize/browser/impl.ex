defmodule Mechanize.Browser.Impl do
  @moduledoc false

  alias Mechanize.{Page, Header, Request}

  defstruct [
    :http_adapter,
    :html_parser,
    :http_headers,
    :follow_redirect,
    :redirect_limit,
    :follow_meta_refresh
  ]

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

  def request!(browser, req) do
    check_request_url!(req)
    resp_chain = request!(browser, req, 0)

    last_response = List.first(resp_chain)

    page = %Page{
      response_chain: resp_chain,
      status_code: last_response.code,
      content: last_response.body,
      url: last_response.url,
      parser: get_html_parser(browser)
    }

    maybe_follow_meta_refresh(browser, page)
  end

  defp maybe_follow_meta_refresh(%__MODULE__{follow_meta_refresh: false}, page), do: page

  defp maybe_follow_meta_refresh(%__MODULE__{follow_meta_refresh: true} = browser, page) do
    case Page.meta_refresh(page) do
      nil ->
        page

      {_delay, nil} ->
        page

      {delay, url} ->
        Process.sleep(delay * 1000)
        follow_url!(browser, page.url, url)
    end
  end

  def follow_url!(browser, base_url, rel_url) do
    abs_url =
      base_url
      |> URI.merge(rel_url)
      |> URI.to_string()

    request!(browser, %Request{method: :get, url: abs_url})
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
end
