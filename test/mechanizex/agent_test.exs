defmodule Mechanizex.AgentTest do
  use ExUnit.Case, async: true
  alias Mechanizex.HTTPAdapter
  doctest Mechanizex.Agent

  setup do
    {:ok, agent: start_supervised!(Mechanizex.Agent)}
  end

  describe ".new" do
    test "start a process", %{agent: agent} do
      assert is_pid(agent)
    end
  end

  describe ".start_link" do
    test "start a process" do
      {:ok, agent} = Mechanizex.Agent.start_link()
      assert is_pid(agent)
    end

    test "start a different agent on each call" do
      {:ok, agent1} = Mechanizex.Agent.start_link()
      {:ok, agent2} = Mechanizex.Agent.start_link()

      refute agent1 == agent2
    end
  end

  describe "http default headers" do
    test "initial header values", %{agent: agent} do
      assert Mechanizex.Agent.http_headers(agent) == %{
               "user-agent" =>
                 "Mechanizex/#{Mix.Project.config()[:version]} Elixir/#{System.version()} (http://github.com/gushonorato/mechanizex/)",
                 "foo" => "bar" #loaded by config env
             }
    end

    test "set headers", %{agent: agent} do
      Mechanizex.Agent.set_http_headers(agent, %{"content-type" => "text/html"})
      assert Mechanizex.Agent.http_headers(agent) == %{"content-type" => "text/html"}
    end

    test "add headers", %{agent: agent} do
      Mechanizex.Agent.add_http_headers(agent, %{"content-type" => "text/html"})

      assert Mechanizex.Agent.http_headers(agent) == %{
               "user-agent" =>
                 "Mechanizex/#{Mix.Project.config()[:version]} Elixir/#{System.version()} (http://github.com/gushonorato/mechanizex/)",
               "content-type" => "text/html",
               "foo" => "bar" #loaded by config env
             }

      Mechanizex.Agent.add_http_headers(agent, %{"content-type" => "application/javascript"})

      assert Mechanizex.Agent.http_headers(agent) == %{
               "user-agent" =>
                 "Mechanizex/#{Mix.Project.config()[:version]} Elixir/#{System.version()} (http://github.com/gushonorato/mechanizex/)",
               "content-type" => "application/javascript",
               "foo" => "bar" #loaded by config env
             }
    end

    test "set on init overrides foo=>bar config" do
      agent = Mechanizex.Agent.new(http_headers: %{"custom-header" => "value"})

      assert Mechanizex.Agent.http_headers(agent) == %{
               "custom-header" => "value",
               "user-agent" =>
                 "Mechanizex/#{Mix.Project.config()[:version]} Elixir/#{System.version()} (http://github.com/gushonorato/mechanizex/)"
             }
    end
  end

  describe ".set_user_agent_alias" do
    test "set by alias", %{agent: agent} do
      Mechanizex.Agent.set_user_agent_alias(agent, :windows_chrome)

      assert Mechanizex.Agent.http_headers(agent) == %{
               "user-agent" =>
                 "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.125 Safari/537.36",
                "foo" => "bar" #loaded by config env
             }
    end

    test "set on init" do
      agent = Mechanizex.Agent.new(user_agent_alias: :windows_chrome)

      assert Mechanizex.Agent.http_headers(agent) == %{
               "user-agent" =>
                 "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.125 Safari/537.36",
                "foo" => "bar" #loaded by config env
             }
    end

    test "raise error when invalid alias passed", %{agent: agent} do
      assert_raise Mechanizex.Agent.InvalidUserAgentAlias, fn ->
        Mechanizex.Agent.set_user_agent_alias(agent, :windows_chrom)
      end
    end
  end

  describe ".http_adapter" do
    test "configure on init" do
      {:ok, agent} = Mechanizex.Agent.start_link(http_adapter: :custom)
      assert Mechanizex.Agent.http_adapter(agent) == Mechanizex.HTTPAdapter.Custom
    end

    test "default http adapter", %{agent: agent} do
      assert Mechanizex.Agent.http_adapter(agent) == HTTPAdapter.Httpoison
    end
  end

  describe ".set_http_adapter" do
    test "returns agent", %{agent: agent} do
      assert Mechanizex.Agent.set_http_adapter(agent, Mechanizex.HTTPAdapter.Custom) == agent
    end

    test "updates http adapter", %{agent: agent} do
      Mechanizex.Agent.set_http_adapter(agent, Mechanizex.HTTPAdapter.Custom)
      assert Mechanizex.Agent.http_adapter(agent) == Mechanizex.HTTPAdapter.Custom
    end
  end

  describe ".set_html_parser" do
    test "returns mechanizex agent", %{agent: agent} do
      assert Mechanizex.Agent.set_html_parser(agent, Mechanizex.HTMLParser.Custom) == agent
    end

    test "updates html parser", %{agent: agent} do
      Mechanizex.Agent.set_html_parser(agent, Mechanizex.HTMLParser.Custom)
      assert Mechanizex.Agent.html_parser(agent) == Mechanizex.HTMLParser.Custom
    end

    test "html parser option" do
      {:ok, agent} = Mechanizex.Agent.start_link(html_parser: :custom)
      assert Mechanizex.Agent.html_parser(agent) == Mechanizex.HTMLParser.Custom
    end
  end
end
