// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


contract IsContract {

    constructor() { }

    function verify() 
        public view
    {
        address sender = msg.sender;
        uint size;
        assembly {
            size := extcodesize(sender)
        }
        require(size == 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IsContract.sol";

contract TriggerVerifySuccess {

    constructor(address _utilAddress) 
    {
        IsContract util = IsContract(_utilAddress);
        util.verify();
    }
}