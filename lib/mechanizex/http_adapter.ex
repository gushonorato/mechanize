defmodule Mechanizex.HTTPAdapter do
  @callback request!(pid(), Mechanizex.Request.t()) :: Mechanizex.Response.t()

  defmacro __using__(_) do
    quote do
      @behaviour Mechanizex.HTTPAdapter

      def get!(mechanize, url) do
        request!(mechanize, %Mechanizex.Request{method: :get, url: url})
      end
    end
  end

  def adapter(adapter_name) do
    Plugin.get(__MODULE__, adapter_name)
  end
end
