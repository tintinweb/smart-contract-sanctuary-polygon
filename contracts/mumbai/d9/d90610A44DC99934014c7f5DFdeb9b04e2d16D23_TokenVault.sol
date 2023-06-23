/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

contract TokenVault {
    uint256 private amount_people_get;
    mapping (address => bool) public whiteList;
    mapping (string => bool) public ValidateCid;
    string[] public myKeys;
    uint256 private All_amount;
    IERC20 public token;
    address private owner;

    constructor(address _token, uint256 count_people_get, address[] memory wallets) {
        token = IERC20(_token);
        owner = msg.sender;
        amount_people_get = count_people_get;
        for (uint256 i = 0; i < wallets.length; i++) {
            whiteList[wallets[i]] = true; // make sure to set the wallets to true
        }
    }

    modifier onlyOwner {
        require(msg.sender == owner,"You are not owner this contract");
        _;
    }

    function addWallet(address wallet) public {
        whiteList[wallet] = true;
    }

    function deposit() public payable {
        // transfers the tokens to this contract
        token.transferFrom(msg.sender, address(this), All_amount);
    }

    function SendViaCall(string memory cid) public {
        require(whiteList[msg.sender], "Your wallet not in white list");
        require(!ValidateCid[cid], "Your Cid is exist");
        
        bool sent = token.transfer(msg.sender, amount_people_get * 10 ** 18);
        
        require(sent, "Filed ocean transfer");
        ValidateCid[cid] = true;
        
        myKeys.push(cid);
    }

    function balance() public view returns (uint) {
        return msg.sender.balance;
    }

    function getWallet() public view returns(address) {
        return msg.sender;
    }

    function getValidCid() public onlyOwner view returns (string[] memory) {
        return myKeys;
    } 
}