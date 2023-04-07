// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

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
     * IERC20 Contracts
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

    function _convertUsdcToWeth(uint256 _amountIn) internal returns (uint256) {
        (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

        // USDC uses 6 decimals
        // WETH uses 18 decimals
        // Chainlink's pricefeed uses 8 decimals
        // However: We need the calculation to end up using the WETH decimals, i.e. 10^18

        // amountIn = USDC_Amount * 10^6
        // ethUSDCPrice = ETH_Price * 10^8
        // expectedWeth = (USDC_Amount * 10^6) * (10^8) * (10^(18-6)) / (ETH_Price * 10^8)
        // Note: the 10^8s in the nominator and denominator cancel each other out, leaving 10^(18-6) * 10^6 which is just 10^18

        // Therefore: expectedWeth = (_amountIn) * (10^8) * (10^(18-6)) / ethUSDCPrice

        return (_amountIn * (10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS))) / uint256(ethUSDCPrice);
    }

    function _convertWbtcToUsdc(uint256 _amountIn) internal returns (uint256) {
        (int256 btcUSDCPrice, uint8 btcUSDCDecimals) = getBtcToUSDCPriceAndDecimals();

        // Unlike WETH and ETH, WBTC and BTC don't trade in parity...
        (int256 wbtcBtcConversionRate, uint8 wbtcBtcConversionDecimals) = getWbtcToBtcConversionRateAndDecimals();

        // WBTC uses 8 decimals
        // USDC uses 6 decimals
        // Chainlink's pricefeeds uses 8 decimals
        // However: We need the calculation to end up using the USDC decimals, i.e. 10^6

        // amountIn = WBTC_Amount * 10^8
        // btcUSDCPrice = BTC_Price * 10^8
        // wbtcBtcConversionRate = Conversion_Rate * 10^8
        // expectedUSDC = (WBTC_Amount * 10^8) * (Conversion_Rate * 10^8) * (btcUSDPrice * 10^8) * (10^(6-8)) / (10^8) * 10(^8)
        // Algebraically, 10^(6-8) in the numerator is the same as 10^(8-6) in the denominator
        // Note: the 10^8s in the nominator and denominator cancel each other out, leaving 10^(18-6) * 10^6 which is just 10^18

        // Therefore: wbtcToUsdcConversion = amountIn * wbtcBtcConversionRate * btcUSDCPrice) / (10(8-6) * (10^8) * 10(^8))

        return (_amountIn * uint256(wbtcBtcConversionRate) * uint256(btcUSDCPrice))
            / ((10 ** (WBTC_DECIMALS - USDC_DECIMALS)) * (10 ** btcUSDCDecimals) * (10 ** wbtcBtcConversionDecimals));
    }

    function _convertUsdcToWbtc(uint256 amountIn) internal returns(uint256) {}

    function _wethToUsdcConversion(uint256 amountIn) internal {
        (int256 ethUSDCPrice, uint8 ethUSDCDecimals) = getEthToUSDCPriceAndDecimals();

        // See prior tests to understand math for this conversion.... 
        return (_amountIn * uint256(ethUSDCPrice)) / ((10 ** ethUSDCDecimals) * (10 ** (WETH_DECIMALS - USDC_DECIMALS)));
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
