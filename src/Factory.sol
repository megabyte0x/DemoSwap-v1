// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {GraphKitExchange} from "./GraphKitExchange.sol";

/**
 * @title Factory
 * @author Megabyte
 * @notice Factory contract for creating GraphKitExchange contracts
 */
contract Factory {

    //////////////////////////////////////////////////////////////
    ////////////////// ERRORS ////////////////////////////////////
    //////////////////////////////////////////////////////////////
    error Factory__ZeroAddress();
    error Factory__ExchangeAlreadyCreated();

    //////////////////////////////////////////////////////////////
    ////////////////// EVENTS ////////////////////////////////////
    //////////////////////////////////////////////////////////////
    event Factory__ExchangeCreated(address indexed _tokenAddress, address indexed _exchangeAddress);

    //////////////////////////////////////////////////////////////
    ////////////////// STATE VARIABLES ///////////////////////////
    //////////////////////////////////////////////////////////////
    mapping (address tokenAddress => address ExchangeAddress) public tokenToExchange;

    /**
     * @notice It deploys a new GraphKitExchange contract for the given token
     * @param _tokenAddress address of the token to create an exchange for
     */
    function createExchange(address _tokenAddress) external returns (address exchangeAddress) {
        
        if(_tokenAddress == address(0)) revert Factory__ZeroAddress();
        if(tokenToExchange[_tokenAddress] != address(0)) revert Factory__ExchangeAlreadyCreated();

        GraphKitExchange exchange = new GraphKitExchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        emit Factory__ExchangeCreated(_tokenAddress, address(exchange));

        return address(exchange);
    }

    /**
     * @notice It returns the exchange address for the given token
     * @param _tokenAddress address of the token to get the exchange for
     */
    function getExchange(address _tokenAddress) external view returns(address exchangeAddress) {
        return tokenToExchange[_tokenAddress];
    }

}