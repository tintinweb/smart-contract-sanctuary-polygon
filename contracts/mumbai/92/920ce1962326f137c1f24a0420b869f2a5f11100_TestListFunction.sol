/**
 *Submitted for verification at polygonscan.com on 2022-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract TestListFunction{
    
    uint256 private _totalShares;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;


    constructor() payable {
    
}
  

  function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }
  
  
  
   function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        
    }


    function _addPayees(address[] memory payees, uint256[] memory shares_) public {
    require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
    require(payees.length > 0, "PaymentSplitter: no payees");

    for (uint256 i = 0; i < payees.length; i++) {
        _addPayee(payees[i], shares_[i]);
    }
}
}