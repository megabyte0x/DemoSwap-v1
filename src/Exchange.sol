// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IFactory} from "./interfaces/IFactory.sol";
import {IExchange} from "./interfaces/IExchange.sol";

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
    error Exchange__RemovingLiquidityFailed();
    error Exchange__ZeroValue();
    error Exchange__SlippageExceeded();
    error Exchange__ETHToTokenFailed();
    error Exchange__TokenToETHSwapFailed();

    //////////////////////////////////////////////////////////////
    ////////////////// EVENTS ////////////////////////////////////
    //////////////////////////////////////////////////////////////
    event Exchange__LiquidityAdded(address indexed _user, uint256 _ethAmount, uint256 _tokenAmount, uint256 _lpAmount);
    event Exchange__LiquidityRemoved(address indexed _user, uint256 _ethAmount, uint256 _tokenAmount, uint256 _lpAmount);
    event Exchange__ETHToTokenSwap(address indexed _user, uint256 _ethAmount, uint256 _tokenAmount);
    event Exchange__TokenToETHSwap(address indexed _user, uint256 _tokenAmount, uint256 _ethAmount);
    event Exchange__TokenToTokenSwap(address indexed _user, address indexed _sentTokenAddress, address indexed _receivedTokenAddress);

    address public immutable i_tokenAddress;
    address public immutable i_factoryAddress;

    string constant public NAME = "Exchange";
    string constant public SYMBOL = "EXC";

    //////////////////////////////////////////////////////////////
    ////////////////// CONSTANTS /////////////////////////////////
    //////////////////////////////////////////////////////////////
    uint256 constant PRECISION_INCREAMENT = 1000;

    constructor(address _tokenAddress) ERC20(NAME, SYMBOL) {
        if(_tokenAddress == address(0)) revert Exchange__ZeroAddress();
        i_tokenAddress = _tokenAddress;
        i_factoryAddress = msg.sender;
    }
    
    //////////////////////////////////////////////////////////////
    ////////////////// External Functions ////////////////////////
    //////////////////////////////////////////////////////////////

    function addLiquidity(uint256 _tokenAmount) external payable returns(uint256){

        if(!(getReserveBalance()>0)) {
            IERC20 token = IERC20(i_tokenAddress);
            if (!token.transferFrom(msg.sender, address(this), _tokenAmount)) revert Exchange__AddingLiquidityFailed();

            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            emit Exchange__LiquidityAdded(msg.sender, msg.value, _tokenAmount, liquidity);

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

            emit Exchange__LiquidityAdded(msg.sender, msg.value, _tokenAmount, liquidity);

            return liquidity;
        }
    }

    /**
     * 
     * @param _amount Amount of LP Tokens to be removed
     * @return ethAmount Amount of ETH to be returned
     * @return tokenAmount Amount of Tokens to be returned
     */
    function removeLiquidity(uint256 _amount) external returns(uint256 ethAmount, uint256 tokenAmount){
        if (_amount < 0) revert Exchange__ZeroValue();

        ethAmount = (address(this).balance * _amount) / totalSupply();
        tokenAmount = (getReserveBalance() * _amount) / totalSupply();

        _burn(msg.sender, _amount);

        payable(msg.sender).transfer(ethAmount);

        IERC20(i_tokenAddress).transfer( msg.sender, tokenAmount);

        emit Exchange__LiquidityRemoved(msg.sender, ethAmount, tokenAmount, _amount);

        return (ethAmount, tokenAmount);
    }

    function ethToTokenSwap(uint256 _minTokens) external payable {
        uint256 tokensBought = ethToToken(_minTokens, msg.sender);
        emit Exchange__ETHToTokenSwap(msg.sender, msg.value, tokensBought);
    }

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable {
        ethToToken(_minTokens, _recipient);
    }

    function tokenToETHSwap(uint256 _tokenSold, uint256 _minTokens) external payable {
        uint256 tokenReserve = getReserveBalance();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance); 
        
        if(ethBought < _minTokens) revert Exchange__SlippageExceeded();

        (bool success, ) = msg.sender.call{value: ethBought}("");
        if(!success) revert Exchange__TokenToETHSwapFailed();

        emit Exchange__TokenToETHSwap(msg.sender, _tokenSold, ethBought);
    }

    function tokenToTokenSwap (uint256 _tokensSold, uint256 _minTokensBought, address _tokenAddress) external payable{
        address exchangeAddress = IFactory(i_factoryAddress).getExchange(_tokenAddress);

        if(exchangeAddress == address(0) && exchangeAddress == address(this)) revert Exchange__ZeroAddress();

        uint256 tokenReserve = getReserveBalance();
        uint256 ethBought = getAmount(_tokensSold, tokenReserve, address(this).balance);

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        IExchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(_minTokensBought, msg.sender);

        emit Exchange__TokenToETHSwap(msg.sender, _tokensSold, ethBought);
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

    function ethToToken(uint256 _minTokens, address _recepient) private returns (uint256 tokensBought) {
        uint256 tokenReserve = getReserveBalance();
        tokensBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        
        if (tokensBought < _minTokens) revert Exchange__SlippageExceeded();

        bool success = IERC20(i_tokenAddress).transfer(_recepient, tokensBought);
        if(!success) revert Exchange__ETHToTokenFailed();
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}