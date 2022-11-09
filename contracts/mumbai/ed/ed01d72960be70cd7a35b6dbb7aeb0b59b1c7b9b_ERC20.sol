/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// interface IERC20 {
//     function totalSupply() external view returns(uint);
//     function balanceOf(address account) external view returns(uint);
//     function transfer(address spender,uint amount) external view returns(bool);
//     function allowance(address owner,address spender) external view returns(uint);
//     function approve(address spender,uint amount) external view returns(bool);
//     function transferFrom(address sender,address recipient,uint amount) external view returns(bool);
//     event Transfer(address indexed from,address indexed to,uint value);
//     event Approval(address indexed owner,address indexed sender,uint value);

// }
contract ERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address=>mapping(address=>uint)) public allowance;
    string public name='ao token';
    string public symbol='ao';
    uint8 decimals=18;
        event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address indexed owner,address indexed sender,uint value);
    function transfer(address spender,uint amount) external  returns(bool){
        balanceOf[msg.sender] -= amount;
        balanceOf[spender] += amount;
        emit Transfer(msg.sender,spender,amount);
        return true;
    }
    // function approve(address spender, uint amount) external returns (bool) {
    //     allowance[msg.sender][spender] = amount;
    //     emit Approval(msg.sender, spender, amount);
    //     return true;
    // }
    // function transferFrom(address sender,address recipient,uint amount) external returns(bool){
    //     allowance[sender][msg.sender] -= amount;
    //     balanceOf[sender] -= amount;
    //     balanceOf[recipient] += amount;
    //     emit Transfer(sender, recipient, amount);
    //     return true;

    // }
    function mint(uint amount) external{
        balanceOf[msg.sender]+=amount;
        totalSupply += amount;
        }
    function burn(uint amount) external{
    balanceOf[msg.sender]-=amount;
    totalSupply -= amount;}
}