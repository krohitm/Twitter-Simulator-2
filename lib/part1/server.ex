defmodule Server do
  @moduledoc """
  Module to handle all the calls to the Server
  """
  use GenServer

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(Server, [], opts)
  end

  def init(args) do
    indicator_r = 0 # For the ReadActor
    indicator_w = 0 # For the WriteActor
    indicator_s = 0 # This is for the TweetActors
    sequenceNum = 0
    request_hitcount = 0
    state = {:running, indicator_r, indicator_w, indicator_s, sequenceNum, request_hitcount}

   Enum.each(0..1000, fn(index)->
     actorName = "readActor"<>Integer.to_string(index) |> String.to_atom()
     GenServer.start(ReadTweets, :running, name: actorName)
   end)
   Enum.each(0..1000, fn(index)->
     actorName = "tweetActor"<>Integer.to_string(index) |> String.to_atom()
     GenServer.start(TweetActors, :running, name: actorName)
   end)
   # GenServer.start(ReadTweets, :running, name: :readActor1)
   # GenServer.start(ReadTweets, :running, name: :readActor2)
   GenServer.start(WriteTweet, :running, name: :writeActor1)
   GenServer.start(WriteTweet, :running, name: :writeActor2)
   {:ok, state}
 end
  # Below Won't be used in the current implementation
  def handle_call(:start, from, state) do
    # ServerApi.startNode()
    # Engine.initTables()
    {:reply, :started, state}
  end
  # handle call for registering a new process,
  # needs to be handle call only since can't tweet until registered
  def handle_call({:register, userName, socket}, clientPid, state) do
    Engine.register(clientPid |> elem(0), userName)
    # Engine.register(clientPid, userName)
    IO.inspect "registered user"
    {:reply, :registered, state}
  end
  # handle_cast to subscribe user/client to another user/client
  def handle_call({:subscribe, usersToSub, uName}, clientPid, state) do
    #{clientPid, _} = clientPid
    # socket = Engine.getPid(uName)
    # usersToSub is a list of pid's
    clientPid = Engine.getPid(uName)
    usersToSub |> Enum.each(fn(userName)->
      userPid = Engine.getPid(userName) #userPid is a socket
      Engine.subscribe(clientPid, userPid)
    end)
    {:reply, {:subscribed}, state}
  end
  # LOGOUT and LOGIN
  def handle_cast({:login, userName}, state) do
    clientPid = Engine.getPid(userName) #clientPid is a socket
    Engine.login(clientPid)
    {:noreply, state}
  end
  def handle_cast({:logout, userName}, state) do
    clientPid = Engine.getPid(userName) #clientPid is a socket
    Engine.logout(clientPid)
    {:noreply, state}
  end
  #-----------------------------------------------------------------------------
  # Write and send tweets to subscribers
   def handle_cast({:tweet_subscribers, tweet_time, tweetText, userName, event}, state) do
     clientId = Engine.getPid(userName) #clientPid is a pid not socket
     state = ServerApi.tweetSubscribers(clientId, tweet_time, tweetText, state, event)
     state = ServerApi.write(state, clientId, tweetText)
     #DO NOT uncomment, already handled in tweetActor -> ServerApi.tweetMentions(tweetText)
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
