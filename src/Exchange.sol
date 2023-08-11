// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Exchange {

    error Exchange__ZeroAddress();
    error Exchange__AddingLiquidityFailed();

    address public immutable i_tokenAddress;

    constructor(address _tokenAddress) {
        if(_tokenAddress != address(0)) revert Exchange__ZeroAddress();
        i_tokenAddress = _tokenAddress;
    }

    function addLiquidity(uint256 _tokenAmount) external payable {
        IERC20 token = IERC20(i_tokenAddress);
        if (token.transferFrom(msg.sender, address(this), _tokenAmount)) revert Exchange__AddingLiquidityFailed();
    }

    function getReserverBalance() external view returns (uint256) {
        return IERC20(i_tokenAddress).balanceOf(address(this));
    }
}