// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Token} from "../src/Token.sol";
import {GraphKitExchange} from "../src/GraphKitExchange.sol";

import {Test, console} from "forge-std/Test.sol";

/**
 * @title ExchangeTest
 * @author Megabyte
 * @notice This contract is used to test the GraphKitExchange contract
 */

contract ExchangeTest is Test {

    error ExchangeTest__TestAddLiquidityFailed();

    Token token;
    GraphKitExchange exchange;

    uint256 constant INITIAL_SUPPLY = 500e18;
    string constant TOKEN_NAME = "New Token";
    string constant TOKEN_SYMBOL = "NT";

    function setUp() external{
        token = new Token(TOKEN_NAME,TOKEN_SYMBOL, INITIAL_SUPPLY);
        exchange = new GraphKitExchange(address(token));
    }

    function testAddLiquidity() public {
        token.approve(address(exchange), 200e18);
        exchange.addLiquidity{value: 100 ether}(200e18);

        uint256 tokenBalance =  exchange.getReserveBalance();
        assertEq(tokenBalance, 200e18);

        uint256 ethBalance =  address(exchange).balance;
        assertEq(ethBalance, 100 ether);

        console.log("=======Test Liquidity Added Successfully=======");
    }

    function testSwapping() public {
        testAddLiquidity();

        uint256 tokenBalanceBefore = token.balanceOf(address(this));

        exchange.ethToTokenSwap{value: 10 ether}(18e18);

        uint256 tokenBalanceAfter = token.balanceOf(address(this));
        
        assertGe(tokenBalanceAfter - tokenBalanceBefore, 18e18);
    }

    function testRemoveLiquidity() public {
        testAddLiquidity();

        uint256 tokenExchangeBalanceBefore = token.balanceOf(address(exchange));
        uint256 ethExchangeBalanceBefore = address(exchange).balance;

        console.log("Token GraphKitExchange Balance, %s", tokenExchangeBalanceBefore);
        console.log("ETH GraphKitExchange Balance, %s", ethExchangeBalanceBefore);

        uint256 tokenBalanceBefore = token.balanceOf(address(this));
        uint256 ethBalanceBefore = address(this).balance;

        exchange.removeLiquidity(100e18);

        uint256 tokenBalanceAfter = token.balanceOf(address(this));
        uint256 ethBalanceAfter = address(this).balance;

        assertEq(tokenBalanceAfter - tokenBalanceBefore, 100e18);
        assertEq(ethBalanceAfter - ethBalanceBefore, 50 ether);
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