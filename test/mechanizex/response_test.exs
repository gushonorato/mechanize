defmodule Mechanize.ResponseTest do
  use ExUnit.Case, async: true

  alias Mechanize.Response

  doctest Mechanize.Response

  @subject %Response{
    url: "https://example.com/search?q=teste",
    headers: [{"Content-type", "text/html"}, {"location", "https://www.example.com/redirected"}],
    code: 301
  }

  describe ".new" do
    @attributes [
      url: "https://example.com/search?q=teste",
      headers: [{"Content-type", "text/html"}, {"location", "https://www.example.com/redirected"}],
      code: 301
    ]
    test "return normalized headers" do
      res = Response.new(@attributes)
      assert res.headers == [{"content-type", "text/html"}, {"location", "https://www.example.com/redirected"}]
    end

    test "fetch location url into field" do
      res = Response.new(@attributes)
      assert res.location == "https://www.example.com/redirected"
    end
  end

  describe ".normalize" do
    test "return normalized headers" do
      res = Response.normalize(@subject)
      assert res.headers == [{"content-type", "text/html"}, {"location", "https://www.example.com/redirected"}]
    end

    test "fetch location url into field" do
      res = Response.normalize(@subject)
      assert res.location == "https://www.example.com/redirected"
    end
  end

  describe ".location" do
    test "return location url from headers" do
      assert Response.location(@subject) == "https://www.example.com/redirected"
    end

    test "return nil if location doesn't exist in headers" do
      assert @subject
             |> Map.put(:headers, [])
             |> Response.location() == nil
    end
  end

  describe ".headers" do
    test "return empty list when no headers found" do
      assert @subject
             |> Map.put(:headers, [])
             |> Response.headers() == []
    end

    test "return all headers" do
      assert @subject
             |> Response.headers() == [
               {"Content-type", "text/html"},
               {"location", "https://www.example.com/redirected"}
             ]
    end
  end
end
