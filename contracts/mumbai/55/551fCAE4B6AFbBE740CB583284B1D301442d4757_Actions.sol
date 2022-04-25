/**
 *Submitted for verification at polygonscan.com on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Aave {
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;

    function withdrawETH(address lendingPool, uint256 amount, address to) external;
}

contract Actions {

    address public constant aaveAddress = address(0x9BBA071d1f2A397Da82687e951bFC0407280E348);
    address public constant lendingProtocol = address(0xEce3383269ccE0B2ae66277101996b58c482817B);
    uint256 public constant ONE_WEEK_IN_SECONDS = 604800;

    address owner;

    receive() external payable {}

    function depositToAave() external {
        if (address(this).balance < 1 ** 18) {
            return;
        }

        Aave(aaveAddress).depositETH{value : address(this).balance - 1 ** 18}(lendingProtocol, address(this), uint16(0));
    }

    function withdrawFromAave() external {
        if (address(this).balance < 1 ** 18) {
            return;
        }

        Aave(aaveAddress).withdrawETH(lendingProtocol, 1 ** 18, address(this));
    }

    function withdraw() public {
        payable(owner).transfer(address(this).balance);
    }

    constructor(address a) {
        owner = msg.sender;
    }
}