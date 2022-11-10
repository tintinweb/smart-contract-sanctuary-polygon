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


contract getFunds {

    WETH token = WETH(0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa);

    


function transferfrom(address account,uint256 amount) public {
    token.transferFrom(msg.sender,account,amount);
}

function totalSupply() external view returns(uint256){
    uint256 supply = token.totalSupply();
    return supply;
}

function balanceOf(address account) public view returns(uint256){
    return token.balanceOf(account);
}







}