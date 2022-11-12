/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: docs.chain.link/samples/VRF/hgv.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// import "@openzeppelin/contracts/access/AccessControl.sol";



interface VRFConsumer {
    function getRequestStatusForLastRequest()
        external
        view
        returns (uint256[] memory randomWords);
}

contract R3ktify is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private roundId;

    // roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROJECT_ROLE = keccak256("PROJECT_ROLE");
    bytes32 public constant R3KTIFIER_ROLE = keccak256("R3KTIFIER_ROLE");
    bytes32 public constant PERMANENT_BAN_ROLE =
        keccak256("PERMANENT_BAN_ROLE");
    bytes32 public constant TEMPORARY_BAN_ROLE =
        keccak256("TEMPORARY_BAN_ROLE");

    // account types
    bytes32 public constant PROJECT = keccak256("PROJECT");
    bytes32 public constant R3KTIFIER = keccak256("R3KTIFIER");

    // temporary ban time
    uint256 public constant TEMPORARY_BAN_TIME = 24 hours;

    // VRFConsumer
    VRFConsumer public _vrfConsumer;

    // enums
    enum Severity {
        none,
        low,
        medium,
        high,
        critical
    }

    enum RewardStatus {
        notRewarded,
        rewarded
    }

    // Sturcts
    struct Report {
        uint256 reportId;
        uint256 rewardAmount;
        string reportUri;
        bool valid;
        address r3ktifier;
        Severity level;
        RewardStatus status;
    }

    struct ProjectBounty {
        uint256 bountyId;
        uint256 submissionCount;
        uint256[5] rewardBreakdown;
        string bountyURI;
    }

    // array
    address[] public projectAddresses;
    ProjectBounty[] public projectBounties;

    // mappings
    mapping(address => bytes32) private _roles;
    mapping(address => uint256) private _banTime;
    mapping(address => ProjectBounty[]) public bounties;
    mapping(uint256 => Report[]) public reports;

    // events
    event RewardedR3ktifier(
        uint256 indexed bountyId,
        uint256 reportId,
        address indexed r3ktifier,
        address indexed project
    );

    event LiftBan(uint256 blocktime, address indexed offender, address amdin);

    event BountyCreated(string bountyURI, address indexed _projectAddress);

    event ReportSubmitted(
        uint256 indexed bountyId,
        string reportURI,
        address indexed r3ktifierAddress
    );

    event ValidatedReport(
        uint256 indexed bountyId,
        uint256 indexed reportId,
        string _reportURI,
        bool _valid
    );

    uint256 internal immutable projectGroupId = 1;
    uint256 internal immutable r3ktifierGroupId = 2;

    // events
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    // modifiers
    modifier onlyAdminRole(address account) {
        // revert if msg.sender is not a Project
        require(hasRole(ADMIN_ROLE, account), "Not an ADMIN");
        _;
    }

    modifier onlyProjectRole(address account) {
        // revert if msg.sender is not a Project
        require(hasRole(PROJECT_ROLE, account), "Not a PROJECT");
        _;
    }

    modifier onlyR3ktifierRole(address account) {
        // revert if msg.sender is banned
        require(
            !hasRole(TEMPORARY_BAN_ROLE, account),
            "Account temporarily banned"
        );
        require(
            !hasRole(PERMANENT_BAN_ROLE, account),
            "Account permanently banned"
        );
        // revert if msg.sender is not a R3ktifier
        require(hasRole(R3KTIFIER_ROLE, account), "Not a R3KTIFIER");
        _;
    }

    constructor(address _vrfAddress) {
        setAdminRole(ADMIN_ROLE, msg.sender);
        _vrfConsumer = VRFConsumer(_vrfAddress);
    }

    function register(string memory accountType, address accountAddress)
        public
        onlyAdminRole(msg.sender)
    {
        bytes32 _accountType = keccak256(abi.encodePacked(accountType));
        // require accountType is one of the accepted types
        require(
            _accountType == PROJECT || _accountType == R3KTIFIER,
            "Unknown account type"
        );

        // check if user is already registered, revert if true.
        require(
            !hasRole(PROJECT_ROLE, accountAddress) ||
                !hasRole(R3KTIFIER_ROLE, accountAddress),
            "Already registered"
        );

        if (_accountType == PROJECT) {
            // add msg.sender to projects array
            _roles[accountAddress] = PROJECT_ROLE;
            projectAddresses.push(accountAddress);

            emit RoleGranted(PROJECT_ROLE, msg.sender, address(this));
        } else {
            // add the user to the registeredR3ktifiers and set role
            _roles[accountAddress] = R3KTIFIER_ROLE;

            emit RoleGranted(R3KTIFIER_ROLE, accountAddress, msg.sender);
        }
    }

    function createBounty(
        string memory bountyURI,
        uint256[5] calldata _rewardBreakdown
    ) public onlyProjectRole(address(msg.sender)) {
        // revert if uri = empty string and rewardBreakdown has 6 values
        require(bytes(bountyURI).length != 0, "Project URI needed");
        require(_rewardBreakdown.length == 5, "5 reward values needed");

        // set Project bounty values
        uint256 currentBountyId = generateId();
        ProjectBounty memory _projectBounty = ProjectBounty({
            bountyId: currentBountyId,
            submissionCount: 0,
            rewardBreakdown: _rewardBreakdown,
            bountyURI: bountyURI
        });

        // write bounty to storage
        bounties[address(msg.sender)].push(_projectBounty);
        projectBounties.push(_projectBounty);

        emit BountyCreated(bountyURI, msg.sender);
    }

    function submitReport(
        uint256 bountyId,
        address projectAddress,
        string memory _reportURI,
        uint8 _severityLevel
    ) public onlyR3ktifierRole(msg.sender) {
        // revert if uri = empty string, _severityLevel out of Severity enum range
        require(bytes(_reportURI).length != 0, "Project URI needed");
        require(_severityLevel < 5, "Invalid severity level");
        require(
            projectBounties[bountyId].bountyId == bountyId,
            "Submitting to wrong project"
        );

        // increment number of submissions for projectBounty
        bounties[projectAddress][bountyId].submissionCount++;

        uint256 currentID = generateId();

        //  fill in report values
        Report memory _report = Report({
            reportId: currentID,
            rewardAmount: 0,
            reportUri: _reportURI,
            valid: false,
            r3ktifier: address(msg.sender),
            level: Severity(_severityLevel),
            status: RewardStatus.notRewarded
        });

        //  store in mapping in projectBounty
        reports[currentID].push(_report);

        emit ReportSubmitted(bountyId, _reportURI, msg.sender);
    }

    function validateReport(
        uint256 bountyId,
        uint256 reportId,
        string memory _reportURI,
        bool _valid,
        uint8 _severityLevel
    ) public onlyProjectRole(address(msg.sender)) {
        // fetch reports data
        Report storage _tempReport = reports[bountyId][reportId];

        require(
            keccak256(abi.encodePacked(_tempReport.reportUri)) ==
                keccak256(abi.encodePacked(_reportURI)),
            "Wrong report data"
        );
        require(_severityLevel < 5, "Invalid severity level");

        // update report data
        _tempReport.valid = _valid;
        _tempReport.level = Severity(_severityLevel);

        // set report to new copy with updated values
        reports[bountyId][reportId] = _tempReport;

        emit ValidatedReport(bountyId, reportId, _reportURI, _valid);
    }

    function rewardR3ktifier(
        address projectAddress,
        uint256 bountyId,
        uint256 reportId
    ) public payable onlyProjectRole(address(msg.sender)) {
        // fetch reports data
        Report memory _tempReport = reports[bountyId][reportId];

        require(_tempReport.valid, "Report marked as invalid");
        require(
            !hasRole(TEMPORARY_BAN_ROLE, _tempReport.r3ktifier) ||
                !hasRole(PERMANENT_BAN_ROLE, _tempReport.r3ktifier),
            "R3ktifier temporarily/permanantly banned"
        );
        require(
            hasRole(R3KTIFIER_ROLE, _tempReport.r3ktifier),
            "Not a r3ktifier"
        );
        require(
            msg.value >=
                bounties[address(projectAddress)][bountyId].rewardBreakdown[
                    uint8(_tempReport.level)
                ],
            "Wrong reward for severity level"
        );

        // change report reward status
        _tempReport.rewardAmount = msg.value;
        _tempReport.status = RewardStatus.rewarded;

        // send reward to r3ktifier
        (bool sent, ) = _tempReport.r3ktifier.call{value: msg.value}("");
        require(sent, "Failed to reward r3ktifier");

        emit RewardedR3ktifier(
            bountyId,
            reportId,
            _tempReport.r3ktifier,
            address(projectAddress)
        );
    }

    function getAllBountiesForAddress(address _projectBounty)
        public
        view
        returns (ProjectBounty[] memory)
    {
        return bounties[_projectBounty];
    }

    function getAllProjects() public view returns (address[] memory) {
        return projectAddresses;
    }

    function getReports(uint256 bountyId)
        public
        view
        onlyProjectRole(address(msg.sender))
        returns (Report[] memory)
    {
        return reports[bountyId];
    }

    function generateId() private returns (uint256) {
        // get randomness value
        uint256[] memory randomWords = _vrfConsumer
            .getRequestStatusForLastRequest();

        uint8 index = uint8(random() % randomWords.length);

        uint256 randomness = randomWords[index] % 999999 + 100000 + index + roundId.current();
        
        return randomness;
    }

    function random() private returns (uint256){
        roundId.increment();
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, roundId.current())));
    }

    function permanentBan(address offenderAddress)
        public
        onlyAdminRole(msg.sender)
    {
        // set offender role
        _roles[offenderAddress] = PERMANENT_BAN_ROLE;
    }

    function temporaryBan(address offenderAddress, uint256 banDuration)
        public
        onlyAdminRole(msg.sender)
    {
        require(
            (banDuration - block.timestamp) > TEMPORARY_BAN_TIME,
            "Ban duration too short"
        );
        require(
            !hasRole(TEMPORARY_BAN_ROLE, offenderAddress),
            "Already on temporary ban"
        );
        // set offender role
        _roles[offenderAddress] = TEMPORARY_BAN_ROLE;
        _banTime[offenderAddress] = banDuration;
    }

    function liftBan(address offenderAddress) public onlyAdminRole(msg.sender) {
        require(
            hasRole(TEMPORARY_BAN_ROLE, offenderAddress),
            "Address not on temporary ban"
        );
        require(
            !hasRole(PERMANENT_BAN_ROLE, offenderAddress),
            "Permanent ban can't be lifted"
        );
        require(
            block.timestamp > _banTime[offenderAddress],
            "Ban still active"
        );

        _roles[offenderAddress] = R3KTIFIER_ROLE;

        emit LiftBan(block.timestamp, offenderAddress, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return role == _roles[account];
    }

    function setAdminRole(bytes32 role, address account) private {
        _roles[account] = role;

        emit RoleGranted(role, account, msg.sender);
    }

    receive() external payable {}

    fallback() external payable {}
}