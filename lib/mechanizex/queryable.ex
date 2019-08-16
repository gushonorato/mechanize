defprotocol Mechanizex.Queryable do
  def attrs(queryable)
  def name(queryable)
  def text(queryable)
end

defimpl Mechanizex.Queryable, for: Any do
  alias Mechanizex.Page.Element
  def attrs(queryable), do: Element.attrs(queryable)
  def name(queryable), do: Element.name(queryable)
  def text(queryable), do: Element.text(queryable)
end
