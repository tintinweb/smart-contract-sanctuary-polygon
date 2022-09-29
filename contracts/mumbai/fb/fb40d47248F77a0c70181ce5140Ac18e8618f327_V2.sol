// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./contractV1.sol";

contract V2 is V1 {
    function decrease() external {
       value -= 1;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract V1 {
   uint public value;
   address public deployer;

   function initialValue(uint _num) external {
       deployer = msg.sender;
       value=_num;
   }

   function increase() external {
       value += 1;
   }
}