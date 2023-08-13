// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IExchange {

    /**
     * @notice Swap ETH to ERC20 token
     * @param _minTokens The minimum amount of tokens to receive
     */
    function ethToTokenSwap(uint256 _minTokens) external payable;

    /**
     * @notice Swap ETH to ERC20 token but with customised recipient
     * @param _minTokens The minimum amount of tokens to receive
     * @param _recipient The recipient of the tokens
     */
    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable;
}