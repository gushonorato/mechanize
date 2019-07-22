defprotocol Mechanizex.Page.Elementable do
  def element(elementable)
  def put_element(elementable, element)
end

defimpl Mechanizex.Page.Elementable, for: Any do
  def element(elementable), do: elementable.element
  def put_element(elementable, element), do: %{elementable | element: element}
end
