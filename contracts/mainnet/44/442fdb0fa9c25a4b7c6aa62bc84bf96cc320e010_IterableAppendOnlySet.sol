/**
 *Submitted for verification at polygonscan.com on 2022-07-22
*/

// File: contracts/dex/IterableAppendOnlySet.sol


pragma solidity ^0.8.0;


library IterableAppendOnlySet {
    struct Data {
        mapping(address => address) nextMap;
        address last;
        uint96 size; // width is chosen to align struct size to full words
    }

    function insert(Data storage self, address value) public returns (bool) {
        if (contains(self, value)) {
            return false;
        }
        self.nextMap[self.last] = value;
        self.last = value;
        self.size += 1;
        return true;
    }

    function contains(Data storage self, address value) public view returns (bool) {
        require(value != address(0), "Inserting address(0) is not supported");
        return self.nextMap[value] != address(0) || (self.last == value);
    }

    function first(Data storage self) public view returns (address) {
        require(self.last != address(0), "Trying to get first from empty set");
        return self.nextMap[address(0)];
    }

    function next(Data storage self, address value) public view returns (address) {
        require(contains(self, value), "Trying to get next of non-existent element");
        require(value != self.last, "Trying to get next of last element");
        return self.nextMap[value];
    }
}