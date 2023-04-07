# Change Log
- Separated KyotoPay contract into two contracts: Disburser and KyotoHub. 
Disburser is used for payments while KyotoPay is used for Preferences
- Changed DECIMALS variable to PRECISION_FACTOR
- Added a deadline parameter to Payment functions in Disburser. Needs to be passed in by frontend
- Moved datatypes, errors, and events from interfaces to libraries
- Changed pay() and payEth() arguments to structs rather than primitives Prevents stack too deep errors for those looking to implement the Disburser
- Updated the payment event to track the token out and amount transferred out rather than the token in and amount transferred in

# To Do
- Add Receive tests.  Possibly refactor so that the disburser tests are separated by file
- Refactor Receive
- EIP712
- Vendor fee reduction OR fee share