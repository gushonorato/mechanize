defmodule Plugin do
  def get(behavior_name, plugin_name, suffix \\ "")

  def get(behavior_name, plugin_name, suffix) do
    plugin_name =
      plugin_name
      |> Atom.to_string()
      |> Kernel.<>(suffix)
      |> Macro.camelize()

    Module.concat([behavior_name, plugin_name])
  end
end
