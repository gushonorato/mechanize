defprotocol Mechanizex.Page.Elementable do
  def element(e)
end

defimpl Mechanizex.Page.Elementable, for: Any do
  def element(e), do: e.element
end
