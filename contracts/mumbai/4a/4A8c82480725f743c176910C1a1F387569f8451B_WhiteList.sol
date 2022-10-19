/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

error emptyAddress();
error notMember();
error didntSendEnoughETH();
// import "./SimpleStorage.sol";

interface SimpleStorage {
    function saveMembersFavNumber(address _userAddress, uint256 _favoriteNumber) external;
    function deleteMembersFavNumber(address _userAddress) external;

}

contract WhiteList {
    address public owner;
    // define a mapping of members
    uint256 constant MINIMUM_FEE_WEI = 2000000000; // 2 Gwei
    mapping(address => bool) members;
    mapping(address => uint256) memberToBalance;

    SimpleStorage ss;
    constructor(address payable _address) {
        owner = msg.sender;
        ss = SimpleStorage(_address);
    }

    // method to check memebership
    function isMember(address _userAddress) public view returns (bool) {
        return members[_userAddress];
    }

    // a method to add member
    function storeFavNumver(uint256 _favoriteNumber) public payable {
        require(!isMember(msg.sender), "User is already a member");
        if(msg.value < MINIMUM_FEE_WEI) revert didntSendEnoughETH();


        memberToBalance[msg.sender] = msg.value;

        members[msg.sender] = true;
        ss.saveMembersFavNumber(msg.sender, _favoriteNumber);

    }

    // a method to remove member
    function deleteFavNumber() public payable {
        require(isMember(msg.sender), "User not found");
        // return fee to member's address


        uint256 fee = memberToBalance[msg.sender];
        (bool callSuccess, ) = msg.sender.call{value:  fee}("");
        require(callSuccess, "Transaction Failed");

        ss.deleteMembersFavNumber(msg.sender);

        memberToBalance[msg.sender] = 0;
        members[msg.sender] = false;
    }

    // transfers ownership of contract 
    function transferOwnership(address _newOwner) public onlyOwner {
        if(_newOwner == address(0)) revert emptyAddress();
        owner = _newOwner;
    }

     function getBalance() public view returns (uint256){
        return address(this).balance;
    }
   

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }


}