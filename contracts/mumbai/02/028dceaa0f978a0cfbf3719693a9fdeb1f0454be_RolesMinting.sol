/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract RolesMinting {

    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event RoledNFTMint(address indexed to, uint indexed id, string indexed role);

    uint public totalTokens;
    address public ownerAddress;
    mapping(address => uint) public tokensOf; // tokensOf any account

    // roleName => price 
    mapping(string => uint) public rolePrice;  
    // id => address
    mapping(uint => address) public ownerOfNft;

    constructor()  {
        ownerAddress = msg.sender;
        totalTokens = 10000; 
        tokensOf[ownerAddress] = totalTokens;
        emit Transfer(address(0), ownerAddress, totalTokens);
    }

    modifier checkRemainingAvailabeTokens(uint256 _tokens){
        require(tokensOf[ownerAddress] > _tokens , "not enough Total tokens available");
        _;
    }

    modifier transferNotToOwner(address _address){
         require(_address != ownerAddress, "Owner can not give token to self");
        _;
    }

    modifier onlyOwner{
        require(msg.sender == ownerAddress, "only owner of contract have rights");
        _;
    }

    function transfer(address _to, uint256 _tokens) public onlyOwner checkRemainingAvailabeTokens(_tokens) transferNotToOwner(_to) returns (bool success){
        tokensOf[ownerAddress] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(ownerAddress, _to, _tokens);
        return true;
    }

    function remainingTokens() public view returns (uint) {
        return tokensOf[ownerAddress]  ;
    }

    function increaseTotalTokens(uint _newTokens) public onlyOwner {
        tokensOf[ownerAddress] += _newTokens;
        totalTokens += _newTokens;
    }


    function createOrUpdateRole(string calldata _roleName, uint _rolePrice) external onlyOwner {
        rolePrice[_roleName] = _rolePrice;
    }

    function mint(address _account, uint _id,  string calldata _roleName) public returns (uint) {
        require(_account == msg.sender, "You are Not Authorized for this");
        require(rolePrice[_roleName] > 0, "not such Role exists");

        uint burnTokens = rolePrice[_roleName];
        require(tokensOf[_account] > burnTokens, "do not have enough tokens to mint");

        tokensOf[_account] -= burnTokens;
        ownerOfNft[_id] = _account;

        emit RoledNFTMint(_account, _id, _roleName);
        return _id;
    }

}