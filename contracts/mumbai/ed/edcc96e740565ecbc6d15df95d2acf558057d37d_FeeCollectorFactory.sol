/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeCollector {
    receive() external payable {}
}

contract FeeCollectorFactory {
    event FeeCollectorCreated(address indexed feeCollectorAddress, bytes32 indexed salt);

function createFeeCollector(uint256 salt) external {
   // require(getFeeCollectorAddress(salt) == address(0), "FeeCollector already exists");
    bytes memory bytecode = type(FeeCollector).creationCode;
    bytes32 hash = keccak256(abi.encodePacked(bytecode, salt));
    address feeCollectorAddress;
    assembly {
        feeCollectorAddress := create2(0, add(bytecode, 32), mload(bytecode), hash)
        if iszero(extcodesize(feeCollectorAddress)) { revert(0, 0) }
    }
}


function getFeeCollectorAddress(uint256 salt) public view returns (address) {
    bytes memory bytecode = type(FeeCollector).creationCode;
    bytes32 hash = keccak256(abi.encodePacked(bytecode, salt));
    return address(uint160(uint256(hash)));
}

}