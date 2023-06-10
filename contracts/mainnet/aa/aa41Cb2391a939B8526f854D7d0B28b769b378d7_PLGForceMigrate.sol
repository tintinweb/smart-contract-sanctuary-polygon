/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGMigrate {
    function getPendingId() external view returns (uint256[] memory);
    function getDataFromId(uint256 id) external view returns (address,uint256[] memory,uint256);
    function approveId(uint256 id,bool force) external returns (bool);
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

contract PLGForceMigrate is permission {

    address public owner;
    address public migrateV2 = 0xBA376019C5535336950F176777326A2C173b5df5;

    uint256[] public reject;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
    }

    function viewReject() public view returns (uint256[] memory) {
        return reject;
    }

    function updateMigration(bool isForce) public forRole("owner") returns (bool) {
        uint256[] memory pendingTx = IPLGMigrate(migrateV2).getPendingId();
        for(uint256 i=0; i<pendingTx.length; i++){
            (,,uint256 status) = IPLGMigrate(migrateV2).getDataFromId(pendingTx[i]);
            if(status==1){
                try IPLGMigrate(migrateV2).approveId(pendingTx[i],isForce) {} catch { reject.push(i); }
            }
        }
        return true;
    }

    function purgeETH() public forRole("owner") returns (bool) {
      _clearStuckBalance(owner);
      return true;
    }

    function _clearStuckBalance(address receiver) internal {
      (bool success,) = receiver.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
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