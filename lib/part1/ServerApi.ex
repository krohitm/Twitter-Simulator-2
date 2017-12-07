defmodule ServerApi do
  @moduledoc """
  Contains server logic and functions to be consumed by GenServer
  """

  @doc """
  Helper function to start a distributed Server Node
  """
  def startNode() do
      nodeFullName = "server@127.0.0.1"
      Node.start (String.to_atom(nodeFullName))
      Node.set_cookie :twitter
      IO.inspect {Node.self, Node.get_cookie}
  end

  @doc """
  Sends a tweet to all the followers of a user
  """
  def tweetSubscribers(userPid, tweet_time, tweetText, state) do
    #TODO send only to users that are connected
    #get client id for given username, get its followers, and send them the tweets
    #IO.puts "server sending tweets to clients"
    {:running, indicator_r,indicator_w, sequenceNum, request_hitcount} = state

    cond do 
      rem(request_hitcount+1, 1000) == 0->
        true
        #IO.inspect ["tweet processing time for server", sequenceNum+1, :os.system_time(:milli_seconds) - tweet_time]
        #IO.inspect ["tweet processing time for server", request_hitcount+1, :os.system_time(:milli_seconds)/1000]
      true -> true
    end

    userPid
    |> Engine.getFollowers()
    |> Enum.filter(fn(pid) ->
        Engine.isLoggedIn(pid) == true
      end)
    |> Enum.each(fn(pid) ->
      GenServer.cast(pid, {:receiveTweet, tweet_time, tweetText})
    end)
    state = {:running, indicator_r,indicator_w, sequenceNum, request_hitcount+1}
  end

  @doc """
  Sends a tweet to all the mentions in a tweet
  """
  def tweetMentions(tweetText) do
    tweetText
    |> EngineUtils.extractFromTweet(0, [], "@")
    |> Enum.each(fn(userName) ->
      pid = Engine.getPid(userName)
      cond do
        Engine.isLoggedIn(pid) == true ->
          GenServer.cast(pid, {:receiveTweet, tweetText})
        true -> true
      end
    end)
  end

  #-----------------------------------------------------------------------------
  # Functions for Read and Write actors below

  @doc """
  Helper function used to distribute writes among the 2 Write Actors
  """
  def write(state, clientId, tweetText) do
    #IO.puts "writing tweets to server"
    {_, indicator_r, indicator, sequenceNum, request_hitcount} = state
     [indicator, sequenceNum] =
       cond do
         indicator == 0 ->
           sequenceNum = sequenceNum + 1
           GenServer.cast(:writeActor1, {:write_tweet, clientId, tweetText, sequenceNum})
           [1, sequenceNum]
         true ->
           sequenceNum = sequenceNum + 1
           GenServer.cast(:writeActor2, {:write_tweet, clientId, tweetText, sequenceNum})
           [0, sequenceNum]
       end
    {:running, indicator_r, indicator, sequenceNum, request_hitcount}
  end

  @doc """
  Helper functions used to distribute reads among the 2 Read Actors
  """
  def read(state, {:search, clientId, requestTime}) do
    {_, indicator_r, indicator_w, sequenceNum, request_hitcount} = state
    indicator_r = rem((indicator_r + 1), 1000)
    actorToCall = "readActor"<>Integer.to_string(indicator_r) |> String.to_atom()

    GenServer.cast(actorToCall, {:search, clientId, requestTime, request_hitcount+1})

    {:running, indicator_r, indicator_w, sequenceNum, request_hitcount+1}
  end
  def read(state, {:search_hashtag, clientId, hashtag_list}) do
    {_, indicator_r, indicator_w, sequenceNum, request_hitcount} = state
    indicator_r = rem((indicator_r + 1), 1000)
    actorToCall = "readActor"<>Integer.to_string(indicator_r) |> String.to_atom()

    GenServer.cast(actorToCall, {:search_hashtag, clientId, hashtag_list})

    {:running, indicator_r, indicator_w, sequenceNum, request_hitcount+1}
  end
  def read(state, {:search_mentions, clientId}) do
    {_, indicator_r, indicator_w, sequenceNum, request_hitcount} = state
    indicator_r = rem((indicator_r + 1), 1000)
    actorToCall = "readActor"<>Integer.to_string(indicator_r) |> String.to_atom()
    GenServer.cast(actorToCall, {:search_mentions, clientId})
    {:running, indicator_r, indicator_w, sequenceNum, request_hitcount+1}
  end
  def read(state, {:retweet, clientId, userName, hashtag_list}) do
    {_, indicator_r, indicator_w, sequenceNum, request_hitcount} = state
    indicator_r = rem((indicator_r + 1), 1000)
    actorToCall = "readActor"<>Integer.to_string(indicator_r) |> String.to_atom()

    GenServer.cast(actorToCall, {:retweet, clientId, userName, hashtag_list})

    {:running, indicator_r, indicator_w, sequenceNum, request_hitcount+1}
  end
end
