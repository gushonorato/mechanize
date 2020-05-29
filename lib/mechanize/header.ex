defmodule Mechanize.Header do
  @type t :: {String.t(), String.t()}
  @type headers :: list(Header.t())

  def merge(nil, _headers2), do: raise(ArgumentError, "headers1 is nil")
  def merge(headers1, nil), do: headers1

  def merge(headers1, headers2) do
    Enum.uniq_by(headers2 ++ headers1, &elem(&1, 0))
  end

  def prepend(nil, _header), do: raise(ArgumentError, "headers is nil")
  def prepend(headers, nil), do: headers

  def prepend(headers, {key, value}) do
    prepend(headers, key, value)
  end

  def prepend(nil, _key, _value), do: raise(ArgumentError, "headers is nil")
  def prepend(_headers, nil, _value), do: raise(ArgumentError, "key is nil")
  def prepend(_headers, _key, nil), do: raise(ArgumentError, "value is nil")

  def prepend(headers, key, value) do
    [{normalize_key(key), value} | headers]
  end

  def delete(nil, _key), do: raise(ArgumentError, "headers is nil")
  def delete(headers, nil), do: headers

  def delete(headers, key) do
    Enum.reject(headers, fn {k, _v} -> normalize_key(k) == normalize_key(key) end)
  end

  def put(nil, _header), do: raise(ArgumentError, "headers is nil")
  def put(headers, nil), do: headers

  def put(headers, {key, value}) do
    put(headers, key, value)
  end

  def put(nil, _key, _value), do: raise(ArgumentError, "headers is nil")
  def put(_headers, nil, _value), do: raise(ArgumentError, "key is nil")
  def put(_headers, _key, nil), do: raise(ArgumentError, "value is nil")

  def put(headers, key, value) do
    List.keystore(headers, normalize_key(key), 0, {normalize_key(key), value})
  end

  def take(nil, _key), do: raise(ArgumentError, "headers is nil")
  def take(_headers, nil), do: nil

  def take(headers, key) do
    List.keytake(headers, normalize_key(key), 0)
  end

  def get_value(nil, _key), do: raise(ArgumentError, "headers is nil")
  def get_value(_headers, nil), do: nil

  def get_value(headers, key) do
    normalized_key = normalize_key(key)

    case List.keytake(headers, normalized_key, 0) do
      {{^normalized_key, value}, _list} -> value
      _ -> nil
    end
  end

  def get_all(nil, _key), do: raise(ArgumentError, "headers is nil")
  def get_all(_headers, nil), do: []

  def get_all(headers, key) do
    Enum.filter(headers, fn {k, _v} -> normalize_key(k) == normalize_key(key) end)
  end

  def normalize_key(k) do
    String.downcase(k)
  end

  def normalize({k, v}) do
    {normalize_key(k), v}
  end

  def normalize(headers) do
    Enum.map(headers, &normalize/1)
  end
end
