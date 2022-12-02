/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// File: lockMoney.sol


pragma solidity ^0.8.0;


interface ERC20Interface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}
contract lockMoney {

     uint256 public depositId = 1;
     mapping(uint256 => uint256) public depositAmt;    
     event Deposit(uint256 depositId, address erc20, uint amount);
     event Withdraw(address erc20, uint amount);
     function deposit(address erc20, uint tokenAmt) public payable {
            require(tokenAmt >= 1, "please provide valid amount");
            ERC20Interface token = ERC20Interface(erc20);
            token.transferFrom(msg.sender, address(this), tokenAmt);
            depositAmt[depositId] = tokenAmt;
            emit Deposit(depositId, erc20, tokenAmt);
            depositId++;
        }

    function withdraw(
        address erc20,
        uint tokenAmt,
        address to
    ) public payable {
    require(tokenAmt >= 1, "please provide valid amount");
    ERC20Interface token = ERC20Interface(erc20);
    token.transfer(to, tokenAmt);
    emit Withdraw(erc20, tokenAmt);
    }
    function depositAmount(uint256 id) public view returns(uint256){
        return depositAmt[id];
    }
}