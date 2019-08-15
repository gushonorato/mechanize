defmodule Mechanizex.Form.FieldMatcher do
  defmacro __using__(opts) do
    {module, opts} = Keyword.pop(opts, :for)
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
    end
  end
end
