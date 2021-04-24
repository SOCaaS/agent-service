import requests, json, time, dotenv, os, subprocess, shlex, sys
# use subprocess
flag = True
try:

    # get env variables
    try:
        dotenv.load_dotenv()
        hostname = os.getenv("hostname")
        username = os.getenv("username")
        password = os.getenv("password")
        agent_id = os.getenv("agent_id")
        suricata_rulefile_path = os.getenv("suricata_rulefile_path")
        
    except:
        print("env file error")

    tshark_rules = [{}]
    old_suricata_rulelist = [{}]
    tshark_status = False
    suricata_status = False
    suricata_process = ""
    counter = 0

    # build tshark_rules
    req = requests.get(hostname + "/api/agent_controller/" + agent_id, auth=(username, password))
    agent_dict = json.loads(req.text)
    for i in agent_dict["services"]["tshark"]["rules"]:
        tshark_rules[counter]["active"] = False
        counter += 1

    while flag:
        # request from api
        req = requests.get(hostname + "/api/agent_controller/" + agent_id, auth=(username, password))

        # check status code
        if req.status_code != 200:
            print("Error" + req.status_code)
            flag = False

        print(req.text)

        # convert json into dict
        agent_dict = json.loads(req.text)

        # used for iteration
        counter = 0

        # check if tshark is active
        if agent_dict["services"]["tshark"]["active"]:
            tshark_status = True

            # iterate over the tshark rules
            for i in agent_dict["services"]["tshark"]["rules"]:
                i["details"].replace("$interface", agent_dict["interface"])
                
                # check if old and new is the same
                if i["active"] == tshark_rules[counter]["active"] and i["details"] == tshark_rules[counter]["details"]:
                    continue
                
                # check if both old and new is inactive
                elif i["active"] == tshark_rules[counter]["active"] and i["active"] == False:
                    continue

                # apply changes
                else:
                    if tshark_rules[counter]["active"] == True:
                        tshark_rules[counter]["process"].terminate()
                    tshark_rules[counter]["active"] = i["active"]
                    tshark_rules[counter]["details"] = i["details"]
                    
                    
                    if i["active"] == True:
                        
                        try:
                            # run process
                            process_details = shlex.split(i["details"])
                            tshark_rules[counter]["process"] = subprocess.Popen(process_details)

                            # check if process does not run
                            if tshark_rules[counter]["process"].poll() != None:
                                print("Tshark error at rule " + str(counter) + ": " +  i["details"])
                                tshark_rules[counter]["active"] = False

                        except:
                            print("Tshark error at rule " + str(counter) + ": " +  i["details"])
                            tshark_rules[counter]["active"] = False
                        
                    else:
                        try:
                            # check if process is running
                            if tshark_rules[counter]["process"].poll() == None:
                                # try to terminate
                                tshark_rules[counter]["process"].terminate()
                        except:
                            print("Unable to terminate rule " + str(counter) + ": " +  i["details"])
                                    

                counter += 1
        
        # if tshark needs to be turned off
        elif agent_dict["services"]["tshark"]["active"] == False and tshark_status == True:
            tshark_status = False
            
            # turn everything off
            for i in tshark_rules:
                if i["active"] == True:
                    i["process"].terminate()
                    i["active"] = False

        # check if suricata is active
        if agent_dict["services"]["suricata"]["active"]:
            
            suricata_rulelist = []

            # iterate over suricata rules
            for i in agent_dict["services"]["suricata"]["rules"]:
                if i["active"] == False:
                    continue
                else:
                    suricata_rulelist.append(i["details"].replace("$interface", agent_dict["interface"]))
            
            # check for changes and apply changes to file
            if suricata_rulelist != old_suricata_rulelist:
                old_suricata_rulelist = suricata_rulelist
                suricata_rule_file = open(suricata_rulefile_path, "r+")
                suricata_rule_file.read()
                suricata_rule_file.seek(0)
                for i in suricata_rulelist:
                    suricata_rule_file.write(i)
                suricata_rule_file.truncate()
                suricata_rule_file.close()

                # restart suricata
                if suricata_status == True:
                    # stop suricata
                    subprocess.run(shlex.split("systemctl stop suricata"))
                
                # start suricata
                subprocess.run(shlex.split("systemctl start suricata"))
                suricata_status = True
                

        
        elif agent_dict["services"]["suricata"]["active"] == False and suricata_status == True:
            # turn off suricata
            subprocess.run(shlex.split("systemctl stop suricata"))
            suricata_status = False

        # print status
        print("Tshark status: " + str(tshark_status))
        print("Suricata status: " + str(suricata_status))

        # wait 120 seconds
        time.sleep(120)
        

# try to cleanup on keyboard interrupt
except KeyboardInterrupt:
    print('\nCleaning up')
    try:
        # turn off tshark and suricata
        for i in tshark_rules:
            if i["active"] == True:
                i["process"].terminate()
                i["active"] = False
        subprocess.run(shlex.split("systemctl stop suricata"))
        sys.exit(0)
    except SystemExit:
        os._exit(0)

