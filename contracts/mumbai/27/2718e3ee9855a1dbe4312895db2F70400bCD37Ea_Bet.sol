// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bet {
    uint256 public result;
    address payable public admin;
    address payable public treasury;
    uint256 public adminFee;
    uint256 public betMinimum;
    uint256 public numOfPlayers;

    uint public constant DECIMAL_FACTOR = 100_00;

    struct Bet {
        uint256 amount;
        uint256 choice;
    }

    mapping(address => Bet) public bet;
    mapping(uint256 => uint256) public choiceBetAmount;
    mapping(address => uint256) public reward;

    address[] public betters;

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller is not the admin");
        _;
    }

    event BetPlaced(address user, uint256 choice, uint256 amount);
    event ResultGenerated(uint256 result);
    event RewardsDistributed(uint256 result, uint256 totalBetAmount);
    event Claimed(address claimer, uint256 claimAmount);

    constructor(
        uint256 _adminfee,
        address _treasury,
        uint256 _betMinimum,
        uint256 _numOfPlayers
    ) {
        admin = payable(msg.sender);
        adminFee = _adminfee;
        treasury = payable(_treasury);
        betMinimum = _betMinimum;
        numOfPlayers = _numOfPlayers;
    }

    function placeBet(uint256 choice) external payable {
        require(msg.value > betMinimum, "cannot bet less than betMinimum");
        uint256 totalAdminFee = ((msg.value * adminFee) / DECIMAL_FACTOR);
        (bool sent1, ) = payable(treasury).call{value: totalAdminFee}("");
        require(sent1, "failed to send fee to admin");
        betters.push(msg.sender);
        bet[msg.sender] = Bet(msg.value - totalAdminFee, choice);
        choiceBetAmount[choice] = choiceBetAmount[choice] += msg.value;
        emit BetPlaced(msg.sender, choice, msg.value);
    }

    function distributeRewards(uint256 result) public payable {
        uint256 totalBetAmount = choiceBetAmount[0] + choiceBetAmount[1];
        for (uint256 i = 0; i < betters.length; i++) {
            if (bet[betters[i]].choice == result) {
                reward[betters[i]] =
                    reward[betters[i]] +
                    (totalBetAmount * bet[betters[i]].amount) /
                    choiceBetAmount[result];
            }
            delete bet[betters[i]];
        }
        delete betters;
        for (uint256 i = 0; i < numOfPlayers; i++) {
            choiceBetAmount[numOfPlayers] = 0;
        }
        emit RewardsDistributed(result, totalBetAmount);
    }

    function claimReward() public {
        require(reward[msg.sender] > 0, "no reward to claim");
        (bool sent, ) = payable(msg.sender).call{value: reward[msg.sender]}("");
        require(sent, "failed to send reward");
        reward[msg.sender] = 0;
        emit Claimed(msg.sender, reward[msg.sender]);
    }

    function withdrawEther(uint256 amount) external onlyAdmin {
        require(
            address(this).balance >= amount,
            "Error, contract has insufficent balance"
        );
        admin.transfer(amount);
    }

    function setAdminFee(uint256 _fee) external onlyAdmin {
        adminFee = _fee;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = payable(_admin);
    }

    function setTreasury(address _treasury) external onlyAdmin {
        treasury = payable(_treasury);
    }

    function setBetMinimum(uint256 _betMinimum) external onlyAdmin {
        betMinimum = _betMinimum;
    }
}