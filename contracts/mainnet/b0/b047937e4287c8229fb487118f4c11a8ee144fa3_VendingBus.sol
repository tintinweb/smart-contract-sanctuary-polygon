/**
 *Submitted for verification at polygonscan.com on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/* A lucemans contract */
contract VendingBus {

    event Complete(uint256 item_id);

    mapping(uint256 => uint256) prices;
    address immutable owner = msg.sender;

    function setPrice(uint256 item_id, uint256 price) public {
        require(msg.sender == owner, "You do not have permission to set this");
        prices[item_id] = price;
    }

    function transacts(uint256 item_id) public payable {
        require(prices[item_id] > 0, "This item is not for sale.");
        require(msg.value >= prices[item_id], "You did not meet the minimum amount.");
        emit Complete(item_id);
    }

    function cleanup() public {
        payable(owner).transfer(address(this).balance);
    }
}