// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// alternative design to MsgFacet
// FacetLib contains the same functionality as MsgFacet, except with internal function calls

library FacetLib {
  // specify psuedorandom storage slot to avoid overwriting vars
  bytes32 internal constant STORAGE_LOCATION =
    keccak256('FacetLib.hashed.location');

  // storage layout
  struct Storage {
    string message;
  }

  function getStorage() internal pure returns (Storage storage s) {
    bytes32 position = STORAGE_LOCATION;
    assembly {
      s.slot := position
    }
  }

  function setMsg(string calldata _message) internal {
    Storage storage s = getStorage();
    s.message = _message;
  }

  function getMsg() internal view returns (string memory m) {
    m = getStorage().message;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './FacetLib.sol';

contract WriteMsg {
  function setMsg(string calldata _message) external {
    FacetLib.setMsg(_message);
  }
}