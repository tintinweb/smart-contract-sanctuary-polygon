// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibMyStorage} from "../libraries/LibMyStorage.sol";

contract StorageFacet {
    function getMapValue() external view returns (uint256) {
        return LibMyStorage.getVar3();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibMyStorage {
    bytes32 constant MYSTORAGEPOSITION = keccak256("diamond.storage.position");

    struct StorageStruct {
        uint256 var1;
        address var2;
        mapping(address => uint256) var3;
    }

    function DiamondStorageStruct() internal pure returns (StorageStruct storage mystorage) {
        bytes32 position = MYSTORAGEPOSITION;
        assembly {
            mystorage.slot := position
        }
    }

    function setStorageStruct(uint256 _var1, address _var2) internal {
        StorageStruct storage ss = DiamondStorageStruct();
        ss.var1 = _var1;
        ss.var2 = _var2;
        ss.var3[msg.sender] = 25;
    }

    function getVar1() internal view returns (uint256) {
        return DiamondStorageStruct().var1;
    }

    function getVar2() internal view returns (address) {
        return DiamondStorageStruct().var2;
    }

    function getVar3() internal view returns (uint256) {
        return DiamondStorageStruct().var3[msg.sender];
    }
}