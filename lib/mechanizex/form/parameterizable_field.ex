defprotocol Mechanize.Form.ParameterizableField do
  @moduledoc false

  def to_param(field)
end

defimpl Mechanize.Form.ParameterizableField, for: Any do
  def to_param(field) do
    [{field.name, field.value}]
  end
end
