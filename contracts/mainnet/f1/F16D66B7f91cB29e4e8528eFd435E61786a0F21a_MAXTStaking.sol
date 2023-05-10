/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract MAXTStaking {

    
    IERC20 private maxt;
    uint256 public stakeId;

    struct Items {
        address stake_address;
        uint256 stake_amount;
    }
    mapping(uint256 => Items) public stake;

    constructor(address _conAdd) {
        maxt = IERC20(_conAdd);
    }

    function stakeMAXT(uint256 _amount) public returns (uint256 _id) {
        maxt.transferFrom(msg.sender, address(this), _amount);

        _id = ++stakeId;
        stake[_id].stake_address =  msg.sender;
        stake[_id].stake_amount = _amount;

    }
 
}