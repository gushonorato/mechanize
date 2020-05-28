defprotocol Mechanize.Page.Elementable do
  def element(e)
end

defimpl Mechanize.Page.Elementable, for: Any do
  def element(e), do: e.element
end
