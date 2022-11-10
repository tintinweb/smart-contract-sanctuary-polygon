// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;


interface WETH{
   function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}


contract getFunds{

    WETH token = WETH(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    
function Deposit( )public payable returns(bool){
   
    token.transfer(msg.sender, msg.value);
    return true;
}

function transferfrom(address account,uint256 amount) public {
    token.transferFrom(msg.sender,account,amount);
}


function totalSupply() external view returns(uint256){
    uint256 supply = token.totalSupply();
    return supply;
}

function allowance(address owner, address delegate) external view returns(uint256) {
    return token.allowance(owner, delegate);
}

function balanceOf(address account) public view returns(uint256){
    return token.balanceOf(account);
}

function approve(address delegate, uint256 amount) external returns(bool){
    return token.approve(delegate,amount);
}




}