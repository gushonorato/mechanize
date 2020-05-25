defmodule Mechanizex.Browser do
  alias Mechanizex.Browser.Impl

  defmodule RedirectLimitReachedError do
    defexception [:message]
  end

  defdelegate new(fields \\ []), to: Impl

  defdelegate put_http_adapter(browser, adapter), to: Impl
  defdelegate get_http_adapter(browser), to: Impl

  defdelegate put_html_parser(browser, parser), to: Impl
  defdelegate get_html_parser(browser), to: Impl

  defdelegate put_http_headers(browser, headers), to: Impl
  defdelegate get_http_headers(browser), to: Impl

  defdelegate put_http_header(browser, header), to: Impl

  defdelegate put_http_header(browser, key, value), to: Impl

  defdelegate get_http_header_value(browser, key), to: Impl

  defdelegate put_follow_redirect(browser, value), to: Impl
  defdelegate follow_redirect?(browser), to: Impl

  defdelegate put_redirect_limit(browser, limit), to: Impl
  defdelegate get_redirect_limit(browser), to: Impl

  defdelegate put_user_agent(browser, ua_alias), to: Impl

  defdelegate put_user_agent_string(browser, agent_string), to: Impl

  defdelegate get_user_agent_string(browser_or_alias), to: Impl

  defdelegate get!(browser, url, params \\ [], headers \\ []), to: Impl

  defdelegate head!(browser, url, params \\ [], headers \\ []), to: Impl

  defdelegate options!(browser, url, params \\ [], headers \\ []), to: Impl

  defdelegate delete!(browser, url, body \\ "", params \\ [], headers \\ []), to: Impl

  defdelegate patch!(browser, url, body \\ "", params \\ [], headers \\ []), to: Impl

  defdelegate post!(browser, url, body \\ "", params \\ [], headers \\ []), to: Impl

  defdelegate put!(browser, url, body \\ "", params \\ [], headers \\ []), to: Impl

  defdelegate request!(browser, req), to: Impl
end
