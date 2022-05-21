// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "ICPO.sol";

// 01: unauthorized
contract Proxy {
  address public immutable logic;
  address public immutable cpo;

  // If you ever change this file
  // Or recompile with a new compiler, this offset will probably be different
  // Run test_get_offset() with 3 verbosity to get the offset
  uint256 internal constant offset = 188;

  constructor(address _cpo, string memory _name) {
    cpo = _cpo;
    logic = ICPO(_cpo).implementations(_name);
  }

  function destroy() public {
    require(msg.sender == cpo, "01");

    address _addr = payable(cpo);
    assembly {
      selfdestruct(_addr)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      // Extract out immutable variable "logic"
      codecopy(0, offset, 20)
      let impl := mload(0)

      switch iszero(impl)
      case 1 {
          revert(0, 0)
      }
      default {

      }

      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(
        gas(),
        shr(96, impl),
        0,
        calldatasize(),
        0,
        0
      )
      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}