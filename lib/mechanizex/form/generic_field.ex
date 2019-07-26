defmodule Mechanizex.Form.GenericField do
  defmacro __using__(_opts) do
    quote do
      def is_type?(field) do
        field.__struct__ == __MODULE__
      end
    end
  end
end
