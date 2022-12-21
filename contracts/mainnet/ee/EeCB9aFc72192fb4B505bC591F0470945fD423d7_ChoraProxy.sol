/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract ChoraProxy {

    // must stay first declared field here as well as in the master contract
    address internal masterContract;

    constructor(address _masterContract) {
        require(_masterContract != address(0), "Invalid master address");
        masterContract = _masterContract;
    }

    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _masterContract := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // special case - return master contract addr. 0x855d70ba = keccak("getMasterContractAddress()")
            if eq(calldataload(0), 0x855d70ba00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _masterContract)
                return(0, 0x20)
            }

            // delegate everything else to the master contract
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _masterContract, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}