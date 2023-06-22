// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract bridgeContract {
    address public admin;
    address public manager;

    struct TokenInfo {
        bool canBridge;
        uint totalSupply;
    }

    mapping(address => TokenInfo) public tokenInfo;

    // user => Token => info
    mapping(address => mapping(address => uint)) public userInfo;

    event claimed(address indexed caller, address indexed user, address indexed token, uint amount);
    event bridged(address indexed user, address indexed token, uint amount, string indexed chainID);
    event userStateUpdated(address indexed user, address indexed token);
    event deposited(address indexed user, address indexed token, uint amount);
    event TokenInfoUpdated(address indexed user, address indexed token, bool state);
    event newManager(address indexed _newManager);

    constructor(address _manager){
        admin = msg.sender;
        manager = _manager;
    }

    modifier onlyAllowedToken(address token) {
        require(tokenInfo[token].canBridge,"only allowed token can be bridge");
        _;
    }

    function updateManager(address _newManager) external returns(bool){
        require(msg.sender == admin,"only owner");

        manager = _newManager;

        emit newManager(_newManager);

        return true;
    }

    function claim(address user, address token, uint amount) external onlyAllowedToken(token) returns(bool) {
        require(userInfo[user][token] >= amount,"invalid amount requested");
        require(tokenInfo[token].totalSupply >= amount,"insufficient amount in pool");

        userInfo[user][token] -= amount;
        tokenInfo[token].totalSupply -= amount;

        bool successTransfer = IERC20(token).transfer(user, amount);
        require(successTransfer,"transfer failed");

        emit claimed(msg.sender, user, token, amount);

        return true;
    }

    function bridge(address token, uint amount, string calldata chainID) external onlyAllowedToken(token) returns(bool) {
        IERC20 Token = IERC20(token);
        address user = msg.sender;

        require(Token.allowance(user, address(this)) >= amount,"need allowance");

        bool successTransfer = Token.transferFrom(user, address(this), amount);
        require(successTransfer,"transfer failed");

        // userInfo[user][token].locked += amount;
        tokenInfo[token].totalSupply += amount;

        emit bridged(user, token, amount, chainID);

        return true;
    }

    function updateUserState(address user, address token, uint amount) external returns(bool){
        require(msg.sender == manager,"only manager");

        userInfo[user][token] += amount;

        emit userStateUpdated(user, token);

        return true;
    }

    function deposit(address token , uint amount) external onlyAllowedToken(token) returns(bool) {
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount,"need allowance");

        bool successTransfer = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(successTransfer,"transfer failed");

        tokenInfo[token].totalSupply += amount;

        emit deposited(msg.sender, token, amount);

        return true;
    } 

    function matchState(address token) external returns(bool) {
        require(admin == msg.sender || manager == msg.sender,"only admin or manager");

        uint contractBalance = tokenInfo[token].totalSupply;
        uint actualBalance = IERC20(token).balanceOf(address(this));

        if(contractBalance == actualBalance){
            return true;
        } else {
            tokenInfo[token].totalSupply = actualBalance;
            return true;
        }
    }

    function updateToken(address token, bool isAllowed) external returns(bool){
        require(admin == msg.sender || manager == msg.sender,"only admin or manager");
        require(tokenInfo[token].canBridge != isAllowed,"already in that state");

        tokenInfo[token].canBridge = isAllowed;

        emit TokenInfoUpdated(msg.sender, token, isAllowed);

        return true;
    }

}