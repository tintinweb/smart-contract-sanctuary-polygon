// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MetaData {
    uint256 public Id = 0;

    struct Data {
        uint256 Id;
        address user;
        string url;
    }

    mapping(uint256 => Data) public DataInfo;

    function setData(string memory _url) public {
        Id += 1;
        DataInfo[Id] = Data(Id, msg.sender, _url);
    }

    function GetData() public view returns (Data[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < Id; i++) {
            if (DataInfo[i + 1].user == msg.sender) {
                count += 1;
            }
        }
        uint256 currentIndex = 0;

        Data[] memory items = new Data[](count);
        for (uint256 i = 0; i <= Id; i++) {
            if (DataInfo[i + 1].user == msg.sender) {
                uint256 currentId = DataInfo[i + 1].Id;
                Data storage currentItem = DataInfo[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}