/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

pragma solidity ^0.8.9;

//SPDX-License-Identifier: MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function lastBuyTime(address account) external view returns (uint256);

    function lastSellTime(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract MetaMallPayment {
    IBEP20 public metaMall;
    address payable public owner;
    address payable public rewardDistributor; 
    address[] public users;

    struct User {
        bool isUserRegistered;
        uint256 registerTime;
        uint256 registerationCount;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }
    mapping(address => User) public userData;

    event Registered(address user, uint256 registrationTime);

    constructor(address _owner,address _metaMall, address  _rewardReceiver){ 
        owner = payable(_owner);
        metaMall = IBEP20(_metaMall);
        rewardDistributor = payable(_rewardReceiver);
    } 

    function Register(uint256 amount) public {
        require(amount > 0, "insufficient funds");
        users.push(msg.sender);
        User storage user = userData[msg.sender];
        user.isUserRegistered = true;
        user.registerTime = block.timestamp;
        metaMall.transferFrom(msg.sender,rewardDistributor,amount);

        emit Registered(msg.sender, block.timestamp);
    }

    function changemetaMall(address _metaMall) external onlyOwner {
        metaMall = IBEP20(_metaMall);
    }

    function TotalUser() public view returns (uint256) {
        return users.length;
    }

    function setRegistration(address _user, bool _state) external onlyOwner {
        userData[_user].isUserRegistered = _state;
    }
}