defmodule Mechanizex.Header do
  @type t :: {String.t(), String.t()}
  @type headers :: list(Header.t())

  def merge(headers1, headers2) do
    Enum.uniq_by(headers2 ++ headers1, &elem(&1, 0))
  end

  def prepend(headers, {key, value}) do
    prepend(headers, key, value)
  end

  def prepend(headers, key, value) do
    [{normalize_key(key), value} | headers]
  end

  def delete(headers, key) do
    Enum.reject(headers, fn {k, _v} -> normalize_key(k) == normalize_key(key) end)
  end

  def put(headers, {key, value}) do
    put(headers, key, value)
  end

  def put(headers, key, value) do
    List.keystore(headers, normalize_key(key), 0, {normalize_key(key), value})
  end

  def take(headers, key) do
    List.keytake(headers, normalize_key(key), 0)
  end

  def get(headers, key) do
    normalized_key = normalize_key(key)

    case List.keytake(headers, normalized_key, 0) do
      {{^normalized_key, value}, _list} -> value
      _ -> nil
    end
  end

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
