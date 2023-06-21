/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Create2Deployer {

  error AlreadyDeployed(address addr);
  error FailedOnDeploy(address addr);
  event Create2Deployed(address indexed addr);

  function deploy(bytes32 salt, bytes memory bytecode) public {

    address addr = computeAddress(salt, keccak256(bytecode));

    uint extSize;
    
    assembly {
      extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
    }

    if(extSize > 0) {
      revert AlreadyDeployed(addr);
    }
    assembly {
      addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
    }
    if(addr == address(0)){
      revert FailedOnDeploy(addr);
    }

    emit Create2Deployed(addr);
  }

  function computeAddress(bytes32 salt, bytes32 bytecodeHash) public view returns (address) {
      return computeAddress(salt, bytecodeHash, address(this));
  }

  //From OpenZeppelin Contracts (last updated v4.9.0) (utils/Create2.sol)
  function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) public pure returns (address addr) {
      
      assembly {
          let ptr := mload(0x40) // Get free memory pointer

          // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
          // |-------------------|---------------------------------------------------------------------------|
          // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
          // | salt              |                                      BBBBBBBBBBBBB...BB                   |
          // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
          // | 0xFF              |            FF                                                             |
          // |-------------------|---------------------------------------------------------------------------|
          // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
          // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

          mstore(add(ptr, 0x40), bytecodeHash)
          mstore(add(ptr, 0x20), salt)
          mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
          let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
          mstore8(start, 0xff)
          addr := keccak256(start, 85)
      }
  }
}