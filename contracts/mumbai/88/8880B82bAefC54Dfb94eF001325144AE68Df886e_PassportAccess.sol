// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PassportAccess {
    enum AccessLevel {
        None,
        Whitelist,
        Owner
    }

    mapping(address => AccessLevel) public accessLevels;

    event MemberAdded(address member);
    event MemberRemoved(address member);

    string[] private info;
    address public owner;

    constructor() {
        owner = msg.sender;
        accessLevels[msg.sender] = AccessLevel.Owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyWhitelist() {
        require(accessLevels[msg.sender] >= AccessLevel.Whitelist, "Only whitelist");
        _;
    }

    event InfoChange(string oldInfo, string newInfo);

    function getInfo(uint256 index) public view returns (string memory) {
        require(index < info.length, "Invalid index");
        return info[index];
    }

    function addInfo(string memory _info) public onlyWhitelist {
        info.push(_info);
        emit InfoChange("", _info);
    }

    function setInfo(uint256 index, string memory _info) public onlyWhitelist {
        require(index < info.length, "Invalid index");
        emit InfoChange(info[index], _info);
        info[index] = _info;
    }

    function listInfo() public view returns (string[] memory) {
        return info;
    }

    function delMember(address _member) public onlyOwner {
        accessLevels[_member] = AccessLevel.None;
        emit MemberRemoved(_member);
    }

    function addMember(address _member) public onlyOwner {
        accessLevels[_member] = AccessLevel.Whitelist;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyOwner {
        accessLevels[_member] = AccessLevel.None;
        emit MemberRemoved(_member);
    }
}