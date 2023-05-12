/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromWithPermit(address sender, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


contract DAppSocialPool {

    enum RequestStatus {
        CREATED,
        CANCELLED,
        ACCEPTED,
        COMPLETED
    }

    struct Request {
        uint8 fromChain;
        uint8 toChain;
        address tokenAddress;
        address fromAddress;
        address toAddress;
        RequestStatus status;
        uint256 amount;
        uint256 amountToClaim;
        bool isClaimed;
        uint256 expTime;
    }

    mapping (address => uint256) _nativeBalances; // Native Coin Balances Address => Value
    mapping (address => mapping(address => uint256)) _tokenBalances; // Token Balances Token => Address => Value
    mapping (address => bool) _supportedTokens;
    mapping (uint256 => Request) _requests;
    uint256 serviceFee = 15 * 10**6; // 6 decimals for USDT / USDC
    uint256 platformFee = 5 * 10**6; // 6 decimals for USDT / USDC


    event TokenSupport_Added(address indexed, bool);
    event TokenSupport_Removed(address indexed, bool);
    event Deposit(address indexed, uint256);
    event Withdrawn(address indexed, uint256);

    event TokenDeposited(address indexed, address indexed, uint256);
    event TokenWithdrawn(address indexed, address indexed, uint256);
    event TokenRequest(address indexed tokenAddress,
        address indexed fromAddress,
        uint8 fromChain,
        uint8 toChain,
        uint256 amount,
        RequestStatus status
    );

    error FailedETHSend();

    constructor() {}

    function addSupportedToken(address tokenAddress) external {
        _supportedTokens[tokenAddress] = true;
        emit TokenSupport_Added(tokenAddress, true);
    }

    function removeSupportedToken(address tokenAddress) external {
        _supportedTokens[tokenAddress] = false;
        emit TokenSupport_Removed(tokenAddress, false);
    }

    function depositETH() external payable {
        require(msg.value > 0, "Amount should be greater than 0");
        _nativeBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function depositTokens(address tokenAddress, uint256 amount) external {
        require(_supportedTokens[tokenAddress], "Token is not supported");
        require(amount > 0, "Amount should be greater than 0");
        // Transfer IERC20 tokens to this address
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        _tokenBalances[tokenAddress][msg.sender] += amount;
        emit TokenDeposited(tokenAddress, msg.sender, amount);

    }

    function withdrawETH(uint256 amount) external {
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _nativeBalances[msg.sender], "Not Enough Amount available to withdraw");
        _nativeBalances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (success) {
            emit Withdrawn(msg.sender, amount);
        } else {
            revert FailedETHSend();
        }

    }

    function withdrawTokens(address tokenAddress, uint256 amount) external {
        require(_supportedTokens[tokenAddress], "Token is not supported");
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _tokenBalances[tokenAddress][msg.sender], "Not Enough Amount available to withdraw");
        _tokenBalances[tokenAddress][msg.sender] -= amount;
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, amount);
        // Transfer IERC20 tokens to msg.sender
        emit TokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    function getNativeBalance() external view returns (uint256) {
        return _nativeBalances[msg.sender];
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        return _tokenBalances[tokenAddress][msg.sender];
    }

    function getNativeBalance(address account) external view returns (uint256) {
        return _nativeBalances[account];
    }

    function getTokenBalance(address tokenAddress, address account) external view returns (uint256) {
        return _tokenBalances[tokenAddress][account];
    }

    // Request Cross Chain Transfer of Tokens
    function requestTokens(uint256 id, address tokenAddress, uint256 amount, uint8 fromChain, uint8 toChain, uint256 expTime) external{
        require(_supportedTokens[tokenAddress], "Token is not supported");
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _tokenBalances[tokenAddress][msg.sender], "Not Enough Amount available to transfer");
        require(amount >= serviceFee, "Not Enough amount available to cover the Fee");
        _tokenBalances[tokenAddress][msg.sender] -= amount;
        _requests[id] = Request(fromChain, toChain, tokenAddress, msg.sender, address(0), RequestStatus.CREATED, amount, amount - platformFee, false, block.timestamp + expTime);
        emit TokenRequest(tokenAddress, msg.sender, fromChain, toChain, amount, RequestStatus.CREATED);
    }

    // Accept the Cross Chain Request
    function acceptRequest(uint256 id, address tokenAddress, address toAddress, uint256 amount, uint8 fromChain, uint8 toChain) external{ 
        require(_supportedTokens[tokenAddress], "Token is not supported");
        require(amount > 0, "Amount should be greater than 0");
        require(amount >= _tokenBalances[tokenAddress][msg.sender], "Not Enough Amount available to support transfer");
        _tokenBalances[tokenAddress][msg.sender] -= amount;
        _requests[id] = Request(fromChain, toChain, tokenAddress, msg.sender, toAddress, RequestStatus.ACCEPTED, amount, amount, false, block.timestamp);
        emit TokenRequest(tokenAddress, msg.sender, fromChain, toChain, amount, RequestStatus.ACCEPTED);
    }

    // Use Modifier as this can be called only by admin
    function updateRequest(uint256 id, address toAddress) external {
        Request memory request = _requests[id];
        request.toAddress = toAddress;
        request.status = RequestStatus.ACCEPTED;
        _requests[id] = request;
    }

    function cancelRequest(uint256 id) external {
        Request memory request = _requests[id];
        require(request.status == RequestStatus.CREATED, "Status should be in Created State");
        require(request.fromAddress == msg.sender, "Only Creator can cancel the request");
        _tokenBalances[request.tokenAddress][msg.sender] += request.amount;
        request.status = RequestStatus.CANCELLED;
        _requests[id] = request;
    }

    function claimTokens(uint256 id) external {
        Request memory request = _requests[id];
        require(!request.isClaimed, "The tokens are already claimed");
        require(request.status == RequestStatus.ACCEPTED, "Status should be in Accepted State");
        require(request.toAddress == msg.sender, "Only toAddress can claim the tokens");
        _tokenBalances[request.tokenAddress][msg.sender] += request.amountToClaim;
        request.status = RequestStatus.COMPLETED;
        request.isClaimed = true;
        _requests[id] = request;
    }

}