defmodule Mechanizex.HTTPAdapter do
  @callback request(pid(), Mechanizex.Request.t()) :: {atom(), Page.t() | Mechanizex.Agent.ConnectionError.t()}

  def adapter(adapter_name) do
    Plugin.get(__MODULE__, adapter_name)
  end
end
