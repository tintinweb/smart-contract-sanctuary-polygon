/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IERC20{
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to,uint256 amount) external returns(bool);
}

interface AccountsData{
    function getAccounts(uint start,uint end) external view returns(address[] memory accounts);
    function count() external view returns(uint);
}

contract DPCAirdropDAO{

    uint public airdroppedAccounts = 13000; 
    IERC20 public token = IERC20(0x4d59249877CfFf9aaa3aE572d06c5B71a79B6215);
    AccountsData public accounts;
    uint public perAccounts = 800;
    uint public minAmount = perAccounts * 1666888 * 1e12;
    
    constructor(address accountsData) {
        accounts = AccountsData(accountsData);
    }
    
    function airdrop() external airdropRequire {
        uint totalAccounts = accounts.count();
         uint end = (totalAccounts - airdroppedAccounts) > perAccounts 
         ? airdroppedAccounts + perAccounts 
         : totalAccounts;
        address[] memory recipients = accounts.getAccounts(airdroppedAccounts+1,end);
        _batchTransfer(recipients, minAmount / perAccounts);
        airdroppedAccounts = end;
    }

    function _batchTransfer(address[] memory recipients,uint perAmount) internal {
        uint allRecipients = recipients.length;
        require(allRecipients >0,"no recipients");
        for(uint i = 0; i < allRecipients;++i){
            if(recipients[i] == address(0)) continue;
            token.transfer(recipients[i],perAmount);
        }
    }

    function balance() public view returns(uint){
        return token.balanceOf(address(this));
    }

    modifier airdropRequire(){
        require(token.balanceOf(address(this)) >= minAmount,"The minimum amount has not been reached");
        require(accounts.count() > airdroppedAccounts, "There are no more addresses that can be airdropped");
        _;
    }


}