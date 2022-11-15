// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingDAO is Ownable {
    uint256 public votingCounter;

    struct Voting {
        bool isActive;
        uint256 month;
        address employeeOfTheMonth;
        mapping(address => bool) votingStatus;
        mapping(address => address) voteTarget;
        mapping(address => uint256) votesReceived;
        address[] eligibleCandidates;
    }

    mapping(uint => Voting) public votingRegistry;

    event VotingCreate(uint month);
    event VotingClosed(uint month);
    event VoteComputed(address votee, address receiver);
    event EmployeeOfTheMonth(address employee, uint month);

    function createNewVoting(
        uint _month,
        address _candidate1,
        address _candidate2,
        address _candidate3
    ) public onlyOwner {
        require(
            !votingRegistry[votingCounter].isActive,
            "A voting section is already live!"
        );
        require(
            _candidate1 != _candidate2 && _candidate2 != _candidate3,
            "Duplicate Candidates"
        );

        Voting storage voting = votingRegistry[votingCounter];

        voting.month = _month;
        voting.isActive = true;

        voting.eligibleCandidates.push(_candidate1);
        voting.eligibleCandidates.push(_candidate2);
        voting.eligibleCandidates.push(_candidate3);

        emit VotingCreate(_month);
    }

    function vote(uint256 _chosenEmployee, address _voter) public onlyOwner {
        require(
            votingRegistry[votingCounter].isActive,
            "No voting section active at the moment."
        );
        require(
            !votingRegistry[votingCounter].votingStatus[_voter],
            "You can only vote once."
        );
        address[] memory candidatesArray = votingRegistry[votingCounter]
            .eligibleCandidates;
        require(_chosenEmployee < 3);

        votingRegistry[votingCounter].votesReceived[
            candidatesArray[_chosenEmployee]
        ]++;
        votingRegistry[votingCounter].voteTarget[_voter] = candidatesArray[
            _chosenEmployee
        ];
        votingRegistry[votingCounter].votingStatus[_voter] = true;

        emit VoteComputed(_voter, candidatesArray[_chosenEmployee]);
    }

    function endVoting() public onlyOwner {
        require(
            votingRegistry[votingCounter].isActive,
            "No voting section active at the moment."
        );
        votingRegistry[votingCounter].isActive = false;
        getMostVotedEmployee();
        emit VotingClosed(votingCounter);
        votingCounter++;
    }

    function getMostVotedEmployee() internal returns (address) {
        address[] storage candidates = votingRegistry[votingCounter]
            .eligibleCandidates;
        address employeeOfTheMonth = candidates[0];
        for (uint i = 1; i < candidates.length; i++) {
            if (
                votingRegistry[votingCounter].votesReceived[candidates[i]] >
                votingRegistry[votingCounter].votesReceived[employeeOfTheMonth]
            ) {
                employeeOfTheMonth = votingRegistry[votingCounter]
                    .eligibleCandidates[i];
            }
        }

        votingRegistry[votingCounter].employeeOfTheMonth = employeeOfTheMonth;
        emit EmployeeOfTheMonth(employeeOfTheMonth, votingCounter);
        return votingRegistry[votingCounter].employeeOfTheMonth;
    }

    //------GETTER FUNCTIONS ---------//
    function getVotingCandidatesByMonth(uint256 _month)
        public
        view
        returns (address[] memory)
    {
        address[] memory candidates = votingRegistry[_month].eligibleCandidates;
        return candidates;
    }

    function hasVoted(uint256 _month, address _voter)
        public
        view
        returns (bool)
    {
        bool voted = votingRegistry[_month].votingStatus[_voter];
        return voted;
    }

    function getPreviousEmployeeOfTheMonth() public view returns (address) {
        Voting storage voting = votingRegistry[votingCounter - 1];
        return voting.employeeOfTheMonth;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}