// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient, uint256 amount
    ) external returns (bool);
    function transferFrom(
        address sender, address recipient, uint256 amount
    ) external returns (bool);
    function allowance(
        address owner, address spender
    ) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface IBorrowingLending {
    function getBorrowingProfilesNumber () external view returns (uint256);
    function getTotalLent (
        uint256 borrowingProfileIndex
    ) external view returns (uint256);
    function getUserProfileLent (
        address userAddress, uint256 borrowingProfileIndex
    ) external view returns (uint256);
    function getUsdRate (
        address contractAddress
    ) external view returns (uint256);
}

/**
 * @dev Interface of the Rates contract.
 */
interface IRates {
    function getUsdRate (
        address contractAddress,
        bool realTime
    ) external view returns (uint256);
}

/**
 * @dev Bonus reward based on the lent amount.
 */
contract Reward is Initializable {
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Caller is not the owner');
        _;
    }
    modifier onlyManager() {
        require(_managers[msg.sender], 'Caller is not the manager');
        _;
    }
    modifier onlyBorrowingLendingContract () {
        require(
            msg.sender == address(_borrowingLendingContract),
                'Caller is not the Borrowing Lending contract'
        );
        _;
    }
    struct Profile {
        uint256 rewardPerToken;
        uint256 lastTimestamp;
        uint256 rewardPercentage; // % * 100
        uint256 lastTotalLentAmount;
    }
    struct User {
        uint256 accumulatedReward;
        uint256 withdrawnReward;
        uint256 rewardPerTokenOffset;
        uint256 lastLentAmount;
        uint256 updatedAt;
    }
    mapping (uint256 => Profile) internal _profiles;
    // profileId => Profile data
    mapping (uint256 => uint256) internal _rewardPaid;
    // profileId => paid reward
    mapping (address => mapping (uint256 => uint256)) internal _userRewardPaid;
    // userAddress => profileId => paid reward
    mapping (address => mapping (uint256 => User)) internal _userProfiles;
    // userAddress => profileId => User data
    mapping (address => bool) private _managers;
    IERC20 internal _rewardToken;
    IBorrowingLending internal _borrowingLendingContract;
    IRates _ratesContract;
    address private _owner;
    uint256 internal _duration;
    uint256 internal _endTime;
    uint256 internal _rewardPool;
    uint256 internal _blockTime; // in milliseconds
    uint256 internal constant _SHIFT_18 = 1 ether;
    uint256 internal constant _YEAR = 365 * 24 * 3600;
    // used for exponent shifting for yieldPerToken calculation
    uint256 internal constant _SHIFT_4 = 10000;
    // used for exponent shifting when calculation with decimals

    function initialize (
        address newOwner,
        address rewardTokenAddress,
        address blContractAddress,
        address ratesContractAddress,
        uint256 duration,
        uint256 rewardPool,
        uint256 blockTime
    ) public initializer returns (bool) {
        require(newOwner != address(0), 'Owner address can not be zero');
        require(
            rewardTokenAddress != address(0),
            'Reward token address can not be zero'
        );
        require(
            blContractAddress != address(0),
            'Borrowing Lending contract address can not be zero'
        );
        require(
            ratesContractAddress != address(0),
            'Rates contract address can not be zero'
        );
        require(rewardPool > 0, 'Reward pool should be greater than zero');
        require(duration > 0, 'Duration should be greater than zero');
        require(blockTime > 0, 'Block time should be greater than zero');
        _managers[newOwner] = true;
        _owner = newOwner;
        _rewardToken = IERC20(rewardTokenAddress);
        _borrowingLendingContract = IBorrowingLending(blContractAddress);
        _ratesContract = IRates(ratesContractAddress);
        _blockTime = blockTime;
        _rewardPool = rewardPool;
        _duration = duration;
        _endTime = block.timestamp + duration;
        uint256 profilesNumber = _borrowingLendingContract
        .getBorrowingProfilesNumber();
        uint256 totalPercentage;
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            _profiles[i].lastTimestamp = block.timestamp;
            if (i == profilesNumber) {
                _profiles[i].rewardPercentage = _SHIFT_4 - totalPercentage;
                break;
            }
            _profiles[i].rewardPercentage = _SHIFT_4 / profilesNumber;
            totalPercentage += _profiles[i].rewardPercentage;
        }
        return true;
    }

    // access control functions
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), 'newOwner should not be zero address');
        _owner = newOwner;
        return true;
    }

    function addToManagers (
        address userAddress
    ) public onlyOwner returns (bool) {
        _managers[userAddress] = true;
        return true;
    }

    function removeFromManagers (
        address userAddress
    ) public onlyOwner returns (bool) {
        _managers[userAddress] = false;
        return true;
    }

    /**
     * @dev If true - user has manager role
     */
    function isManager (
        address userAddress
    ) external view returns (bool) {
        return _managers[userAddress];
    }

    /**
     * @dev Owner address getter
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Let users withdraw accrued reward
     */
    function withdrawReward () external returns (bool) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        uint256 reward;
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            uint256 lent = _borrowingLendingContract
                .getUserProfileLent(msg.sender, i);
            uint256 totalLent = _borrowingLendingContract
                .getTotalLent(i);
            _updateProfileReward (
                i
            );
            _updateUserProfileReward (
                msg.sender,
                i
            );
            _profiles[i].lastTotalLentAmount = totalLent;
            _userProfiles[msg.sender][i].lastLentAmount = lent;
            uint256 profileReward = _userProfiles[msg.sender][i].accumulatedReward
                - _userProfiles[msg.sender][i].withdrawnReward;
            _userProfiles[msg.sender][i].withdrawnReward
                += profileReward;
            _rewardPaid[i] += profileReward;
            _userRewardPaid[msg.sender][i] += profileReward;
            reward += profileReward;
        }
        _rewardToken.transfer(msg.sender, reward);
        return true;
    }

    /**
     * @dev This function update total lent and user's lent amount
     * when user lend or withdraw lending
     */
    function updateRewardData (
        address userAddress,
        uint256 profileId,
        uint256 lent,
        uint256 totalLent
    ) external onlyBorrowingLendingContract returns (bool) {
        _updateProfileReward (
            profileId
        );
        _updateUserProfileReward(
            userAddress,
            profileId
        );
        _profiles[profileId].lastTotalLentAmount = totalLent;
        _userProfiles[userAddress][profileId].lastLentAmount = lent;
        return true;
    }

    // manager function
    /**
     * @dev Block time is used for reference only, all calculations in the contract
     * are time based.
     */
    function setBlockTime (
        uint256 blockTime
    ) external onlyManager returns (bool) {
        require(blockTime > 0, 'Block time should be greater than zero');
        _blockTime = blockTime;
        return true;
    }

    /**
     * @dev Borrowing contract is the source of information for reward calculation
     */
    function setBorrowingContract (
        address blContractAddress
    ) external onlyManager returns (bool) {
        require(
            blContractAddress != address(0),
                'Borrowing Lending contract address can not be zero'
        );
        _borrowingLendingContract = IBorrowingLending(blContractAddress);
        return true;
    }

    /**
     * @dev Accrued reward is distributed between deposit profiles of the
     * borrowing-lending contracts according to the percentage that is defined
     * for each borrowing profile. This function allows manager to update borrowing
     * profiles percentage
     */
    function setRewardPercentage (
        uint256[] memory percentage
    ) external onlyManager returns (bool) {
        _updateTotalReward();
        uint256 totalPercentage;
        for (uint256 i; i < percentage.length; i ++) {
            _profiles[i + 1].rewardPercentage = percentage[i];
            totalPercentage += percentage[i];
        }
        require(
            totalPercentage == 10000,
            'Total percentage should be equal 10000 (100%)'
        );
        return true;
    }

    /**
     * @dev This function allows manager to update reward settings
     */
    function setRewardData (
        uint256 duration,
        uint256 endTime,
        uint256 rewardPool
    ) external onlyManager returns (bool) {
        _updateTotalReward();
        _duration = duration;
        _endTime = endTime;
        _rewardPool = rewardPool;
        return true;
    }

    /**
     * @dev Setting rates contract
     */
    function setRatesContract (
        address ratesContractAddress
    ) external onlyManager returns (bool) {
        require(ratesContractAddress != address(0), 'Contract address can not be zero');
        _ratesContract = IRates(ratesContractAddress);
        return true;
    }

    /**
     * @dev This function is for a reward contract migration. It collect total lent data
     * from the borrowing-lending contract
     */
    function setProfilesTotalLent () external onlyManager returns (bool) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            uint256 totalLent = _borrowingLendingContract
                .getTotalLent(i);
            _profiles[i].lastTotalLentAmount = totalLent;
            _profiles[i].lastTimestamp = block.timestamp;
        }
        return true;
    }

    /**
     * @dev This function is for a reward contract migration. It collect users lent data
     * from the borrowing-lending contract for array of addresses.
     */
    function setUserProfilesLent (
        address[] calldata userAddresses
    ) external onlyManager returns (bool) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        for (uint256 i = 0; i < userAddresses.length; i ++) {
            for (uint256 j = 1; j <= profilesNumber; j ++) {
                uint256 lent = _borrowingLendingContract
                    .getUserProfileLent(userAddresses[i], j);
                _userProfiles[userAddresses[i]][j].lastLentAmount = lent;
                _userProfiles[userAddresses[i]][j].updatedAt = block.timestamp;
            }
        }
        return true;
    }

    // admin functions
    function adminWithdrawToken (
        uint256 amount, address tokenAddress
    ) external onlyOwner returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        tokenContract.transfer(msg.sender, amount);
        return true;
    }

    // internal functions
    function _updateTotalReward () internal returns (bool) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            uint256 totalLent = _borrowingLendingContract
                .getTotalLent(i);
            _updateProfileReward(
                i
            );
            _profiles[i].lastTotalLentAmount = totalLent;
        }
        return true;
    }

    function _updateProfileReward (
        uint256 profileId
    ) internal returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp > _endTime) {
            currentTimestamp = _endTime;
        }
        if (_profiles[profileId].lastTimestamp == 0) {
            _profiles[profileId].lastTimestamp = currentTimestamp;
            return true;
        }
        if (_profiles[profileId].lastTotalLentAmount == 0) {
            _profiles[profileId].lastTimestamp = currentTimestamp;
            return true;
        }
        if (_profiles[profileId].rewardPercentage == 0) {
            _profiles[profileId].lastTimestamp = currentTimestamp;
            return true;
        }
        uint256 endTime = currentTimestamp;
        uint256 period = endTime
            - _profiles[profileId].lastTimestamp;
        if (period == 0) return true;

        uint256 profileRewardPerToken = _SHIFT_18
            * _rewardPool
            * period
            * _profiles[profileId].rewardPercentage
            / _duration
            / _SHIFT_4
            / _profiles[profileId].lastTotalLentAmount;
        _profiles[profileId].rewardPerToken += profileRewardPerToken;
        _profiles[profileId].lastTimestamp = currentTimestamp;
        return true;
    }

    function _updateUserProfileReward (
        address userAddress,
        uint256 profileId
    ) internal returns (bool) {
        if (_profiles[profileId].lastTotalLentAmount == 0) {
            _userProfiles[userAddress][profileId].updatedAt =
                _profiles[profileId].lastTimestamp;
            return true;
        }
        uint256 accumulatedReward = (
            _profiles[profileId].rewardPerToken
                - _userProfiles[userAddress][profileId].rewardPerTokenOffset
        ) * _userProfiles[userAddress][profileId].lastLentAmount / _SHIFT_18;
        _userProfiles[userAddress][profileId].accumulatedReward
            += accumulatedReward;
        _userProfiles[userAddress][profileId].rewardPerTokenOffset
            = _profiles[profileId].rewardPerToken;
        _userProfiles[userAddress][profileId].updatedAt =
            _profiles[profileId].lastTimestamp;
        return true;
    }

    // view functions
    function getTokenBalance (
        address tokenAddress
    ) external view returns (uint256) {
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.balanceOf(address(this));
    }

    function getRewardToken () external view returns (address) {
        return address(_rewardToken);
    }

    function getProfile (
        uint256 profileId
    ) external view returns (
        uint256 rewardPerToken,
        uint256 lastTimestamp,
        uint256 rewardPercentage,
        uint256 lastTotalLentAmount
    ) {
        return (
            _profiles[profileId].rewardPerToken,
            _profiles[profileId].lastTimestamp,
            _profiles[profileId].rewardPercentage,
            _profiles[profileId].lastTotalLentAmount
        );
    }

    function getUserProfile (
        address userAddress,
        uint256 profileId
    ) external view returns (
        uint256 accumulatedReward,
        uint256 withdrawnReward,
        uint256 rewardPerTokenOffset,
        uint256 lastLentAmount,
        uint256 updatedAt
    ) {
        return (
            _userProfiles[userAddress][profileId].accumulatedReward,
            _userProfiles[userAddress][profileId].withdrawnReward,
            _userProfiles[userAddress][profileId].rewardPerTokenOffset,
            _userProfiles[userAddress][profileId].lastLentAmount,
            _userProfiles[userAddress][profileId].updatedAt
        );
    }

    function getRewardPercentage (
        uint256 profileId
    ) external view returns (uint256) {
        return _profiles[profileId].rewardPercentage;
    }

    function getRewardData () external view returns (
        uint256 duration,
        uint256 endTime,
        uint256 rewardPool
    ) {
        return (_duration, _endTime, _rewardPool);
    }

    function getRatesContractAddress () external view returns (address) {
        return address(_ratesContract);
    }

    function getRewardPaid(
        uint256 profileId
    ) external view returns (uint256) {
        return _rewardPaid[profileId];
    }

    function getUserRewardPaid(
        address userAddress,
        uint256 profileId
    ) external view returns (uint256) {
        return _userRewardPaid[userAddress][profileId];
    }

    function calculateProfileReward (
        address userAddress,
        uint256 profileId,
        bool accumulated
    ) public view returns (uint256) {
        uint256 lent = _borrowingLendingContract
            .getUserProfileLent(userAddress, profileId);
        uint256 totalLent = _borrowingLendingContract
            .getTotalLent(profileId);
        uint256 reward = _calculateProfileReward(
            userAddress, profileId, lent, totalLent
        );
        if (accumulated) {
            reward += (
                _userProfiles[userAddress][profileId].accumulatedReward
                    - _userProfiles[userAddress][profileId].withdrawnReward
            );
        }
        return reward;
    }

    function calculateReward (
        address userAddress, bool accumulated
    ) external view returns (uint256) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        uint256 reward;
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            reward += calculateProfileReward(
                userAddress,
                i,
                accumulated
            );
        }
        return reward;
    }

    function _calculateProfileReward (
        address userAddress,
        uint256 profileId,
        uint256 lent,
        uint256 totalLent
    ) internal view returns (uint256) {
        if (_profiles[profileId].rewardPercentage == 0) return 0;
        if (lent == 0) return 0;
        uint256 extraPeriodStartTime
            = _profiles[profileId].lastTimestamp;
        if (
            extraPeriodStartTime <
                _userProfiles[userAddress][profileId].updatedAt
        ) {
            extraPeriodStartTime = _userProfiles[userAddress][profileId].updatedAt;
        }
        uint256 endTime = block.timestamp;
        if (endTime > _endTime) {
            endTime = _endTime;
        }
        uint256 extraPeriod;
        if (endTime > extraPeriodStartTime) {
            extraPeriod = endTime - extraPeriodStartTime;
        }
        uint256 rewardPerToken = _profiles[profileId].rewardPerToken;
        if (extraPeriod > 0) {
            rewardPerToken += _SHIFT_18
                * _rewardPool
                * extraPeriod
                * _profiles[profileId].rewardPercentage
                / _duration
                / totalLent
                / _SHIFT_4;
        }
        uint256 reward = (
            rewardPerToken - _userProfiles[userAddress][profileId]
                .rewardPerTokenOffset
        ) * lent / _SHIFT_18;
        return reward;
    }

    function getBlockTime() external view returns (uint256) {
        return _blockTime;
    }

    function getBorrowingContract() external view returns (address) {
        return address(_borrowingLendingContract);
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
     * Calculate current APR (depends on totalLent)
     * uint256 apr = _SHIFT_4 // shift decimals point
     *    * (_rewardPool * rewardTokenUsdRate / _SHIFT_18) // reward amount in USD
     *    * (_profiles[profileId].rewardPercentage / _SHIFT_4) // exact profile part
     *    / (_duration / _YEAR) // duration in years
     *    / totalLent;
     */
    function getProfileApr(
        uint256 profileId
    ) external view returns (uint256) {
        uint256 rewardTokenUsdRate = _ratesContract
            .getUsdRate(address(_rewardToken), false);
        uint256 totalLent = _borrowingLendingContract
            .getTotalLent(profileId);
        if (totalLent == 0) return 0;
        uint256 apr = _rewardPool
            * rewardTokenUsdRate
            * _profiles[profileId].rewardPercentage
            * _YEAR
            / _SHIFT_18
            / _duration
            / totalLent;
        return apr;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}