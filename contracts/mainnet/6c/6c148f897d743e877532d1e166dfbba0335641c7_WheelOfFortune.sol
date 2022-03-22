/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// File: Token.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract WheelOfFortune {
    IERC20 public rewardsToken;
    address public admin;
    uint256 public spinPrice = 500;
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
            500,
            500,
            200,
            200,
            100,
            200,
            100,
            200,
            500,
            200,
            200,
            100,
            750,
            200,
            500,
            750,
            200,
            100,
            100,
            100,
            100,
            200,
            200,
            200,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            200,
            100,
            100,
            200,
            200,
            200,
            500,
            200,
            750,
            200,
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

    event WheelFinished(Prize[] prizes);
    struct Prize {
        string prizeType;
        uint256 prizeAmount;
        uint256 id;
    }

    function SetSpinPrice(uint256 amount) public {
        require(msg.sender == admin,"Access Deny");
        spinPrice = amount;
    }

    function SpinWheel(uint256 spinAmount) public {
        Prize[] memory prizes = new Prize[](spinAmount);
        require(spinAmount < 10,"Max 10 Spins at once");
        //Check if user has enough Spins and reduce 1 spin
        require(userRewards[msg.sender]["Spins"] >= 1, "No Spins");
        require(spinAmount >= 1, "Must use atleast 1 Spin");
        require(
            spinAmount <= userRewards[msg.sender]["Spins"],
            "Dont have enough Spins"
        );

        for (uint256 j = 0; j < spinAmount; j++) {
            Prize memory newPrize; //for loop example
            userRewards[msg.sender]["Spins"] -= 1;
            uint256 prizeTypeRandom = random(10000, j * 2);
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
            uint256 prizeRandom = random(
                possiblePrizes[prizeType].length,
                j * 2
            );
            uint256 finalPrize = possiblePrizes[prizeType][prizeRandom];
            newPrize.prizeType = prizeType;
            newPrize.prizeAmount = finalPrize;
            newPrize.id = prizeRandom;
            prizes[j] = newPrize;
            userRewards[msg.sender][prizeType] += finalPrize;
        }
        emit WheelFinished(prizes);
    }

    function buySpins(uint256 amount) public {
        require(amount > 0, "Cant Buy 0 Spins");
        rewardsToken.spend(msg.sender, ((amount * spinPrice) * 10**18));

        userRewards[msg.sender]["Spins"] += amount;
    }

    function random(uint256 maxNumber, uint256 randomSeed)
        private
        view
        returns (uint256)
    {
        uint256 randomVRTXPrize = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp * randomSeed,
                    maxNumber
                )
            )
        );
        return randomVRTXPrize % maxNumber;
    }

    function AddRewards(address account, uint256 amount,string memory key)
        public
        returns (uint256)
    {
        require(msg.sender == admin, "Access Deny");
        userRewards[account][key] += amount;
        return userRewards[account][key];
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