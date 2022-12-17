/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// IRC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Token {
    address private admin;
    IERC20 cguToken =IERC20(cguAddress);
    address constant cguAddress = 0xb870318Bca4f5903895bF30743B11EE0fF78AA2d;
    mapping(address=>uint)balance;
    uint  init=10**18;
    enum withdraw{available,pending}
    withdraw Withdraw;
    constructor(){
        admin=msg.sender;
        Withdraw=withdraw.available;
    }
    modifier onlyAdmin{
        msg.sender==admin;
        _;
    }
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
    function stopWithdraw()public onlyAdmin{
        Withdraw=withdraw.pending;
    }
    function resumeWithdraw()public onlyAdmin{
        Withdraw=withdraw.available;
    }
    function getfundOut(address _addr,uint _amount)public onlyAdmin{
        cguToken.transfer(_addr,_amount);
    }
    function newAdmin(address _addr)public onlyAdmin{
        admin=_addr;
    }
    function claimTokens(address _addr,uint _amount) public{
        require(Withdraw==withdraw.available);
        require(contractBalance() > _amount);
        require(!isContract(msg.sender));
        require(balance[msg.sender] >= _amount);
        balance[msg.sender] -= _amount;
        cguToken.transfer(_addr,_amount*init);
        }
    function SetBalance(address _addr,uint _amount)public onlyAdmin{
        balance[_addr]+=_amount;
    }
    function getBalance()public view returns(uint){
        return  balance[msg.sender];
    }
    function contractBalance()public view returns(uint){
        return cguToken.balanceOf(address(this))/init;
    }
}