defmodule Mechanizex.HTTPAdapter do
  alias Mechanizex.{Request, Response}

  @callback request!(Request.t()) :: Response.t()

  defmodule NetworkError do
    defexception [:message, :cause, :url]
  end
end
