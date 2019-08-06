defmodule Mechanizex.Form.FieldMatchHelper do
  defmacro __using__(_opts) do
    quote do
      import Mechanizex.Form.FieldMatchHelper
    end
  end

  defmacro field_match_helper_for(module, opts \\ [])

  defmacro field_match_helper_for(module, opts) do
    {suffix, _} = Keyword.pop(opts, :suffix, "s")

    module_name =
      module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    quote do
      def unquote(:"#{module_name}#{suffix}")(form), do: unquote(:"#{module_name}#{suffix}_with")(form, [])

      def unquote(:"#{module_name}#{suffix}_with")(form, criteria) do
        Mechanizex.Form.fields_with(form, unquote(module), criteria)
      end

      def unquote(:"update_#{module_name}#{suffix}")(form, fun) do
        Mechanizex.Form.update_fields(form, unquote(module), fun)
      end

      def unquote(:"update_#{module_name}#{suffix}_with")(form, criteria, fun) do
        Mechanizex.Form.update_fields(form, unquote(module), criteria, fun)
      end
    end
  end
end
