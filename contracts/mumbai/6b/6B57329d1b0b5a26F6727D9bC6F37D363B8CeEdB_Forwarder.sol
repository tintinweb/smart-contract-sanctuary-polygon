//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ECDSA.sol";

contract Forwarder {
    using ECDSA for bytes32;
  
    // verify the data and execute the data at the target address
    function forward(address _to, bytes calldata _data, bytes memory _signature) external returns (bytes memory _result) {
        bool success;
    
        verifySignature(_to, _data, _signature);
    
        (success, _result) = _to.call(_data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
  
    // Recover signer public key and verify that it's a whitelisted signer.
    function verifySignature(address _to, bytes calldata _data, bytes memory signature) private pure {
        require(_to != address(0), "invalid target address");
    
        bytes memory payload = abi.encode(_to, _data);
        keccak256(payload).toEthSignedMessageHash().recover(signature);
    }
}