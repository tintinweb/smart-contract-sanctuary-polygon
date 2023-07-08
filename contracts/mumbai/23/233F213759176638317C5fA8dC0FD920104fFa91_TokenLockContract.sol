// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenLockContract {
    address private owner;
    mapping(address => bool) private approvers;
    mapping(uint256 => LockedToken) private lockedTokens;
    uint256 private transactionIdCounter;
    address private immutable tokenContractAddress = 0xf32074e01d972Ec6417308327CB6F9edbB2dD26c ;

    struct LockedToken {
        uint256 transactionId;
        address sender;
        address recipient;
        address tokenAddress;
        uint256 amount;
        bool claimed;
        bool approved;
    }

    event TokenLocked(uint256 indexed transactionId, address indexed sender, address indexed recipient, address tokenAddress, uint256 amount, address[] _approvers);
    event TokensClaimed(uint256 indexed transactionId, address indexed recipient, uint256 amount);
    event TransactionApproved(uint256 indexed transactionId, bool approved);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyApprovers() {
        require(approvers[msg.sender], "Only approved addresses can call this function");
        _;
    }

    function lockTokens(
        address _recipient,
        address _tokenAddress,
        uint256 _amount,
        bool _approved,
        address[] memory _approvers
    ) external {        
        require(_recipient != address(0), "Invalid recipient address");
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20(tokenContractAddress).approve(address(this), _amount );
        IERC20(tokenContractAddress).transferFrom(msg.sender, address(this), _amount );

        uint256 newTransactionId = transactionIdCounter;
        lockedTokens[newTransactionId] = LockedToken({
            transactionId: newTransactionId,
            sender: msg.sender,
            recipient: _recipient,
            tokenAddress: _tokenAddress,
            amount: _amount,
            claimed: false,
            approved: _approved
        });

        emit TokenLocked(newTransactionId, msg.sender, _recipient, _tokenAddress, _amount, _approvers);
        transactionIdCounter++;
    }


    function approveTransaction(uint256 _transactionId, bool _approved) external onlyApprovers {
        require(_transactionId < transactionIdCounter, "Invalid transaction ID");

        lockedTokens[_transactionId].approved = _approved;
        emit TransactionApproved(_transactionId, _approved);
    }

    function claimTokens(uint256 _transactionId) external {
        require(_transactionId < transactionIdCounter, "Invalid transaction ID");
        require(!lockedTokens[_transactionId].claimed, "Tokens already claimed");
        require(lockedTokens[_transactionId].approved, "Transaction not approved");

        uint256 balance = lockedTokens[_transactionId].amount;
        lockedTokens[_transactionId].claimed = true;

        require(
            IERC20(lockedTokens[_transactionId].tokenAddress).transfer(lockedTokens[_transactionId].recipient, balance),
            "Token transfer failed"
        );

        emit TokensClaimed(_transactionId, lockedTokens[_transactionId].recipient, balance);
    }

    function getLockedToken(uint256 _transactionId) external view returns (LockedToken memory) {
        require(_transactionId < transactionIdCounter, "Invalid transaction ID");
        return lockedTokens[_transactionId];
    }

    function withdrawTokens(address _recipient, uint256 _amount, address _tokenAddress) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        require(_tokenAddress != address(0), "Invalid token address");

        require(
            IERC20(_tokenAddress).transfer(_recipient, _amount),
            "Token transfer failed"
        );
    }
}