// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20Interface {
    function transferFrom(
        address sender,
        address recepient,
        uint amount
    ) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function balanceOf(address account) external view returns (uint);
}

contract MyContract {
    address public owner;
    mapping(address => bool) private verifiedTokens;
    address[] public verifiedTokensList;

    struct Transaction {
        address sender;
        address receiver;
        uint amount;
        string message;
    }

    event TransactionCompleted(
        address sender,
        address receiver,
        uint amount,
        string message
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the Owner");
        _;
    }

    modifier onlyVerifiedToken(address _token) {
        require(verifiedTokens[_token], "Token is not verified");
        _;
    }

    function addVerifyToken(address _token) public onlyOwner {
        verifiedTokens[_token] = true;
        verifiedTokensList.push(_token);
    }

    function removeverifiedToken(address _token) public onlyOwner {
        require(verifiedTokens[_token] == true, "Token not verifed");
        verifiedTokens[_token] = false;

        for (uint i = 0; i < verifiedTokensList.length; i++) {
            if (verifiedTokensList[i] == _token) {
                verifiedTokensList.pop();
                break;
            }
        }
    }

    function getVerifiedTokens() public view returns (address[] memory) {
        return verifiedTokensList;
    }

    function transfer(
        IERC20Interface token,
        address to,
        uint amount,
        string memory message
    ) public onlyVerifiedToken(address(token)) returns (bool) {

        uint senderBal=token.balanceOf(msg.sender);
        require(senderBal>=amount,"Insuffiecient Balance");

       bool success= token.transferFrom(msg.sender, to, amount); 
           require(success,"Transaction failed");
         
         Transaction memory transaction= Transaction({
            sender:msg.sender,
            receiver:to,
            amount:amount,
            message:message
         });

         emit TransactionCompleted(msg.sender, transaction.receiver, transaction.amount,transaction.message );
         return true;
    }
}