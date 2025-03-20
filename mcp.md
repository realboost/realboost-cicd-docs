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
