defmodule Introspection do

  defmacro __using__(_) do
    quote do
      def submodule(name, suffix \\ "")
      def submodule(name, suffix) do
        name =
          name
          |> Atom.to_string()
          |> Kernel.<>(suffix)
          |> Macro.camelize

          Module.concat([__MODULE__, name])
      end
    end
  end
end
