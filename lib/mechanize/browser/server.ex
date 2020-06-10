defmodule Mechanize.Browser.Server do
  @moduledoc false

  use GenServer
  alias Mechanize.Browser.Impl

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:put_http_adapter, adapter}, state) do
    {:noreply, Impl.put_http_adapter(state, adapter)}
  end

  def handle_cast({:put_html_parser, parser}, state) do
    {:noreply, Impl.put_html_parser(state, parser)}
  end

  def handle_cast({:put_http_headers, headers}, state) do
    {:noreply, Impl.put_http_headers(state, headers)}
  end

  def handle_cast({:put_http_header, header}, state) do
    {:noreply, Impl.put_http_header(state, header)}
  end

  def handle_cast({:put_redirect_limit, limit}, state) do
    {:noreply, Impl.put_redirect_limit(state, limit)}
  end

  def handle_cast({:put_follow_redirect, value}, state) do
    {:noreply, Impl.put_follow_redirect(state, value)}
  end

  def handle_cast({:put_http_header, key, value}, state) do
    {:noreply, Impl.put_http_header(state, key, value)}
  end

  def handle_call({:get_http_adapter}, _from, state) do
    {:reply, Impl.get_http_adapter(state), state}
  end

  def handle_call({:get_http_header_value, key}, _from, state) do
    {:reply, Impl.get_http_header_value(state, key), state}
  end

  def handle_call({:get_html_parser}, _from, state) do
    {:reply, Impl.get_html_parser(state), state}
  end

  def handle_call({:get_http_headers}, _from, state) do
    {:reply, Impl.get_http_headers(state), state}
  end

  def handle_call({:follow_redirect?}, _from, state) do
    {:reply, Impl.follow_redirect?(state), state}
  end

  def handle_call({:get_redirect_limit}, _from, state) do
    {:reply, Impl.get_redirect_limit(state), state}
  end

  def handle_call({:current_page}, _from, state) do
    {:reply, Impl.current_page(state), state}
  end

  def handle_call({:request!, req}, _from, state) do
    browser = Impl.request!(state, req)

    {:reply, browser.current_page, browser}
  end

  def handle_call({:follow_url!, base_url, url}, _from, state) do
    {:reply, Impl.follow_url!(state, base_url, url), state}
  end
end
