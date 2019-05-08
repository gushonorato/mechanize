defmodule Mechanize.Page do

  alias Mechanize.{Request, Response}
  defstruct request: nil, response: nil, body: nil, mechanize: nil

  @type t :: %__MODULE__{
    request: Request.t(),
    response: Response.t(),
    body: term()
  }
end
