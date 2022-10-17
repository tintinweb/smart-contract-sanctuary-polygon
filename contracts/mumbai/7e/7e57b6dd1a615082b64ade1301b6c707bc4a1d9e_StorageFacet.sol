// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibMyStorage} from "../libraries/LibMyStorage.sol";

contract StorageFacet {
    function getValue()
        external
        view
        returns (
            uint256,
            address,
            uint256,
            bool
        )
    {
        return LibMyStorage.getValues();
    }

    function setValues(
        uint256 _var1,
        address _var2,
        uint256 _var3
    ) external {
        LibMyStorage.setStorageStruct(_var1, _var2, _var3);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibMyStorage {
    bytes32 constant MYSTORAGEPOSITION = keccak256("diamond.storage.position.slot");

    struct StorageStruct {
        uint256 var1;
        address var2;
        mapping(address => uint256) var3;
        bool var4;
    }

    function DiamondStorageStruct() internal pure returns (StorageStruct storage mystorage) {
        bytes32 position = MYSTORAGEPOSITION;
        assembly {
            mystorage.slot := position
        }
    }

    function setStorageStruct(uint256 _var1, address _var2,uint256 _var3) internal {
        StorageStruct storage ss = DiamondStorageStruct();
        ss.var1 = _var1;
        ss.var2 = _var2;
        ss.var3[msg.sender] = _var3;
        ss.var4 = true;
    }

    function getValues()
        internal
        view
        returns (
            uint256 var1_,
            address var2_,
            uint256 var3_,
            bool var4_
        )
    {
        (var1_) = DiamondStorageStruct().var1;
        (var2_) = DiamondStorageStruct().var2;
        (var3_) = DiamondStorageStruct().var3[msg.sender];
        (var4_) = DiamondStorageStruct().var4;
    }
}