/**
 *Submitted for verification at polygonscan.com on 2022-02-10
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


interface iGain {
    function mintLP(uint256 amount, uint256 min_lp) external returns (uint256 _lp);
}

interface Pool {
    function stakeFor(address to, uint256 amount) external;
}

contract iGainLPProxy {
    iGain public igain;
    Pool public pool;
    IERC20 public token;

    constructor(address _igain, address _pool, address _token) {
        igain = iGain(_igain);
        pool = Pool(_pool);
        token = IERC20(_token);
        token.approve(address(igain), type(uint256).max);
        IERC20(address(igain)).approve(address(pool), type(uint256).max);
    }

    function deposit(uint256 amount, uint256 min_lp) external returns (uint256 _lp) {
        token.transferFrom(msg.sender, address(this), amount);
        _lp = igain.mintLP(amount, min_lp);
        pool.stakeFor(msg.sender, _lp);
    }

}