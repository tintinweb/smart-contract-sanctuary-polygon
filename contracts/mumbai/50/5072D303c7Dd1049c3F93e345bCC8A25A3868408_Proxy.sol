/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

// SPDX-License-Identifier: MIT
// File: ProxyStorage.sol


pragma solidity ^0.8.1;

contract ProxyStorage {
    address public logicContractAddress;

    function setLogicAddressStorage(address _logicContract) internal {
        logicContractAddress = _logicContract;
    }

    function _contractAddress() public view returns (address) {
        return address(this);
    }
}

// File: Proxy.sol


pragma solidity ^0.8.1;


contract Proxy is ProxyStorage {
    // constructor(address _logicContract) {
    //     setLogicAddress(_logicContract);
    // }
    event LogicAddressSet(address indexed _setBy, address indexed _logicContract);

    function setLogicAddress(address _logicContract) public {
        super.setLogicAddressStorage(_logicContract);
        emit LogicAddressSet(msg.sender, _logicContract);
    }

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        address _impl = logicContractAddress;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}