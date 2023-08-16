// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IFactory} from "./interfaces/IFactory.sol";
import {IExchange} from "./interfaces/IExchange.sol";

/**
 * @title GraphKitExchange
 * @author Megabyte
 * @notice This contract is used to exchange ETH and tokens
 */
contract GraphKitExchange is ERC20 {

    //////////////////////////////////////////////////////////////
    ////////////////// ERRORS ////////////////////////////////////
    //////////////////////////////////////////////////////////////
    error GraphKitExchange__ZeroAddress();
    error GraphKitExchange__AddingLiquidityFailed();
    error GraphKitExchange__RemovingLiquidityFailed();
    error GraphKitExchange__ZeroValue();
    error GraphKitExchange__SlippageExceeded();
    error GraphKitExchange__ETHToTokenFailed();
    error GraphKitExchange__TokenToETHSwapFailed();

    //////////////////////////////////////////////////////////////
    ////////////////// EVENTS ////////////////////////////////////
    //////////////////////////////////////////////////////////////
    event GraphKitExchange__LiquidityAdded(address indexed _user, uint256 _ethAmount, uint256 _tokenAmount, uint256 _lpAmount);
    event GraphKitExchange__LiquidityRemoved(address indexed _user, uint256 _ethAmount, uint256 _tokenAmount, uint256 _lpAmount);
    event GraphKitExchange__ETHToTokenSwap(address indexed _user, uint256 _ethAmount, uint256 _tokenAmount);
    event GraphKitExchange__TokenToETHSwap(address indexed _user, uint256 _tokenAmount, uint256 _ethAmount);
    event GraphKitExchange__TokenToTokenSwap(address indexed _user, address indexed _sentTokenAddress, address indexed _receivedTokenAddress);

    //////////////////////////////////////////////////////////////
    ////////////////// CONSTANTS /////////////////////////////////
    //////////////////////////////////////////////////////////////
    uint256 constant PRECISION_INCREAMENT = 1000;
    string constant public NAME = "GraphKitExchange";
    string constant public SYMBOL = "GKE";

    //////////////////////////////////////////////////////////////
    ////////////////// IMMUTABLE /////////////////////////////////
    //////////////////////////////////////////////////////////////
    address public immutable i_tokenAddress;
    address public immutable i_factoryAddress;

    constructor(address _tokenAddress) ERC20(NAME, SYMBOL) {
        if(_tokenAddress == address(0)) revert GraphKitExchange__ZeroAddress();
        i_tokenAddress = _tokenAddress;
        i_factoryAddress = msg.sender;
    }
    
    //////////////////////////////////////////////////////////////
    ////////////////// External Functions ////////////////////////
    //////////////////////////////////////////////////////////////

    /**
     * @notice This function is used to add liquidity to the pool
     * @param _tokenAmount Amount of tokens to be added
     * @dev - If the Reserve is empty then the user can add any amount of tokens and ETH, else the user can add ETH in the ratio of the tokens in the reserve.
     */
    function addLiquidity(uint256 _tokenAmount) external payable returns(uint256){

        if(!(getReserveBalance()>0)) {
            IERC20 token = IERC20(i_tokenAddress);
            if (!token.transferFrom(msg.sender, address(this), _tokenAmount)) revert GraphKitExchange__AddingLiquidityFailed();

            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            emit GraphKitExchange__LiquidityAdded(msg.sender, msg.value, _tokenAmount, liquidity);

            return liquidity;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserveBalance();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            if(tokenAmount < _tokenAmount) revert GraphKitExchange__SlippageExceeded();

            IERC20 token = IERC20(i_tokenAddress);
            if (!token.transferFrom(msg.sender, address(this), _tokenAmount)) revert GraphKitExchange__AddingLiquidityFailed();

            uint256 liquidity = (totalSupply() * msg.value)/ethReserve;
            _mint(msg.sender, liquidity);

            emit GraphKitExchange__LiquidityAdded(msg.sender, msg.value, _tokenAmount, liquidity);

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
        if (_amount < 0) revert GraphKitExchange__ZeroValue();

        ethAmount = (address(this).balance * _amount) / totalSupply();
        tokenAmount = (getReserveBalance() * _amount) / totalSupply();

        _burn(msg.sender, _amount);

        payable(msg.sender).transfer(ethAmount);

        IERC20(i_tokenAddress).transfer( msg.sender, tokenAmount);

        emit GraphKitExchange__LiquidityRemoved(msg.sender, ethAmount, tokenAmount, _amount);

        return (ethAmount, tokenAmount);
    }

    /**
     * @notice This function is used to swap ETH to Tokens
     * @param _minTokens Minimum amount of tokens to be received
     */
    function ethToTokenSwap(uint256 _minTokens) external payable {
        uint256 tokensBought = ethToToken(_minTokens, msg.sender);
        emit GraphKitExchange__ETHToTokenSwap(msg.sender, msg.value, tokensBought);
    }

    /**
     * @notice This function is used to swap Tokens to ETH but with a custom recipient.
     * @param _minTokens Minimum amount of tokens to be received
     * @param _recipient Address of the recipient
     */
    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable {
        ethToToken(_minTokens, _recipient);
    }

    /**
     * @notice This function is used to swap Tokens to ETH
     * @param _tokenSold Amount of tokens to be sold
     * @param _minTokens Minimum amount of tokens to be received
     */
    function tokenToETHSwap(uint256 _tokenSold, uint256 _minTokens) external payable {
        uint256 tokenReserve = getReserveBalance();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance); 
        
        if(ethBought < _minTokens) revert GraphKitExchange__SlippageExceeded();

        (bool success, ) = msg.sender.call{value: ethBought}("");
        if(!success) revert GraphKitExchange__TokenToETHSwapFailed();

        emit GraphKitExchange__TokenToETHSwap(msg.sender, _tokenSold, ethBought);
    }

    /**
     * @notice This function is used to swap Tokens to Token
     * @param _tokensSold Amount of tokens to be sold
     * @param _minTokensBought Minimum amount of tokens to be received
     * @param _tokenAddress Address of the token to be received
     */
    function tokenToTokenSwap (uint256 _tokensSold, uint256 _minTokensBought, address _tokenAddress) external payable{
        address exchangeAddress = IFactory(i_factoryAddress).getExchange(_tokenAddress);

        if(exchangeAddress == address(0) && exchangeAddress == address(this)) revert GraphKitExchange__ZeroAddress();

        uint256 tokenReserve = getReserveBalance();
        uint256 ethBought = getAmount(_tokensSold, tokenReserve, address(this).balance);

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        IExchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(_minTokensBought, msg.sender);

        emit GraphKitExchange__TokenToETHSwap(msg.sender, _tokensSold, ethBought);
    }

    //////////////////////////////////////////////////////////////
    ////////////////// External & Pure Functions /////////////////
    //////////////////////////////////////////////////////////////

    /**
     * @notice This function is used to get the price, either of Token/ETH or ETH/Token
     * @param inputReserve Amount of ETH or Tokens in the reserve
     * @param outputReserve Amount of ETH or Tokens 
     */
    function getPrice(uint256 inputReserve, uint256 outputReserve) external pure returns (uint256) {
        if (inputReserve < 0 && outputReserve < 0) revert GraphKitExchange__ZeroValue();

        return (inputReserve * PRECISION_INCREAMENT)  / outputReserve;
    }

    //////////////////////////////////////////////////////////////
    ////////////////// Public & View Functions ///////////////////
    //////////////////////////////////////////////////////////////

    /**
     * @notice To get the amount of tokens that will be received for a given amount of ETH
     * @param _ethSold Amount of ETH to be sold
     */
    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        if(_ethSold<0) revert GraphKitExchange__ZeroValue();

        uint256 tokenReserve = getReserveBalance();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    /**
     * @notice To get the amount of ETH that will be received for a given amount of Tokens
     * @param _tokenSold Amount of Tokens to be sold
     */
    function getETHAmount(uint256 _tokenSold) public view returns (uint256) {
        if(_tokenSold<0) revert GraphKitExchange__ZeroValue();

        uint256 tokenReserve = getReserveBalance();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    /**
     * @notice To get the amount of tokens in the reserve
     */
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
        if (inputReserve < 0 && outputReserve < 0) revert GraphKitExchange__ZeroValue();

        uint256 inputAmountWithFee = inputAmount * 999;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        
        return numerator / denominator;
    }

    /**
     * @notice This function is used to swap ETH to Tokens
     * @param _minTokens Minimum amount of tokens to be received
     * @param _recepient Address of the recipient
     */
    function ethToToken(uint256 _minTokens, address _recepient) private returns (uint256 tokensBought) {
        uint256 tokenReserve = getReserveBalance();
        tokensBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        
        if (tokensBought < _minTokens) revert GraphKitExchange__SlippageExceeded();

        bool success = IERC20(i_tokenAddress).transfer(_recepient, tokensBought);
        if(!success) revert GraphKitExchange__ETHToTokenFailed();
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}