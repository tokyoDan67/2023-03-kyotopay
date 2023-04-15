# Change Log
## V1.1
- Separated KyotoPay contract into two contracts: Disburser and KyotoHub. 
Disburser is used for payments while KyotoPay is used for Preferences
- Changed DECIMALS variable to PRECISION_FACTOR
- Added a deadline parameter to Payment functions in Disburser. Needs to be passed in by frontend
- Moved datatypes, errors, and events from interfaces to libraries
- Changed pay() and payEth() arguments to structs rather than primitives Prevents stack too deep errors for those looking to implement the Disburser
- Updated the payment event to track the token out and amount transferred out rather than the token in and amount transferred in
- Added Receive functions, enabling smart contracts to receive payments in their preferred ERC20
- Enabled admin to offer vendors a fee reduction