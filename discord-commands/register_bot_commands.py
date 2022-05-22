"""
https://discord.com/developers/docs/interactions/slash-commands#registering-a-command
"""

import os

import requests

APPLICATION_ID = os.environ.get("APPLICATION_ID")
GUILD_ID = os.environ.get("GUILD_ID")
BOT_TOKEN = os.environ.get("BOT_TOKEN")

url = f"https://discord.com/api/v8/applications/{APPLICATION_ID}/guilds/{GUILD_ID}/commands"

json = {
    "name": "container",
    "description": "Start, stop or get the status of a container on synds",
    "options": [
        {
            "name": "container_name",
            "description": "Which container do you want to act on.",
            "type": 3,
            "required": True,
        },
        {
            "name": "action",
            "description": "What do you want to do?",
            "type": 3,
            "required": True,
            "choices": [
                {
                    "name": "status",
                    "value": "status"
                },
                {
                    "name": "start",
                    "value": "start"
                },
                {
                    "name": "stop",
                    "value": "stop"
                }
            ]
        },
    ]
}

headers = {
    "Authorization": f"Bot {BOT_TOKEN}"
}

if __name__ == "__main__":
    r = requests.post(url, headers=headers, json=json)
    print(r.content)
