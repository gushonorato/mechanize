defprotocol Mechanize.Queryable do
  @moduledoc false
  def attrs(queryable)
  def name(queryable)
  def text(queryable)
end

defmodule Mechanize.Queryable.Defaults do
  @moduledoc false

  alias Mechanize.Page.Element

  def attrs(queryable) do
    queryable
    |> Map.to_list()
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), value} end)
    |> List.keydelete("element", 0)
    |> Kernel.++(Element.attrs(queryable))
  end

  def name(queryable), do: Element.name(queryable)
  def text(queryable), do: Element.text(queryable)
end

defimpl Mechanize.Queryable, for: Any do
  defdelegate attrs(queryable), to: Mechanize.Queryable.Defaults
  defdelegate name(queryable), to: Mechanize.Queryable.Defaults
  defdelegate text(queryable), to: Mechanize.Queryable.Defaults
end
