// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channelsList, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

//let socket = new Socket("/socket", {params: {token: window.userToken}})

var numClients
var channelsList = []
var socketsList = []
let maxClients = 1000
let userFollowers = {}
let userNamesList = []
let userName
let messageContainer = document.querySelector('#messages')
var clientsProcessed = 0


register()

function register(){
  for (numClients = 0; numClients < maxClients; numClients++){
    userName = "user_"+numClients
    let socket = new Socket("/socket", {params: {token: window.userToken, userName: userName}})
    userNamesList[numClients] = userName
    userFollowers[userName] = []
    socket.connect()
    socketsList[numClients] = socket
    let channel = socket.channel("room:lobby", {})
    channelsList[numClients] = channel

    //join the new client
    channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

    //register the new client
    channel.push("register", userName)
    .receive("registered" , resp => console.log("registered", resp))
  }

  for (let channel of channelsList){
    channel.on("registered", payload => {
      clientsProcessed++

      if (clientsProcessed === maxClients){
        subscribe()
      }
    })
  }
}

//give subscribers to each client
function subscribe() {
  var numSubscribers, subscribersList;
  for (numClients = 0; numClients < maxClients; numClients++){
    numSubscribers = Math.floor((maxClients-2)/(numClients+1)) //following zipf distribution
    if (numSubscribers == 0){
      numSubscribers = 1
    }
    subscribersList = getRandom(userNamesList, numSubscribers)
    var user = userNamesList[numClients]
    channelsList[numClients].push("subscribe", {username: user, usersToSub: subscribersList})
    .receive("subscribed", resp => console.log("subscribed", user))
  }

   var clientssubscribed= 0

  for (var i = 0; i<maxClients; i++){
    channelsList[i].on("subscribed", payload => {
      clientssubscribed++
      console.log("subscribed", clientssubscribed)

      if (clientssubscribed === maxClients){
        simulation()
      }
    })
  }
}

/**function to send tweets */

 function sendTweet(i){
   console.log("sending tweets")
   var numUsers = userNamesList.length
   var mention, tweetText, numSubscribers, interval
 
   //for (var i = 0; i < numUsers; i++){
     mention = getRandom(userNamesList, 1)
     tweetText = "tweet@"+mention+getHashtag()
     console.log(tweetText)
     numSubscribers = userFollowers[userNamesList[i]].len
     //interval = Math.floor(maxClients/numSubscribers) * minInterval

     channelsList[i].push("tweet_subscribers", {tweetText: tweetText,
       username: userNamesList[i], time: `${Date()}`})
   //}
 }

var clearCounter = 0

var check = 0
function simulation(){
  console.log("simulation started")
  while (true){
    for (var i = 0; i < userNamesList.length; i++){
      //sendTweet(10, i)
      //console.log("checking behavior")
      //if(clearCounter%1000 == 0) messageContainer.innerHTML = ""
      var runBehavior = getRandom(["send_tweet","search", "search_hashtag", "search_mentions"], 1)
      switch (runBehavior[0]){
        case("send_tweet"):
        console.log("sending tweet", userNamesList[i])
        sendTweet(i)
        case("search"):
        console.log("searching", userNamesList[i])
        channelsList[i].push("search", {username: userNamesList[i], time: `${Date()}`})
        break
        case("search_hashtag"):
        console.log("searching for hashtag", userNamesList[i])
        var hashtagList = [getHashtag()]
        channelsList[i].push("search_hashtag", {username: userNamesList[i], hashtagList: hashtagList, time: `${Date()}`})
        break
        case("search_mentions"):
        console.log("searching for mentions", userNamesList[i])
        channelsList[i].push("search_mentions", {username: userNamesList[i], time: `${Date()}`})
        break
        default:
        break
      }
      clearCounter++
    }
    //check += 1
  }
}


/////////////////////////////////////////////////////////////////////////////
//EVENT LISTENERS BELOW THIS

/**event listener to receive tweet from 
 * the user this user has subscribed to*/
for (let channel of channelsList){
  channel.on("tweet_sub", payload => {
    let messageItem = document.createElement("li");
    messageItem.innerText = `Tweeted: [${Date()}] ${payload.tweetText}`
    messageContainer.appendChild(messageItem)
  })
}

/**even listener to receive search results as tweets from a 
 * paticular user who's tweet are searched for */
for (let channel of channelsList){
  channel.on("search_result", payload => {
    let messageItem = document.createElement("li");
    messageItem.innerText = `search result: [${Date()}] ${payload.searched_tweet}`
    messageContainer.appendChild(messageItem)
  })
}

/**event listener to receive tweets for a particular 
 * hashtag searched for by this user */
for (let channel of channelsList){
  channel.on("search_hashtag", payload => {
    let messageItem = document.createElement("li");
    messageItem.innerText = `search hashtag: [${Date()}] ${payload.searched_tweet}`
    messageContainer.appendChild(messageItem)
  })
}

/**event listener to receive tweets for 
 * mentions searched by this user */
for (let channel of channelsList){
  channel.on("search_mentions", payload => {
    let messageItem = document.createElement("li");
    messageItem.innerText = `search mentions: [${Date()}] ${payload.searched_tweet}`
    messageContainer.appendChild(messageItem)
  })
}


//////////////////////////////////////////////////////////////////////////////////////////////////////
/**ALL HELPER FUNCTIONS BELOW THIS */

/** function to get random subscribers*/
function getRandom(arr, n, i) {
  var result = new Array(n),
  len = arr.length,
  taken = new Array(len);
  if (n > len)
    throw new RangeError("getRandom: more elements taken than available");
  while (n--) {
    var x = randNum(arr, i);
    result[n] = arr[x in taken ? taken[x] : x];
    taken[x] = --len;
  }
  return result;
}

function randNum(arr,excludeNum){
  var randNumber = Math.floor(Math.random()*arr.length);
  if(arr[randNumber]==excludeNum){
      return randNum(arr,excludeNum);
  }else{
      return randNumber;
  }
}

/**function to get random hashtag */
function getHashtag(){
  var hashList = ["#marketing", "#marketingtips", "#b2cmarketing",
  "#b2bmarketing", "#strategy", "#mktg", "#digitalmarketing",
  "#marketingstrategy", "#mobilemarketing", "#socialmediamarketing",
  "#promotion", "#food", "#yummy", "#nom", "#hungry", "#cleaneating",
  "#vegetarian", "#wine", "#sushi", "#birthday", "#red", "#workout",
  "#sweet",  "#wedding", "#blackandwhite"]
  return hashList[Math.floor(Math.random() * hashList.length)]
}


export default socketsList