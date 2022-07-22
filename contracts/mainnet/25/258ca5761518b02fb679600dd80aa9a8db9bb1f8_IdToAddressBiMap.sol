/**
 *Submitted for verification at polygonscan.com on 2022-07-22
*/

// File: contracts/dex/IdToAddressBiMap.sol


pragma solidity ^0.8.0;


library IdToAddressBiMap {
    struct Data {
        mapping(uint16 => address) idToAddress;
        mapping(address => uint16) addressToId;
    }

    function hasId(Data storage self, uint16 id) public view returns (bool) {
        return self.idToAddress[id + 1] != address(0);
    }

    function hasAddress(Data storage self, address addr) public view returns (bool) {
        return self.addressToId[addr] != 0;
    }

    function getAddressAt(Data storage self, uint16 id) public view returns (address) {
        require(hasId(self, id), "Must have ID to get Address");
        return self.idToAddress[id + 1];
    }

    function getId(Data storage self, address addr) public view returns (uint16) {
        require(hasAddress(self, addr), "Must have Address to get ID");
        return self.addressToId[addr] - 1;
    }

    function insert(Data storage self, uint16 id, address addr) public returns (bool) {
        require(addr != address(0), "Cannot insert zero address");
        require(id != type(uint16).max, "Cannot insert max uint16");
        // Ensure bijectivity of the mappings
        if (self.addressToId[addr] != 0 || self.idToAddress[id + 1] != address(0)) {
            return false;
        }
        self.idToAddress[id + 1] = addr;
        self.addressToId[addr] = id + 1;
        return true;
    }
}