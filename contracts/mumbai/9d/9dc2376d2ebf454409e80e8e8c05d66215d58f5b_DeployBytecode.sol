/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

pragma solidity ^0.7.6;

contract DeployBytecode {
    
    // @custom:dev-run-script
    function deployContract(bytes32 salt, bytes memory contractBytecode) public {
        address addr;
        assembly {
            addr := create2(0, add(contractBytecode, 0x20), mload(contractBytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
}