import requests, json, time, dotenv, os, subprocess, shlex, sys
import function

def main():
    #get env variable
    try:
        hostname = os.getenv("hostname")
        username = os.getenv("username")
        password = os.getenv("password")
        agent_id = os.getenv("agent_id")
    except:
        print("env file error")

    #Delete id on exit
    print("\nDelete elasticsearch document on exit")
    headers = {"kbn-xsrf": "reporting", "Content-Type": "application/json"}
    req = requests.post(hostname + "/api/agent_controller/"+agent_id+"/delete", auth=(username, password), headers=headers)

    #Clear from ENV
    function.edit_env("")