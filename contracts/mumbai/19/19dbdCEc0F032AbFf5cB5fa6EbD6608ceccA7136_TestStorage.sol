// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract TestStorage {
    bytes[] public abiStorage;

    function store(
        string calldata _string1,
        string calldata _string2,
        string calldata _string3,
        uint256 _data
    ) external {
        bytes memory newItem = abi.encode(
            block.timestamp,
            _string1,
            _string2,
            _string3,
            _data
        );
        abiStorage.push(newItem);
    }

    function read(uint256 _index)
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            string memory,
            uint256
        )
    {
        return
            abi.decode(
                abiStorage[_index],
                (uint256, string, string, string, uint256)
            );
    }

    function retrieveAll() external view returns (bytes[] memory) {
        return abiStorage;
    }
}