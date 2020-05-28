defmodule Mechanize.Form.FieldUpdater do
  defmacro __using__(opts) do
    module = __CALLER__.module
    {suffix, _} = Keyword.pop(opts, :suffix, "s")

    module_name =
      module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    quote do
      def unquote(:"update_#{module_name}#{suffix}")(form, fun) do
        Mechanize.Form.update_fields(form, unquote(module), fun)
      end

      def unquote(:"update_#{module_name}#{suffix}_with")(form, criteria, fun) do
        Mechanize.Form.update_fields(form, unquote(module), criteria, fun)
      end
    end
  end
end
