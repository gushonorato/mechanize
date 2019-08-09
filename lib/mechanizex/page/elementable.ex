defprotocol Mechanizex.Page.Elementable do
  def page(elementable)
  def attrs(elementable)
  def name(elementable)
  def text(elementable)
end

defimpl Mechanizex.Page.Elementable, for: Any do
  def page(elementable), do: elementable.element.page
  def attrs(elementable), do: elementable.element.attrs
  def name(elementable), do: elementable.element.name
  def text(elementable), do: elementable.element.text
end
