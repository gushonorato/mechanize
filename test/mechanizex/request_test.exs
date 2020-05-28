defmodule Mechanize.RequestTest do
  use ExUnit.Case, async: true

  alias Mechanize.{Request, Header}

  doctest Mechanize.Request

  @subject %Request{url: "https://example.com/search?q=teste"}

  describe ".normalize" do
    test "downcase all headers" do
      result =
        @subject
        |> Map.put(:headers, [{"FOO", "BAR"}, {"Location", "https://example.com/redirect"}])
        |> Request.normalize()
        |> Map.get(:headers)

      assert result == [{"foo", "BAR"}, {"location", "https://example.com/redirect"}]
    end

    test "merge params into url" do
      fixtures = [
        {[], "https://example.com/search?q=teste"},
        {[{"", ""}, {"q", "10"}], "https://example.com/search?q=10"},
        {[{nil, ""}, {"q", "10"}], "https://example.com/search?q=10"},
        {[{nil, nil}, {"q", "10"}], "https://example.com/search?q=10"},
        {[{"p", nil}, {"q", "10"}], "https://example.com/search?p=&q=10"},
        {[{"p", ""}], "https://example.com/search?p="},
        {[{"p", 10}], "https://example.com/search?p=10"},
        {[{"p", "10"}], "https://example.com/search?p=10"},
        {[{"p", "10"}, {"q", "lero"}], "https://example.com/search?p=10&q=lero"},
        {%{}, "https://example.com/search?q=teste"},
        {%{"" => ""}, "https://example.com/search?q=teste"},
        {%{nil => ""}, "https://example.com/search?q=teste"},
        {%{nil => nil}, "https://example.com/search?q=teste"},
        {%{p: nil}, "https://example.com/search?p="},
        {%{p: 10}, "https://example.com/search?p=10"},
        {%{p: ""}, "https://example.com/search?p="},
        {%{"p" => ""}, "https://example.com/search?p="},
        {%{p: "10"}, "https://example.com/search?p=10"},
        {%{p: "10", q: "lero"}, "https://example.com/search?p=10&q=lero"},
        {%{"p" => "10"}, "https://example.com/search?p=10"},
        {%{"p" => "10", "q" => "lero"}, "https://example.com/search?p=10&q=lero"}
      ]

      Enum.each(fixtures, fn {params, expected} ->
        result =
          @subject
          |> Map.put(:params, params)
          |> Request.normalize()
          |> Map.get(:url)

        assert result == expected, ~s(expected "#{expected}" but got "#{result}" with params=#{inspect(params)})
      end)
    end

    test "ignore body on bodyless requests" do
      [:get, :options, :head]
      |> Enum.each(fn method ->
        assert %Request{method: method, url: "https://www.example.com", body: "q=teste&p=10"}
               |> Request.normalize()
               |> Map.get(:body) == ""
      end)
    end

    test "passing form into body" do
      [:post, :put, :patch, :delete]
      |> Enum.each(fn method ->
        assert %Request{
                 method: method,
                 url: "https://www.example.com",
                 body: {:form, [{"q", "teste"}, {:p, 10}]}
               }
               |> Request.normalize()
               |> Map.get(:body) == "q=teste&p=10"
      end)
    end

    test "passing raw data into body" do
      [:post, :put, :patch, :delete]
      |> Enum.each(fn method ->
        assert %Request{
                 method: method,
                 url: "https://www.example.com",
                 body: Jason.encode!(%{q: "teste", p: 10})
               }
               |> Request.normalize()
               |> Map.get(:body) == ~s({"p":10,"q":"teste"})
      end)
    end

    test "adds correct content-type depending on body data" do
      [:post, :put, :patch, :delete]
      |> Enum.each(fn method ->
        req =
          Request.normalize(%Request{
            method: method,
            url: "https://www.example.com",
            body: {:form, [{"q", "teste"}, {"p", "10"}]}
          })

        assert Header.get_value(req.headers, "content-type") == "application/x-www-form-urlencoded"
      end)
    end

    test "do not add content-type header on bodyless requests" do
      [:get, :options, :head]
      |> Enum.each(fn method ->
        req =
          Request.normalize(%Request{
            method: method,
            url: "https://www.example.com"
          })

        assert Header.get_value(req.headers, "content-type") == nil
      end)
    end

    test "params is aways empty list after normalization" do
      assert %Request{
               method: :get,
               url: "https://www.example.com",
               params: [{"q", "teste"}, {"p", "10"}]
             }
             |> Request.normalize()
             |> Map.get(:params) == []
    end
  end
end
