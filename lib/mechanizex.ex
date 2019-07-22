defmodule Mechanizex do
  defdelegate new(options \\ []), to: Mechanizex.Agent
  defdelegate get!(agent, url), to: Mechanizex.Agent
  defdelegate form_with(form, criterias \\ []), to: Mechanizex.Page
  defdelegate click_link(agent, criterias), to: Mechanizex.Page
  defdelegate fill_field(form, field, options), to: Mechanizex.Form
  defdelegate submit(form, button \\ nil), to: Mechanizex.Form
  defdelegate click_button(form, locator), to: Mechanizex.Form
end
