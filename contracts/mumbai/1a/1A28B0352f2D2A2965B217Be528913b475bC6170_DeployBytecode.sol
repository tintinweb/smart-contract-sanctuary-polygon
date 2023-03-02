/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

pragma solidity ^0.5.5;

contract DeployBytecode {
    
    address public contractAddress;
    function deployBytecode(bytes memory bytecode) public returns (address) {
        address retval;
        assembly{
            mstore(0x0, bytecode)
            retval := create(0,0xa0, calldatasize)
        }
        contractAddress=retval;
        return retval;
   }
}