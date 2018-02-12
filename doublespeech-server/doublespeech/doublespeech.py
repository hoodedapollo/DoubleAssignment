import tornado.httpserver
import tornado.websocket
import tornado.ioloop
import tornado.web
import socket
import time
import json
import random

# default subroute
subroute = "/websocketserver"

#default port
port = "8080"

# Definition of phrase blocks.
# While the greetings and batInfo arrays express simple concepts, the batSuggestion part is more
# connected to the humanization of the robot's personality, by randomly choosing
# a proper sentence related to the actual battery level

greetings = [

    "Hello, ",
    "Good morning, ",
    "Ciao, ",
    "Hi, ",
    "Good to see you, ",
    "Aloha, ",
    "Namaste, "]

batInfo = [

    "my battery level is ",
    "my battery power is ",
    "power is ",
    "iPad's battery is "]

batSuggestion = [

    ". Could you charge me? ",
    ". I'm running out of battery!",
    ". Do you actually want to kill me??",
    ". Please, help! No battery",
    ". I can still make it for a couple of hours",
    ". Don't forget the charger",
    ". As you command Captain!",
    ". I'm in perfect shape, let's go!",
    ". Charged & Fast!"]

#Colors used in console log of the websocket server
#nothing special, but useful to visualize errors clearly

class colors:

    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

##              WEBSOCKET SERVER                ##

#here the websocket is set properly. All the asyncronous functions
#are listed here.

# ON_MESSAGE => handles what happens when a new message is recieved by the ws SERVER
# OPEN => handles the action to be done when a new client is connected
# ON_CLOSE => handles the actions to be done when a client is disconnected

class server(tornado.websocket.WebSocketHandler):
    def open(self):
        # Called when a new connection is enstablished
        localtime = time.asctime(time.localtime(time.time()))
        print (colors.OKBLUE +'[' + localtime + ']'+ colors.ENDC +
            ' - Welcome new client! Ipv6: ' + self.request.remote_ip)

    def on_message(self, message):
        # called when a new message arrives from the clients
        localtime = time.asctime(time.localtime(time.time()))
        print (colors.OKBLUE +'[' + localtime + ']'+ colors.ENDC +
            ' - New Message recieved from: ' + self.request.remote_ip + ' -> ' + message)
        newMessage = messageHandler(message)
        self.write_message(newMessage)

    def on_close(self):
        # called when a connection is closed
        localtime = time.asctime(time.localtime(time.time()))
        print (colors.OKBLUE +'[' + localtime + ']'+ colors.ENDC +
            ' - Bye Bye Client ' + self.request.remote_ip)

    def check_origin(self, origin):
        return True

##                  THE MESSAGE HANDLER             ##

#Here the python server decide which phrase has to be built by using the data recieved by the Double robot
#The exchange format between the two platform is JSON!

def messageHandler(message):

    # Parsing the JSON STRING

    try:
        recievedData = json.loads(message)
    except:
        print(colors.WARNING + "The message recieved is not a valid JSON format!" + colors.ENDC)
        return "Something went wrong! Check server log..."

    # Checking which type of data is recieved
    # Battery status?

    if recievedData["typeID"] == "battery":
        try:
            value = int(recievedData["value"])
        except:
            print colors.WARNING + "invalid battery data" + colors.ENDC
            return "Something went wrong! Check server log..."

        # by looking at the value recieved a phrase is composed.

        if (value >= 0):
            if value <= 20:
                # danger situation
                n = random.randint(0,3)
                return (random.choice(greetings) + recievedData["name"] + ", " + random.choice(batInfo) +
                str(value) + batSuggestion[n])

            if value > 20 and value <= 75:
                # normal situation
                n = random.randint(4,6)
                return (random.choice(greetings) + recievedData["name"] + ", " +
                random.choice(batInfo) + str(value) + batSuggestion[n])

            if value > 75:
                # perfect condition
                n = random.randint(7,8)
                return (random.choice(greetings) + recievedData["name"] + ", " + random.choice(batInfo) +
                str(value) + batSuggestion[n])
        else:
            print colors.WARNING + "invalid value, please provide the correct battery level" + colors.ENDC
            return "Something went wrong! Check server log..."

    #Ip Address ??

    elif recievedData["typeID"] == "ipAddress":
        return recievedData["name"] + ", My ip address is " + recievedData["value"]

    else:
        print(colors.WARNING + "WHAT KIND OF DATA DID YOU SEND ME??" + colors.ENDC)
        return "Invalid data format! Maybe I messed up something..."

##                  MAIN FUNCTION               ##
#Here we start the websocket server on the specified port
#We display our ip and loop the connection

def main():

    try:
        wsServer = tornado.web.Application([
            (subroute, server),
        ])

    except:
        print(colors.WARNING + "Error during the Websocket creation!" + colors.ENDC)

    print (colors.OKGREEN + "Server started correctly!" + colors.ENDC)
    ip = socket.gethostbyname(socket.gethostname())
    feedback = "Listening on " + colors.UNDERLINE + "ws://" + ip + ":" + port + subroute + colors.ENDC + "\n"
    print(feedback)

    http_server = tornado.httpserver.HTTPServer(wsServer)
    http_server.listen(int(port))
    tornado.ioloop.IOLoop.instance().start()
