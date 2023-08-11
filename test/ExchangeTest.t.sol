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

        exchange = new Exchange(address(token));
    }

    function testAddLiquidity() public {
        token.approve(address(exchange), 200e18);
        exchange.addLiquidity(200e18);
        
        (bool success, ) = address(exchange).call{value: 100 ether}("");
        if(!success) revert ExchangeTest__TestAddLiquidityFailed();

        uint256 tokenBalance =  exchange.getReserveBalance();
        assertEq(tokenBalance, 200e18);

        uint256 ethBalance =  address(exchange).balance;
        assertEq(ethBalance, 100 ether);

        console.log("=======Test Liquidity Added Successfully=======");
    }

    function testGetPrice() public {
        testAddLiquidity();

        uint256 tokenBalance =  exchange.getReserveBalance();
        uint256 ethBalance =  address(exchange).balance;

        // @notice: This returns the ETH per token with 3 decimals
        uint256 ethPerToken = exchange.getPrice(ethBalance, tokenBalance);

        // @notice: This returns the Token per ETH with 3 decimals
        uint256 tokenPerETH = exchange.getPrice(tokenBalance, ethBalance);

        assertEq(ethPerToken, 500);
        assertEq(tokenPerETH, 2000);

        console.log("=======Test Get Price Successful=======");

    }

    function testAmount() public {
        testAddLiquidity();
        uint256 ethAmount = exchange.getETHAmount(2e18);
        console.log(ethAmount);
        uint256 tokenAmount = exchange.getTokenAmount(1 ether);
        console.log(tokenAmount);
    }
}