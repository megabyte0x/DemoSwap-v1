// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Token} from "../src/Token.sol";
import {Exchange} from "../src/Exchange.sol";

import {Test, console} from "forge-std/Test.sol";

contract ExchangeTest is Test {

    Token token;
    Exchange exchange;

    uint256 constant INITIAL_SUPPLY = 500e18;
    string constant TOKEN_NAME = "New Token";
    string constant TOKEN_SYMBOL = "NT";


    function setUp() external{
        token = new Token(TOKEN_NAME,TOKEN_SYMBOL, INITIAL_SUPPLY);
        console.log("Token address: %s", address(token));

        exchange = new Exchange(address(token));
        console.log("Exchange address: %s", address(exchange));
    }

    function testAddLiquidity() public {
        token.approve(address(exchange), 100e18);
        exchange.addLiquidity(10e18);
        console.log("Liquidity Added");
    }
}