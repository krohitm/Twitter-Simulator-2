defmodule WriteTweet do
  @moduledoc """
  This is an actor that handles the writes to database
  When a user tweets, the tweet is written to the tweet ets table

  The main server process delegates writes to the Actor
  """
  use GenServer

  @doc """
  Writes a tweet. A tweet contains hashtags, mentions and the tweet text; each
  having their own ets table.
  """
  def handle_cast({:write_tweet, clientId, tweetText, sequenceNum}, state) do
    Engine.writeTweet(clientId, tweetText, sequenceNum)
    #IO.inspect sequenceNum
    cond do
      rem(sequenceNum, 1000) == 0 ->
        true
         #IO.inspect [sequenceNum, DateTime.utc_now]#:os.system_time(:milli_seconds)]
      true ->
        true
    end
    {:noreply, state}
  end

  def init(state) do
    {:ok, state}
  end
end
