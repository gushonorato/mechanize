defmodule MechanizexTest do
  use ExUnit.Case, async: true
  doctest Mechanizex

  describe ".new" do
    test "start a process" do
      agent = Mechanizex.new
      assert is_pid(agent)
    end

  end

  describe ".start_link" do
    test "start a process" do
      {:ok, agent } = Mechanizex.start_link
      assert is_pid(agent)
    end

    test "start a different agent on each call" do
      {:ok, agent1} = Mechanizex.start_link
      {:ok, agent2} = Mechanizex.start_link

      refute agent1 == agent2
    end

    test "input options by config file" do
      {:ok, agent} = Mechanizex.start_link
      assert Mechanizex.option(agent, :foo) == "bar from config"
    end

    test "input options by parameters takes precedence over config file" do
      {:ok, agent} = Mechanizex.start_link(foo: "bar from params")
      assert Mechanizex.option(agent, :foo) == "bar from params"
    end

    test "input options by params only affects current agent" do
      {:ok, _} = Mechanizex.start_link(foo: "bar from params")
      {:ok, agent2} = Mechanizex.start_link

      assert Mechanizex.option(agent2, :foo) == "bar from config"
    end

    test "http adapter option" do
      {:ok, agent} = Mechanizex.start_link(http_adapter: :custom)
      assert Mechanizex.http_adapter(agent) == Mechanizex.HTTPAdapter.Custom
    end

    test "html parser option" do
      {:ok, agent} = Mechanizex.start_link(html_parser: :custom)
      assert Mechanizex.html_parser(agent) == Mechanizex.HTMLParser.Custom
    end
  end

  describe ".http_adapter" do
    test "default http adapter" do
      default_adapter = Mechanizex.new |> Mechanizex.http_adapter
      assert default_adapter == Mechanizex.HTTPAdapter.Httpoison
    end
  end

  describe ".set_http_adapter" do
    test "returns mechanizex agent" do
      agent = Mechanizex.new
      assert Mechanizex.set_http_adapter(agent, Mechanizex.HTTPAdapter.Custom) == agent
    end

    test "updates http adapter" do
      agent = Mechanizex.new
        |> Mechanizex.set_http_adapter(Mechanizex.HTTPAdapter.Custom)

      assert Mechanizex.http_adapter(agent) == Mechanizex.HTTPAdapter.Custom
    end
  end

  describe ".set_html_parser" do
    test "returns mechanizex agent" do
      agent = Mechanizex.new
      assert Mechanizex.set_html_parser(agent, Mechanizex.HTMLParser.Custom) == agent
    end

    test "updates html parser" do
      agent = Mechanizex.new
        |> Mechanizex.set_html_parser(Mechanizex.HTMLParser.Custom)

      assert Mechanizex.html_parser(agent) == Mechanizex.HTMLParser.Custom
    end
  end
end
