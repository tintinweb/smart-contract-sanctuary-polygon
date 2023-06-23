/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenVault {
    uint256 private amount_people_get;
    mapping (address => bool) private whiteList;
    mapping (string => bool) public ValidateCid;
    string[] private myCids;
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

    function addWallet(address wallet) public onlyOwner {
        whiteList[wallet] = true;
    }

    function SendViaCall(string memory cid) public {
        require(whiteList[msg.sender], "Your wallet not in white list");
        require(!ValidateCid[cid], "Your Cid is exist");
        
        bool sent = token.transfer(msg.sender, amount_people_get * 10 ** 18);
        
        require(sent, "Filed ocean transfer");
        ValidateCid[cid] = true;
        
        myCids.push(cid);
    }
    
    function getValidCid() public view returns (string[] memory){
        return myCids;
    } 
}