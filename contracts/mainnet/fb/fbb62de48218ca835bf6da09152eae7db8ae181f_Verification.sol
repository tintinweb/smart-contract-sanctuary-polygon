/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/// @title Fractal registry v0
/// @author Antoni Dikov and Shelby Doolittle
contract FractalRegistry {
    address root;
    mapping(address => bool) public delegates;

    mapping(address => bytes32) fractalIdForAddress;
    mapping(string => mapping(bytes32 => bool)) userLists;

    constructor(address _root) {
        root = _root;
    }

    /// @param addr is Eth address
    /// @return FractalId as bytes32
    function getFractalId(address addr) external view returns (bytes32) {
        return fractalIdForAddress[addr];
    }

    /// @notice Adds a user to the mapping of Eth address to FractalId.
    /// @param addr is Eth address.
    /// @param fractalId is FractalId in bytes32.
    function addUserAddress(address addr, bytes32 fractalId) external {
        requireMutatePermission();
        fractalIdForAddress[addr] = fractalId;
    }

    /// @notice Removes an address from the mapping of Eth address to FractalId.
    /// @param addr is Eth address.
    function removeUserAddress(address addr) external {
        requireMutatePermission();
        delete fractalIdForAddress[addr];
    }

    /// @notice Checks if a user by FractalId exists in a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    /// @return bool if the user is the specified list.
    function isUserInList(bytes32 userId, string memory listId)
        external
        view
        returns (bool)
    {
        return userLists[listId][userId];
    }

    /// @notice Add user by FractalId to a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    function addUserToList(bytes32 userId, string memory listId) external {
        requireMutatePermission();
        userLists[listId][userId] = true;
    }

    /// @notice Remove user by FractalId from a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    function removeUserFromList(bytes32 userId, string memory listId) external {
        requireMutatePermission();
        delete userLists[listId][userId];
    }

    /// @notice Only root can add delegates. Delegates have mutate permissions.
    /// @param addr is Eth address
    function addDelegate(address addr) external {
        require(msg.sender == root, "Must be root");
        delegates[addr] = true;
    }

    /// @notice Removing delegates is only posible from root or by himself.
    /// @param addr is Eth address
    function removeDelegate(address addr) external {
        require(
            msg.sender == root || msg.sender == addr,
            "Not allowed to remove address"
        );
        delete delegates[addr];
    }

    function requireMutatePermission() private view {
        require(
            msg.sender == root || delegates[msg.sender],
            "Not allowed to mutate"
        );
    }
}

contract Proxy {

function hasPassedKYC(address addr) public view returns (bool) {
    FractalRegistry registry = FractalRegistry(0xa73084a9F71e1A4183Cf7A4Bf3cEDbDF46BeF61E);
    bytes32 fractalId = registry.getFractalId(addr);
    if (fractalId == 0) {
        return false;
    }
        return registry.isUserInList(fractalId, "0bafea9656909fcb14579fe449b8874c46c8b5b3b2cf2c3d9fd5ad834d18fe5c") || registry.isUserInList(fractalId, "4e1d61ab6c70b34a40b5696a36815dae72dcf00d53d16115761002fd8353cb72");
    }
}


// File contracts/Verification/Fractal.sol



interface IPolytradeProxy {
    function hasPassedKYC(address user) external view returns (bool);
}

interface IVerification {

    /**
     * @notice Emits when new kyc Limit is set
     * @dev Emitted when new kycLimit is set by the owner
     * @param kycLimit, new value of kycLimit
     */
    event ValidationLimitUpdated(uint kycLimit);

/**
 * @notice Updates the limit for the Validation to be required
     * @dev updates validationLimit variable
     * @param validationLimit, new value of depositLimit
     *
     * Emits {ValidationLimitUpdated} event
     */
    function updateValidationLimit(uint validationLimit) external;

/**
 * @notice Returns whether a user's KYC is verified or not
     * @dev returns a boolean if the KYC is valid
     * @param user, address of the user to check
     * @return returns true if user's KYC is valid or false if not
     */
    function isValid(address user) external view returns (bool);

/**
 * @notice Returns whether a validation is required or not based on deposit
     * @dev returns a boolean if the KYC is required or not
     * @param user, address of the user to check
     * @param amount, amount to be added
     * @return returns a boolean if the amount requires a Validation or not
     */
    function isValidationRequired(address user, uint amount)
    external
    view
    returns (bool);

    /**
 * @notice Returns user's provider
     * @dev returns a bytes2 representation of the provider if valid
     * @param user, address of the user to check
     * @return returns bytes2 code representing the provider
     */
    function getUserProvider(address user) external view returns (bytes2);
}


// File contracts/LenderPool/interface/ILenderPool.sol



interface ILenderPool {
    struct Lender {
        uint deposit;
        mapping(address => bool) isRegistered;
    }

    /**
     * @notice Emits when new fund is added to the Lender Pool
     * @dev Emitted when funds are deposited by the `lender`.
     * @param lender, address of the lender
     * @param amount, stable token deposited by the lender
     */
    event Deposit(address indexed lender, uint amount);

    /**
     * @notice Emits when fund is withdrawn by the lender
     * @dev Emitted when tStable token are withdrawn by the `lender`.
     * @param lender, address of the lender
     * @param amount, tStable token withdrawn by the lender
     */
    event Withdraw(address indexed lender, uint amount);

    /**
     * @notice Emitted when staking treasury is switched
     * @dev Emitted when switchTreasury function is called by owner
     * @param oldTreasury, address of the old staking treasury
     * @param newTreasury, address of the new staking treasury
     */
    event TreasurySwitched(address oldTreasury, address newTreasury);

    /**
     * @notice Emits when new DepositLimit is set
     * @dev Emitted when new DepositLimit is set by the owner
     * @param oldVerification, old verification Address
     * @param newVerification, new verification Address
     */
    event VerificationSwitched(
        address oldVerification,
        address newVerification
    );

    /**
     * @notice Emitted when staking strategy is switched
     * @dev Emitted when switchStrategy function is called by owner
     * @param oldStrategy, address of the old staking strategy
     * @param newStrategy, address of the new staking strategy
     */
    event StrategySwitched(address oldStrategy, address newStrategy);

    /**
     * @notice Emitted when `RewardManager` is switched
     * @dev Emitted when `RewardManager` function is called by owner
     * @param oldRewardManager, address of the old RewardManager
     * @param newRewardManager, address of the old RewardManager
     */
    event RewardManagerSwitched(
        address oldRewardManager,
        address newRewardManager
    );

    /**
     * @notice `deposit` is used by lenders to deposit stable token to smart contract.
     * @dev It transfers the approved stable token from msg.sender to lender pool.
     * @param amount, The number of stable token to be deposited.
     *
     * Requirements:
     *
     * - `amount` should be greater than zero.
     * - `amount` must be approved from the stable token contract for the LenderPool.
     * - `amount` should be less than validation limit or KYC needs to be completed.
     *
     * Emits {Deposit} event
     */
    function deposit(uint amount) external;

    /**
     * @notice `withdrawAllDeposit` send lender tStable equivalent to stable deposited.
     * @dev It mints tStable and sends to lender.
     * @dev It sets the amount deposited by lender to zero.
     *
     * Emits {Withdraw} event
     */
    function withdrawAllDeposit() external;

    /**
     * @notice `withdrawDeposit` send lender tStable equivalent to stable requested.
     * @dev It mints tStable and sends to lender.
     * @dev It decreases the amount deposited by lender.
     * @param amount, Total token requested by lender.
     *
     * Requirements:
     * - `amount` should be greater than 0.
     * - `amount` should be not greater than deposited.
     *
     * Emits {Withdraw} event
     */
    function withdrawDeposit(uint amount) external;

    /**
     * @notice `redeemAll` call transfers all reward and deposited amount in stable token.
     * @dev It converts the tStable to stable using `RedeemPool`.
     * @dev It calls `claimRewardsFor` from `RewardManager`.
     *
     * Requirements :
     * - `RedeemPool` should have stable tokens more than lender deposited.
     *
     */
    function redeemAll() external;

    /**
     * @notice `switchRewardManager` is used to switch reward manager.
     * @dev It pauses reward for previous `RewardManager` and initializes new `RewardManager` .
     * @dev It can be called by only owner of LenderPool.
     * @dev Changed `RewardManager` contract must complies with `IRewardManager`.
     * @param newRewardManager, Address of the new `RewardManager`.
     *
     * Emits {RewardManagerSwitched} event
     */
    function switchRewardManager(address newRewardManager) external;

    /**
     * @notice `switchVerification` updates the Verification contract address.
     * @dev Changed verification Contract must complies with `IVerification`
     * @param newVerification, address of the new Verification contract
     *
     * Emits {VerificationContractUpdated} event
     */
    function switchVerification(address newVerification) external;

    /**
     * @notice `switchStrategy` is used for switching the strategy.
     * @dev It moves all the funds from the old strategy to the new strategy.
     * @dev It can be called by only owner of LenderPool.
     * @dev Changed strategy contract must complies with `IStrategy`.
     * @param newStrategy, address of the new staking strategy.
     *
     * Emits {StrategySwitched} event
     */
    function switchStrategy(address newStrategy) external;

    /**
     * @notice `claimReward` transfer all the `token` reward to `msg.sender`
     * @dev It loops through all the `RewardManager` and transfer `token` reward.
     * @param token, address of the token
     */
    function claimReward(address token) external;

    /**
     * @notice `rewardOf` returns the total reward of the lender
     * @dev It returns array of number, where each element is a reward
     * @dev For example - [stable reward, trade reward 1, trade reward 2]
     * @return Returns the total pending reward
     */
    function rewardOf(address lender, address token) external returns (uint);

    /**
     * @notice `getDeposit` returns total amount deposited by the lender
     * @param lender, address of the lender
     * @return returns amount of stable token deposited by the lender
     */
    function getDeposit(address lender) external view returns (uint);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File contracts/Verification/Verification.sol



/**
 * @author Polytrade
 * @title Verification
 */
contract Verification is IVerification, Ownable {

    uint public validationLimit;

    ILenderPool public lenderPool;
    IVerification public verification;
    IPolytradeProxy public proxy;

    constructor(address _lenderPool, IVerification _verification, IPolytradeProxy _proxy) {
        lenderPool = ILenderPool(_lenderPool);
        verification = _verification;
        proxy = _proxy;
    }

    /**
     * @notice Updates the limit for the Validation to be required
     * @dev updates validationLimit variable
     * @param _validationLimit, new value of depositLimit
     *
     * Emits {ValidationLimitUpdated} event
     */
    function updateValidationLimit(uint _validationLimit) external onlyOwner {
        validationLimit = _validationLimit;
        emit ValidationLimitUpdated(_validationLimit);
    }

    /**
     * @notice Returns whether a user's Validation is verified or not
     * @dev returns a boolean if the Validation is valid
     * @param user, address of the user to check
     * @return returns true if user's Validation is valid or false if not
     */
    function isValid(address user) external view returns (bool) {
        return verification.isValid(user) ? true : proxy.hasPassedKYC(user);
    }

    /**
     * @notice Returns user's provider
     * @dev returns a bytes2 representation of the provider if valid
     * @param user, address of the user to check
     * @return returns bytes2 code representing the provider (0x00a3 for FractalID)
     */
    function getUserProvider(address user) external view returns (bytes2) {
        return proxy.hasPassedKYC(user) ? bytes2(0xa300) : verification.getUserProvider(user);
    }

    /**
     * @notice `isValidationRequired` returns if Validation is required to deposit `amount` on LenderPool
     * @dev returns true if Validation is required otherwise false
     */
    function isValidationRequired(address user, uint amount)
        external
        view
        returns (bool)
    {
        if (IVerification(this).isValid(user)) {
            return false;
        }
        uint deposit = lenderPool.getDeposit(user);
        return deposit + amount >= validationLimit;
    }
}