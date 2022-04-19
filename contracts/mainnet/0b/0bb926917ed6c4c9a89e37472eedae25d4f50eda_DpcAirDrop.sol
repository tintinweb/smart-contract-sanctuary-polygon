/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IERC20{
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DpcAirDrop{

    address public owner;
    address public DPC;

    constructor(address _dpc) {
        owner = msg.sender;
        DPC = _dpc;
    }
    
    function batchTransferDPC(address[] memory recipients,uint perAmount ) external onlyOwner {
        batchTransfer(recipients, perAmount, DPC);
    }

    function batchTransfer(address[] memory recipients,uint perAmount,address erc20Token) public onlyOwner {
        uint allRecipients = recipients.length;
        require(allRecipients >0,"no recipients");
        uint count = 0;
        IERC20 token = IERC20(erc20Token);
        for(uint i = 0; i < allRecipients;i++){
            if(recipients[i] == address(0)) continue;
            token.transferFrom(msg.sender,recipients[i],perAmount);
            count += perAmount;
        }
        emit AirdropLog(count);
    }

    function batchTransferDiff(address[] memory recipients,uint[] memory amount,address erc20Token) public onlyOwner {
        uint allRecipients = recipients.length;
        require(allRecipients >0,"no recipients");
        require(allRecipients == amount.length," recipients and amount lengths do not match ");

        uint count = 0;
        IERC20 token = IERC20(erc20Token);
        for(uint i = 0; i < allRecipients;i++){
            if(recipients[i] == address(0)) continue;
            token.transferFrom(msg.sender,recipients[i],amount[i]);
        }
        emit AirdropLog(count);
    }

    function batchTransferETH( address[] memory  recipients,uint perAmount) external payable onlyOwner{
        uint allRecipients = recipients.length; 
        require(allRecipients >0,"no recipients");

        uint count = 0;
         for(uint i = 0; i < allRecipients;i++){
            if(recipients[i] == address(0)) continue;
            payable(recipients[i]).transfer(perAmount);
            count += perAmount;
        }
        payable(msg.sender).transfer(msg.value - count);
        emit AirdropLog(count);
    }

    function batchTransferDiffETH(address[] memory recipients,uint[] memory amount) public payable onlyOwner {
        uint allRecipients = recipients.length; 
        require(allRecipients >0,"no recipients");
        require(allRecipients == amount.length,"recipients and amount lengths do not match");

        uint count = 0;
         for(uint i = 0; i < allRecipients;i++){
            if(recipients[i] == address(0)) continue;
            payable(recipients[i]).transfer(amount[i]);
            count += amount[i];
        }
        payable(msg.sender).transfer(msg.value - count);
        emit AirdropLog(count);

    }

    event AirdropLog(uint airdrop);

    function balance(address token,address account) public view returns(uint){
            return IERC20(token).balanceOf(account);
    }

    function balanceETH(address account) public view returns(uint) {
            return account.balance;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }
}