defprotocol Mechanizex.Page.Elementable do
  def element(elementable)
end

defimpl Mechanizex.Page.Elementable, for: Any do
  def element(elementable), do: elementable.element
end
