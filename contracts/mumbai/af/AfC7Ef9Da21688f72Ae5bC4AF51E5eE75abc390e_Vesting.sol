//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./preEVCToken.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

interface SwappedToken {

    function individualEVCswapVesting(address _user) external view returns(uint256);

}

contract Vesting is Ownable, ReentrancyGuard {

    preEVCToken public preevcToken;
    IERC20 public EVCToken;

    address public evcNft;

    uint256 public claimVestPercentage = 10;
    uint256 public claimVestTime = 60;

    mapping(address => bool) public completeClaim;
    mapping(address => uint256) redeemValue;
    mapping(address => uint256) claimable;
    mapping(address => uint256) public nextRedeemTime;
    mapping(address => uint256) public nextRedeemTime_poolSwap;
    mapping(address => uint256) public redeemValue_poolSwap;
    mapping(address => uint256) public RBlastClaimTime;

    event EVCTokensClaimedRB(address indexed account, uint256 amount);
    event RedeemVested(address sender, uint256 amount);

    //Constructor
    constructor(address _preevcAddress, address _evcAddress) {
        EVCToken = IERC20(_evcAddress);
        preevcToken = preEVCToken(_preevcAddress);
    }

    //User
    function claimVested() public nonReentrant {
        require(nextRedeemTime[msg.sender] < block.timestamp, "To claim vested, please wait until the next redeemable timing");
        uint256 preEVCTotal = preevcToken.userpreEVCTotally(msg.sender);
        require(preEVCTotal > 0, "Please buy preEVC to redeem EVC");
        uint256 VestedAmount = remainingAmount(msg.sender);
        require(VestedAmount > 0, "Please redeem preEVC with EVC");
        claimable[msg.sender] = VestedAmount;
        uint256 transferableAmount = VestedAmount / claimVestPercentage;
        require(EVCToken.balanceOf(address(this)) >= VestedAmount, "Not Enough tokens in contract for claim");
        EVCToken.transfer(msg.sender, transferableAmount);
        redeemValue[msg.sender] += transferableAmount;
        nextRedeemTime[msg.sender] = block.timestamp + claimVestTime;
        emit RedeemVested(msg.sender, transferableAmount);
    }

    function claimVestedRB() public nonReentrant {
        require(nextRedeemTime_poolSwap[msg.sender] < block.timestamp, "To claim vested, please wait until the next redeemable timing");
        uint256 swapEVCearning = SwappedToken(evcNft).individualEVCswapVesting(msg.sender);
        uint256 totalClaimed = redeemValue_poolSwap[msg.sender];
        uint256 rewardPercentage;
        require(totalClaimed < swapEVCearning, "you have no balance to claim");
        if (RBlastClaimTime[msg.sender] > 0) {
            if (completeClaim[msg.sender] == true) {
                rewardPercentage = 10;
                completeClaim[msg.sender] = false;
            } else {
                uint256 elapsedTime = block.timestamp - RBlastClaimTime[msg.sender];
                if (elapsedTime >= 60 && elapsedTime <= 599) {
                    rewardPercentage = (elapsedTime / 60) * 10;
                } else if (elapsedTime >= 600) {
                    rewardPercentage = 100;
                    completeClaim[msg.sender] = true;
                }
            }
        } else {
            rewardPercentage = 10;
        }
        uint256 swapEVCTotal = swapEVCearning - totalClaimed;
        uint256 amountEVC = (swapEVCTotal * rewardPercentage) / 100;
        require(amountEVC > 0, "can't transfer zero tokens");
        EVCToken.transfer(msg.sender, amountEVC);
        redeemValue_poolSwap[msg.sender] += amountEVC;
        nextRedeemTime_poolSwap[msg.sender] = block.timestamp + claimVestTime;
        RBlastClaimTime[msg.sender] = block.timestamp;
        emit EVCTokensClaimedRB(msg.sender, amountEVC);
    }

    //View
    function claimableAmount(address _address) public view returns(uint256) {
        return remainingAmount(_address) / claimVestPercentage;
    }

    function getElapsedTime(address _user) public view returns(uint256) {
        if (RBlastClaimTime[_user] == 0) {
            return 0;
        }
        if (completeClaim[msg.sender] == true) {
            return 0;
        }
        uint256 elapsedTime = block.timestamp - RBlastClaimTime[_user];
        return elapsedTime;
    }

    function getRemainingEVCAmountRB(address _user) public view returns(uint256) {
        uint256 swapEVCearning = SwappedToken(evcNft).individualEVCswapVesting(_user);
        uint256 totalClaimed = redeemValue_poolSwap[_user];
        uint256 swapEVCTotal = swapEVCearning - totalClaimed;
        return swapEVCTotal;
    }

    function getRewardPercentageEVCRB(address _user) public view returns(uint256) {
        if (RBlastClaimTime[_user] == 0 || completeClaim[msg.sender] == true) {
            return 10;
        }
        uint256 elapsedTime = block.timestamp - RBlastClaimTime[_user];
        uint256 rewardPercentage;
        if (elapsedTime >= 1 && elapsedTime <= 59) {
            return 0;
        }
        if (elapsedTime >= 60 && elapsedTime <= 119) {
            rewardPercentage = 10;
        } else if (elapsedTime >= 120 && elapsedTime <= 179) {
            rewardPercentage = 20;
        } else if (elapsedTime >= 180 && elapsedTime <= 239) {
            rewardPercentage = 30;
        } else if (elapsedTime >= 240 && elapsedTime <= 299) {
            rewardPercentage = 40;
        } else if (elapsedTime >= 300 && elapsedTime <= 359) {
            rewardPercentage = 50;
        } else if (elapsedTime >= 360 && elapsedTime <= 419) {
            rewardPercentage = 60;
        } else if (elapsedTime >= 420 && elapsedTime <= 479) {
            rewardPercentage = 70;
        } else if (elapsedTime >= 480 && elapsedTime <= 539) {
            rewardPercentage = 80;
        } else if (elapsedTime >= 540 && elapsedTime <= 599) {
            rewardPercentage = 90;
        } else if (elapsedTime >= 600) {
            rewardPercentage = 100;
        }
        return rewardPercentage;
    }

    function remainingAmount(address _address) public view returns(uint256) {
        if (preevcToken.balanceOf(_address) > 0) {
            return (preevcToken.userpreEVCTotally(_address) - redeemValue[_address]) - preevcToken.balanceOf(_address);
        } else {
            return preevcToken.userpreEVCTotally(_address) - redeemValue[_address];
        }
    }

    //Admin
    function setClaimVestPercentage(uint256 _claimVestPercentage) public onlyOwner {
        claimVestPercentage = _claimVestPercentage;
    }

    function setClaimVestTime(uint256 _claimVestTime) public onlyOwner {
        claimVestTime = _claimVestTime;
    }

    function setEvcNftAddress(address _evcNft) public onlyOwner {
        evcNft = _evcNft;
    }

    function setEVCToken(address _EVCToken) public onlyOwner {
        EVCToken = IERC20(_EVCToken);
    }

    function setPreevcToken(address _preevcToken) public onlyOwner {
        preevcToken = preEVCToken(_preevcToken);
    }

}