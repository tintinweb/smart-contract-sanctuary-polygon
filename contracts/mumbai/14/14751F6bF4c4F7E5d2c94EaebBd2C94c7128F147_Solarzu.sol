// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Solarzu{

    struct user {
        uint256 used;
        uint256 instalment_amount;
        uint8 instalments_left;
        uint256 tokenId;
        address tokenAddress;
    }

    mapping (address=>user) public users;
    event BNPL(address indexed user,uint256 total_amount,uint256 instalment_amount,uint8 instalments,uint256 tokenId,address tokenAddress);
    event INSTALMENT_PAID(address indexed user,uint256 instalment_amount,uint8 instalments_left,uint256 tokenId,address tokenAddress);

    function divide_installments(uint256 total_amount,uint8 instalments,uint256 _instalment_amount,uint256 _tokenId,address _tokenAddress) public{
        require(users[msg.sender].instalments_left == 0,"You already have instalments");
        require(instalments > 0);
        users[msg.sender] = user(total_amount,_instalment_amount,instalments,_tokenId,_tokenAddress);
        emit BNPL(msg.sender,total_amount,_instalment_amount,instalments,_tokenId,_tokenAddress);
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
        require(users[msg.sender].instalments_left > 0,"No instalments");
        require(msg.value >= users[msg.sender].instalment_amount,"amount not matched");
        emit INSTALMENT_PAID(msg.sender,users[msg.sender].instalment_amount,users[msg.sender].instalments_left,users[msg.sender].tokenId,users[msg.sender].tokenAddress);
        users[msg.sender].instalments_left-=1;
    }

    receive() external payable {}
    fallback() external payable {}
}