defmodule Mechanizex.Form.GenericField do
  defmacro __using__(_opts) do
    quote do
      def is_type?(field) do
        field.__struct__ == __MODULE__
      end
    end
  end

  def to_param(field) do
    Mechanizex.Form.ParameterizableField.to_param(field)
  end
end
