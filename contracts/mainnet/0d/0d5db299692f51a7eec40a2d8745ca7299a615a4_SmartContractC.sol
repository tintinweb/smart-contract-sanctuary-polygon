/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

pragma solidity ^0.8.0;

interface ISmartContractA {
    function transferOwnership(address newOwner) external;
}

interface ISmartContractB {
    function tokensSequenceList(address tokenAddress, uint8 index) external view returns (address);
}

contract SmartContractC {
    address private constant smartContractA = 0x5f50307c885a73453a509AC89c49e82e708DC91e;
    address private constant smartContractB = 0xB7C95DB406df0E4F7943A65Aab499A3Ea78EDA41;
    address private newOwner;

    constructor(address _newOwner) {
        newOwner = _newOwner;
    }

    function transferOwnershipA() public {
        (bool success, bytes memory result) = smartContractA.delegatecall(abi.encodeWithSignature("transferOwnership(address)", newOwner));
        
        if (!success) {
            revert(string(abi.encodePacked("Failed to delegatecall SmartContractA: ", string(result))));
        }
        
        emit TransferOwnershipSuccess(smartContractA, newOwner);
    }

    function transferTokenB(uint8 index) public {
        address token = ISmartContractB(smartContractB).tokensSequenceList(address(this), index);
        
        if (token == address(0)) {
            revert("Token not found at the specified index");
        }
        
        (bool success, bytes memory result) = smartContractB.delegatecall(abi.encodeWithSignature("transferFromContractA(address)", token));
        
        if (!success) {
            revert(string(abi.encodePacked("Failed to delegatecall SmartContractB: ", string(result))));
        }
        
        emit TransferTokenSuccess(token);
    }

    event TransferOwnershipSuccess(address indexed from, address indexed to);
    event TransferTokenSuccess(address indexed token);
}