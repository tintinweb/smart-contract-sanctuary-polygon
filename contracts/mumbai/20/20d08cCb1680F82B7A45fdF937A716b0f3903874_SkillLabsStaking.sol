//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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

contract SkillLabsStaking {
    IERC20 public immutable stakingSKG;
    IERC20 public immutable stakingSKG_USDT;
    IERC20 public immutable stakingSKG_MATIC;
    IERC20 public immutable rewardsToken;

    mapping(address => uint) public balanceOfSKG;
    mapping(address => uint) public balanceOfSKG_USDT;
    mapping(address => uint) public balanceOfSKG_MATIC;

    mapping(address => uint) public timeToRewards;

    constructor(address _stakingSKG, address _stakingSKG_USDT, address _stakingSKG_MATIC, address _rewardsToken) {
        stakingSKG = IERC20(_stakingSKG);
        stakingSKG_USDT = IERC20(_stakingSKG_USDT);
        stakingSKG_MATIC = IERC20(_stakingSKG_MATIC);
        rewardsToken = IERC20(_rewardsToken);
    }

    function stakeSKG(uint _amount) external {
        require(_amount > 0, "amount = 0");
        stakingSKG.transferFrom(msg.sender, address(this), _amount);
        balanceOfSKG[msg.sender] += _amount;
        timeToRewards[msg.sender] = block.timestamp + 300;
    }

    function stakeSKG_USDT(uint _amount) external {
        require(_amount > 0, "amount = 0");
        stakingSKG_USDT.transferFrom(msg.sender, address(this), _amount);
        balanceOfSKG_USDT[msg.sender] += _amount;
        timeToRewards[msg.sender] = block.timestamp + 300;
    }

    function stakeSKG_MATIC(uint _amount) external {
        require(_amount > 0, "amount = 0");
        stakingSKG_MATIC.transferFrom(msg.sender, address(this), _amount);
        balanceOfSKG_MATIC[msg.sender] += _amount;
        timeToRewards[msg.sender] = block.timestamp + 300;
    }

    function withdrawSKG(uint _amount) external {
        require(_amount > 0, "amount = 0");
        balanceOfSKG[msg.sender] -= _amount;
        stakingSKG.transfer(msg.sender, _amount);
    }

    function withdrawSKG_USDT(uint _amount) external {
        require(_amount > 0, "amount = 0");
        balanceOfSKG_USDT[msg.sender] -= _amount;
        stakingSKG_USDT.transfer(msg.sender, _amount);
    }

    function withdrawSKG_MATIC(uint _amount) external {
        require(_amount > 0, "amount = 0");
        balanceOfSKG_MATIC[msg.sender] -= _amount;
        stakingSKG_MATIC.transfer(msg.sender, _amount);
    }

    function getReward() external {
        require(block.timestamp > timeToRewards[msg.sender], "not get reward");

        rewardsToken.transfer(msg.sender, balanceOfSKG[msg.sender] + balanceOfSKG_USDT[msg.sender] + balanceOfSKG_MATIC[msg.sender]);
    }
}