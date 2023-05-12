/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract EnterE {
    function enter(uint gas, address gate, bytes8 _gateKey) external {
        (bool success, bytes memory res) = gate.call{gas: gas}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
        if (!success) {
            if (res.length == 0) revert();
                assembly {
                    // We use Yul's revert() to bubble up errors from the target contract.
                    revert(add(32, res), mload(res))
                }
        }
    }
}