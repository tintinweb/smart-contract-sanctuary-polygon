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
pragma solidity =0.8.0;


contract LoanVault{
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint public totalSupply;

    mapping(address => uint)public balanceOf;

    //Initialize token0 as USDC
    //Initialize token1 as WMATIC or WETH
    constructor(address _token0, address _token1){
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    //Mint Shares 
    function _mint(address _to, uint _shares)private{
        totalSupply+=_shares;
        balanceOf[_to]+=_shares;
    }

    //Burn Shares
    function _burn(address _from, uint _shares)private{
        totalSupply-=_shares;
        balanceOf[_from]-=_shares;
    }

    //Deposit USDC into the Vault
    function deposit(uint _amount)external returns(uint shares){
        if(totalSupply == 0){
            shares =_amount;
        }else{
            shares=(_amount * totalSupply)/token0.balanceOf(address(this));
        }
        _mint(msg.sender, shares);
        token0.transferFrom(msg.sender, address(this), _amount);
    }

    //Withdraw USDC from the vault
    function withdraw(uint _shares)external returns(uint amount){
        amount=(_shares * token0.balanceOf(address(this)))/totalSupply;
        _burn(msg.sender, _shares);
        token0.transfer(msg.sender, amount);
    }

    //Contract Unlocks WMATIC or WETH locked and transfers it when the borrower repays the full amount
    function unlock(uint _amount) external{
        token0.transfer(msg.sender, _amount);
    } 

}