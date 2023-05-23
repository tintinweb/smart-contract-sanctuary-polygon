/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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

contract UserManagerV1 is permission {
    
    address public owner;

    address[] users;

    struct Users {
        uint256 id;
        address ref;
        bool registerd;
        address[] refmap;
    }

    mapping(address => Users) user;
    
    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
    }

    function getParticipants() public view returns (address[] memory) {
        return users;
    }

    function getUser(address account) public view returns (uint256,address,bool,address[] memory) {
        return (user[account].id,user[account].ref,user[account].registerd,user[account].refmap);
    }

    function getUserId(address account) public view returns (uint256) {
        return user[account].id;
    }

    function getUserReferral(address account) public view returns (address) {
        return user[account].ref;
    }

    function getUserRegistered(address account) public view returns (bool) {
        return user[account].registerd;
    }

    function getUserReferralMap(address account) public view returns (address[] memory) {
        return user[account].refmap;
    }

    function getUserUpline(address account,uint256 level) public view returns (address[] memory) {
        address[] memory result = new address[](level);
        for(uint256 i=0; i<level; i++){
            result[i] = user[account].ref;
            account = user[account].ref;
        }
        return result;
    }

    function register(address referree,address referral) public forRole("operator") returns (bool) {
        if(!user[referree].registerd){
            users.push(referree);
            user[referree].id = users.length-1;
            user[referree].ref = referral;
            user[referree].registerd = true;
            user[referral].refmap.push(referree);
        }
        return true;
    }

    function updateUserWithPermit(address account,uint256 id,address ref,bool registerd,address[] memory refmap) public forRole("operator") returns (bool) {
        user[account].id = id;
        user[account].ref = ref;
        user[account].registerd = registerd;
        user[account].refmap = refmap;
        return true;
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