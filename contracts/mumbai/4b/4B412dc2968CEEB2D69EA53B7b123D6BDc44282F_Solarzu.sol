// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Solarzu{

    struct user {
        uint256 used;
        uint256 instalment_amount;
        uint8 instalments_left;
    }

    mapping (address=>user) users;
    event BNPL(address indexed user,uint256 total_amount,uint256 instalment_amount,uint8 instalments);

    function dividing(uint256 total_amount,uint8 instalments,uint256 _instalment_amount) public{
        users[msg.sender] = user(total_amount,_instalment_amount,instalments);
        emit BNPL(msg.sender,total_amount,_instalment_amount,instalments);
    }

    function used_amount() public view returns(uint256){
         return users[msg.sender].used;
    }

    function instalments_amount() public view returns(uint256){
         return users[msg.sender].instalment_amount;
    }

    function instalments_left() public view returns(uint256){
         return users[msg.sender].instalments_left;
    }

    function repayment() public payable{
        require(msg.value >= users[msg.sender].instalment_amount,"amount not matched");
        require(users[msg.sender].instalments_left > 0,"No instalments");
        users[msg.sender].instalments_left-=1;
    }

    receive() external payable {}
    fallback() external payable {}
}