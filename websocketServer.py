import tornado.httpserver
import tornado.websocket
import tornado.ioloop
import tornado.web
import socket
import time
import json

class colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

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
            ' - Bye Bye ' + self.request.remote_ip)

    def check_origin(self, origin):
        return True


def messageHandler(message):
    try:
        value = int(message)
    except ValueError:
        return "invalid string!"

    if(value >= 0):

        if(value < 6):
            return "Please charge me, I'm dying..."
        if(value < 20) and (value > 5):
            return "I have to sleep, but i can still make it for a couple of hours"
        if (value < 51) and (value > 19):
            return "I'm a little bit tired, but i can still work if you need!"
        if (value > 50) and (value < 71):
            return "Ready to operate! At your orders Captain"
        if(value > 70) and (value < 96):
            return "Charged & Fast!"
        if(value > 95):
            return "I'm in perfect shape, let's go!"
        else:
            return "invalid value, please provide the correct battery level"
    else:
        return "invalid value, please provide the correct battery level"

wsServer = tornado.web.Application([
    (r'/websocketserver', server),
])


http_server = tornado.httpserver.HTTPServer(wsServer)
http_server.listen(4040)
tornado.ioloop.IOLoop.instance().start()
