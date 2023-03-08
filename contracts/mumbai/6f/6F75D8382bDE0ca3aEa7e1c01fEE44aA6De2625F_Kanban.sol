// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Kanban {
    enum Stage { Todo, InProgress, Done }
    struct Item {
        uint256 id;
        string title;
        uint256 stage;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemCount;

    event ItemCreated(uint256 id, string title, uint256 stage);
    event ItemMoved(uint256 id, uint256 stage);

    function createItem(string memory _title) public {
        itemCount++;
        items[itemCount] = Item(itemCount, _title, 0);
        emit ItemCreated(itemCount, _title, 0);
    }

    function moveItem(uint256 _itemId, uint256 _newStage) public payable {
        require(_itemId <= itemCount, "Invalid item ID");
        require(_newStage <= 3, "Invalid stage number");

        Item storage item = items[_itemId];
        uint256 currentStage = item.stage;

        require(_newStage > currentStage, "Item must be moved forward");
        require(msg.sender != address(0), "Invalid sender address");

        item.stage = _newStage;
        emit ItemMoved(_itemId, _newStage);

       /* if (currentStage == 0) {
            payable(msg.sender).transfer(0.001 ether);
        }*/
    }
}