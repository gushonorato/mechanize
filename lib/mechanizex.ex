defmodule Mechanizex do

  defdelegate new(options \\ []), to: Mechanizex.Agent
  defdelegate get!(agent, url), to: Mechanizex.Agent

end
