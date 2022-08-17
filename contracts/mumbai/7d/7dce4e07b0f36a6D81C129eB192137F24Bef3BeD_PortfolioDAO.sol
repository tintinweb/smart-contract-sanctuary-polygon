// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PortfolioDAO is Ownable{
    struct Projects {
        address payable creator;
        // CapitalNeeded - Amount needed to start the project
        uint256 CapitalNeeded;
        // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
        uint256 deadline;
        // funded - Amount funded
        uint256 totalFunded;
        // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
        bool executed;
        // investors - list of investors 
        address payable[] investors;
        // investments - list of investments
        uint256[] investments;
    }

    // Emits when a new project is created
    event NewProject(address indexed creator, uint256 indexed projectId, uint256 CapitalNeeded, uint256 deadline);
    // Emits when a project is funded
    event Funded(address indexed investors, uint256 indexed projectId, uint256 amount);
    // Emits when a project is executed
    event Executed(address indexed creator, uint256 indexed projectId, uint256 amount);
    // Emits when a project is cancelled
    event Cancelled(address indexed creator, uint256 indexed projectId, uint256 amount);

    // Create a mapping of ID to Proposal
    mapping(uint256 => Projects) public projects;
    // Number of proposals that have been created
    uint256 public numProjects;

    // Create a payable constructor which initializes the contract
    // The payable allows this constructor to accept an ETH deposit when it is being deployed
    constructor() payable {}

    // Create a modifier which only allows a function to be
    // called if the given proposal's deadline has not been exceeded yet
    modifier activeProjectOnly(uint256 projectIndex) {
        require(projects[projectIndex].deadline > block.timestamp, "Deadline has been exceeded");
        _;
    }

    // Create project 
    function createProject(uint256 _CapitalNeeded, uint256 _deadline) public {
        // Create a new proposal and store it in the `proposals` array
        // The proposal ID is the index of the proposal in the array
        projects[numProjects] = Projects({
            creator: payable(msg.sender),
            CapitalNeeded: _CapitalNeeded,
            deadline: _deadline,
            totalFunded: 0,
            executed: false,
            investors: new address payable[](0),
            investments: new uint256[](0) 
        });
        // Increment the number of proposals
        numProjects++;
        // Emit the NewProposal event
        emit NewProject(msg.sender, numProjects, _CapitalNeeded, _deadline);
    }

    // Fund project
    function fundProject(uint256 projectIndex) public payable {
        // Make sure the proposal is still active
        require(projects[projectIndex].deadline > block.timestamp, "Deadline has been exceeded");
        // Make sure the proposal has not been executed yet
        require(projects[projectIndex].executed == false, "Proposal has already been executed");
        // Make sure the proposal has not been executed yet
        require(projects[projectIndex].totalFunded < projects[projectIndex].CapitalNeeded, "Project has been fully funded");
        // Make sure the proposal has not been executed yet
        require(projects[projectIndex].totalFunded + msg.value <= projects[projectIndex].CapitalNeeded, "Project has been fully funded");
        // Add the amount funded to the totalFunded
        projects[projectIndex].totalFunded += msg.value;
        // Add the investor to the investors array
        projects[projectIndex].investors.push(payable(msg.sender));
        // Add the investment to the investments array
        projects[projectIndex].investments.push(msg.value);
        // Emit the Fund event
        emit Funded(msg.sender, projectIndex, msg.value);
    }

    // Execute project
    function executeProject(uint256 projectIndex) public payable {
        // Make sure the proposal has not been executed yet
        require(projects[projectIndex].executed == false, "Proposal has already been executed");
        // Make sure the proposal is still active
        require(projects[projectIndex].deadline <= block.timestamp, "Deadline has not been exceeded");
        // Mark the proposal as executed
        projects[projectIndex].executed = true;
        // Check if capital needed is met
        if (projects[projectIndex].totalFunded >= projects[projectIndex].CapitalNeeded) {
            // Transfer the totalFunded to the creator
            projects[projectIndex].creator.transfer(projects[projectIndex].totalFunded);
            // Emit the Executed event
            emit Executed(projects[projectIndex].creator, projectIndex, projects[projectIndex].totalFunded);
        }
        else {
            // Transfer back to the investors
            for (uint i = 0; i < projects[projectIndex].investors.length; i++) {
                projects[projectIndex].investors[i].transfer(projects[projectIndex].investments[i]);
            }   
        }    
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