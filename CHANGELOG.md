# Change Log

- Separated KyotoPay contract into two contracts: Disburser and KyotoHub. 
Disburser is used for payments while KyotoPay is used for Preferences
- Changed DECIMALS variable to PRECISION_FACTOR
- Added a deadline parameter to Payment functions in Disburser. Needs to be passed in by frontend
- Moved datatypes, errors, and events from interfaces to libraries

# To Do
- Change params in Disburser to structs
- Test pay deadlines
- Update payment event to track the token out and amount transferred
- Adjust tests to account for UNI fees