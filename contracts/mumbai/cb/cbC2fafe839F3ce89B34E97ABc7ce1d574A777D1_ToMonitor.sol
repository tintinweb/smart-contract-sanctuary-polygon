//SPDX-License-Identifier: MI
pragma solidity ^0.8.9;

contract ToMonitor {
    struct Data {
        string title;
        bool status;
        address owner;
        uint256 count;
    }

    uint256 count = 0;

    Data[] private data;

    function addData(string memory _title) public {
        count += 1;
        data.push(Data(_title, false, msg.sender, count));
    }

    function getStatus(uint _index) public view returns (bool) {
        Data storage dataStatus = data[_index];
        return dataStatus.status;
    }

    function getAllData() external view returns (Data[] memory) {
        return data;
    }

    function changeStatus(uint _index) public {
        Data storage dataStatus = data[_index];
        require(
            msg.sender == dataStatus.owner,
            "Only owner can change status!"
        );

        if (dataStatus.status) {
            dataStatus.status = false;
        } else {
            dataStatus.status = true;
        }
    }
}