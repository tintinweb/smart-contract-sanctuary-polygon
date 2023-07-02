// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenTransferContract {
    address public owner;

    mapping(address => bool) private verifiedTokens;
    address[] public verifiedTokensList;

    struct Transaction {
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
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    } 

    modifier onlyVerifiedToken(address _token) {
        require(verifiedTokens[_token], "Token is not verified");
        _;
    }

    function addVerifiedToken(address _token) public onlyOwner {
        verifiedTokens[_token] = true;
        verifiedTokensList.push(_token);
    }

    function removeVerifiedToken(address _token) public onlyOwner {
        require(verifiedTokens[_token], "Token is not verified");
        verifiedTokens[_token] = false;
        for (uint256 i = 0; i < verifiedTokensList.length - 1; i++) {
            if (verifiedTokensList[i] == _token) {
                verifiedTokensList[i] = verifiedTokensList[verifiedTokensList.length - 1];
                verifiedTokensList.pop();
                break;
            }
        }
    }
    
    // Rest of the contract functions...
    function getVerifiedTokens() public view returns (address[] memory) {
        return verifiedTokensList;
    }

    function transfer(IERC20 token, address to, uint256 amount, string memory message)
    public
    onlyVerifiedToken(address(token))
    returns (bool)
    {
        // Check the token balance of the sender
        uint256 senderBalance = token.balanceOf(msg.sender);

        // Check if the sender has sufficient balance
        require(senderBalance >= amount, "Insufficient balance");

        // Perform the transfer
        bool success = token.transferFrom(msg.sender, to, amount);

        // Check if the transfer was successful
        require(success, "Transfer failed");

        // Emit the transaction completed event
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