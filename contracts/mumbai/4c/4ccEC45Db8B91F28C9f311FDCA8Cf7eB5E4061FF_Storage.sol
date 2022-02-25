// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces/IStorage.sol";

contract Storage is IStorage {
    mapping(string => Data) private allData;
    string[] private keys;

    modifier onlyOwner(string memory _key) {
        require(allData[_key].owner != address(0), 'NO_OWNER');
        require(msg.sender == allData[_key].owner, 'FORBIDDEN');
        _;
    }

    modifier notEmpty(string memory _value) {
        bytes memory byteValue = bytes(_value);
        require(byteValue.length != 0, 'NO_VALUE');
        _;
    }

    function getData(string memory _key) external override view notEmpty(_key) returns(Data memory) {
        return _keyData(_key);
    }

    function allKeys() external override view returns(string[] memory) {
        return keys;
    }

    function allKeysData() external override view returns(Data[] memory) {
        Data[] memory _allKeysData = new Data[](keys.length);
        for(uint x; x < keys.length; x++) {
            _allKeysData[x] = _keyData(keys[x]);
        }
        return _allKeysData;
    }

    function setData(string memory _key, Data memory _data) external override notEmpty(_key) {
        if (allData[_key].owner != address(0)) {
            require(msg.sender == allData[_key].owner, 'FORBIDDEN');
        } else {
            keys.push(_key);
        }
        allData[_key].owner = _data.owner;
        allData[_key].info = _data.info;
    }

    function clearData(string memory _key) external override notEmpty(_key) onlyOwner(_key) {
        delete allData[_key];
        bool arrayOffset;
        for(uint x; x < keys.length - 1; x++) {
            if (keccak256(abi.encodePacked(keys[x])) == keccak256(abi.encodePacked(_key))) {
                arrayOffset = true;
            }
            if (arrayOffset) keys[x] = keys[x + 1];
        }
        if (arrayOffset) keys.pop();
    }

    function _keyData(string memory _key) private view notEmpty(_key) returns(Data memory _data) {
        _data = Data({
            owner: allData[_key].owner,
            info: allData[_key].info
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IStorage {
    struct Data {
        address owner;
        string info;
    }

    function getData(string memory _key) external view returns(Data memory);
    function allKeys() external view returns(string[] memory);
    function allKeysData() external view returns(Data[] memory);
    function setData(string memory _key, Data memory _data) external;
    function clearData(string memory _key) external;
}