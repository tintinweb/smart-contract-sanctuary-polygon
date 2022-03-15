// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


//  .d8888b.  d8b 888      888 d8b                   888               888               \\
// d88P  Y88b Y8P 888      888 Y8P                   888               888               \\
// Y88b.          888      888                       888               888               \\
//  "Y888b.   888 88888b.  888 888 88888b.   .d88b.  888       8888b.  88888b.  .d8888b  \\
//     "Y88b. 888 888 "88b 888 888 888 "88b d88P"88b 888          "88b 888 "88b 88K      \\
//       "888 888 888  888 888 888 888  888 888  888 888      .d888888 888  888 "Y8888b. \\
// Y88b  d88P 888 888 d88P 888 888 888  888 Y88b 888 888      888  888 888 d88P      X88 \\
//  "Y8888P"  888 88888P"  888 888 888  888  "Y88888 88888888 "Y888888 88888P"   88888P' \\
//                                               888                                     \\
//                                          Y8b d88P                                     \\
//                                           "Y88P"                                      \\

import "./VRFConsumerBase.sol";
import "./AdminControl.sol";

contract SiblingsRandomNumber is VRFConsumerBase, AdminControl {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public index;

    struct Result {
        uint256 _index;
        uint256 _blockNumber;
        bytes32 _requestId;
        uint256 _randomResult;
        string _description;
    }
    
    mapping(uint256 => Result) public results;

    constructor() 
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0,
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1
            ) 
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber(string memory description) public adminRequired returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK");
        Result storage result = results[index];
        result._description = description;
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        Result storage result = results[index];
        result._index = index;
        result._blockNumber = block.timestamp;
        result._requestId = requestId;
        result._randomResult = randomness;

        index++;
    }
    
    /**
     * Withdraw LINK from this contract
     */
    function withdrawLink() external adminRequired {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}