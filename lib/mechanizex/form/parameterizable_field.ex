defprotocol Mechanizex.Form.ParameterizableField do
  def to_param(field)
end

defimpl Mechanizex.Form.ParameterizableField, for: Any do
  def to_param(field) do
    [{field.name, field.value}]
  end
end
