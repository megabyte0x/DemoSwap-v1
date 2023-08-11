// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Token} from "../src/Token.sol";
import {Exchange} from "../src/Exchange.sol";

import {Test, console} from "forge-std/Test.sol";

contract ExchangeTest is Test {

    error ExchangeTest__TestAddLiquidityFailed();

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
        token.approve(address(exchange), 200 ether);
        exchange.addLiquidity(200 ether);
        (bool success, ) = address(exchange).call{value: 100 ether}("");
        if(!success) revert ExchangeTest__TestAddLiquidityFailed();
        console.log("Liquidity Added");
    }
}