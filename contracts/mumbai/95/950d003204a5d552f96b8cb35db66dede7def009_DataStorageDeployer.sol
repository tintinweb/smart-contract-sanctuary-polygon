// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DataStorage.sol";

contract DataStorageDeployer {
    address[] public dataStorages;
    uint256 public dataStoragesCount;

    function deploy(address dataFeed) public returns (address) {
        DataStorage dataStorage = new DataStorage(dataFeed);
        dataStorages.push(address(dataStorage));
        dataStoragesCount++;
        return address(dataStorage);
    }
}