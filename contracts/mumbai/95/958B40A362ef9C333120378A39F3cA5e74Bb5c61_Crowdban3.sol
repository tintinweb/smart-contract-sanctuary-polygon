// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdban3 {
    struct Item {
        string id;
        string stage;
        address assignedTo;
        uint256 reward;
        bool isMoved; // Added flag to track item movement
        bool isPaid;
    }

    Item[] public items;
    mapping(address => uint[]) assignedItems;

    event ItemCreated(string id, string stage, address assignedTo, uint256 reward);
    event ItemMoved(string id, string oldStage, string newStage, address assignedTo, uint256 reward);
    event RewardPaid(string id, address to, uint256 amount);

    constructor() {}

	 function createItem(string memory id, string memory stage, address assignedTo) public payable {
        uint256 reward = msg.value;
        items.push(Item(id, stage, assignedTo, reward, false,false));
        assignedItems[assignedTo].push(items.length - 1);
        emit ItemCreated(id, stage, assignedTo, reward);
        (bool sent,) = payable(address(this)).call{value: reward}("");
    require(sent, "Failed to send Ether to the contract");
    }
    
    function moveItem(string memory itemId, string memory newStage) public {
        uint id = findItemId(itemId);
        require(id < items.length, "Invalid item ID");
        Item storage item = items[id];
        require(msg.sender == item.assignedTo, "Only assigned user can move item");
        require(item.reward > 0, "Reward amount is zero");
        require(!item.isPaid, "Reward already paid");
        require(!item.isMoved, "Item has already been moved"); // Added check for item movement

        string memory oldStage = item.stage;
        item.stage = newStage;

        emit ItemMoved(itemId, oldStage, newStage, item.assignedTo, item.reward);
        item.isMoved = true; // Marking item as moved
    }

    function withdrawReward(string memory itemId) public {
        uint id = findItemId(itemId);
        require(id < items.length, "Invalid item ID");
        Item storage item = items[id];
        require(item.isMoved, "Item has not been moved"); // Allowing reward withdrawal only after item movement
        require(!item.isPaid, "Reward already paid");
        require(msg.sender == item.assignedTo, "Only assigned user can withdraw the reward");

        uint256 rewardAmount = item.reward;
        item.reward = 0;

        // This is the new code to make the transaction external
        (bool success, ) = payable(address(item.assignedTo)).call{value: rewardAmount}("");

        require(success, "Failed to send Ether");

        item.isPaid = true; // Marking the reward as paid

        emit RewardPaid(itemId, item.assignedTo, rewardAmount);
    }

    function getItemIdsByAssignee(address assignee) public view returns (uint[] memory) {
        return assignedItems[assignee];
    }

    function findItemId(string memory itemId) internal view returns (uint) {
        for (uint i = 0; i < items.length; i++) {
            if (keccak256(bytes(items[i].id)) == keccak256(bytes(itemId))) {
                return i;
            }
        }
        return items.length;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRewardAmount(string memory itemId) public view returns (uint256) {
        uint id = findItemId(itemId);
        require(id < items.length, "Invalid item ID");
        Item storage item = items[id];
        return item.reward;
    }

    receive() external payable {}
}