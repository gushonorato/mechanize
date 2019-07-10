defmodule Mechanizex.HTTPAdapter do
  @callback request!(pid(), Mechanizex.Request.t()) :: Mechanizex.Response.t()

  def adapter(adapter_name) do
    Plugin.get(__MODULE__, adapter_name)
  end
end
