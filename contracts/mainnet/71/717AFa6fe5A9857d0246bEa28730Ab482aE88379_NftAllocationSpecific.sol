/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

//SPDX-License-Identifier: NONE
pragma solidity 0.8.0;

contract NftAllocationSpecific {
	address public landNftContract;
	address public immutable initAddress;
	
	bool public canChange = true;
	
	uint256 public baseAllocation = 25 * 1e6 *1e18; //25M
	uint256 public addressesInitialized;

    mapping(uint256 => uint256) public allocation;

    constructor() {
		initAddress = msg.sender;
    }
	
	function nftAllocation(address _tokenAddress, uint256 _tokenID) external view returns (uint256) {
        require(_tokenAddress == landNftContract, "wrong NFT contract");
		return allocation[_tokenID];
	}

    function initialize(uint256[] calldata _allocations, bool endInit, address _landNftContract) external {
    	require(msg.sender == initAddress, "not allowed");
        require(canChange, "already initialized");
        for(uint i=0; i < _allocations.length; i++) {
            allocation[addressesInitialized] = _allocations[i];
			addressesInitialized++;
        }
		if(endInit) {
			canChange = false;
            landNftContract = _landNftContract;
		}
    }

    function getAllocationManually(uint256 _tokenID) external view returns (uint256) {
			uint256 _value = baseAllocation;
            uint256 _occurence = 0;
            uint256 _moduloNum = 20;
		for(uint i=0; i< _tokenID; i++) {
            if(_occurence > 50) {
                _moduloNum = 200;
            }
            if(i % _moduloNum == 0) {
                _value = _value * (1000 - _occurence) / 1000;
                _occurence++;
            }
		}
		return _value;
	}
}