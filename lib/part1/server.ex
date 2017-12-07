defmodule Server do
  @moduledoc """
  Module to handle all the calls to the Server
  """
  use GenServer

  def init(state) do
    Enum.each(0..1000, fn(index)->
      actorName = "readActor"<>Integer.to_string(index) |> String.to_atom()
      GenServer.start(ReadTweets, :running, name: actorName)
    end)
    # GenServer.start(ReadTweets, :running, name: :readActor1)
    # GenServer.start(ReadTweets, :running, name: :readActor2)
    GenServer.start(WriteTweet, :running, name: :writeActor1)
    GenServer.start(WriteTweet, :running, name: :writeActor2)
    {:ok, state}
  end

  def handle_call(:start, from, state) do
    ServerApi.startNode()
    Engine.initTables()
    {:reply, :started, state}
  end
  # handle call for registering a new process,
  # needs to be handle call only since can't tweet until registered
  def handle_call({:register, userName}, clientPid, state) do
    Engine.register(clientPid |> elem(0), userName)
    IO.inspect "registered user"
    {:reply, :registered, state}
  end
  # handle_cast to subscribe user/client to another user/client
  def handle_call({:subscribe, usersToSub}, clientPid, state) do
    {clientPid, _} = clientPid
    # usersToSub is a list of pid's
    usersToSub |> Enum.each(fn(userName)->
      userPid = Engine.getPid(userName)
      Engine.subscribe(clientPid, userPid)
    end)
    {:reply, {:subscribed}, state}
  end
  # LOGOUT and LOGIN
  def handle_cast({:login, userName}, state) do
    clientPid = Engine.getPid(userName)
    Engine.login(clientPid)
    {:noreply, state}
  end
  def handle_cast({:logout, userName}, state) do
    clientPid = Engine.getPid(userName)
    Engine.logout(clientPid)
    {:noreply, state}
  end
  #-----------------------------------------------------------------------------
  # Write and send tweets to subscribers
  def handle_cast({:tweet_subscribers, tweet_time, tweetText, userName}, state) do
    clientId = Engine.getPid(userName)
    state = ServerApi.write(state, clientId, tweetText)
    state = ServerApi.tweetSubscribers(clientId, tweet_time, tweetText, state)
    ServerApi.tweetMentions(tweetText)
    {:noreply, state}
  end
  #-----------------------------------------------------------------------------
  # Handle search requests by clients
  def handle_cast({:search, userName, requestTime}, state) do
    #IO.puts "searching for tweets"
    clientId = Engine.getPid(userName)
    state = ServerApi.read(state, {:search, clientId, requestTime})
    {:noreply, state}
  end
  def handle_cast({:search_hashtag, userName, hashtag_list}, state) do
    clientId = Engine.getPid(userName)
    state = ServerApi.read(state, {:search_hashtag, clientId, hashtag_list})
    {:noreply, state}
  end
  def handle_cast({:search_mentions, userName}, state) do
    #IO.puts "searching for mentions"
    clientId = Engine.getPid(userName)
    state = ServerApi.read(state, {:search_mentions, clientId})
    {:noreply, state}
  end
  def handle_cast({:retweet, userName, hashtag_list}, state) do
    clientId = Engine.getPid(userName)
    state = ServerApi.read(state, {:retweet, clientId, userName, hashtag_list})
    {:noreply, state}
  end
end
