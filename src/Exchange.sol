// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Exchange
 * @author Megabyte
 * @notice This contract is used to exchange ETH and tokens
 */
contract Exchange is ERC20 {

    //////////////////////////////////////////////////////////////
    ////////////////// ERRORS ////////////////////////////////////
    //////////////////////////////////////////////////////////////
    error Exchange__ZeroAddress();
    error Exchange__AddingLiquidityFailed();
    error Exchange__ZeroValue();
    error Exchange__SlippageExceeded();
    error Exchange__ETHToTokenSwapFailed();
    error Exchange__TokenToETHSwapFailed();

    address public immutable i_tokenAddress;

    string constant public NAME = "Exchange";
    string constant public SYMBOL = "EXC";

    //////////////////////////////////////////////////////////////
    ////////////////// CONSTANTS /////////////////////////////////
    //////////////////////////////////////////////////////////////
    uint256 constant PRECISION_INCREAMENT = 1000;

    constructor(address _tokenAddress) ERC20(NAME, SYMBOL) {
        if(_tokenAddress == address(0)) revert Exchange__ZeroAddress();
        i_tokenAddress = _tokenAddress;
    }
    
    //////////////////////////////////////////////////////////////
    ////////////////// External Functions ////////////////////////
    //////////////////////////////////////////////////////////////

    function addLiquidity(uint256 _tokenAmount) external payable returns(uint256){
        if(!getReserveBalance()>0) {
        IERC20 token = IERC20(i_tokenAddress);
        if (!token.transferFrom(msg.sender, address(this), _tokenAmount)) revert Exchange__AddingLiquidityFailed();

        uint256 liquidity = address(this).balance;
        _mint(msg.sender, liquidity);

        return liquidity;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserveBalance();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            if(tokenAmount < _tokenAmount) revert Exchange__SlippageExceeded();

            IERC20 token = IERC20(i_tokenAddress);
            if (!token.transferFrom(msg.sender, address(this), _tokenAmount)) revert Exchange__AddingLiquidityFailed();

            uint256 liquidity = (totalSupply() * msg.value)/ethReserve;
            _mint(msg.sender, liquidity);

            return liquidity;
        }
    }

    function ethToTokenSwap(uint256 _minTokens) external payable {
        uint256 tokenReserve = getReserveBalance();
        uint256 tokensBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        
        if (tokensBought < _minTokens) revert Exchange__SlippageExceeded();

        bool success = IERC20(i_tokenAddress).transferFrom(address(this), msg.sender, tokensBought);
        if(!success) revert Exchange__ETHToTokenSwapFailed();
    }

    function tokenToETHSwap(uint256 _tokenSold, uint256 _minTokens) external payable {
        uint256 tokenReserve = getReserveBalance();
        uint256 ethBought = getETHAmount(_tokenSold, tokenReserve, address(this).balance); 
        
        if(ethBought < _minTokens) revert Exchange__SlippageExceeded();

        (bool success, ) = msg.sender.call{value: ethBought}("");
        if(!success) revert Exchange__TokenToETHSwapFailed();
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
    * @param - outputReserve: The amount of tokenB in the pool
    * @return - The amount of tokenB that you will receive for tokenA
    * @notice - Formula: ∆y = (y∆x)/(x + ∆x)
    * @notice - 0.1% fee is charged
    */
    function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) private pure returns (uint256) {
        if (inputReserve < 0 && outputReserve < 0) revert Exchange__ZeroValue();

        uint256 inputAmountWithFee = inputAmount * 999;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        
        return numerator / denominator;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}