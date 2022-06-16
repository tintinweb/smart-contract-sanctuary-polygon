// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC777.sol";

contract AXTR is ERC777 {
    constructor(
        uint256 initialSupply,
        address[] memory at
        //address _trustedSigner
    )
    ERC777("AT7test11", "AXTR", at)
    //GSNRecipientSignature(_trustedSigner)
   
    {
        _mint(msg.sender, initialSupply, "","");
    }

}