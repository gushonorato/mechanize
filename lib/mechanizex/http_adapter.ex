defmodule Mechanizex.HTTPAdapter do
  @callback request(pid(), Mechanizex.Request.t()) :: {atom(), Page.t() | Mechanizex.Browser.ConnectionError.t()}

  defmodule NetworkError do
    defexception [:message, :cause]
  end

  def adapter(adapter_name) do
    Plugin.get(__MODULE__, adapter_name)
  end
end
