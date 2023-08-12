// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Token} from "../src/Token.sol";
import {Exchange} from "../src/Exchange.sol";

import {Test, console} from "forge-std/Test.sol";

/**
 * @title ExchangeTest
 * @author Megabyte
 * @notice This contract is used to test the Exchange contract
 */

contract ExchangeTest is Test {

    error ExchangeTest__TestAddLiquidityFailed();

    Token token;
    Exchange exchange;

    uint256 constant INITIAL_SUPPLY = 500e18;
    string constant TOKEN_NAME = "New Token";
    string constant TOKEN_SYMBOL = "NT";

    /**
     * @notice: This function is called before each test function
     * @dev: It creates a new token and exchange contract
     */
    function setUp() external{
        token = new Token(TOKEN_NAME,TOKEN_SYMBOL, INITIAL_SUPPLY);
        exchange = new Exchange(address(token));
    }

    /**
     * @notice: This test function checks if the liquidity is added successfully
     * @dev: It approves the exchange contract to transfer tokens from the user
     * @dev: It adds liquidity to the exchange contract
     * @dev: It checks if the token and eth balance of the exchange contract is correct
     */
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

    /**
     * @notice: This test function checks if the ETH/Token or Token/ETH price function is working correctly
     */
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

    /**
     * @notice: This function test if the ETH/Token amount received after selling ETH/Token is working correctly
     */
    function testAmount() public {
        testAddLiquidity();
        uint256 ethAmount = exchange.getETHAmount(2e18);
        console.log(ethAmount);
        uint256 tokenAmount = exchange.getTokenAmount(1 ether);
        console.log(tokenAmount);
    }
}