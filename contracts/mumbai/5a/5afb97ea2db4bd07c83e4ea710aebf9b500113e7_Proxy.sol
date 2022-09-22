/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Proxy {
  address public callee;
  address public deployer;

  constructor (address callee_, address deployer_) {
    callee = callee_;
    deployer = deployer_;
  }

  fallback() external {
    assembly {
      let _target := sload(0)                                                  /* Load the target from storage slot 1 */
      calldatacopy(0x0, 0x0, calldatasize())                                   /* Copy the calldata to memory position f to mem at position t*/    
      let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)  /* Call the target with calldata */
      returndatacopy(0x0, 0x0, returndatasize())
      switch result
        case 0  { revert(0, returndatasize()) }
        default { return (0, returndatasize()) }  
    }
  }
}