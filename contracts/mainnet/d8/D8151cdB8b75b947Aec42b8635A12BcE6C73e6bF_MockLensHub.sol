// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface ICollectModule {
    function initializePublicationCollectModule(uint256 profileId, uint256 pubId, bytes calldata data) external returns (bytes memory);
    function processCollect(uint256 referrerProfileId, address collector, uint256 profileId, uint256 pubId, bytes calldata data) external;
}

contract MockLensHub {
    ICollectModule public mockCollectModule;
    event Collected(uint256 profileId, uint256 pubId, bytes data); 

    constructor(address _mockCollectModule) {
        mockCollectModule = ICollectModule(_mockCollectModule);
    }

    function collect(uint256 profileId, uint256 pubId, bytes calldata data) external {
        // require(profileId == 0x01 && pubId == 0x02, "Fixed publication");

        uint256 mockReferrerProfileId = 0x02;
        mockCollectModule.processCollect(mockReferrerProfileId, msg.sender, profileId, pubId, data);
        // if reaches here, trigger collect action
        // ...
        emit Collected(profileId, pubId, data);
    }
}