// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@openzeppelin/contracts/utils/Counters.sol";

contract BetMain {
    using Counters for Counters.Counter;
    Counters.Counter public _betIDs;
    Counters.Counter public match_id;
    uint256 baseBetValue = 10 ether;
    bool betOn = false;

    address ownerOne;
    address[] Owners;

    mapping(uint256 => MatchStruct) matches;

    struct MatchStruct {
        uint256 _matchId;
        string teamOne;
        string teamTwo;
        string winningTeam;
        uint256[] betIds;
    }
    //Mapping matchId to MatchStruct
    mapping(uint256 => MatchStruct) matchIdToMatchStruct;

    event MatchUpdateLauncher(
        uint256 matchId,
        string teamOne,
        string teamTwo,
        string winningTeam,
        uint256[] betIds
    );
    // Need to set this up
    uint256 currentUserWinAmount;

    struct BetStruct {
        uint256 matchId;
        uint256 betId;
        uint256 betAmount;
        address betMakerAddress;
        address betTakerAddress;
        address betWinnerAddress;
        string makerBetTeam;
    }

    event BetEventLauncher(
        uint256 matchId,
        uint256 betId,
        uint256 betAmount,
        address betMakerAddress,
        address betTakerAddress,
        address betWinnerAddress,
        string makerBetTeam
    );

    //betId and BetStruct mapping
    mapping(uint256 => BetStruct) betIdToStruct;

    //winner address to Clamable amount
    mapping(address => uint256) betWinnerAmountClaimable;

    constructor() {
        ownerOne = msg.sender;
        Owners.push(ownerOne);
    }

    modifier onlyOwner() {
        require(
            ownerOne == msg.sender || checkOwner(msg.sender) == true,
            "Only Owners modifier"
        );
        require(betOn == true, "Contract has been turned off by admin");
        _;
    }

    function updateOwners(address addAddress)
        external
        onlyOwner
        returns (address[] memory)
    {
        Owners.push(addAddress);
        return Owners;
    }

    function removeOwner(address removeAddress) external onlyOwner {
        require(Owners.length > 0, "There is only single owner,contact admin");
        uint256 index = Owners.length + 1;

        for (uint256 j = 0; j < Owners.length; j++) {
            if (Owners[j] == removeAddress) {
                index = j;
                for (uint256 i = index; i < Owners.length - 1; i++) {
                    Owners[i] = Owners[i + 1];
                }
                Owners.pop();
                break;
            }
        }
        require(index >= Owners.length, "Please check the address");
    }

    function checkOwner(address checkAddress)
        internal
        onlyOwner
        returns (bool)
    {
        bool check = false;
        require(Owners.length > 0, "There is only single owner,contact admin");
        for (uint256 i = 0; i < Owners.length; i++) {
            if (Owners[i] == checkAddress) {
                check = true;
            }
        }
        return check;
    }

    //@dev this function will supply initial amount to account and to mapping betWinnerAmountClaimable
    function setbetWinnerAmountClaimable(address claimableAddress)
        public
        payable
        onlyOwner
    {
        betWinnerAmountClaimable[claimableAddress] += msg.value;
    }

    // function checkAndAllotFunds(uint256 betAmount) private {
    //     uint256 existingBalance = betWinnerAmountClaimable[msg.sender];
    //     uint256 existingBalancePlusBetAmount = existingBalance + msg.value;

    //     require(
    //         existingBalancePlusBetAmount >= betAmount ||
    //             existingBalance >= betAmount,
    //         "Please enter appropriate amount"
    //     );

    //     if (existingBalance >= betAmount) {
    //         // existing will be used, so reducing only required amount
    //         betWinnerAmountClaimable[msg.sender] -= betAmount;
    //     } else {
    //         // existing + msg.value will be used, so setting 0
    //         betWinnerAmountClaimable[msg.sender] = 0;
    //     }
    // }

    function checkAndAllotFunds(uint256 betAmount) private {
        uint256 existingBalance = betWinnerAmountClaimable[msg.sender];

        if (existingBalance >= betAmount) {
            // existing will be used, so reducing only required amount
            betWinnerAmountClaimable[msg.sender] -= betAmount;
        } else {
            // existing + msg.value will be used, so setting 0
            betWinnerAmountClaimable[msg.sender] = 0;
        }
    }

    //@dev  This fucntion create bets for exsisiting match Ids
    //
    function _createBet(
        //uint256 _betAmount,
        uint256 _matchId,
        string memory _teamName
    ) external payable {
        checkAndAllotFunds(msg.value);
        //checkAndAllotFunds(_betAmount);

        BetStruct memory newStruct = BetStruct(
            _matchId,
            _betIDs.current(),
            msg.value,
            msg.sender,
            address(0),
            address(0),
            _teamName
        );
        betIdToStruct[_betIDs.current()] = newStruct;

        emit BetEventLauncher(
            _matchId,
            _betIDs.current(),
            msg.value,
            msg.sender,
            address(0),
            address(0),
            _teamName
        );

        // We are not able to store  betIds.push(_betIDs.current()) with memory key word
        //MatchStruct memory newMatchStruct = matchIdToMatchStruct[_matchId];
        matchIdToMatchStruct[_matchId].betIds.push(_betIDs.current());
        _betIDs.increment();
    }

    //@dev People can join existing bets , for existing matchs, and bets
    function _joinBet(uint256 _betId) external payable {
        BetStruct memory existingBetStruct = betIdToStruct[_betId];

        checkAndAllotFunds(existingBetStruct.betAmount);

        //update the betTaker
        existingBetStruct.betTakerAddress = msg.sender;
        existingBetStruct.betAmount = existingBetStruct.betAmount * 2;

        emit BetEventLauncher(
            existingBetStruct.matchId,
            existingBetStruct.betId,
            existingBetStruct.betAmount,
            existingBetStruct.betMakerAddress,
            existingBetStruct.betTakerAddress,
            existingBetStruct.betWinnerAddress,
            existingBetStruct.makerBetTeam
        );

        betIdToStruct[existingBetStruct.betId] = existingBetStruct;
    }

    //@dev this is an internal function to settle all the bets from particular maatch
    function _settleBet(uint256 _matchId) internal onlyOwner {
        MatchStruct memory newMatchStruct = matchIdToMatchStruct[_matchId];
        require(newMatchStruct.betIds.length > 0, "No bets Placed");

        for (uint256 j = 0; j < newMatchStruct.betIds.length; j++) {
            BetStruct memory newStruct = betIdToStruct[
                newMatchStruct.betIds[j]
            ];

            if (
                keccak256(abi.encodePacked(newStruct.makerBetTeam)) ==
                keccak256(abi.encodePacked(newMatchStruct.winningTeam))
            ) {
                newStruct.betWinnerAddress = newStruct.betMakerAddress;
                betWinnerAmountClaimable[newStruct.betWinnerAddress] +=
                    (newStruct.betAmount * 9) /
                    10;
            } else {
                newStruct.betWinnerAddress = newStruct.betTakerAddress;
                betWinnerAmountClaimable[newStruct.betWinnerAddress] +=
                    (newStruct.betAmount * 9) /
                    10;
            }

            emit BetEventLauncher(
                _matchId,
                newStruct.betId,
                newStruct.betAmount,
                newStruct.betMakerAddress,
                newStruct.betTakerAddress,
                newStruct.betWinnerAddress,
                newMatchStruct.winningTeam
            );
        }
    }

    // @dev This function decides the winningTeam for particular match
    function updateWinningTeam(uint256 _matchId, string memory winningTeam)
        external
        onlyOwner
    {
        require(
            abi.encodePacked(winningTeam).length != 0,
            "Please enter appropriate value for winning team"
        );

        MatchStruct memory newMatchStruct = matchIdToMatchStruct[_matchId];

        require(
            keccak256(abi.encodePacked(winningTeam)) ==
                keccak256(abi.encodePacked(newMatchStruct.teamOne)) ||
                keccak256(abi.encodePacked(winningTeam)) ==
                keccak256(abi.encodePacked(newMatchStruct.teamTwo)),
            "Invalid Team Name Entered"
        );

        if (
            keccak256(abi.encodePacked(winningTeam)) ==
            keccak256(abi.encodePacked(newMatchStruct.teamOne))
        ) {
            newMatchStruct.winningTeam = newMatchStruct.teamOne;
        } else {
            newMatchStruct.winningTeam = newMatchStruct.teamTwo;
        }

        emit MatchUpdateLauncher(
            _matchId,
            newMatchStruct.teamOne,
            newMatchStruct.teamTwo,
            newMatchStruct.winningTeam,
            newMatchStruct.betIds
        );
        _settleBet(_matchId);
    }

    //@dev this fucntion can only be called by owners declared in the onlyOwner
    function _createMatchs(string memory _teamOne, string memory _teamTwo)
        external
        onlyOwner
    {
        require(
            abi.encodePacked(_teamOne).length != 0 &&
                abi.encodePacked(_teamTwo).length != 0,
            "Please enter appropriate data for teams"
        );

        require(
            abi.encodePacked(_teamOne).length !=
                abi.encodePacked(_teamTwo).length,
            "Please check the teams, how can a team play against itself"
        );

        uint256[] memory betArray;
        //matchIdsArr.push(_matchId);
        MatchStruct memory newMatchStruct = MatchStruct(
            match_id.current(),
            _teamOne,
            _teamTwo,
            "",
            betArray
        );

        emit MatchUpdateLauncher(
            match_id.current(),
            _teamOne,
            _teamTwo,
            "",
            betArray
        );
        matchIdToMatchStruct[match_id.current()] = newMatchStruct;
        match_id.increment();
    }

    //@dev this fucntion anyone who wins to calim there winning amount
    //just after the match or collectively afterwards
    function claimYourWinning() external payable {
        require(
            betWinnerAmountClaimable[msg.sender] != 0,
            "You do not have any claimble amount"
        );
        uint256 amountTransfer = betWinnerAmountClaimable[msg.sender];
        payable(msg.sender).transfer(amountTransfer);
        betWinnerAmountClaimable[msg.sender] -= 0;
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function toggleStatus() external returns (bool) {
        require(
            msg.sender == ownerOne,
            "Only Owner can change the status of contract"
        );
        betOn = !betOn;
        return betOn;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}