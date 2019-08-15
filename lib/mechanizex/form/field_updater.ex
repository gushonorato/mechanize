defmodule Mechanizex.Form.FieldUpdater do
  defmacro __using__(opts) do
    {module, opts} = Keyword.pop(opts, :for)
    {suffix, _} = Keyword.pop(opts, :suffix, "s")

    module_name =
      module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    quote do
      def unquote(:"update_#{module_name}#{suffix}")(form, fun) do
        Mechanizex.Form.update_fields(form, unquote(module), fun)
      end

      def unquote(:"update_#{module_name}#{suffix}_with")(form, criteria, fun) do
        Mechanizex.Form.update_fields(form, unquote(module), criteria, fun)
      end
    end
  end
end
