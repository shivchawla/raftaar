
# @Author: Shiv Chawla
# @Date:   2017-11-17 11:20:21
# @Last Modified by:   Shiv Chawla
# @Last Modified time: 2017-11-18 12:46:13

#Using python to creat client side connection from Julia
from websocket import create_connection
import sys

host="127.0.0.1"
port=8000

try:
	host=sys.argv[1]
	port=int(sys.argv[2])
finally:
	conn="ws://{}:{}".format(host,port)
	print("Connecting: {}".format(conn))
	ws = create_connection(conn)
	print("Sending Message")
	ws.send('{"requestType":"setready"}')
