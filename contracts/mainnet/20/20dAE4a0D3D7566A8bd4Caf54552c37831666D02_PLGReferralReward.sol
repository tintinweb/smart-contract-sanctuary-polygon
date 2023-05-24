/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGUser {
    function getUserUpline(address account,uint256 level) external view returns (address[] memory);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }

    modifier forRole(string memory str) {
        require(checkpermit(msg.sender,str),"Permit Revert!");
        _;
    }
}

contract PLGReferralReward is permission {
    
    address public owner;

    mapping(address => mapping(address => bool)) public isCount;
    mapping(address => mapping(uint256 => uint256)) public members;
    mapping(address => mapping(string => mapping(uint256 => uint256))) public recordData;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
    }

    function rewardDistribute(address account,address userContract,string memory dataSlot) public payable forRole("router") returns (bool) {
        address[] memory addrs = IPLGUser(userContract).getUserUpline(account,30);
        uint256 senderAmount = msg.value/30;
        for(uint256 i=0; i<30; i++){
            address reacts = safeAddr(addrs[i]);
            if(!isCount[account][reacts]){
                isCount[account][reacts] = true;
                members[reacts][i+1] += 1;
            }
            recordData[reacts][dataSlot][i] += senderAmount;
            (bool success,) = reacts.call{ value: senderAmount }("");
            require(success, "!fail to send eth");
        }
        return true;
    }

    function safeAddr(address account) internal view returns (address) {
        if(account==address(0)){ return owner; }else{ return account; }
    }

    function grantRole(address adr,string memory role) public forRole("owner") returns (bool) {
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public forRole("owner") returns (bool) {
        clearpermit(adr,role);
        return true;
    }

    function transferOwnership(address adr) public forRole("owner") returns (bool) {
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

    receive() external payable {}
}