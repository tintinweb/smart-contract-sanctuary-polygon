// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibA{
struct DiamondStorage {
    uint256 number;
}

function diamondStorage() internal pure returns(DiamondStorage storage ds) {
    bytes32 storagePosition = keccak256("diamond.storage.LibA");
    assembly {
        ds.slot := storagePosition
    }

}
}

contract contractA {
    function setter(uint256 _number) external {
        LibA.DiamondStorage storage ds = LibA.diamondStorage();
        ds.number += _number;
    }

    function getter() external view returns (uint256){
        return LibA.diamondStorage().number;
        
    }
}