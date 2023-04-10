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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./Ownable.sol";

contract Ballot is Ownable {
    uint projectId = 0;
    mapping(uint => Project) projects;
    mapping(uint => Ticket[]) tickets;
    mapping(uint => mapping(address => uint)) ownerTicketCount;

    uint randNonce = 0;

    struct Ticket {
        address owner;
        uint ticketNumber;
    }

    struct Project {
        uint id;
        string name;
        uint endingTime;
        uint ticketPrice;
        address owner;
        bool prizeClaimed;
        uint nextTicketNumber;
    }

    function addProject(
        string calldata _name,
        uint _endingTime,
        uint _ticketPrice
    ) external {
        projects[projectId] = Project(
            projectId,
            _name,
            _endingTime,
            _ticketPrice,
            msg.sender,
            false,
            0
        );

        projectId++;
    }

    function buyTicket(uint _projectId) external payable {
        require(
            block.timestamp <= projects[_projectId].endingTime,
            "The raffle for this project has already ended"
        );

        Project storage selectedProject = projects[_projectId];

        require(msg.value / selectedProject.ticketPrice > 0);

        uint ticketNumber = selectedProject.nextTicketNumber;

        uint buyQuatity = (msg.value -
            (msg.value % selectedProject.ticketPrice)) /
            selectedProject.ticketPrice;

        for (uint i = 0; i < buyQuatity; i++) {
            tickets[_projectId].push(Ticket(msg.sender, ticketNumber));

            ticketNumber++;
            ownerTicketCount[_projectId][msg.sender]++;
        }
    }

    function getProject(uint _projectId) public view returns (Project memory) {
        return projects[_projectId];
    }

    function getTickets(
        uint _projectId,
        address _participant
    ) public view returns (uint[] memory) {
        uint[] memory participantTickets = new uint[](
            ownerTicketCount[_projectId][_participant]
        );
        uint participantTicketOrder = 0;

        for (uint i = 0; i < tickets[uint(_projectId)].length; i++) {
            if (tickets[_projectId][i].owner == _participant) {
                participantTickets[participantTicketOrder] = tickets[
                    uint(_projectId)
                ][i].ticketNumber;
                participantTicketOrder++;
            }
        }

        return participantTickets;
    }

    function raffleWinner(uint _projectId) external {
        require(
            projects[_projectId].owner == msg.sender || msg.sender == owner(),
            "Sender must be project owner or contract owner"
        );
        require(
            block.timestamp > projects[_projectId].endingTime,
            "Current time has not passed ending time yet"
        );
        require(
            !projects[_projectId].prizeClaimed,
            "Prize has been already claimed"
        );

        uint randomNumber = random(tickets[_projectId].length);

        Ticket memory winnerTicket = tickets[_projectId][randomNumber];

        (bool sent, ) = winnerTicket.owner.call{
            value: tickets[_projectId].length * projects[_projectId].ticketPrice
        }("");
        require(sent, "Failed to send Ether");

        projects[_projectId].prizeClaimed = true;
    }

    function random(uint _total) internal returns (uint) {
        uint randomnumber = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % _total;
        randomnumber = randomnumber;
        randNonce++;

        return randomnumber;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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