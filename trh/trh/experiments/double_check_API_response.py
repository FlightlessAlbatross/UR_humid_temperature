import time
import httpx

from dotenv import load_dotenv
import os

# Token cache
TOKEN_CACHE = {"access_token": None, "expires_at": 0}

# Load .env file
load_dotenv()

# Retrieve credentials and URLs
CLIENT_ID      = os.getenv("CLIENT_ID")
CLIENT_SECRET  = os.getenv("CLIENT_SECRET")
TOKEN_URL      = os.getenv("TOKEN_URL")

def fetch_access_token():
    payload = {
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
    }

    with httpx.Client() as client:
        response = client.post(TOKEN_URL, data=payload)
        response.raise_for_status()  # Raise error for bad responses

        # Parse token data
        token_data = response.json()
        access_token = token_data["access_token"]
        expires_in = token_data.get("expires_in", 3600)  # Default to 1 hour if missing
        expires_at = time.time() + expires_in

        # Cache the token
        TOKEN_CACHE["access_token"] = access_token
        TOKEN_CACHE["expires_at"] = expires_at

        return access_token
    

def get_access_token():
    # Reuse token if it's still valid
    if time.time() < TOKEN_CACHE["expires_at"]:
        return TOKEN_CACHE["access_token"]

    # Fetch a new token if expired
    return fetch_access_token()


def make_api_request(api_url):
    headers = {
        "Authorization": f"Bearer {get_access_token()}"
    }

    with httpx.Client() as client:
        response = client.get(api_url, headers=headers)
        
        # Handle expired token gracefully
        if response.status_code == 401:
            print("Token expired. Fetching a new token...")
            TOKEN_CACHE["access_token"] = None  # Clear cache
            headers["Authorization"] = f"Bearer {get_access_token()}"
            response = client.get(api_url, headers=headers)

        response.raise_for_status()  # Raise error for non-2xx responses
        return response.json()
    



def adjust_frost_url(url:str, base_url = "https://platform-urbanreleaf.iccs.gr/FROST-Server/v1.1") -> str:
    """
    Take the Url and replace http://frost-server:/v1.1 with the base url
    return the new url 
    """
    return url.replace("http://frost-server:/v1.1", base_url)




sensor_namelist = ['88901ccb-88c0-435a-af7f-fb37fc890bcb']

for device_id in sensor_namelist:
   
    all_device_obs = []
    
    url = api_endpoint_obs_by_sensorname(device_id)

    while url:
        response_data = api_client.make_api_request(url)
        
        all_device_obs.extend(response_data.get('value',[]))
        
        local_url = response_data.get("@iot.nextLink")
        if local_url:
            url = api_client.adjust_frost_url(local_url)
        else: 
            data_out = {"device_id": device_id, 
                        "responses": all_device_obs}
            # write to jsonl and break the while. Onto the next sensor name. 
            break

print(f'All devices responses saved to {path_output}')