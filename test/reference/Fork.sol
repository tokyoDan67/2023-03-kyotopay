// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Helper} from "./Helper.sol";
import {IUSDC} from "./IUSDC.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Fork is Helper, Test {
    /**
     * Mainnet
     */
    uint256 mainnetForkId;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    uint256 constant MAINNET_FORK_BLOCK = 16520928;

    /**
     * Goerli 
     */
     uint256 goerliForkId;
     string GOERLI_RPC_URL = vm.envString("GOERLI_RPC_URL"); 
     uint256 constant GOERLI_FORK_BLOCK = 8404430;

     /**
      * Polygon
      */
    uint256 polygonForkId;
    string POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");
    uint256 constant POLYGON_FORK_BLOCK = 38712600;


    /**
     * Store contracts
     */
    IERC20 USDC_CONTRACT = IERC20(USDC_ADDRESS);
    IERC20 DAI_CONTRACT = IERC20(DAI_ADDRESS);
    IERC20 WBTC_CONTRACT = IERC20(WBTC_ADDRESS);
    IERC20 WETH_CONTRACT = IERC20(WETH_ADDRESS);

    /**
     *  Chainlink Aggregators
     */
    AggregatorV3Interface USDC_PER_ETH_PRICE_FEED;
    AggregatorV3Interface USDC_PER_BTC_PRICE_FEED;
    AggregatorV3Interface WBTC_PER_BTC_PRICE_FEED;

    function setUp() public virtual {
        MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        USDC_PER_ETH_PRICE_FEED = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        USDC_PER_BTC_PRICE_FEED = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        WBTC_PER_BTC_PRICE_FEED = AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    }

    function getEthToUSDCPriceAndDecimals() internal view returns (int256, uint8) {
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = USDC_PER_ETH_PRICE_FEED.latestRoundData();

        require(price > 0, "Negative price value");

        uint8 decimals = USDC_PER_ETH_PRICE_FEED.decimals();

        return (price, decimals);
    }

    function getBtcToUSDCPriceAndDecimals() internal view returns (int256, uint8) {
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = USDC_PER_BTC_PRICE_FEED.latestRoundData();

        require(price > 0, "Negative price value");

        uint8 decimals = USDC_PER_BTC_PRICE_FEED.decimals();

        return (price, decimals);
    }

    function getWbtcToBtcConversionRateAndDecimals() internal view returns (int256, uint8) {
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = WBTC_PER_BTC_PRICE_FEED.latestRoundData();

        require(price > 0, "Negative price value");

        uint8 decimals = WBTC_PER_BTC_PRICE_FEED.decimals();

        return (price, decimals);
    }

    /**
     * @dev Can only be used when the vm is forked from mainnet
     * Issues an amount of USDC given an address
     * Requirements:
     *     - The address cannot be address(0)
     *     - The address cannot be blacklisted by USDC
     */
    function issueUSDC(address _address, uint256 _amount) internal {
        // Set msg.sender temporarily to the owner of the USDC contracts
        vm.startPrank(USDC_MASTER_MINTER);

        IUSDC(USDC_ADDRESS).configureMinter(USDC_MASTER_MINTER, _amount);

        IUSDC(USDC_ADDRESS).mint(_address, _amount);

        assertGe(IUSDC(USDC_ADDRESS).balanceOf(_address), _amount);
        // Set msg.sender to back to normal
        vm.stopPrank();
    }

    /**
     * @dev Internal function to get token balances from 3 different addresses
     */
    function getTokenBalances(IERC20 token, address first, address second, address third)
        internal
        view
        returns (uint256, uint256, uint256)
    {
        return (token.balanceOf(first), token.balanceOf(second), token.balanceOf(third));
    }
}
