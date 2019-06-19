defmodule Mechanizex do
  defdelegate new(options \\ []), to: Mechanizex.Agent
  defdelegate get!(agent, url), to: Mechanizex.Agent
  defdelegate with_form(form, criterias \\ []), to: Mechanizex.Page
  defdelegate fill_field(form, field, options), to: Mechanizex.Form
end
