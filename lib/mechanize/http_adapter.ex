defmodule Mechanize.HTTPAdapter do
  use Introspection

  defmacro __using__(_) do
    quote do
      @behaviour Mechanize.HTTPAdapter
    end
  end

  @callback request!(pid(), Mechanize.Request.t()) :: Mechanize.Response.t()

  def get!(mechanize, url) do
    request!(mechanize, %Mechanize.Request{method: :get, url: url})
  end

  def request!(mechanize, request) do
    adapter(mechanize).request!(mechanize, request)
  end

  defp adapter(mechanize) do
    mechanize
    |> Mechanize.get_option(:adapter)
    |> submodule
  end
end
