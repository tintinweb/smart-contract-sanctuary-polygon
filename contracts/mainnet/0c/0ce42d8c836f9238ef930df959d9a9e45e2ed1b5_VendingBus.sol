/**
 *Submitted for verification at polygonscan.com on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * v1.1
* A lucemans contract
 */
contract VendingBus {

    event Complete(address user, uint256 item_id);

    mapping(uint256 => uint256) public prices;
    address public immutable owner = msg.sender;
    uint256 public max_items = 10e2; /* req: multiple of 10 */

    function setPrice(uint256 item_id, uint256 price) public {
        require(msg.sender == owner, "You do not have permission to set this");
        prices[item_id] = price;
    }

    receive() external payable {
        uint256 item_id = msg.value % max_items; /* Lowest number above product limit */
        require(prices[item_id] > 0, "This item is not for sale.");
        require(msg.value >= (prices[item_id] - item_id), "You did not meet the minimum amount.");
        emit Complete(msg.sender, item_id);
    }

    function cleanup() public {
        payable(owner).transfer(address(this).balance);
    }
}