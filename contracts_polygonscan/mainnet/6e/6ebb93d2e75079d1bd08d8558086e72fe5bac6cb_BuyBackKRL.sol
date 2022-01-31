/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

// File: contracts/whitelist.sol

/**
 *Submitted for verification at polygonscan.com on 2021-11-18
*/

pragma solidity ^0.8;

contract StakingRewards {
    mapping(address => uint256) public rewards;

    uint public _totalSupply;
    mapping(address => uint256) public _balances;

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function currentReward(address account) public view returns (uint256) {
        return rewards[account];
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BuyBackKRL {

    IERC20 public KRL;
    StakingRewards public Staked;

    mapping(address=>bool) public whitelistCheck;
    mapping(address=>uint256) public KRLbalance;
    uint public whitelistCount;

    constructor(address _krl, address _stake) {
        KRL = IERC20(_krl);
        Staked = StakingRewards(_stake);
    }

    function whitelist() external {
        address _sender = msg.sender;
        uint _val = KRL.balanceOf(_sender);
        require(_val > 0, "Error: KRL Token balance zero");
        require(whitelistCheck[_sender] == false, "Error: Wallet already whitelisted");
        whitelistCheck[_sender] = true;
        KRLbalance[_sender] += _val;
        whitelistCount += 1;
    }

    function whitelistStaked() external {
        address _sender = msg.sender;
        uint _val = Staked.balanceOf(_sender);
        require(_val > 0, "Error: KRL Token balance zero");
        require(whitelistCheck[_sender] == false, "Error: Wallet already whitelisted");
        whitelistCheck[_sender] = true;
        KRLbalance[_sender] += _val;
        whitelistCount += 1;
    }
}