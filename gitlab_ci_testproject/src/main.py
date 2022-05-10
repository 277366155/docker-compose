import datetime
from flask import Flask
import socket
import config

app=Flask(__name__)

@app.route("/")
@app.route("/helloworld")
def hello_world():
    hostname=socket.gethostname()
    ip=socket.gethostbyname(hostname)
    now=datetime.datetime.now()
    return ("ahaha . Hello world , now is : [%s] , here is ： [hostname: %s] - [ip: %s]"%(str(now),hostname,ip))

if __name__=='__main__':
    app.run(config.HOSTURL,config.PORT)