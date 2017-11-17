
# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-17 16:52:52

#Using python to creat client side connection from Julia
from websocket import create_connection
ws = create_connection("ws://localhost:2000")
print("Sending Message")
ws.send('{"requestType":"setready"}')


#result =  ws.recv()
#print("Received '%s'" % result)
#ws.close()
