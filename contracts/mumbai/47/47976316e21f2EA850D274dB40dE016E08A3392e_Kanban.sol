// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Kanban {
    enum Stage { Todo, InProgress, Done }
    struct Item {
        string id;
        string title;
        string stage;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemCount;

    event ItemCreated(string id, string title, string stage);
    event ItemMoved(string id, string stage);

    function createItem(string memory _title) public {
        itemCount++;
        string memory idStr = toString(itemCount);
        items[itemCount] = Item(idStr, _title, toString(uint256(0)));
        emit ItemCreated(idStr, _title, toString(uint256(0)));
    }

    function moveItem(string memory _itemId, string memory _newStage) public payable {
        uint256 itemId = parseInt(_itemId);
        uint256 newStage = parseInt(_newStage);
        require(itemId <= itemCount, "Invalid item ID");
        require(newStage <= 3, "Invalid stage number");

        Item storage item = items[itemId];
        uint256 currentStage = parseInt(item.stage);

        require(newStage > currentStage, "Item must be moved forward");
        require(msg.sender != address(0), "Invalid sender address");

        item.stage = toString(newStage);
        emit ItemMoved(_itemId, _newStage);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function parseInt(string memory value) internal pure returns (uint256) {
        bytes memory b = bytes(value);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }
}