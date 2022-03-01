// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Signature.sol";
import "./ERC20PresetMinterPauser.sol";

contract HoneyWasp is Signature, Ownable, ERC20PresetMinterPauser {
    
    mapping (address => uint) public claimByAddress;

    constructor() ERC20PresetMinterPauser("Honey Wasp", "HON") { 
        _mint(_msgSender(), 100000*10**18);

    }

    // input the getEthSignedHash results and the signature hash results
    // the output of this function will be the account number that signed the original message
    function claim(uint _amount, uint _nonce, bytes memory _signature) public returns (address) {
        address signer = verifySignature(_amount,  _nonce,  _signature);        
        require(signer == owner(), "Signer is not owner");
        uint amountWei = _amount * 1e18;
        _mint(_msgSender(), amountWei);
        claimByAddress[_msgSender()] += amountWei; 

        return signer;
    }
}