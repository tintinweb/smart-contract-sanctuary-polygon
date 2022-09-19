/**
 *Submitted for verification at polygonscan.com on 2022-09-19
*/

pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

interface IERC897 {
    function proxyType() external view returns(uint256);
    
    function implementation() external view returns(address);
}

abstract contract ContractOwner {
    event OwnerChanged(address indexed from, address indexed to);

    address private contractOwner = msg.sender;
    
    modifier onlyContractOwner {
        require(msg.sender == contractOwner, "only contract owner");
        _;
    }
    
    function getContractOwner() public view returns(address) {
        return contractOwner;
    }
    
    function changeContractOwner(address to) external onlyContractOwner {
        address from = contractOwner;
        contractOwner = to;
        emit OwnerChanged(from, to);
    }
}

contract ERC897 is ContractOwner, IERC897 {
    address public override implementation;
    uint256 public override proxyType = 2; 
    
    receive() external payable {
    }
    
    fallback(bytes calldata input) external payable returns(bytes memory) {
        (bool success, bytes memory output) = implementation.delegatecall(input);
        
        require(success, string(output));
        
        return output;
    }
    
    function setCodeAddress(address codeAddress) external onlyContractOwner {
        implementation = codeAddress;
    }
    
	/*
    function callContract(address contractAddress, bytes calldata input)
        external payable onlyContractOwner {
        
        (bool success, bytes memory output) = contractAddress.call(input);
        
    	require(success, string(output));
    }
    
    function callContract(address contractAddress, bytes calldata input, uint256 value)
        external payable onlyContractOwner {
        
        (bool success, bytes memory output) = contractAddress.call
            {value: value} (input);
        
        require(success, string(output));
    }
	*/
}