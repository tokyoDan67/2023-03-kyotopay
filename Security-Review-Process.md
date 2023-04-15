# Security review process guide

## Questions to project

1. What is the clear scope (`.sol` files) of the security review?

|       File Name           |     SLOC      |
| -----------------------   | ------------- |
| base/HubAware.sol         |       10      |
| base/HubOwnable.sol       |       13      |
| libraries/DataTypes.sol   |       37      |
| libraries/Errors.sol      |       14      |
| libraries/Events.sol      |       10      |
| interfaces/IDisburser.sol |       7       |
| interfaces/IKyotoHub.sol  |       16      |
|  Disburser.sol            |       166     |
|  KyotoHub.sol             |       75      |
|   ----------------------  | ------------- |
|  Total SLOC               |      348      | 

2. Does the project have well written specifications & code documentation?

Not great.  The website is: https://kyotopay.com/.  

The project enables users to pay other users with a whitelisted input currencies, which are ERC20s.
The backend then utilizes Uniswap V3 to convert the inputted currency into the user's
preffered whitelisted output currency.

3. What is the code test coverage percentage?

100% of 

4. Have you had any audits so far?

**Based on the answers we can discuss the effort needed, the payment amount and the timeline.**

## Security review result & fixes review

After the time agreed upon has passed, the project will receive the security review report. The project has 7 days to apply fixes on issues found. Then, a single iteration of a "fixes review" will be executed by me, free of additional charges, to verify your fixes are correct and secure.

### Important notes for the fixes review

- for any questions or clarifications on the vulnerabilities/recommendations in the report, you can reach out to me on the intended channel of communication
- changes to be reviewed should not include anything else other than fixes for the reported issues, so no big refactorings, new features or architectural changes
- in the case that fixes are too difficult to implement or more than one iteration of reviews is needed then this is a special case that can be discussed independently of this review

## Important Off-Topic Questions
1. Are you okay with me publishing the security review report after you apply fixes?
2. Are you okay with me being transparent with our work, findings and payment?
3. What is your preferred communication channel?

## Disclaimer

A smart contract security review can never verify the complete absence of vulnerabilities. This is a time, resource and expertise bound effort where I try to find as many vulnerabilities as possible. I can not guarantee 100% security after the review or if even the review will find any problems with your smart contracts.