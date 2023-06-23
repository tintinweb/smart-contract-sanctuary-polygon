//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./preEVCToken.sol";

contract RedeemVest is Ownable, ReentrancyGuard {

    preEVCToken public immutable preevcToken;
    IERC20 public immutable EVCToken;

    uint256 public claimVestTime = 30;
    uint256 public claimVestPercentage = 10;

    mapping(address => uint) public nextRedeemTime;
    mapping(address => uint) redeemvalue;
    mapping(address => uint) claimable;

    event RedeemVested(address sender, uint256 amount);

    //Constructor
    constructor(address _preevcAddress, address _evcAddress) {
        EVCToken = IERC20(_evcAddress);
        preevcToken = preEVCToken(_preevcAddress);
    }

    //User
    function claimVested() external nonReentrant {
        require(nextRedeemTime[msg.sender] < block.timestamp, "To claim vested, please wait until the next redeemable timing");
        uint256 preEVCTotal = preevcToken.userpreEVCTotally(msg.sender);
        require(preEVCTotal > 0, "Please buy preEVC to redeem EVC");
        uint VestedAmount = remainingAmount(msg.sender);
        require(VestedAmount > 0, "Please redeem preEVC with EVC");
        claimable[msg.sender] = VestedAmount;
        uint transferableAmount = VestedAmount / claimVestPercentage;
        require(EVCToken.balanceOf(address(this)) >= VestedAmount, "Not Enough tokens in contract for claim");
        EVCToken.transfer(msg.sender, transferableAmount);
        redeemvalue[msg.sender] += transferableAmount;
        nextRedeemTime[msg.sender] = block.timestamp + claimVestTime;
        emit RedeemVested(msg.sender, transferableAmount);
    }

    //View
    function remainingAmount(address _address) public view returns(uint256) {
        if (preevcToken.balanceOf(_address) > 0) {
            return (preevcToken.userpreEVCTotally(_address) - redeemvalue[_address]) - preevcToken.balanceOf(_address);
        } else {
            return preevcToken.userpreEVCTotally(_address) - redeemvalue[_address];
        }
    }

    function claimableAmount(address _address) public view returns(uint) {
        return remainingAmount(_address) / claimVestPercentage;
    }

    //Admin
    function setClaimVestTime(uint256 _claimVestTime) public onlyOwner {
        claimVestTime = _claimVestTime;
    }

    function setClaimVestPercentage(uint256 _claimVestPercentage) public onlyOwner {
        claimVestPercentage = _claimVestPercentage;
    }

}