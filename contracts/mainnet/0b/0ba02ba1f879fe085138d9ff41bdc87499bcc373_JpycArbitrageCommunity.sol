/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IErc20 {
    function decimals() external pure returns(uint8);
    function balanceOf(address) external view returns(uint256);
    function transfer(address, uint256) external returns(bool);
    function approve(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
}

interface IJpycArbitrage {
    function checkArbitrage(uint256) external returns(uint256, uint256);
    function arbitrage(uint256, uint256, uint256, uint256) external;
}

contract JpycArbitrageCommunity {
    address internal immutable self;
    IErc20 internal constant jpyc = IErc20(0x6AE7Dfc73E0dDE2aa99ac063DcF7e8A63265108c);
    mapping(address => bool) internal owners;
    IJpycArbitrage internal implementation;
    uint256 internal reserve;
    uint256 internal contribution;
    uint256 internal threshold;
    uint256 internal distribution;
    uint256 internal commission;
    mapping(address => uint256) internal userAdjustment;
    modifier limited {
        require(address(this) == self);
        require(owners[msg.sender]);
        _;
    }
    constructor() {
        self = address(this);
        owners[msg.sender] = true;
    }
    function addOwner(address[] calldata addresses) public limited {
        uint256 i;
        for(i = 0; i < addresses.length; i++) {
            owners[addresses[i]] = true;
        }
    }
    function removeOwner(address[] calldata addresses) public limited {
        uint256 i;
        for(i = 0; i < addresses.length; i++) {
            owners[addresses[i]] = false;
        }
    }
    function call(address payable target, bytes calldata arguments) public limited returns(bytes memory) {
        bytes memory a;
        (, a) = target.call(arguments);
        return a;
    }
    function setImplementation(address _implementation) public limited {
        implementation = IJpycArbitrage(_implementation);
        jpyc.approve(_implementation, type(uint256).max);
    }
    function getParameters() public view returns(uint256, uint256, uint256, uint256) {
        return (contribution, threshold, distribution, commission);
    }
    function setParameters(uint256 _contribution, uint256 _threshold, uint256 _distribution, uint256 _commission) public limited {
        contribution = _contribution;
        threshold = _threshold;
        distribution = _distribution;
        commission = _commission;
    }
    function getReserve() public view returns(uint256) {
        return reserve;
    }
    function getBalance() public view returns(uint256) {
        return jpyc.balanceOf(address(this));
    }
    function withdraw(uint256 amount) public limited {
        jpyc.transfer(msg.sender, amount);
    }
    function checkArbitrage(uint256 amount) public returns(uint256, uint256) {
        return implementation.checkArbitrage(amount);
    }
    function arbitrage(uint256 amount, uint256 minimum, uint256 route, uint256 loop) public {
        uint256 balance;
        uint256 borrowed;
        uint256 balanceNew;
        uint256 profit;
        uint256 adjustment;
        balance = jpyc.balanceOf(address(this));
        if(balance >= amount + reserve) {
            borrowed = 0;
        }
        else {
            borrowed = jpyc.balanceOf(msg.sender);
            require(balance + borrowed >= amount + reserve);
            jpyc.transferFrom(msg.sender, address(this), borrowed);
        }
        implementation.arbitrage(amount, minimum, route, loop);
        balanceNew = jpyc.balanceOf(address(this));
        require(balanceNew > balance + borrowed);
        profit = balanceNew - balance - borrowed;
        userAdjustment[msg.sender] += amount * contribution / (10 ** 18);
        if(profit < threshold) {
            adjustment = (threshold - profit) * distribution / (10 ** 18);
            if(adjustment > userAdjustment[msg.sender]) {
                adjustment = userAdjustment[msg.sender];
            }
            if(adjustment > reserve) {
                adjustment = reserve;
            }
            reserve -= adjustment;
            userAdjustment[msg.sender] -= adjustment;
            profit += adjustment;
        }
        else {
            adjustment = (profit - threshold) * commission / (10 ** 18);
            reserve += adjustment;
            userAdjustment[msg.sender] += adjustment;
            profit -= adjustment;
        }
        borrowed += profit;
        jpyc.transfer(msg.sender, borrowed);
    }
}