/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// File: contracts/migrate/InviteStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library InviteStorage {

    bytes32 public constant sSlot = keccak256("InviteStorage.storage.location");

    struct Storage{
        address owner;
        uint256 lastId;
        mapping(uint256 => address)  indexs;
        mapping(address => address)  inviter;
        mapping(address => address[])  inviterList;
        mapping(address => bool)  whiteListed;
        mapping(address => uint256)  userIndex;
    }

    function load() internal pure returns (Storage storage s) {
        bytes32 loc = sSlot;
        assembly {
        s_slot := loc
        }
    }

}

// File: contracts/Invite.sol


pragma solidity ^0.6.12;


contract Invite {


    constructor(uint256 index) public {
        init(index);
    }

    modifier onlyOwner() {
        require(InviteStorage.load().owner == msg.sender, "Invite.onlyOwner: caller is not the owner");
        _;
    }

    function init(uint256 index) public {
        require(InviteStorage.load().owner == address(0), 'Invite.init: already initialised');
        InviteStorage.load().owner = msg.sender;
        InviteStorage.load().lastId = index;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        InviteStorage.load().owner = newOwner;
    }

    function owner() public view returns (address){
        return InviteStorage.load().owner;
    }

    function setWhiteList(address[] memory users) public onlyOwner {
        InviteStorage.Storage storage inviteData = InviteStorage.load();
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            inviteData.whiteListed[user] = true;
            if (inviteData.userIndex[user] == 0) {
                inviteData.userIndex[user] = inviteData.lastId;
                inviteData.indexs[inviteData.lastId] = user;
                inviteData.lastId = inviteData.lastId + 1;
            }
        }
    }

    function repairInviteUser(address[] memory inviters,address[] memory inviteUsers) public onlyOwner{
        for (uint256 i = 0; i < inviters.length; i++) {
            saveInviteUser(inviters[i],inviteUsers[i]);
        }
    }

    function setInviteUser(address inviter) public {
        InviteStorage.Storage storage inviteData = InviteStorage.load();
        require(!inviteData.whiteListed[msg.sender], 'whiteList user cannot be invited');
        saveInviteUser(inviter,msg.sender);
    }

    function saveInviteUser(address inviter,address inviteUser) internal {
        InviteStorage.Storage storage inviteData = InviteStorage.load();
        if (inviteData.userIndex[inviteUser] == 0) {
            inviteData.userIndex[inviteUser] = inviteData.lastId;
            inviteData.indexs[inviteData.lastId] = inviteUser;
            inviteData.lastId = inviteData.lastId + 1;
        }
        if (inviteData.whiteListed[inviter] || inviteData.inviter[inviter] != address(0)) {
            inviteData.inviter[inviteUser] = inviter;
            inviteData.inviterList[inviter].push(inviteUser);
        }
    }


    function getInviteCount(address inviter) external view returns (uint256) {
        return InviteStorage.load().inviterList[inviter].length;
    }

    function lastId() public view returns (uint256){
        return InviteStorage.load().lastId;
    }

    function indexs(uint256 id) public view returns (address){
        return InviteStorage.load().indexs[id];
    }

    function inviter(address user) public view returns (address){
        return InviteStorage.load().inviter[user];
    }

    function inviterList(address inviter) public view returns (address[] memory){
        return InviteStorage.load().inviterList[inviter];
    }

    function whiteListed(address user) public view returns (bool){
        return InviteStorage.load().whiteListed[user];
    }

    function userIndex(address user) public view returns (uint256){
        return InviteStorage.load().userIndex[user];
    }
}