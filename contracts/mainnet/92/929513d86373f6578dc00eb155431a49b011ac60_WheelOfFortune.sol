/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

// File: Token.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract WheelOfFortune {
    IERC20 public rewardsToken;
    address public admin;
    uint256 spinPrice = 500;
    mapping(address => mapping(string => uint256)) userRewards;
    mapping(string => uint256[]) possiblePrizes;

    constructor(address _rewardsToken) {
        rewardsToken = IERC20(_rewardsToken);
        admin = msg.sender;
        possiblePrizes["VRTX"] = [
            100,
            200,
            200,
            200,
            500,
            500,
            200,
            500,
            750,
            200,
            500,
            750,
            200,
            100,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            1000,
            500,
            200,
            200,
            200,
            200,
            500,
            750,
            200,
            1000,
            5000,
            2500,
            100,
            500,
            750,
            750,
            750,
            10000,
            750,
            2500,
            1500,
            1500
        ];
        possiblePrizes["Spins"] = [
            1,
            1,
            1,
            1,
            2,
            1,
            1,
            1,
            2,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            3
        ];
        possiblePrizes["Mint"] = [1];
    }

    event WheelFinished(uint256 prize, string prizeType);

    function SpinWheel() public {
        //Check if user has enough Spins and reduce 1 spin
        require(userRewards[msg.sender]["Spins"] >= 1, "No Spins");
        userRewards[msg.sender]["Spins"] -= 1;
        uint256 prizeTypeRandom = random(10000);
        string memory prizeType = "";
        if (prizeTypeRandom >= 0 && prizeTypeRandom <= 150) {
            prizeType = "Mint";
        } else if (prizeTypeRandom >= 151 && prizeTypeRandom <= 2500) {
            prizeType = "Spins";
        } else if (prizeTypeRandom >= 2501 && prizeTypeRandom <= 10000) {
            prizeType = "VRTX";
        } else {
            prizeType = "VRTX";
        }
        uint256 prizeRandom = random(possiblePrizes[prizeType].length);
        uint256 finalPrize = possiblePrizes[prizeType][prizeRandom];

        userRewards[msg.sender][prizeType] += finalPrize;
        emit WheelFinished(finalPrize, prizeType);
    }

    function buySpins(uint256 amount) public {
        require(amount > 0, "Cant Buy 0 Spins");
        rewardsToken.spend(msg.sender, ((amount * spinPrice) * 10**18));

        userRewards[msg.sender]["Spins"] += amount;
    }

    function random(uint256 maxNumber) private view returns (uint256) {
        uint256 randomVRTXPrize = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, maxNumber)
            )
        );
        return randomVRTXPrize % maxNumber;
    }

    function AddSpins(address account, uint256 amount)
        public
        returns (uint256)
    {
        require(msg.sender == admin, "Access Deny");
        userRewards[account]["Spins"] += amount;
        return userRewards[account]["Spins"];
    }

    function GetRewards(address account, string memory key)
        public
        view
        returns (uint256)
    {
        return userRewards[account][key];
    }

    function ResetReward(address account, string memory key) public virtual {
        require(msg.sender == admin, "Access Deny");
        userRewards[account][key] = 0;
    }

    function ClaimPrize() public {
        uint256 reward = userRewards[msg.sender]["VRTX"];
        uint256 dexBalance = rewardsToken.balanceOf(address(this));
        require(reward >= 0, "Cant Claim 0 VRTX");
        require(reward <= dexBalance, "Not enough tokens in the reserve");
        userRewards[msg.sender]["VRTX"] = 0;
        rewardsToken.transfer(msg.sender, reward * 10**18);
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function spend(address from, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}