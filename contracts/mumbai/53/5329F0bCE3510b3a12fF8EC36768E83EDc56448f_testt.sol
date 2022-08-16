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
        return 0x1C3789D10918337C2AFeA695475545078DbacCdF;
    }
    
}