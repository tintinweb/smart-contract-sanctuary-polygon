/**
 *Submitted for verification at polygonscan.com on 2022-08-16
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

    uint public airdroppedAccounts;
    IERC20 public token;
    AccountsData accounts;
    uint public minAmount = 1000 * 1e18;
    uint public perAccounts = 200;
    
    constructor(address _token,address accountsData) {
        token = IERC20(_token);
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