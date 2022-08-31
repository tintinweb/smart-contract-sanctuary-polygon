/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: BSD-3-Clause  

contract proxy {
    
    address public contractOperator;
    address public currentDefaultVersion;
    mapping (bytes4 => address) public methodIdToAddress;

    event updateContractOperator(address indexed contractOperator);
    event updateDefaultContract(address indexed defaultContract);
    event updateMethodIdToAddress(bytes4 indexed methodId, address indexed logicContract);
    
    modifier onlyOwner() {
        require(msg.sender == contractOperator);
        _;
    }


    constructor(address initAddr) {
        currentDefaultVersion = initAddr;
        contractOperator = msg.sender;
    }   


    function setDefaultContract(address newVersion) public onlyOwner(){
        currentDefaultVersion = newVersion;
        emit updateDefaultContract(newVersion);
    }


    function setMethodIdToAddress(bytes4 methodId, address logicContract) public onlyOwner{
        methodIdToAddress[methodId] = logicContract;
        emit updateMethodIdToAddress(methodId, logicContract);
    }


    function setContractOperator(address newOperator) public onlyOwner(){
        contractOperator = newOperator;
        emit updateContractOperator(newOperator);
    }

    
    receive() external payable {}


    fallback() external payable {

        bool success;
        bytes memory resultData;

        if (methodIdToAddress[msg.sig] != address(0)){
            (success, resultData) = methodIdToAddress[msg.sig].delegatecall(msg.data); 
        }
        else {
            (success, resultData) = currentDefaultVersion.delegatecall(msg.data);
        }

        if (!success){
            _revertWithData(resultData);
        }
        _returnWithData(resultData);

    }


    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }


    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }

}