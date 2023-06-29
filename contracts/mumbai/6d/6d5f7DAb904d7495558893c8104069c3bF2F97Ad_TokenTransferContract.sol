// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20Interface {
    function transferForm(address sender, address receiver, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns(uint256);
}

contract TokenTransferContract {
    address public owner;
    mapping (address => bool) private VerifiedTokens;
    address [] public verifiedTokensList;

   struct Transaction{
    address sender;
    address receiver;
    uint256 amount;
    string message;
   }

    event TransactionCompleted (
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        string message
    );
    
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyVerifiedTokens(address _token) {
        require(VerifiedTokens[_token],"Token is not verified");
        _;
    }

    function addVerifiedTokens (address _token) public onlyOwner {
        VerifiedTokens[_token] = true;
        verifiedTokensList.push(_token);
    }

    function removeVerifiedTokens (address _token) public onlyOwner{
        require(VerifiedTokens[_token] = true, "Token is not verified yet");
        VerifiedTokens[_token] = false;

        for (uint256 i=0; i < verifiedTokensList.length; i++) {
            if (verifiedTokensList[i] == _token) {
                verifiedTokensList[i] = verifiedTokensList[verifiedTokensList.length - 1];
                verifiedTokensList.pop();
                break;
            }
        }
    }

    function getVerifiedTokens() public view returns(address[] memory) {
        return verifiedTokensList;
    }

    function transfer(IERC20Interface token, address to, uint256 amount, string memory message) public onlyVerifiedTokens(address(token)) returns (bool) {
        uint256 senderBalance = token.balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient Balance");

        bool success = token.transferForm(msg.sender, to, amount);
        require(success, "Transaction Failed!");

        Transaction memory transaction = Transaction({
            sender: msg.sender,
            receiver: to,
            amount: amount,
            message: message
        });

        emit TransactionCompleted(msg.sender, transaction.receiver, transaction.amount, transaction.message);

        return true;
    }   

}