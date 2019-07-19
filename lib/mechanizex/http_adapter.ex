defmodule Mechanizex.HTTPAdapter do
  @callback request(pid(), Mechanizex.Request.t()) ::
              {atom(), Page.t() | Mechanizex.Agent.ConnectionError.t()}

  defmodule Error do
    defexception [:message, :cause]
  end

  def adapter(adapter_name) do
    Plugin.get(__MODULE__, adapter_name)
  end
end
