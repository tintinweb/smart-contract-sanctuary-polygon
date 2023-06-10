// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatible directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatible as KeeperCompatible} from "./AutomationCompatible.sol";
import {AutomationBase as KeeperBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./ProjectTracker.sol";

contract AxialDAO is Ownable, AutomationCompatibleInterface, KeeperCompatible {
    using Address for address;

    // Proposal struct
    struct Proposal {
        uint256 id;
        address creator;
        string projectId;
        string goal;
        uint256 fundingRequired;
        uint256 fundingReceived;
        uint256 startTime;
        uint256 endTime;
        bool votingExpired;
        bool approved;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) voted;
    }

    struct ProposalResponse {
        uint256 id;
        address creator;
        string projectId;
        string goal;
        uint256 fundingRequired;
        uint256 fundingReceived;
        uint256 startTime;
        uint256 endTime;
        bool votingExpired;
        bool approved;
        uint256 yesVotes;
        uint256 noVotes;
    }

    // Other contract references
    ProjectTracker private projectTrackerContract;

    // Proposal variables
    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;

    // DAO treasury
    uint256 public daoTreasury;

    constructor(address _projectTrackerAddress) {
        projectTrackerContract = ProjectTracker(_projectTrackerAddress);
        proposalCounter = 0;
        daoTreasury = 0;
    }

    // Function to create a new proposal
    function createProposal(
        string memory _goal,
        uint256 _fundingRequired,
        uint256 _duration,
        string memory projectId
    ) public {
        require(_duration > 0, "Duration must be greater than zero");
        require(
            _fundingRequired > 0,
            "Funding required must be greater than zero"
        );

        uint256 endTime = block.timestamp + _duration;

        Proposal storage newProposal = proposals[proposalCounter];

        newProposal.id = proposalCounter;
        newProposal.projectId = projectId;
        newProposal.creator = msg.sender;
        newProposal.goal = _goal;
        newProposal.fundingRequired = _fundingRequired;
        newProposal.fundingReceived = 0;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = endTime;
        newProposal.votingExpired = false;
        newProposal.approved = false;
        newProposal.yesVotes = 0;
        newProposal.noVotes = 0;

        proposalCounter++;
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, bool _approve) public {
        require(_proposalId < proposalCounter, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.votingExpired == false, "Proposal Voting has Expired");
        require(
            proposal.voted[msg.sender] == false,
            "Address has already voted"
        );

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        proposal.voted[msg.sender] = true;
    }

    // Function to expire a proposal and trigger approval or rejection
    function expireProposalVoting(uint256 _proposalId) internal returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        if (
            _proposalId > proposalCounter ||
            proposal.votingExpired == true ||
            block.timestamp <= proposal.endTime
        ) {
            return false;
        }

        proposal.votingExpired = true;
        proposal.approved = proposal.yesVotes > proposal.noVotes;

        return true;
    }

    function getProposalById(
        uint256 _proposalId
    ) external view returns (ProposalResponse memory) {
        Proposal storage proposal = proposals[_proposalId];
        ProposalResponse memory response = ProposalResponse({
            id: proposal.id,
            projectId: proposal.projectId,
            creator: proposal.creator,
            goal: proposal.goal,
            fundingRequired: proposal.fundingRequired,
            fundingReceived: proposal.fundingReceived,
            startTime: proposal.startTime,
            endTime: proposal.endTime,
            votingExpired: proposal.votingExpired,
            approved: proposal.approved,
            yesVotes: proposal.yesVotes,
            noVotes: proposal.noVotes
        });

        return response;
    }

    // Function to check if a proposal has votingExpired
    function checkProjectFundingElligible(
        uint256 _proposalId
    ) internal view returns (bool) {
        Proposal storage _proposal = proposals[_proposalId];
        return
            _proposal.votingExpired &&
            (_proposal.fundingRequired - _proposal.fundingReceived > 0);
    }

    // Function to check if a proposal is approved
    function checkApproved(uint256 _proposalId) external view returns (bool) {
        return proposals[_proposalId].approved;
    }

    // Chainlink Keeper method: checkUpkeep
    function checkUpkeep(
        bytes calldata /*checkData*/
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        uint256 proposalId = 0;
        for (uint256 i = 0; i < proposalCounter; i++) {
            if (checkProjectFundingElligible(i)) {
                proposalId = i;
                upkeepNeeded = true;
                break;
            }
        }
        return (upkeepNeeded, abi.encode(proposalId));
    }

    // Chainlink Keeper method: performUpkeep
    function performUpkeep(bytes calldata performData) external override {
        uint256 proposalId = abi.decode(performData, (uint256));
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp >= proposal.endTime,
            "Proposal has not yet votingExpired"
        );

        proposal.approved = proposal.yesVotes > proposal.noVotes;

        if (
            proposal.approved &&
            ((proposal.fundingRequired - proposal.fundingReceived > 0))
        ) {
            // Expire the voting proposal as a first step
            if (!proposal.votingExpired) {
                expireProposalVoting(proposalId);
            }

            if (daoTreasury >= proposal.fundingRequired) {
                projectTrackerContract.fundProject(
                    proposal.projectId,
                    proposal.fundingRequired
                );
                daoTreasury -= proposal.fundingRequired;
                proposal.fundingReceived += proposal.fundingRequired;
            } else {
                // Funding goal not met, wait until sufficient funds are available
            }
        }
    }
}

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract ProjectTracker {
    // Mapping from project ID to project data
    mapping(string => Project) public projects;

    // Array to track admin addresses
    address[] public admins;

    // Modifier to check if the caller is an admin
    modifier onlyAdmin() {
        bool isAdmin = false;
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Only admins can call this function");
        _;
    }

    // Structure for storing project data
    struct Project {
        string id;
        string name;
        uint256 funding;
        uint256 balance;
        uint256 impactGoal;
        uint256 rating;
        bool isCommissioned;
        address[] teamMembers;
    }

    // Constructor to set the deployer as the first admin
    constructor() {
        admins.push(msg.sender);
    }

    function addAdmin(address account) external onlyAdmin returns (bool) {
        admins.push(account);
        return true;
    }

    // Function to add a new project
    function addProject(
        string memory id,
        string memory name,
        uint256 funding,
        uint256 impactGoal,
        uint256 rating,
        address[] memory teamMembers
    ) public {
        // Create a new project object
        Project memory newProject = Project(
            id,
            name,
            funding,
            0,
            impactGoal,
            rating,
            false,
            teamMembers
        );

        // Add the new project to the mapping
        projects[newProject.id] = newProject;
    }

    // Function to transfer MATIC to a project's balance
    function fundProject(string memory projectId, uint256 amount) public payable {
        // Get the project data
        Project memory project = projects[projectId];

        // Check if the sender has enough funds
        require(msg.value >= amount, "Insufficient funds");

        // Update the project's balance
        project.balance += msg.value;

        // Update the project's funding
        project.funding += amount;

        // Emit an event to notify listeners of the transfer
        emit FundProject(projectId, amount);
    }

    function getProjectById(string memory projectId) public view returns (Project memory){
        // return the project data
        return projects[projectId];
    }

    // Function to update the rating of a project by ID
    function updateRating(string memory projectId, uint256 newRating) public {
        // Get the project data
        Project storage project = projects[projectId];

        // Update the project's rating
        project.rating = newRating;
    }

    // Function to allow a team member to withdraw funds from a project's balance
    function withdrawFunds(string memory projectId, uint256 amount) public {
        // Get the project data
        Project storage project = projects[projectId];

        // Check if the sender is a team member
        require(isTeamMember(projectId, msg.sender), "Not a team member");

        // Check if the project has sufficient balance
        require(project.balance >= amount, "Insufficient project balance");

        // Update the project's balance
        project.balance -= amount;

        // Transfer the funds to the sender
        payable(msg.sender).transfer(amount);

        // Emit an event to notify listeners of the withdrawal
        emit WithdrawFunds(projectId, msg.sender, amount);
    }

    // Function to update the commission status of a project
    function updateCommissionStatus(string memory projectId, bool isCommissioned) public onlyAdmin {
        // Get the project data
        Project storage project = projects[projectId];

        // Update the commission status of the project
        project.isCommissioned = isCommissioned;
    }

    // Function to check if an address is a team member of a project
    function isTeamMember(string memory projectId, address teamMember) internal view returns (bool) {
        // Get the project data
        Project storage project = projects[projectId];

        // Check if the team member's address is in the project's team members list
        for (uint256 i = 0; i < project.teamMembers.length; i++) {
            if (project.teamMembers[i] == teamMember) {
                return true;
            }
        }

        return false;
    }

     // Function to add address is a team member of a project
    function addTeamMember(string memory projectId, address teamMember) public returns (bool) {
        // Get the project data
        if(isTeamMember(projectId , msg.sender)){
            Project storage project = projects[projectId];
            project.teamMembers.push(teamMember);
            return true;
        }

        return false;
    }

    // Event to notify listeners of a MATIC transfer
    event FundProject(string projectId, uint256 amount);

    // Event to notify listeners of a funds withdrawal
    event WithdrawFunds(string projectId, address teamMember, uint256 amount);
}