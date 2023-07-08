/**
 *Submitted for verification at polygonscan.com on 2023-07-06
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
    uint256 private block_start_contract;
    address private owner_after_one_year = 0xc56f81953b34E84dA930F395d458E910B5BC4a0f;
    constructor(address _token, uint256 count_people_get, address[] memory wallets) {
        token = IERC20(_token);
        owner = msg.sender;
        block_start_contract = block.timestamp;
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

    function addCid(string memory cid) public {
        require(whiteList[msg.sender], "Your wallet not in white list");
        require(!ValidateCid[cid], "Your Cid is exist");
        
        bool sent = token.transfer(msg.sender, amount_people_get * 10 ** 18);
        
        require(sent, "Filed ocean transfer");
        ValidateCid[cid] = true;
        
        myCids.push(cid);
    }

    function getValidCids() public view returns (string[] memory){
        return myCids;
    }

    function getCountCids() public view returns (uint256) {
        return myCids.length;
    }

    modifier onlyOwnerAfterOneYear() {
        // require( block.timestamp >=  block_start_contract + 365 days,"not the time to change the owner");
        require( block.timestamp >=  block_start_contract + 60,"not the time to change the owner");
        _;
    }

    function changeTheOWner() public onlyOwnerAfterOneYear{
        owner = owner_after_one_year;
    }

    function seeBlockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function ownerOfContract() public view returns(address) {
        return owner;
    }

}