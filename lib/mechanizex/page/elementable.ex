defprotocol Mechanizex.Page.Elementable do
  def page(elementable)
  def attrs(elementable)
  def name(elementable)
  def text(elementable)
end

defmodule Mechanizex.Page.Elementable.Defaults do
  def page(elementable), do: elementable.element.page
  def attrs(elementable), do: elementable.element.attrs
  def name(elementable), do: elementable.element.name
  def text(elementable), do: elementable.element.text
end

defmodule Mechanizex.Page.Elementable.LabeledElementable do
  defdelegate page(e), to: Mechanizex.Page.Elementable.Defaults
  defdelegate name(e), to: Mechanizex.Page.Elementable.Defaults
  defdelegate text(e), to: Mechanizex.Page.Elementable.Defaults

  def attrs(e) do
    [{"label", e.label} | Mechanizex.Page.Elementable.Defaults.attrs(e)]
  end
end

defimpl Mechanizex.Page.Elementable, for: Any do
  defdelegate page(elementable), to: Mechanizex.Page.Elementable.Defaults
  defdelegate attrs(elementable), to: Mechanizex.Page.Elementable.Defaults
  defdelegate name(elementable), to: Mechanizex.Page.Elementable.Defaults
  defdelegate text(elementable), to: Mechanizex.Page.Elementable.Defaults
end
