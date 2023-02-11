// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Warranty {
    mapping(bytes8 => Data) public Cards;
    address public owner;
    uint256 public total;
    uint256 public burned;
    uint256 public updated;

    struct Data {
        bool created;
        bool burned;
        bool updated;
        string data;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier _isOwner() {
        require(owner == msg.sender, "Not a owner");
        _;
    }

    function addWaranty(
        bytes8 id,
        string memory data_
    ) public _isOwner returns (bool) {
        Data memory card = Cards[id];
        require(!card.created, "created already");
        Data memory _data;
        _data.created = true;
        _data.data = data_;
        Cards[id] = _data;
        total++;
        return true;
    }

    function update(
        bytes8 id,
        string memory data_
    ) public _isOwner returns (bool) {
        Data storage card = Cards[id];
        require(!card.burned && !card.updated, "burned or updated already");
        card.updated = true;
        card.data = data_;
        updated++;
        return true;
    }

    function burn(bytes8 id) public _isOwner returns (bool) {
        Data storage card = Cards[id];
        require(!card.burned, "burned already");
        card.burned = true;
        card.data = "";
        burned++;
        return true;
    }

    function generateBytes8() public view returns (bytes8) {
        return bytes8(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
    }

    function generateBytes8Array(
        uint256 _num
    ) public view returns (bytes8[] memory qrHash) {
        qrHash = new bytes8[](_num);
        for (uint256 i = 0; i < _num; i++) {
            qrHash[i] = (
                bytes8(
                    keccak256(abi.encodePacked(block.timestamp, i, msg.sender))
                )
            );
        }
        return qrHash;
    }

    function burnAdnCreate(
        bytes8 id,
        bytes8 id2,
        string memory data_
    ) public _isOwner returns (bool) {
        burn(id);
        addWaranty(id2, data_);
        return true;
    }
}