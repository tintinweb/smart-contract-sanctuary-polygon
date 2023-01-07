// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./iKnockout.sol";

contract Bet {
    IKnockout public knockout;
    mapping(uint => uint) public totalAmount; // tournament index => total value
    mapping(uint => uint) public totalAmountToWithdraw; // tournament index => total value
    mapping(uint => mapping(address => uint)) public totalAmountPerPlayer; // tournament index => player address => total value
    mapping(uint => mapping(address => mapping(address => uint)))
        public totalAmountPerPlayerPerUser; // tournament index => player address => user address => total value
    mapping(uint => mapping(address => uint)) public totalAmountPerUser; // tournament index => user address => total value
    mapping(uint => mapping(address => bool)) public hasWithdrawn; // tournament index => address => has withdrawn price or ticket cost

    constructor(address _knockout) {
        require(_knockout != address(0), "please provide a knockout contract");
        knockout = IKnockout(_knockout);
    }

    // place a bet
    function placeABet(uint tournamentId, address player) external payable {
        require(msg.value > 0, "No value");
        TournamentInfo memory info = knockout.getTournament(tournamentId);

        require(
            info.state == TournamentState.CREATED,
            "Invalid tournament state"
        );
        require(
            info.config.registerEndDate < block.timestamp,
            "Registration is still open"
        );
        require(
            indexOf(info.remainingParticipants, player) >= 0,
            "Player not found"
        );
        require(
            info.config.owner != msg.sender,
            "Tournament owner is not allowed to bet"
        );
        totalAmount[tournamentId] += msg.value;
        totalAmountToWithdraw[tournamentId] += msg.value;
        totalAmountPerPlayer[tournamentId][player] += msg.value;
        totalAmountPerPlayerPerUser[tournamentId][player][msg.sender] += msg
            .value;
        totalAmountPerUser[tournamentId][msg.sender] += msg.value;
    }

    // For the winner to claim his price or if a tournament did not have enough participants or did not finish with a winner to withdraw their initial money
    function claimPrice(uint tournamentId) external {
        TournamentInfo memory info = knockout.getTournament(tournamentId);
        require(!hasWithdrawn[tournamentId][msg.sender], "Already withdrawn");

        uint toWithdraw;
        if (info.state == TournamentState.FINISHED) {
            // if nobody bet on the right winner users can withdraw their funds back
            if (totalAmountPerPlayer[tournamentId][info.winner] == 0) {
                toWithdraw = totalAmountPerUser[tournamentId][msg.sender];
            } else {
                require(
                    totalAmountPerPlayerPerUser[tournamentId][info.winner][
                        msg.sender
                    ] > 0,
                    "Bet on the wrong player"
                );

                uint share = (totalAmountPerPlayerPerUser[tournamentId][
                    info.winner
                ][msg.sender] * 100) /
                    totalAmountPerPlayer[tournamentId][info.winner];
                toWithdraw = (totalAmount[tournamentId] * share) / 100;
            }
        } else if (
            info.state == TournamentState.CANCELED ||
            info.config.createdAt + 365 days < block.timestamp
        ) {
            toWithdraw = totalAmountPerUser[tournamentId][msg.sender];
        }
        if (
            toWithdraw > totalAmountToWithdraw[tournamentId]
        ) // to be sure we dont' withdraw to much, like if there is a rounding error.
        {
            toWithdraw = totalAmountToWithdraw[tournamentId];
        }
        require(toWithdraw > 0, "Nothing to withdraw");
        (bool sent, ) = msg.sender.call{value: toWithdraw}("");
        require(sent, "Failed to withdraw");
        hasWithdrawn[tournamentId][msg.sender] = true;
        totalAmountToWithdraw[tournamentId] -= toWithdraw;
    }

    function indexOf(
        address[] memory arr,
        address searchFor
    ) private pure returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        revert("Address not found");
    }
}