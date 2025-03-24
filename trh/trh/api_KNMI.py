import os
import httpx
import dotenv

# Load API key from .env file
dotenv.load_dotenv()
API_KEY = os.getenv("KNMI_API_KEY")

# API endpoint
EDR_API_URL = "https://api.dataplatform.knmi.nl/edr/v1/collections/observations"

# Function to get 10-minute temperature and humidity data
def get_weather_data(lat, lon, start_time, end_time):
    headers = {"Authorization": f"Bearer {API_KEY}"}
    params = {
        "bbox": f"{lon},{lat},{lon},{lat}",  # Single point query
        "datetime": f"{start_time}/{end_time}",
        "parameter-name": "airTemperature,relativeHumidity,wetBulbTemperature"
    }
    
    response = httpx.get(EDR_API_URL, headers=headers, params=params)
    
    if response.status_code == 200:
        data = response.json()
        return process_weather_data(data)
    else:
        print(f"Error: {response.status_code}, {response.text}")
        return None

# Function to process API response
def process_weather_data(data):
    results = []
    for feature in data.get("features", []):
        props = feature.get("properties", {})
        temp = props.get("airTemperature")
        humidity = props.get("relativeHumidity")
        
        # Calculate humidity if missing
        if humidity is None and "wetBulbTemperature" in props:
            humidity = calculate_humidity(temp, props["wetBulbTemperature"])
        
        results.append({
            "timestamp": props.get("phenomenonTime"),
            "temperature": temp,
            "humidity": humidity
        })
    return results

# Function to estimate relative humidity (if needed)
def calculate_humidity(temp, wet_bulb_temp):
    # Approximate formula for relative humidity
    return 100 * (6.112 * (10**((7.5 * wet_bulb_temp) / (237.3 + wet_bulb_temp))) /
                  6.112 * (10**((7.5 * temp) / (237.3 + temp))))

# Example usage
if __name__ == "__main__":
    lat, lon = 52.1, 5.2  # Example coordinates (Netherlands)
    start_time = "2025-03-23T00:00:00Z"
    end_time = "2025-03-23T23:59:59Z"
    
    data = get_weather_data(lat, lon, start_time, end_time)
    print(data)
