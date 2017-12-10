// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channelsList, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

//let socket = new Socket("/socket", {params: {token: window.userToken}})

var numClients
var channelsList = []
var socketsList = []
let maxClients = 3
let userFollowers = {}
let userNamesList = []
let userName
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
  .receive("registered", resp => console.log("registered", resp))
}


//give subscribers to each client
setTimeout(() => {
  var numSubscribers, subscribersList;
  for (var i = 0; i < maxClients; i++){
    numSubscribers = Math.floor((maxClients-2)/(i+1)) //following zipf distribution
    if (numSubscribers == 0){
      numSubscribers = 1
    }
    subscribersList = getRandom(userNamesList, numSubscribers, i)
    channelsList[i].push("subscribe", {username: userNamesList[i], usersToSub: subscribersList})
    .receive("subscribed", resp => console.log("subscribed", resp))
  }
  //setTimeout(simulation(), 5000000)
}, 3000)

/**function to send tweets */
function sendTweet(minInterval){
  console.log("sending tweets")
  var numUsers = userNamesList.length
  var mention, tweetText, numSubscribers, interval

  for (var i = 0; i < numUsers; i++){
    mention = getRandom(userNamesList, 1)
    tweetText = "tweet@"+mention+getHashtag()
    console.log(tweetText)
    numSubscribers = userFollowers[userNamesList[i]].len
    interval = Math.floor(maxClients/numSubscribers) * minInterval

    channelsList[i].push("tweet_subscribers", {tweetText: tweetText, 
      username: userNamesList[i], time: `${Date()}`})
  }
}


var check = 0
function simulation(){
  while (check <= 1){
    for (var i = 0; i < userNamesList.length; i++){
      setInterval(sendTweet(10), 2)
      //console.log("checking behavior")
      var runBehavior = getRandom(["search", "search_hashtag", "search_mentions", "retweet"], 1)
      switch (runBehavior[0]){
        case("search"):
        console.log("searching", userNamesList[i])
        channelsList[i].push("search", {username: userNamesList[i], time: `${Date()}`})
        break
        case("search_hashtag", userNamesList[i]):
        console.log("searching for hashtag")
        hashtagList = [getHashtag]
        channelsList[i].push("search_hashtag", {username: userNamesList[i], hashtagList: hashtagList, time: `${Date()}`})
        break
        case("search_mentions", userNamesList[i]):
        console.log("searching for mentions")
        channelsList[i].push("search_mentions", {username: userNamesList[i], time: `${Date()}`})
        break
        case("retweet"):
        console.log("retweeting", userNamesList[i])
        var hashtagList = [getHashtag]
        channelsList[i].push("retweet", {username: userNamesList[i], hashtagList: hashtagList, time: `${Date()}`})
        break
        default:
        break
      }
    }
    check += 1
  }
}

//window.setTimeout(simulation(), 5000000000)

//let channel = socket.channel("room:lobby", {})
//let chatInput = document.querySelector('#chat-input')
let messageContainer = document.querySelector('#messages')

/*chatInput.addEventListener("keypress", event => {
  if (event.keyCode === 13){
    channel.push("new_msg", {body: chatInput.value})
    chatInput.value = ""
  }
})*/

/*channelsList[0].on("tweet_subscribers", payload => {
  let messageItem = document.createElement("li");
  messageItem.innerText = `[${Date()}] ${payload.tweetText}`//'[${Date()}] ${payload.body}'
  messageContainer.appendChild(messageItem)
})*/

//////////////////////////////////////////////////////////////////////////////////////////////////////
/**All helper functions below this */


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