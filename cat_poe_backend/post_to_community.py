import os
import sys

import requests
from dotenv import load_dotenv
from requests_oauthlib import OAuth1

load_dotenv()


def _require(name: str) -> str:
    v = os.getenv(name, "").strip()
    if not v:
        print(f"Missing required environment variable: {name}", file=sys.stderr)
        sys.exit(1)
    return v


def post_tweet():
    consumer_key = _require("X_CONSUMER_KEY")
    consumer_secret = _require("X_CONSUMER_SECRET")
    access_token = _require("X_ACCESS_TOKEN")
    access_token_secret = _require("X_ACCESS_TOKEN_SECRET")
    community_id = os.getenv("X_COMMUNITY_ID", "2017584249789157568")

    print("Authenticating with X API v2 (OAuth 1.0a User Context)...")

    url = "https://api.twitter.com/2/tweets"
    auth = OAuth1(
        consumer_key,
        consumer_secret,
        access_token,
        access_token_secret,
    )

    payload = {
        "text": "Hello Catcoin Community! This is a test post from the backend script. #Catcoin",
        "community_id": community_id,
    }

    print(f"Posting Tweet: {payload['text']}")
    response = requests.post(url, json=payload, auth=auth)

    if response.status_code == 201:
        print("Tweet posted successfully.")
        data = response.json()
        tweet_id = data["data"]["id"]
        print(f"Tweet ID: {tweet_id}")
        print(f"Full response: {data}")
    else:
        print(f"Failed to post: {response.status_code}")
        print(f"Error: {response.text}")


if __name__ == "__main__":
    post_tweet()
