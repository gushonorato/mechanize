defmodule Mechanizex.AgentTest do
  use ExUnit.Case, async: true
  alias Mechanizex.HTTPAdapter
  doctest Mechanizex.Agent

  describe ".new" do
    test "start a process" do
      agent = Mechanizex.Agent.new
      assert is_pid(agent)
    end

  end

  describe ".start_link" do
    test "start a process" do
      {:ok, agent } = Mechanizex.Agent.start_link
      assert is_pid(agent)
    end

    test "start a different agent on each call" do
      {:ok, agent1} = Mechanizex.Agent.start_link
      {:ok, agent2} = Mechanizex.Agent.start_link

      refute agent1 == agent2
    end

    test "input options by config file" do
      {:ok, agent} = Mechanizex.Agent.start_link
      assert Mechanizex.Agent.option(agent, :foo) == "bar from config"
    end

    test "input options by parameters takes precedence over config file" do
      {:ok, agent} = Mechanizex.Agent.start_link(foo: "bar from params")
      assert Mechanizex.Agent.option(agent, :foo) == "bar from params"
    end

    test "input options by params only affects current agent" do
      {:ok, _} = Mechanizex.Agent.start_link(foo: "bar from params")
      {:ok, agent2} = Mechanizex.Agent.start_link

      assert Mechanizex.Agent.option(agent2, :foo) == "bar from config"
    end

    test "http adapter option" do
      {:ok, agent} = Mechanizex.Agent.start_link(http_adapter: :custom)
      assert Mechanizex.Agent.http_adapter(agent) == Mechanizex.HTTPAdapter.Custom
    end

    test "html parser option" do
      {:ok, agent} = Mechanizex.Agent.start_link(html_parser: :custom)
      assert Mechanizex.Agent.html_parser(agent) == Mechanizex.HTMLParser.Custom
    end
  end

  describe ".http_adapter" do
    test "default http adapter" do
      default_adapter = Mechanizex.Agent.new |> Mechanizex.Agent.http_adapter
      assert default_adapter == HTTPAdapter.Httpoison
    end
  end

  describe ".set_http_adapter" do
    test "returns mechanizex agent" do
      agent = Mechanizex.Agent.new
      assert Mechanizex.Agent.set_http_adapter(agent, Mechanizex.HTTPAdapter.Custom) == agent
    end

    test "updates http adapter" do
      agent = Mechanizex.Agent.new
        |> Mechanizex.Agent.set_http_adapter(Mechanizex.HTTPAdapter.Custom)

      assert Mechanizex.Agent.http_adapter(agent) == Mechanizex.HTTPAdapter.Custom
    end
  end

  describe ".set_html_parser" do
    test "returns mechanizex agent" do
      agent = Mechanizex.Agent.new
      assert Mechanizex.Agent.set_html_parser(agent, Mechanizex.HTMLParser.Custom) == agent
    end

    test "updates html parser" do
      agent = Mechanizex.Agent.new
        |> Mechanizex.Agent.set_html_parser(Mechanizex.HTMLParser.Custom)

      assert Mechanizex.Agent.html_parser(agent) == Mechanizex.HTMLParser.Custom
    end
  end
end
