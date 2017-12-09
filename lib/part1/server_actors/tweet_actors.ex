defmodule TweetActors do
  @moduledoc """
  This is an Actor to handle the incoming tweets to the Server
  The Server distributes the work of sending tweets among many such TweetActors
  """
  use GenServer
  use Phoenix.Channel
  @doc """
  Sends a tweet to the followers of a user
  Also sends the tweet to the mentions inside a tweet
  """
  def handle_cast({:tweet_subscribers, userPid, tweet_time, tweetText, event}, state) do
    userPid # userPid is a socket
    |> Engine.getFollowers()
    |> Enum.filter(fn(pid) ->
        Engine.isLoggedIn(pid) == true
      end)
    |> Enum.each(fn(pid) ->
      push pid, event, tweetText
    end)

    tweetText
    |> EngineUtils.extractFromTweet(0, [], "@")
    |> Enum.each(fn(userName) ->
      pid = Engine.getPid(userName)
      cond do
        Engine.isLoggedIn(pid) == true ->
          push pid, event, tweetText
          # GenServer.cast(pid, {:receiveTweet, tweetText})
        true -> true
      end
    end)

    {:noreply, state}
  end

  def init(state) do
    {:ok, state}
  end
end
