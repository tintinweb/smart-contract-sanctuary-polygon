// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockFactory {
    address private mockPool;
    function setMockPool(address mPool) public {
        require(mockPool == address(0), "Mock pool already set");
        mockPool = mPool;
    }
    
    function allNFTGemPools(uint256) external view returns (address gemPool) {
        return mockPool;
    }
    function allNFTGemPoolsLength() external pure returns (uint256) {
        return 1;
    }
}