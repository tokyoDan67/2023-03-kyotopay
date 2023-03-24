// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract Constants {
    /**
     * Goerli
     */
    address constant UNISWAP_ROUTER_ADDRESS_GOERLI = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant WETH_ADDRESS_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address constant USDC_ADDRESS_GOERLI = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    // Note: there is no official Tether testnet deployment. This is a randomly selected deployment for testing
    address constant USDT_ADDRESS_GOERLI = 0x509Ee0d083DdF8AC028f2a56731412edD63223B9;
    address constant GOERLI_EOA = 0x8313b3727E47efaaBB90b7C2f00A73758D52A2b5;

    /**
     * Mainnet
     */
    address constant UNISWAP_ROUTER_ADDRESS_MAINNET = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant WETH_ADDRESS_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC_ADDRESS_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT_ADDRESS_MAINNET = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant MAINNET_MULTISIG = 0x9211A0BB478B4Bbed725e63D26a784A0cE19E3e4;
}
