/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract MusakaDistributor{

    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public owner1;
    address public owner2;
    

    constructor(address one,address two){
        owner1 = one;
        owner2 = two;
    }
    modifier onlyOnwers(){
        require(msg.sender == owner1 || msg.sender == owner2);
        _;
    }

    function changeOwner1(address newOwner) external onlyOnwers{
        owner1 = newOwner;
    } 
    function changeOwner2(address newOwner) external onlyOnwers{
        owner2 = newOwner;
    } 

    function distributeERC20(address erc20Address) public {
        IERC20 erc20Token = IERC20(erc20Address);
        uint balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(owner1,balance/2);
        erc20Token.transfer(owner2,balance/2);
    }

    function distributeUSDC() external {
        distributeERC20(USDC);
    }
    function withdrawMatic() external onlyOnwers{
        uint bal = address(this).balance;
        (bool da,) = owner1.call{value: bal/2}("");
        (bool da1,) = owner2.call{value: bal/2}("");
        require(da);
        require(da1);
    }
    receive() external payable{}
}