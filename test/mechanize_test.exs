defmodule MechanizeTest do
  use ExUnit.Case, async: true
  doctest Mechanize

  describe ".new" do
    test "start a process" do
      agent = Mechanize.new
      assert is_pid(agent)
    end

  end

  describe ".start_link" do
    test "start a process" do
      {:ok, agent } = Mechanize.start_link
      assert is_pid(agent)
    end

    test "start a different agent on each call" do
      {:ok, agent1} = Mechanize.start_link
      {:ok, agent2} = Mechanize.start_link

      refute agent1 == agent2
    end

    test "input options by config file" do
      {:ok, agent} = Mechanize.start_link
      assert Mechanize.option(agent, :foo) == "bar from config"
    end

    test "input options by parameters takes precedence over config file" do
      {:ok, agent} = Mechanize.start_link(foo: "bar from params")
      assert Mechanize.option(agent, :foo) == "bar from params"
    end

    test "input options by params only affects current agent" do
      {:ok, _} = Mechanize.start_link(foo: "bar from params")
      {:ok, agent2} = Mechanize.start_link

      assert Mechanize.option(agent2, :foo) == "bar from config"
    end

    test "http adapter option" do
      {:ok, agent} = Mechanize.start_link(http_adapter: :custom)
      assert Mechanize.http_adapter(agent) == Mechanize.HTTPAdapter.Custom
    end

    test "html parser option" do
      {:ok, agent} = Mechanize.start_link(html_parser: :custom)
      assert Mechanize.html_parser(agent) == Mechanize.HTMLParser.Custom
    end
  end

  describe ".http_adapter" do
    test "default http adapter" do
      default_adapter = Mechanize.new |> Mechanize.http_adapter
      assert default_adapter == Mechanize.HTTPAdapter.Httpoison
    end
  end

  describe ".set_http_adapter" do
    test "returns mechanize agent" do
      agent = Mechanize.new
      assert Mechanize.set_http_adapter(agent, Mechanize.HTTPAdapter.Custom) == agent
    end

    test "updates http adapter" do
      agent = Mechanize.new
        |> Mechanize.set_http_adapter(Mechanize.HTTPAdapter.Custom)

      assert Mechanize.http_adapter(agent) == Mechanize.HTTPAdapter.Custom
    end
  end

  describe ".set_html_parser" do
    test "returns mechanize agent" do
      agent = Mechanize.new
      assert Mechanize.set_html_parser(agent, Mechanize.HTMLParser.Custom) == agent
    end

    test "updates html parser" do
      agent = Mechanize.new
        |> Mechanize.set_html_parser(Mechanize.HTMLParser.Custom)

      assert Mechanize.html_parser(agent) == Mechanize.HTMLParser.Custom
    end
  end
end
