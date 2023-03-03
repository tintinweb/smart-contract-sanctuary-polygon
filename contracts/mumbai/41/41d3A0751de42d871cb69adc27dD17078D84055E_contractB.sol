// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


library LibB {
     struct RoleData {
        mapping(address => bool) members;
       
    }
    struct Data {
        address admin;
        mapping(bytes32 => RoleData) _roles;
    }
        

    function diamondStorage() internal pure returns(Data storage db){
        bytes32 StoragePosition = keccak256("diamond.storage.LibB");
        assembly {
            db.slot := StoragePosition
        }
    }
}

contract contractB {

    function addRole(bytes32 role,address _ad) public {
         LibB.Data storage db = LibB.diamondStorage();
        db. _roles[role].members[_ad] = true;
    }


    function removeRole(bytes32 role,address target) public {
         LibB.Data storage db = LibB.diamondStorage();
        db. _roles[role].members[target] = false;
    }

    function transferRole(address from,bytes32 role,address to) public {
         LibB.Data storage db = LibB.diamondStorage();
        require(db. _roles[role].members[msg.sender],"you can't transfer");
        db. _roles[role].members[from] = false;
        db. _roles[role].members[to] = true;
    }

    function renounceAdmin(address otherAddress) public {
        require(msg.sender == LibB.diamondStorage().admin);
         LibB.Data storage db = LibB.diamondStorage();
         db.admin = otherAddress;
    }

}