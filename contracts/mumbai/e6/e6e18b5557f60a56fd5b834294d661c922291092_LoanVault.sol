/**
 *Submitted for verification at polygonscan.com on 2022-07-06
*/

// File: IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}
// File: LoanVault.sol

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


contract LoanVault{
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint public totalSupply;

    constructor(address _token0, address _token1){
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function deposit(uint _amount)public{
        token0.transferFrom(msg.sender,address(this),_amount);
    }

    function withdraw(uint _amount)public{
        token1.transfer(msg.sender,_amount);
    }

}