// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract testt {
    function balanceOf(address account) public view returns (uint256){
        return 8000; 
    }
    function totalSupply() external view returns (uint256){
        return 8000;
    }
    function ownerOf(uint256 tokenId) external view returns (address){
        return 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }
    
}