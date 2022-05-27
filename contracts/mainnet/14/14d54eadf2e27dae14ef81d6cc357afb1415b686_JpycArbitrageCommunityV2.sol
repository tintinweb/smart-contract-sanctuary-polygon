/**
 *Submitted for verification at polygonscan.com on 2022-05-27
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

contract JpycArbitrageCommunityV2 {
    address internal immutable self;
    IErc20 internal constant jpycv2 = IErc20(0x431D5dfF03120AFA4bDf332c61A6e1766eF37BDB);
    mapping(address => bool) internal owners;
    IJpycArbitrage internal implementation;
    uint256 internal reserve;
    uint256 internal contribution;
    uint256 internal threshold;
    uint256 internal distribution;
    uint256 internal commission;
    mapping(address => uint256) internal userAdjustment;
    modifier restricted {
        require(address(this) == self);
        require(owners[msg.sender]);
        _;
    }
    constructor() {
        self = address(this);
        owners[msg.sender] = true;
    }
    function addOwner(address[] calldata addresses) public restricted {
        uint256 i;
        for(i = 0; i < addresses.length; i++) {
            owners[addresses[i]] = true;
        }
    }
    function removeOwner(address[] calldata addresses) public restricted {
        uint256 i;
        for(i = 0; i < addresses.length; i++) {
            owners[addresses[i]] = false;
        }
    }
    function call(address payable target, bytes calldata arguments) public restricted returns(bytes memory) {
        bytes memory a;
        (, a) = target.call(arguments);
        return a;
    }
    function read(bytes32 slot) public view restricted returns(bytes32) {
        bytes32 a;
        assembly {
            a := sload(slot)
        }
        return a;
    }
    function write(bytes32 slot, bytes32 data) public restricted {
        assembly {
            sstore(slot, data)
        }
    }
    function setImplementation(address _implementation) public restricted {
        implementation = IJpycArbitrage(_implementation);
        jpycv2.approve(_implementation, type(uint256).max);
    }
    function getParameters() public view returns(uint256, uint256, uint256, uint256) {
        return (contribution, threshold, distribution, commission);
    }
    function setParameters(uint256 _contribution, uint256 _threshold, uint256 _distribution, uint256 _commission) public restricted {
        contribution = _contribution;
        threshold = _threshold;
        distribution = _distribution;
        commission = _commission;
    }
    function getReserve() public view returns(uint256) {
        return reserve;
    }
    function getBalance() public view returns(uint256) {
        return jpycv2.balanceOf(address(this));
    }
    function withdraw(uint256 amount) public restricted {
        jpycv2.transfer(msg.sender, amount);
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
        balance = jpycv2.balanceOf(address(this));
        if(balance >= amount + reserve) {
            borrowed = 0;
        }
        else {
            borrowed = jpycv2.balanceOf(msg.sender);
            require(balance + borrowed >= amount + reserve);
            jpycv2.transferFrom(msg.sender, address(this), borrowed);
        }
        implementation.arbitrage(amount, minimum, route, loop);
        balanceNew = jpycv2.balanceOf(address(this));
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
        jpycv2.transfer(msg.sender, borrowed);
    }
}