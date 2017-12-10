defmodule Engine do
  @moduledoc """
  This module creates various ets tables for the application. It also comes
  with various functions to deal with these tables.
  For the part II this module has been turned into a GenServer and added as a worker in the
  application's supervision tree.
  NOTE: The PID's in the previous version have been replaced with sockets. However, these
  namings have not been changed

  We have the following tables for our application
  users - user_id (key), username, followers | mapping of a c and client's alias
  following - user_id (key), listOfPeopleIFollow | a list of people I follow
  tweets - user_id (key), [[tweet_id, tweetText]] | contains tweet data.
           Tweets are a list of lists. Each element is a tweet
  hashtag - hashtag (key), [[tweet_id, tweetText]] | quick access of tweets for a given hashtag
  userPid - username (key), pid | mapping of username and pid
  userMentions - user_id (key), [[tweet_id, tweetText]]
           A list of tweets where a user is mentioned
  loggedInUsers - userId, logged_in flag
          logged_in if true = user is logged in else user is logged out

  Types -
  user_id: socket
  username: String.t
  followers: socket | a list of user_id's followers
  listOfPeopleIFollow: list of sockets's
  tweet_id: number | a sequence number, used in place of a timestamp
  hashtag: String.t
  """
  use GenServer

  def start_link(opts \\ []) do
  {:ok, _pid} = GenServer.start_link(Engine, [], opts)
  end

  #function to initialize in-memory tables
  def init(args) do
    #initialize all tables. See moduledoc for details
    :ets.new(:users, [:set, :public, :named_table])
    :ets.new(:following, [:set, :public, :named_table])
    :ets.new(:tweets, [:set, :public, :named_table, {:read_concurrency, true}, {:write_concurrency, true}])
    :ets.new(:hashtag, [:set, :public, :named_table, {:read_concurrency, true}, {:write_concurrency, true}])
    :ets.new(:userPid, [:set, :public, :named_table])
    :ets.new(:userMentions, [:set, :public, :named_table, {:read_concurrency, true}, {:write_concurrency, true}])
    :ets.new(:loggedInUsers, [:set, :public, :named_table])
    {:ok, :running}
  end

  #userName is client's socket
  def register(clientPid, userName) do
    :ets.insert_new(:users, {clientPid, userName, []})
    # IO.inspect ["Engine prints ===", :ets.member(:userPid, userName), clientPid]
    :ets.insert_new(:userPid, {userName, clientPid})
    :ets.insert_new(:loggedInUsers, {clientPid, :true})
  end

  @doc """
  Subscribe the clientPid to the userToSubPid
  Upon subscription, the clientPid becomes a follower of userToSubPid

  The userToSubPid is also added to clientPid's 'list of people I follow'
  This association is made by also inserting in the :following table
  """
  #TODO userToSubPid can be changed to userName, just as it would happen in a normal tweet
  def subscribe(userToSubPid, clientPid) do
    [{userToSubPid, userName, followers}] = :ets.lookup(:users, userToSubPid)
    followers = followers ++ [clientPid]
    :ets.insert(:users, {userToSubPid, userName, followers})

    # also insert in the :following table
    toFollow = cond do
      :ets.member(:following, clientPid) ->
        [{_, listOfPeopleIFollow}] = :ets.lookup(:following, clientPid)
        listOfPeopleIFollow ++ [userToSubPid]
      true -> [userToSubPid]
    end
    :ets.insert(:following, {clientPid, toFollow})
  end

  @doc """
  Takes as input a clientPid, tweetText contaning hashtag and mentions, a sequenceNum
  Makes an insertion in - tweets, hashtag, userMentions
  """
  def writeTweet(clientPid, tweetText, sequenceNum) do
    tweet = cond do
      :ets.member(:tweets, clientPid) ->
        [{_, tweet_list}] = :ets.lookup(:tweets, clientPid)
        [[sequenceNum, tweetText]] ++ tweet_list
      true ->
        [[sequenceNum, tweetText]]
    end
    :ets.insert(:tweets, {clientPid, tweet})

    # insertion into the hashtag table
    EngineUtils.extractFromTweet(tweetText, 0, [], "#")
      |> Enum.each(fn(hashtag) ->
          tweet = cond do
            :ets.member(:hashtag, hashtag) ->
              [{_, tweet_list}] = :ets.lookup(:hashtag, hashtag)
              [[sequenceNum, tweetText]] ++ tweet_list
            true -> [[sequenceNum, tweetText]]
          end
          :ets.insert(:hashtag, {hashtag, tweet})
      end)

    # insertion into the userMentions table
    EngineUtils.extractFromTweet(tweetText, 0, [], "@")
      |> Enum.each(fn(mention)->
        mention = Engine.getPid(mention)
        #IO.inspect ["PIDs of mentions", mention]
        #mention = EngineUtils.mentionToPid(mention)
        tweet = cond do
          :ets.member(:userMentions, mention) ->
            [{_, tweet_list}] = :ets.lookup(:userMentions, mention)
            [[sequenceNum, tweetText]] ++ tweet_list
          true -> [[sequenceNum, tweetText]]
        end
        :ets.insert(:userMentions, {mention, tweet})
    end)
  end

  @doc """
  LOGIN a client
  """
  def login(clientPid) do
    :ets.insert(:loggedInUsers, {clientPid, :true})
  end

  @doc """
  LOGOUT a client
  """
  def logout(clientPid) do
    :ets.insert(:loggedInUsers, {clientPid, :false})
  end

  #----------------------------------------------------------------------------
  # Below: functions that only read from database
  # Do not add write functions

  @doc """
  Returns a list of pid's of followers for a given pid
  """
  # @spec getFollowers(pid) :: list
  def getFollowers(userPid) do
    [{_, _, follower_list}] = :ets.lookup(:users, userPid)
    follower_list
  end

  @doc """
  Returns a list of pid's of all the users, a pid is following
  """
  # @spec getFollowing(pid) :: list
  def getFollowing(clientPid) do
    [{_, peopleIFollow}] = :ets.lookup(:following, clientPid)
    peopleIFollow
  end

  @doc """
  Returns the pid, given a username
  """
  # @spec getPid(String.t) :: pid
  def getPid(userName) do
    [{_, pid}] = :ets.lookup(:userPid, userName)
    pid
  end

  @doc """
  Returns all the tweets of a given pid (user/client)
  """
  # @spec getTweets(pid) :: list
  def getTweets(clientPid) do
    #TODO sort tweets based on sequence number in descending order
    cond do
      :ets.member(:tweets, clientPid) ->
        [{_, tweet_list}]= :ets.lookup(:tweets, clientPid)
        tweet_list
      true -> []
    end
  end

  @doc """
  Usage: getTweetHavingHashtag
  Pass a hashtag to get a list in return as below
  hashtag = "studentLife"
  [tweetText1, tweetText2] = Engine.getTweetHavingHashtag(hashtag)
  TODO Returned list is sorted based on sequence number (desc)
  """
  # @spec getTweetsHavingHashtag(String.t) :: list
  def getTweetsHavingHashtag(hashtag) do
    #IO.inspect hashtag
    #TODO do the sorting of tweets
    cond do
      :ets.member(:hashtag, hashtag) ->
        [{_, tweet_list}] = :ets.lookup(:hashtag, hashtag)
        tweet_list
      true -> []
    end
  end

  @doc """
  Returns a list of tweets where a pid has been mentioned
  """
  # @spec getMentions(pid) :: list
  def getMentions(clientPid) do
    #TODO sorting tweets
    cond do
        :ets.member(:userMentions, clientPid) ->
            [{_, tweet_list}] = :ets.lookup(:userMentions, clientPid)
            tweet_list
        true -> []
    end
  end

  @doc """
  Returns true if a user is logged in, else false
  Eg: isLoggedIn(self()) will return true or false
  """
  def isLoggedIn(clientPid) do
    [{_, flag}] = :ets.lookup(:loggedInUsers, clientPid)
    flag == :true
  end
end

defmodule EngineUtils do
  @moduledoc """
  Utility functions for Engine module
  """

  @doc """
  Turns a mention into a pid
    eg: mention = '<0.81.0>'
    mention |> EngineUtils.mentionToPid
    This transforms the mention into a pid - #PID<0.81.0>
  Warning: :erlang.list_to_pid should only be used for debugging purposes
    This dependency should be removed in future version
  """
  @spec mentionToPid(String.t) :: pid
  def mentionToPid(mention) do
    :erlang.list_to_pid('#{mention}')
  end

  @doc """
  Function to extract hashtags and mentions from a tweet
    Eg: check test cases for how this works
  """
  @spec extractFromTweet(String.t, integer, list, String.t) :: list
  def extractFromTweet(tweetText, index, list, htOrMention) do
    cond do
      String.length(tweetText) == 0 -> list
      index == String.length(tweetText) - 1 -> list
      String.at(tweetText, index) == htOrMention -> extractFromTweet(tweetText, index+1, list, "", htOrMention)
      true-> extractFromTweet(tweetText, index+1, list, htOrMention)
    end
  end
  @spec  extractFromTweet(String.t, integer, list, String.t, String.t) :: list
  def extractFromTweet(tweetText, index, list, acc, htOrMention) do
    cond do
      index == String.length(tweetText) - 1 ->
        cond do
          String.at(tweetText, index) == htOrMention -> list ++ [String.trim(acc)]
          true ->
            acc = acc<>String.at(tweetText, index)
            list ++ [String.trim(acc)]
        end
      String.at(tweetText, index) == "@" || String.at(tweetText, index) == "#"->
        cond do
          String.at(tweetText, index) == htOrMention ->
            list = list ++ [String.trim(acc)]
            extractFromTweet(tweetText, index+1, list, "", htOrMention)
          true ->
            list = list ++ [String.trim(acc)]
            extractFromTweet(tweetText, index+1, list, htOrMention)
        end
      true ->
        acc = acc<>String.at(tweetText, index)
        extractFromTweet(tweetText, index+1, list, acc, htOrMention)
    end
  end
end
