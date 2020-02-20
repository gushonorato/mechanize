defmodule Mechanizex.HTTPAdapter do
  alias Mechanizex.{Request, Response}

  @callback request!(Request.t()) :: Response.t()

  defmodule NetworkError do
    defexception [:message, :cause]
  end

  def adapter(adapter_name) do
    Plugin.get(__MODULE__, adapter_name)
  end
end
