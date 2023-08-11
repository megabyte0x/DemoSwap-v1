// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Exchange {

    //////////////////////////////////////////////////////////////
    ////////////////// ERRORS ////////////////////////////////////
    //////////////////////////////////////////////////////////////
    error Exchange__ZeroAddress();
    error Exchange__AddingLiquidityFailed();
    error Exchange__ZeroValue();

    address public immutable i_tokenAddress;

    //////////////////////////////////////////////////////////////
    ////////////////// CONSTANTS /////////////////////////////////
    //////////////////////////////////////////////////////////////
    uint256 constant PRECISION_INCREAMENT = 1000;

    constructor(address _tokenAddress) {
        if(_tokenAddress == address(0)) revert Exchange__ZeroAddress();
        i_tokenAddress = _tokenAddress;
    }
    
    //////////////////////////////////////////////////////////////
    ////////////////// External Functions ////////////////////////
    //////////////////////////////////////////////////////////////

    function addLiquidity(uint256 _tokenAmount) external payable {
        IERC20 token = IERC20(i_tokenAddress);
        if (!token.transferFrom(msg.sender, address(this), _tokenAmount)) revert Exchange__AddingLiquidityFailed();
    }

    //////////////////////////////////////////////////////////////
    ////////////////// External & Pure Functions /////////////////
    //////////////////////////////////////////////////////////////

    function getPrice(uint256 inputReserve, uint256 outputReserve) external pure returns (uint256) {
        if (inputReserve < 0 && outputReserve < 0) revert Exchange__ZeroValue();

        return (inputReserve * PRECISION_INCREAMENT)  / outputReserve;
    }

    //////////////////////////////////////////////////////////////
    ////////////////// Public & View Functions ///////////////////
    //////////////////////////////////////////////////////////////

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        if(_ethSold<0) revert Exchange__ZeroValue();

        uint256 tokenReserve = getReserveBalance();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getETHAmount(uint256 _tokenSold) public view returns (uint256) {
        if(_tokenSold<0) revert Exchange__ZeroValue();

        uint256 tokenReserve = getReserveBalance();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    //////////////////////////////////////////////////////////////
    ////////////////// Public & View Functions /////////////////
    //////////////////////////////////////////////////////////////

    function getReserveBalance() public view returns (uint256) {
        return IERC20(i_tokenAddress).balanceOf(address(this));
    }

    //////////////////////////////////////////////////////////////
    ////////////////// Private & Pure Functions //////////////////
    //////////////////////////////////////////////////////////////

    /**
    * @param - inputAmount: The amount of tokenA received 
    * @param - inputReserve: The amount of tokenA in the pool
    * @param - outputReserver: The amount of tokenB in the pool
    * @return - The amount of tokenB that you will receive for tokenA
    * @notice - Formula: ∆y = (y∆x)/(x + ∆x)
    */
    function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserver) private pure returns (uint256) {
        if (inputReserve < 0 && outputReserver < 0) revert Exchange__ZeroValue();
        
        return (inputAmount * outputReserver) / (inputReserve + inputAmount);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}