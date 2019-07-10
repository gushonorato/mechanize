defmodule Mechanizex do
  defdelegate new(options \\ []), to: Mechanizex.Agent
  defdelegate get!(agent, url), to: Mechanizex.Agent
  defdelegate with_form(form, criterias \\ []), to: Mechanizex.Page
  defdelegate click_link(agent, criterias), to: Mechanizex.Page
  defdelegate fill_field(form, field, options), to: Mechanizex.Form
  defdelegate submit(form), to: Mechanizex.Form
end
