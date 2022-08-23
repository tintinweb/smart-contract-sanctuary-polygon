/**
 *Submitted for verification at polygonscan.com on 2022-08-22
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/trustv4.sol


pragma solidity ^0.8.9;




//  /$$$$$$$$/$$$$$$/$$   /$$/$$$$$$$$/$$$$$$$ /$$   /$$ /$$$$$$ /$$$$$$$$
// | $$_____|_  $$_| $$$ | $|__  $$__| $$__  $| $$  | $$/$$__  $|__  $$__/
// | $$       | $$ | $$$$| $$  | $$  | $$  \ $| $$  | $| $$  \__/  | $$
// | $$$$$    | $$ | $$ $$ $$  | $$  | $$$$$$$| $$  | $|  $$$$$$   | $$
// | $$__/    | $$ | $$  $$$$  | $$  | $$__  $| $$  | $$\____  $$  | $$
// | $$       | $$ | $$\  $$$  | $$  | $$  \ $| $$  | $$/$$  \ $$  | $$
// | $$      /$$$$$| $$ \  $$  | $$  | $$  | $|  $$$$$$|  $$$$$$/  | $$
// |__/     |______|__/  \__/  |__/  |__/  |__/\______/ \______/   |__/

/// @title Fintrust fundraiser
/// @author OGUBUIKE ALEX
/// @notice A contract that handles decentralized societal funding
/// @dev This contract manages donations and withdrawal of funds.
/// @dev The actors are the creators and the signatories.
/// @dev A creator creates a campaign and stores three signatories within the campaign.
/// @dev After receiving donations, a creator requests withdrawal acces from signatories.
/// @dev After withdraw authorization, then the creator can withdraw funds.
contract Fintrust is Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _campaignIdCounter;
    uint256 constant MIN_AMOUNT = 500;
    uint256 constant CHARGE = 0.04 ether;
    uint256 charge;

    enum State {
        Inactive,
        Active,
        TargetReached,
        Ended
    }

    error InvalidAmount(uint256 amount);
    error InactiveCampaign(uint256 campaignId);
    error Unauthorized(address sender);
    error TargetReached(uint256 campaignId);
    error InvalidState(uint256 campaignId, address creator);

    event CampaignCreated(uint256 indexed id, address indexed initiator);
    event Deposit(
        uint256 indexed id,
        address indexed creator,
        address indexed depositor,
        uint256 timeStamp,
        uint256 amount
    );
    event Withdraw(
        uint256 indexed id,
        address indexed creator,
        uint256 indexed timeStamp,
        uint256 amount
    );

    event WithdrawInitiated(
        uint256 indexed id,
        address indexed creator,
        uint256 indexed timeStamp
    );

    event SignerConfirmed(
        uint256 indexed id,
        address indexed creator,
        address indexed sender
    );
    event SignerRejected(
        uint256 indexed id,
        address indexed creator,
        address indexed sender
    );

    modifier onlyEOA() {
        require(isNotContract(msg.sender), "Must use EOA");
        _;
    }

    struct Campaign {
        bool isActive;
        bool withdrawInitiated;
        uint8 confirmations;
        uint8 signatoriesCount;
        State state;
        address initiator;
        uint128 startTimeStamp;
        uint128 endTimeStamp;
        uint256 id;
        uint256 amount;
        uint256 balance;
        uint256 deposited;
        string url;
        address[] signatories;
    }

    struct CampaignRef {
        address initiator;
        bool hasVoted;
        bool withdrawInitiated;
        uint256 id;
        string url;
    }

    mapping(address => Campaign[]) creators;
    mapping(address => CampaignRef[]) signatories;
    Campaign[] campaigns;

    constructor() {}

    /// @notice Pause the smart contract incase of an emergency
    /// @dev modifier onlyRole ensures that it can only be called by a user with the Pauser Role
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause the smart contract
    /// @dev modifier onlyRole ensures that it can only be called by a user with the Pauser Role
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Creates a new campaign for sender
    /// @dev Requires that sender is EOA and contract is not paused
    /// @param _url IPFS Link for campaign metadata
    /// @param _amount Target amount to be generated from campaign
    /// @param _signatories An array that contains the wallet addresses of assigned signatories
    function createCampaign(
        string calldata _url,
        uint256 _amount,
        address[] calldata _signatories
    ) external onlyEOA whenNotPaused {
        //check the value of url is not 0x00 or default bytes32
        if (_amount < MIN_AMOUNT) {
            revert InvalidAmount(_amount);
        }

        if (_signatories.length < 3 || _signatories.length > 250) {
            revert("Error");
        }

        //get the current count of his campaigns created
        Campaign[] storage _signersCampaigns = creators[msg.sender];
        uint256 campaignLength = _signersCampaigns.length;
        uint8 signatorieslength = uint8(_signatories.length);

        //create a new campaign
        Campaign memory _campaign = Campaign({
            url: _url,
            amount: _amount,
            initiator: msg.sender,
            startTimeStamp: uint128(block.timestamp),
            endTimeStamp: 0,
            isActive: true,
            balance: 0,
            deposited: 0,
            withdrawInitiated: false,
            confirmations: 0,
            state: State.Active,
            id: campaignLength,
            signatories: _signatories,
            signatoriesCount: signatorieslength
        });

        //use current count as index to push to the his camapign arrays
        _signersCampaigns.push(_campaign);

        //next for every signatory inside the signatory verify that they are not smart contracts
        address[] memory signers = _signatories;

        for (uint256 i = 0; i < signers.length; i++) {
            address signer = signers[i];

            //verify caller is not part of the signatories
            if (signer == msg.sender) {
                revert("invalid signatory");
            }

            if (!isNotContract(signer)) {
                revert("Not EOA");
            }

            CampaignRef memory _campaignRef = CampaignRef({
                initiator: _campaign.initiator,
                id: _campaign.id,
                url: _campaign.url,
                hasVoted: false,
                withdrawInitiated: false
            });

            CampaignRef[] storage _campaigns = signatories[signer];
            _campaigns.push(_campaignRef);
        }
        campaigns.push(_campaign);
        emit CampaignCreated(_campaign.id, msg.sender);
    }

    /// @notice Donate to a campaign
    /// @dev Payable function that reaquires that the contract is not paused
    /// @param creator The address of the creator of the context campaign
    /// @param _campaignId The campaign Id
    /// @param amount The amount to be deposited
    function donate(
        address creator,
        uint256 _campaignId,
        uint256 amount
    ) external payable whenNotPaused {
        if (msg.value != amount) {
            revert("Invalid amount");
        }

        Campaign[] storage _campaigns = creators[creator];
        Campaign memory _campaign = _campaigns[_campaignId];

        if (_campaign.state != State.Active) {
            revert InvalidState(_campaignId, _campaign.initiator);
        }

        if (!_campaign.isActive) {
            revert InactiveCampaign(_campaignId);
        }

        if (_campaign.deposited >= _campaign.amount) {
            _campaign.state = State.TargetReached;
            revert TargetReached(_campaignId);
        }

        _campaign.balance += msg.value;
        _campaign.deposited += msg.value;
        _campaigns[_campaignId] = _campaign;

        emit Deposit(
            _campaignId,
            _campaign.initiator,
            msg.sender,
            block.timestamp,
            amount
        );
    }

    /// @notice Confirm withdrawal request
    /// @dev To be called by an authoried signatory of context campaign
    /// @param creator The address of the creator of the context campaign
    /// @param _campaignId The campaign Id
    function confirmWithdraw(address creator, uint256 _campaignId) external {
        Campaign storage _campaign = authSigner(creator, _campaignId);
        _campaign.confirmations += 1;
        emit SignerConfirmed(_campaignId, _campaign.initiator, msg.sender);
    }

    /// @notice Reject withdrawal request
    /// @dev To be called by an authoried signatory of context campaign
    /// @dev Resets withdrawal initiation to false
    /// @param creator The address of the creator of the context campaign
    /// @param _campaignId The campaign Id
    function rejectWithdraw(address creator, uint256 _campaignId) external {
        Campaign storage _campaign = authSigner(creator, _campaignId);
        Campaign memory __campaign = _campaign;

        __campaign.withdrawInitiated = false;
        __campaign.confirmations = 0;

        creators[creator][_campaignId] = __campaign;

        emit SignerRejected(_campaignId, _campaign.initiator, msg.sender);
    }

    /// @notice Request withdrawal
    /// @dev Can only be called by creator of context campaign
    /// @param _campaignId The campaign Id
    function requestWithdraw(uint256 _campaignId) external {
        Campaign[] storage _signersCampaigns = creators[msg.sender];
        Campaign memory _campaign = _signersCampaigns[_campaignId];

        if (_campaign.state != State.Active) {
            revert InvalidState(_campaignId, _campaign.initiator);
        }

        if (_campaign.withdrawInitiated) {
            revert("Already requested");
        }

        if (_campaign.deposited <= 0) {
            revert("No deposit yet!");
        }

        _campaign.withdrawInitiated = true;

        _signersCampaigns[_campaignId] = _campaign;

        emit WithdrawInitiated(_campaignId, msg.sender, block.timestamp);
    }

    /// @notice Withdraw funds deposited to a campaign
    /// @dev Requires withdrawal charge of 0.04 MATIC
    /// @dev To be called by the creator of the context campaign
    /// @param amount The amount to be withdrawn
    /// @param _campaignId The campaign Id
    function withdraw(uint256 _campaignId, uint256 amount) external payable {
        if (CHARGE != msg.value) {
            revert("Invalid Charge");
        }

        Campaign[] storage _signersCampaigns = creators[msg.sender];
        Campaign memory _campaign = _signersCampaigns[_campaignId];

        if (msg.sender != _campaign.initiator) {
            revert Unauthorized(msg.sender);
        }

        if (
            _campaign.state != State.Active &&
            _campaign.state != State.TargetReached
        ) {
            revert InvalidState(_campaignId, msg.sender);
        }

        if (!_campaign.withdrawInitiated) {
            revert("campaign withdraw not requested");
        }

        if (_campaign.confirmations != _campaign.signatoriesCount) {
            revert Unauthorized(msg.sender);
        }

        if (_campaign.balance < amount) {
            revert("Insufficient Funds");
        }

        charge += amount;
        _campaign.withdrawInitiated = false;
        _campaign.confirmations = 0;

        if (_campaign.state == State.TargetReached) {
            if (_campaign.balance - amount == 0) {
                _campaign.state = State.Ended;
            }
        }

        _campaign.balance -= amount;
        _campaign.state = State.Ended;

        _signersCampaigns[_campaignId] = _campaign;
        emit Withdraw(
            _campaignId,
            _campaign.initiator,
            block.timestamp,
            amount
        );

        (bool success, ) = _campaign.initiator.call{value: amount}("");

        require(success, "Error in Send");
    }

    /// @notice Withdraw withdraw charges
    /// @dev To be called by only admin
    /// @dev Will send funds to admin/owner account
    function withdrawCharge() external onlyOwner {
        address payable _owner = payable(owner());
        (bool success, ) = _owner.call{value: charge}("");

        require(success, "Error in Send");
    }

    /// @notice Authenticate a user before allowing them to approve/reject withdrawal request
    /// @dev Internal function
    /// @param creator The address of the creator of the context campaign
    /// @param _campaignId The campaign Id
    function authSigner(address creator, uint256 _campaignId)
        internal
        returns (Campaign storage)
    {
        Campaign[] storage _campaigns = creators[creator];
        Campaign storage _campaign = _campaigns[_campaignId];

        if (_campaign.state != State.Active) {
            revert InvalidState(_campaignId, creator);
        }

        if (!_campaign.withdrawInitiated) {
            revert("campaign withdraw not requested");
        }

        CampaignRef[] memory _campaignAssigned = signatories[msg.sender];

        bool isAuthorized = false;
        CampaignRef memory ref;
        uint256 id;

        for (uint256 i = 0; i < _campaignAssigned.length; i++) {
            if (
                _campaignAssigned[i].id == _campaign.id &&
                _campaignAssigned[i].initiator == _campaign.initiator
            ) {
                isAuthorized = true;
                ref = _campaignAssigned[i];
                id = i;
            }
        }

        if (!isAuthorized) {
            revert Unauthorized(msg.sender);
        }

        if (ref.hasVoted) {
            revert("Already voted");
        }

        ref.hasVoted = true;

        signatories[msg.sender][id] = ref;

        return _campaign;
    }

    /// @notice Get a campaign
    /// @param creator The address of the creator of the context campaign
    /// @param _campaignId The campaign Id
    function getCampaign(uint256 _campaignId, address creator)
        external
        view
        returns (Campaign memory)
    {
        return creators[creator][_campaignId];
    }

    /// @notice Get all campaigns created by an address
    /// @param creator The address of the creator of the context campaign
    function allCampaigns(address creator)
        external
        view
        returns (Campaign[] memory)
    {
        return creators[creator];
    }

    /// @notice Get users capaign reference
    /// @param signatory The address of the signatory
    function allRef(address signatory)
        external
        view
        returns (CampaignRef[] memory)
    {
        return signatories[signatory];
    }

    /// @notice Get all campaigns where withdawal request has been initiated
    /// @param signatory The address of the signatory
    function allWithdrawRequest(address signatory)
        external
        view
        returns (Campaign[] memory _campaigns)
    {
        CampaignRef[] memory _campaignRefs = signatories[signatory];
        uint256 index = 0;

        for (uint256 i = 0; i < _campaignRefs.length; i++) {
            address initiator = _campaignRefs[i].initiator;
            uint256 id = _campaignRefs[i].id;

            Campaign memory _campaign = creators[initiator][id];

            if (_campaign.withdrawInitiated) {
                _campaigns[index] = _campaign;
                index += 1;
            }
        }
    }

    /// @notice Get all campaigns ever created
    function getAllCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }

    function isNotContract(address _a) private view returns (bool) {
        uint256 len;
        assembly {
            len := extcodesize(_a)
        }
        if (len == 0) {
            return true;
        }

        return false;
    }
}