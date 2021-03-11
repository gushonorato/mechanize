defmodule Mechanize.Request do
  alias Mechanize.Header

  @default_params []
  @default_options []
  @default_body ""

  @enforce_keys [:url]
  defstruct method: :get, url: nil, headers: [], body: @default_body, params: @default_params, options: @default_options

  @type body() :: {atom(), Enum.t()} | binary()
  @type params() :: Enum.t()
  @type options() :: Enum.t()
  @type t :: %__MODULE__{
          method: atom(),
          url: binary(),
          params: params(),
          headers: Header.headers(),
          options: options(),
          body: body()
        }

  def normalize(%__MODULE__{} = req) do
    req
    |> normalize_headers()
    |> reject_invalid_params()
    |> maybe_normalize_params()
    |> normalize_body()
  end

  defp normalize_headers(%__MODULE__{} = req) do
    %__MODULE__{req | headers: Header.normalize(req.headers)}
  end

  defp reject_invalid_params(%__MODULE__{} = req) do
    %__MODULE__{req | params: Enum.reject(req.params, &param_invalid?/1)}
  end

  defp param_invalid?(param) do
    case param do
      {"", _} -> true
      {nil, _} -> true
      _ -> false
    end
  end

  defp maybe_normalize_params(%__MODULE__{} = req) do
    if Enum.empty?(req.params) do
      req
    else
      normalize_params(req)
    end
  end

  defp normalize_params(%__MODULE__{} = req) do
    url =
      req.url
      |> URI.merge("?" <> URI.encode_query(req.params))
      |> URI.to_string()

    req
    |> Map.put(:url, url)
    |> Map.put(:params, @default_params)
  end

  defp normalize_body(%__MODULE__{method: :get} = req), do: Map.put(req, :body, @default_body)
  defp normalize_body(%__MODULE__{method: :head} = req), do: Map.put(req, :body, @default_body)
  defp normalize_body(%__MODULE__{method: :options} = req), do: Map.put(req, :body, @default_body)

  defp normalize_body(%__MODULE__{} = req) do
    case req.body do
      {:form, params} ->
        %__MODULE__{
          req
          | body: URI.encode_query(params),
            headers: Header.prepend(req.headers, "content-type", "application/x-www-form-urlencoded")
        }

      _ ->
        req
    end
  end
end
