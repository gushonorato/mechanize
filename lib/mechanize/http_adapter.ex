defmodule Mechanize.HTTPAdapter do
  @callback request!(pid(), Mechanize.Request.t()) :: Mechanize.Response.t()

  defmacro __using__(_) do
    quote do
      @behaviour Mechanize.HTTPAdapter

      def get!(mechanize, url) do
        request!(mechanize, %Mechanize.Request{method: :get, url: url})
      end
    end
  end

  def adapter(adapter_name) do
    Plugin.get(__MODULE__, adapter_name)
  end
end
