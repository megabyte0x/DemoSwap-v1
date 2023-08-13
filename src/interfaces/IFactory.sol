// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IFactory {

    /**
     * @notice Create a new exchange contract for an ERC20 token
     * @param _tokenAddress The address of the ERC20 token
     */
    function createExchange(address _tokenAddress) external returns(address exchangeAddress);
    
    /**
     * @notice Get the exchange contract for an ERC20 token
     * @param _tokenAddress The address of the ERC20 token
     */
    function getExchange(address _tokenAddress) external view returns(address exchangeAddress);
}