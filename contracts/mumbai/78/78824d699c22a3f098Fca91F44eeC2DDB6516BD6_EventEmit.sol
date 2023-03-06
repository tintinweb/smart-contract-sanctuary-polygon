// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


contract EventEmit{
    event Staked(address token, uint256 price);

    function ex(uint256 price) external  {
        emit Staked(msg.sender, price);
    }
}