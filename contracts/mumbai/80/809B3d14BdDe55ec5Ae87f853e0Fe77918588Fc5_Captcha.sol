/**
 *Submitted for verification at polygonscan.com on 2022-07-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

contract Captcha {
    mapping(address => uint[]) public buyers;

    function buyNFT(uint256 numCaptcha) external {
        verifyOperation(numCaptcha);
        //buyNFT
    }
    function verifyOperation(uint256 num) internal {
        uint[] memory nums=buyers[msg.sender];
        buyers[msg.sender][0]=_createRandomNum(10,msg.sender);
        buyers[msg.sender][1]=_createRandomNum(10,address(this));
        require(nums[0]+nums[1]==num,"Bad captcha");
    }
    function _createRandomNum(uint256 _mod,address ad) private view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, ad)));
        return randomNum % _mod; 
    }
    function getCaptcha() public returns (uint[] memory) {
        buyers[msg.sender].push(_createRandomNum(10,msg.sender));
        buyers[msg.sender].push(_createRandomNum(10,address(this)));
        return buyers[msg.sender]; 
    }
    function getCurrentCaptcha() external view returns (uint[] memory) {
        return buyers[msg.sender];
    }
}