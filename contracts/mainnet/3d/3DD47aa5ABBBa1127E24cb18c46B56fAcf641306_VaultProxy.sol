/**
 *Submitted for verification at polygonscan.com on 2022-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract VaultProxy {
  bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation')
  bytes32 constant OWNER_SLOT =
      0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')

  constructor(address _implementationAddress, address _ownerAddress) {
    assembly {
      sstore(IMPLEMENTATION_SLOT, _implementationAddress)
      sstore(OWNER_SLOT, _ownerAddress)
    }
  }

  function implementationAddress() external view returns (address _implementationAddress) {
    assembly {
      _implementationAddress := sload(IMPLEMENTATION_SLOT)
    }
  }

  function ownerAddress() public view returns (address _ownerAddress) {
    assembly {
      _ownerAddress := sload(OWNER_SLOT)
    }
  }

  function updateImplementationAddress(address _implementationAddress) external {
    require(msg.sender == ownerAddress(), "Only owners can update implementation");
    assembly {
      sstore(IMPLEMENTATION_SLOT, _implementationAddress)
    }
  }

  function updateOwnerAddress(address _ownerAddress) external {
    require(msg.sender == ownerAddress(), "Only owners can update owners");
    assembly {
      sstore(OWNER_SLOT, _ownerAddress)
    }
  }

  fallback() external {
    assembly {
      let contractLogic := sload(IMPLEMENTATION_SLOT)
      calldatacopy(0x0, 0x0, calldatasize())
      let success := delegatecall(
        gas(),
        contractLogic,
        0x0,
        calldatasize(),
        0,
        0
      )
      let returnDataSize := returndatasize()
      returndatacopy(0, 0, returnDataSize)
      switch success
      case 0 {
        revert(0, returnDataSize)
      }
      default {
        return(0, returnDataSize)
      }
    }
  }
}