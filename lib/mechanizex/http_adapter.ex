defmodule Mechanize.HTTPAdapter do
  alias Mechanize.{Request, Response}

  @callback request!(Request.t()) :: Response.t()

  defmodule NetworkError do
    defexception [:message, :cause, :url]
  end
end
