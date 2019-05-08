defmodule Mechanize.HTTPAdapter do
  defmacro __using__(_) do
    quote do
      @behaviour Mechanize.HTTPAdapter
    end
  end

  @callback request!(pid(), Mechanize.Request.t()) :: Mechanize.Response.t()

  def adapter(mechanize) do
    adapter_name =
      mechanize
      |> Mechanize.get_option(:adapter)
      |> Atom.to_string()
      |> String.capitalize()

    Module.concat([__MODULE__, adapter_name])
  end

  def get!(mechanize, url) do
    request!(mechanize, %Mechanize.Request{method: :get, url: url})
  end

  def request!(mechanize, request) do
    adapter(mechanize).request!(mechanize, request)
  end
end
