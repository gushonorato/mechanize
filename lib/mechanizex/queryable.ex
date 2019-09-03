defprotocol Mechanizex.Queryable do
  def attrs(queryable)
  def name(queryable)
  def text(queryable)
end

defmodule Mechanizex.Queryable.Defaults do
  alias Mechanizex.Page.Element

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

defimpl Mechanizex.Queryable, for: Any do
  defdelegate attrs(queryable), to: Mechanizex.Queryable.Defaults
  defdelegate name(queryable), to: Mechanizex.Queryable.Defaults
  defdelegate text(queryable), to: Mechanizex.Queryable.Defaults
end
