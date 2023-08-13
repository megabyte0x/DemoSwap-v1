// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Exchange} from "./Exchange.sol";

contract Factory {

    error Factory__ZeroAddress();
    error Factory__ExchangeAlreadyCreated();

    event Factory__ExchangeCreated(address indexed _tokenAddress, address indexed _exchangeAddress);

    mapping (address tokenAddress => address ExchangeAddress) public tokenToExchange;

    function createExchange(address _tokenAddress) external returns (address exchangeAddress) {
        
        if(_tokenAddress == address(0)) revert Factory__ZeroAddress();
        if(tokenToExchange[_tokenAddress] == address(0)) revert Factory__ExchangeAlreadyCreated();

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        emit Factory__ExchangeCreated(_tokenAddress, address(exchange));

        return address(exchange);
    }

    function getExchange(address _tokenAddress) external view returns(address exchangeAddress) {
        return tokenToExchange[_tokenAddress];
    }

}