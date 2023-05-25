/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGReferralReward {
    function recordData(address account,string memory dataslot,uint256 index) external view returns (uint256);
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

contract PLGReader is permission {
    
    address public owner;
    address public data = 0x5EEddE12d4F65af99a29c27Dcbb9389732ddAC4a;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
    }

    function viewData(address account,string memory dataslot) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](31);
        for(uint256 i=0; i<30; i++){
            result[i] = IPLGReferralReward(data).recordData(account,dataslot,i);
        }
        return result;
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