// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract EnumerableMap {
    struct MapData{
        uint key;
        address value;
    }

    MapData[] public items;
    
    mapping(uint => uint) public key2Index;
    mapping(uint => bool) public isExistKey;

    event Set(uint key);
    event Remove(uint key);
    
    function set(uint _key, address _value) public {
        require(!isExistKey[_key], "Duplicated key");

        items.push(MapData(
            {key : _key, value : _value}
        ));
        
        key2Index[_key] = items.length - 1;
        isExistKey[_key] = true;

        emit Set(_key);
    }

    function remove(uint _key) public {
        require(isExistKey[_key], "No Key!");

        uint _index = key2Index[_key];
        removeAt(_index);
    }

    function removeAt(uint _index) public {
        uint total_ids = items.length;
        require(_index < total_ids, "Wrong value range");

        uint _key = items[_index].key;
        uint _lastKey = items[total_ids - 1].key;

        key2Index[_lastKey] = _index;
        items[_index] = items[total_ids - 1];
        items.pop();

        delete key2Index[_key];
        isExistKey[_key] = false;

        emit Remove(_key);
    }

    function getItem(uint _key) public view returns (MapData memory){
        require(isExistKey[_key], "No Key!");

        uint _index = key2Index[_key];
        return items[_index];
    }

    function at(uint _index) public view returns (MapData memory){
        uint total_ids = items.length;
        require(_index < total_ids, "Wrong value range");

        return items[_index];
    }

    function getLength() public view returns (uint) {
        return items.length;
    }
}