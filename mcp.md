# Accessing Public APIs in the USA with Node.js

Here are some excellent public data sources in the USA that you can access via APIs, along with Node.js code snippets to get you started:

## 1. NASA Open APIs

NASA provides fascinating public data including astronomy pictures, Mars rover photos, and space weather.

```javascript
const axios = require('axios');

// NASA Astronomy Picture of the Day
async function getNasaAPOD() {
  try {
    const response = await axios.get('https://api.nasa.gov/planetary/apod', {
      params: {
        api_key: 'DEMO_KEY' // Replace with your API key from https://api.nasa.gov/
      }
    });
    console.log('Today\'s astronomy picture:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error fetching NASA APOD:', error.message);
  }
}

getNasaAPOD();
```

## 2. U.S. Census Bureau Data

Access demographic, economic, and geographic data for the United States.

```javascript
const axios = require('axios');

// Get population estimates
async function getCensusData() {
  try {
    const response = await axios.get(
      'https://api.census.gov/data/2021/pep/population',
      {
        params: {
          get: 'NAME,POP',
          'for': 'state:*',
          key: 'YOUR_API_KEY' // Get from https://api.census.gov/data/key_signup.html
        }
      }
    );
    console.log('Census population data:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error fetching Census data:', error.message);
  }
}

getCensusData();
```

## 3. National Weather Service API

Get weather forecasts, alerts, and observations without requiring an API key.

```javascript
const axios = require('axios');

// Get weather forecast for a location
async function getWeatherForecast(lat, lon) {
  try {
    // First, get the metadata for the location
    const pointsResponse = await axios.get(
      `https://api.weather.gov/points/${lat},${lon}`
    );
    
    // Then get the forecast using the URL from the metadata
    const forecastUrl = pointsResponse.data.properties.forecast;
    const forecastResponse = await axios.get(forecastUrl);
    
    console.log('Weather forecast periods:', forecastResponse.data.properties.periods);
    return forecastResponse.data;
  } catch (error) {
    console.error('Error fetching weather data:', error.message);
  }
}

// Example: San Francisco coordinates
getWeatherForecast(37.7749, -122.4194);
```

## 4. Data.gov APIs

Access thousands of datasets from the US Government.

```javascript
const axios = require('axios');

// Search for datasets related to a topic
async function searchDataGov(query) {
  try {
    const response = await axios.get('https://catalog.data.gov/api/3/action/package_search', {
      params: {
        q: query
      }
    });
    console.log(`Found ${response.data.result.count} datasets for "${query}"`);
    console.log('First few results:', response.data.result.results.slice(0, 3).map(r => r.title));
    return response.data.result;
  } catch (error) {
    console.error('Error searching Data.gov:', error.message);
  }
}

searchDataGov('climate change');
```

## 5. FDA Open Data

Access information on drugs, food safety, and medical devices.

```javascript
const axios = require('axios');

// Search for drug information
async function searchFDADrugs(brandName) {
  try {
    const response = await axios.get('https://api.fda.gov/drug/label.json', {
      params: {
        search: `openfda.brand_name:"${brandName}"`,
        limit: 5
      }
    });
    console.log(`Drug information for ${brandName}:`, response.data);
    return response.data;
  } catch (error) {
    console.error('Error fetching FDA drug data:', error.message);
  }
}

searchFDADrugs('Advil');
```

## 6. CDC WONDER API

Access public health data including mortality, natality, and disease surveillance.

```javascript
const axios = require('axios');
const FormData = require('form-data');

// Get provisional COVID-19 deaths data
async function getCOVIDDeathData() {
  try {
    const formData = new FormData();
    formData.append('accept_datause_restrictions', 'true');
    formData.append('stage', 'request');
    formData.append('action', 'Send');
    formData.append('finder-stage-D124.show', 'true');
    formData.append('F_D124.V9', '*All*');
    
    const response = await axios.post(
      'https://wonder.cdc.gov/controller/datarequest/D124', 
      formData,
      {
        headers: {
          ...formData.getHeaders(),
          'Content-Type': 'multipart/form-data'
        }
      }
    );
    
    console.log('CDC COVID-19 data:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error fetching CDC data:', error.message);
  }
}

getCOVIDDeathData();
```

## 7. Geocoding with U.S. Census Geocoder

Convert addresses to geographic coordinates.

```javascript
const axios = require('axios');

// Geocode an address
async function geocodeAddress(address) {
  try {
    const encodedAddress = encodeURIComponent(address);
    const response = await axios.get(
      `https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=${encodedAddress}&benchmark=2020&format=json`
    );
    
    const matches = response.data.result.addressMatches;
    if (matches.length > 0) {
      console.log('Geocoding results:', matches[0]);
      return matches[0];
    } else {
      console.log('No matches found for address');
      return null;
    }
  } catch (error) {
    console.error('Error geocoding address:', error.message);
  }
}

geocodeAddress('1600 Pennsylvania Avenue, Washington DC');
```

## 8. USA Spending API

Track federal spending including contracts, grants, loans, and other financial assistance.

```javascript
const axios = require('axios');

// Get federal spending by agency
async function getFederalSpending(fiscalYear) {
  try {
    const response = await axios.get(
      'https://api.usaspending.gov/api/v2/budget_functions/spending/',
      {
        params: {
          fiscal_year: fiscalYear
        }
      }
    );
    
    console.log(`Federal spending for FY${fiscalYear}:`, response.data);
    return response.data;
  } catch (error) {
    console.error('Error fetching spending data:', error.message);
  }
}

getFederalSpending(2023);
```

## Installing Dependencies

For the code snippets above, make sure to install the required packages:

```bash
npm install axios form-data
```

## Tips for Working with Public APIs

1. **Rate Limits**: Most public APIs have rate limits. Check the documentation and implement throttling if needed.
2. **Error Handling**: Implement robust error handling for API failures.
3. **Caching**: Consider caching responses to reduce API calls.
4. **API Keys**: Even for public APIs, many require registration for an API key.
5. **Data Processing**: Many APIs return large datasets that may need filtering or processing.

These examples should give you a good starting point for working with public data APIs in the USA using Node.js!
