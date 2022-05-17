/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

pragma solidity ^0.8.13;

    struct Users {
        address wallet;
        uint level;
        bool status;
    }

    struct Staking {
        address wallet;
        uint[] nftIds;
        mapping(uint => uint) tokenStakindIndx;
    }

contract DevTestContract {

    address owner;

    mapping (address => Users) public _users;
    mapping (address => Staking) public _stake;

    constructor() public {
        owner = msg.sender;
    }

    modifier userChecks() {
        //require(msg.sender == owner, "Only owner allow using this function!");
        _;
    }

    function login(address wallet) public userChecks {
        require(msg.sender == wallet, "Account Error!");
        _users[wallet] = Users(wallet, 0, true);
    }

    function Stake(uint256 tokenId) public{
        require(_users[msg.sender].status == true, "User not logined!");

        Staking storage stake = _stake[msg.sender];

        stake.wallet = msg.sender;
        stake.nftIds.push(tokenId);
        stake.tokenStakindIndx[tokenId] = block.timestamp; 
    }


    function getLevel(address wallet) public userChecks returns (Users memory){
        return _users[wallet];
    }

    function getStatus(address wallet) public userChecks returns (bool){

    }

}