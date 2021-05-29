import requests, json, time, dotenv, os, subprocess, shlex, sys

# function used to add agent_id to the .env file
def edit_env(agent_id):
    envFile = open(".env", "r")
    envData = envFile.readlines()
    envFile.close()

    # save new env file
    envFile = open(".env", "w")

    for i in envData:
        if "agent_id=" in i:
            i = "agent_id=" + agent_id + "\n"
        envFile.write(i)

    envFile.close()

# function used to create an index in elastic
def create_index():
    # load .env file
    try:
        dotenv.load_dotenv()
        hostname = os.getenv("hostname")
        username = os.getenv("username")
        password = os.getenv("password")
        name = os.getenv("name")
        agent_id = os.getenv("agent_id")
        if agent_id != "":
            print("ID already exists")
            return True
    except:
        print("env file error")

    # get interfaces
    interfaces = subprocess.check_output("ip link show | grep -oP '(?<=(\\d:\\s))\\w+'", shell=True).strip().decode().split("\n")
    interface = interfaces[1]

    # get ipv4 address
    ip_addr = subprocess.check_output("ip -4 addr show " + interface + " | grep -oP '(?<=inet\\s)\d+(\\.\\d+){3}' | head -1", shell=True).strip().decode().split("\n")
    ip_addr = ip_addr[0]

    # build json
    data = {
        "interfaces": interfaces,
        "name": name,
        "ip": ip_addr
    }
    data = json.dumps(data)

    # request
    headers = {"kbn-xsrf": "reporting", "Content-Type": "application/json"}
    req = requests.post(hostname + "/api/agent_controller/create", auth=(username, password), headers=headers, data=data)

    # get id
    agent_id = json.loads(req.text)
    agent_id = agent_id["_id"]

    # set agent id to environment variable
    os.environ["agent_id"] = agent_id

    # read env file
    edit_env(agent_id)

    return False