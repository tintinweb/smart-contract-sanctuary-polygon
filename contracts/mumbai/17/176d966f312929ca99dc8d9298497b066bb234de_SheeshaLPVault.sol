//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./interfaces/ISheeshaVault.sol";
import "./interfaces/ISheeshaVotesLocker.sol";
import "./interfaces/ISheeshaAutocompound.sol";

/**
 * @title Sheesha staking contract
 * @author Sheesha Finance
 */
contract SheeshaLPVault is
    ISheeshaVault,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        bool status;
    }

    struct PoolInfo {
        IERC20Upgradeable lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accSheeshaPerShare;
    }

    IERC20Upgradeable public sheesha;

    uint256 public startBlock;
    uint256 public sheeshaPerBlock;
    uint256 public lpRewards;
    uint256 public totalAllocPoint;
    uint256 public userCount;

    address public feeWallet;
    address public locker;
    address public autoCompound;

    bool public migrationDone;
    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => address) public userList;
    mapping(address => bool) internal isExisting;

    /**
     * @dev Throws if called by any account other than the autoCompound.
     */
    modifier onlyAutocompound() {
        require(
            autoCompound == _msgSender(),
            "Caller is not the autocompound contract"
        );
        _;
    }

    /**
     * @param _sheesha Sheesha native token.
     * @param _feeWallet Address where fee would be transfered.
     * @param _startBlock Start block of staking contract.
     * @param _sheeshaPerBlock Amount of Sheesha rewards per block.
     */
    function initialize(
        IERC20Upgradeable _sheesha,
        address _feeWallet,
        uint256 _startBlock,
        uint256 _sheeshaPerBlock
    ) external initializer {
        require(address(_sheesha) != address(0), "Sheesha can't be address 0");
        require(_feeWallet != address(0), "Fee wallet can't be address 0");
        sheesha = _sheesha;
        feeWallet = _feeWallet;
        startBlock = _startBlock;
        sheeshaPerBlock = _sheeshaPerBlock;
        lpRewards = 200_000_000e18; // need to be change before deployment
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice Function for changing wallet wich recieve all fees
     * @param _feeWallet address of fee reciever
     */
    function changeFeeWallet(address _feeWallet) external onlyOwner {
        require(_feeWallet != address(0), "Fee wallet can't be address 0");
        feeWallet = _feeWallet;
    }

    /**
     * @dev Sets auto compound LP contract
     * param _autoCompound address of auto compound LP contract
     */
    function setAutocompound(address _autoCompound) external onlyOwner {
        autoCompound = _autoCompound;
    }

    /**
     * @dev Adds new locker contract from current voting
     * param _locker address of new locker contract
     */
    function setLocker(address _locker) external onlyOwner {
        locker = _locker;
    }

    /**
     * @dev Creates new pool for staking.
     * @param _allocPoint Allocation points of new pool.
     * @param _lpToken Address of pool token.
     * @param _withUpdate Declare if it needed to update all other pools
     */
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _lpToken,
        bool _withUpdate
    ) external onlyOwner {
        for (uint256 i; i < poolInfo.length; i++) {
            require(poolInfo[i].lpToken != _lpToken, "Pool already exist");
        }
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSheeshaPerShare: 0
            })
        );
    }

    /**
     * @dev Add rewards for Sheesha staking
     * @param _amount Amount of rewards to be added.
     */
    function addRewards(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        IERC20Upgradeable(sheesha).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        lpRewards = lpRewards + _amount;
    }

    /**
     * @dev Updates allocation points of chosen pool
     * @param _pid Pool's unique ID.
     * @param _allocPoint Desired allocation points of new pool.
     * @param _withUpdate Declare if it needed to update all other pools
     */
    function setPoolAllocation(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @notice set last reward block for pool
     * @param _blockNumber specified block number
     */
    function setLastRewardBlock(uint256 _blockNumber) external onlyOwner {
        require(!migrationDone, "Not allowed");
        PoolInfo storage pool = poolInfo[0];
        pool.lastRewardBlock = _blockNumber;
    }

    /**
     * @dev migrates user staked amounts from previous vault contract
     * @param _addr array of users wallets
     * @param _amount array of stake amounts
     * @param _rewardDebt data for reward calculation
     */
    function sync(
        address[] calldata _addr,
        uint256[] calldata _amount,
        uint256[] calldata _rewardDebt
    ) external onlyOwner {
        require(
            _addr.length == _amount.length &&
                _amount.length == _rewardDebt.length,
            "Parameters length mismatch"
        );
        require(!migrationDone, "Not allowed");
        for (uint256 i = 0; i < _addr.length; i++) {
            if (!isUserExisting(_addr[i])) {
                userList[userCount] = _addr[i];
                userCount++;
                isExisting[_addr[i]] = true;
            }
            UserInfo storage user = userInfo[0][_addr[i]];
            user.amount = _amount[i];
            user.rewardDebt = _rewardDebt[i];
            user.status = true;
        }
    }

    /**
     * @dev stop migration
     */
    function stopSync() external onlyOwner {
        require(!migrationDone, "Not allowed");
        migrationDone = true;
    }

    /**
     * @dev Deposits tokens by Auto-Compound to staking contract.
     * @notice Pending rewards would be transfered to Auto-Compound for re-investment
     * param _amount amount of tokens for deposit
     */
    function enterStaking(uint256 _amount) external onlyAutocompound {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accSheeshaPerShare) / 1e12) -
                user.rewardDebt;
            if (pending > 0) {
                _safeSheeshaTransfer(_msgSender(), pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
            user.amount = user.amount + _amount;
        }
        user.rewardDebt = (user.amount * pool.accSheeshaPerShare) / 1e12;
        emit Deposit(msg.sender, 0, _amount);
    }

    /**
     * @dev function that allow to deposit tokens for Auto-compound
     * @notice Pending rewards would be transfered to Auto-Compound for re-investment
     * param _amount amount of tokens for deposit
     */
    function leaveStaking(uint256 _amount) external onlyAutocompound {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = ((user.amount * pool.accSheeshaPerShare) / 1e12) -
            user.rewardDebt;
        if (pending > 0) {
            _safeSheeshaTransfer(_msgSender(), pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(_msgSender(), _amount);
        }
        user.rewardDebt = (user.amount * pool.accSheeshaPerShare) / 1e12;

        emit Withdraw(msg.sender, 0, _amount);
    }

    /**
     * @dev Deposits tokens by user to staking contract.
     * @notice User first need to approve deposited amount of tokens
     * @notice If User has some pending rewards they would be transfered to his wallet
     * @param _pid Pool's unique ID.
     * @param _amount The amount to deposit.
     */
    function deposit(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
    {
        _deposit(_msgSender(), _pid, _amount);
    }

    /**
     * @dev Deposits tokens for specific user in staking contract.
     * @notice Caller of method first need to approve deposited amount of tokens
     * @notice If User has some pending rewards they would be transfered to his wallet
     * @param _depositFor Address of user for which deposit is created
     * @param _pid Pool's unique ID.
     * @param _amount The amount to deposit.
     */
    function depositFor(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) external override nonReentrant {
        _deposit(_depositFor, _pid, _amount);
    }

    /**
     * @dev Withdraws tokens from staking.
     * @notice If User has some pending rewards they would be transfered to his wallet
     * @notice This would take 4% fee which will be sent to fee wallet.
     * @notice No fee for pending rewards.
     * @param _pid Pool's unique ID.
     * @param _amount The amount to withdraw.
     */
    function withdraw(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
    {
        if (locker != address(0)) {
            uint256 unlocked = ISheeshaVotesLocker(locker).unlockedLPOf(
                _msgSender()
            );
            require(unlocked >= _amount, "Tokens locked");
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = ((user.amount * pool.accSheeshaPerShare) / 1e12) -
            user.rewardDebt;
        if (pending > 0) {
            _safeSheeshaTransfer(_msgSender(), pending);
        }
        if (_amount > 0) {
            uint256 fees = (_amount * 4) / 100;
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(feeWallet, fees);
            pool.lpToken.safeTransfer(_msgSender(), _amount - fees);
        }
        user.rewardDebt = (user.amount * pool.accSheeshaPerShare) / 1e12;
        emit Withdraw(_msgSender(), _pid, _amount);
    }

    /**
     * @dev Withdraws all user available amount of tokens without caring about rewards.
     * @notice This would take 4% fee which will be burnt.
     * @param _pid Pool's unique ID.
     */
    function emergencyWithdraw(uint256 _pid) external override nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        uint256 userAvailableAmount = user.amount;
        if (locker != address(0)) {
            uint256 unlocked = ISheeshaVotesLocker(locker).unlockedLPOf(
                _msgSender()
            );
            userAvailableAmount = userAvailableAmount < unlocked
                ? userAvailableAmount
                : unlocked;
        }
        user.amount = user.amount - userAvailableAmount;
        if (user.amount > 0) {
            user.rewardDebt = (user.amount * pool.accSheeshaPerShare) / 1e12;
        } else {
            user.rewardDebt = 0;
        }
        uint256 fees = (userAvailableAmount * 4) / 100;
        pool.lpToken.safeTransfer(feeWallet, fees);
        pool.lpToken.safeTransfer(_msgSender(), userAvailableAmount - fees);
        emit EmergencyWithdraw(_msgSender(), _pid, userAvailableAmount);
    }

    /**
     * @dev Used to display user pending rewards on FE
     * @param _pid Pool's unique ID.
     * @param _user Address of user for which dosplay rewards.
     * @return Amount of rewards available
     */
    function pendingSheesha(uint256 _pid, address _user)
        external
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSheeshaPerShare = pool.accSheeshaPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 sheeshaReward = (multiplier *
                sheeshaPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accSheeshaPerShare =
                accSheeshaPerShare +
                ((sheeshaReward * 1e12) / lpSupply);
        }
        return ((user.amount * accSheeshaPerShare) / 1e12) - user.rewardDebt;
    }

    /**
     * @dev Return address of Sheesha token
     */
    function token() external view override returns (address) {
        PoolInfo storage pool = poolInfo[0];
        return address(pool.lpToken);
    }

    /**
     * @dev Return total token staked
     */
    function staked() external view override returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        return pool.lpToken.balanceOf(address(this));
    }

    /**
     * @dev Return amount deposited by user
     */
    function stakedOf(address member) external view override returns (uint256) {
        uint256 amountFromAutoCompound;
        UserInfo storage user = userInfo[0][member];
        if (autoCompound != address(0) && _msgSender() != autoCompound) {
            amountFromAutoCompound = ISheeshaAutocompound(autoCompound)
                .stakedOf(member);
        }
        return user.amount + amountFromAutoCompound;
    }

    /**
     * @dev Checks amounts of pools
     * @return Number of pools available
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Updates all available pools accumulated Sheesha per share and last reward block
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Updates chosen pool accumulated Sheesha per share and last reward block
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sheeshaReward = (multiplier *
            sheeshaPerBlock *
            pool.allocPoint) / totalAllocPoint;
        if (sheeshaReward > lpRewards) {
            sheeshaReward = lpRewards;
        }
        lpRewards = lpRewards - sheeshaReward;
        pool.accSheeshaPerShare =
            pool.accSheeshaPerShare +
            ((sheeshaReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev Returns multiplier according to last reward block and current block
     * @param _from Last reward block
     * @param _to Current block number
     * @return Multiplier according to _from and _to value
     */
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    /**
     * @dev Checks if user was participating in staking
     * @param _who Address of user.
     * @return If user participate in staking
     */
    function isUserExisting(address _who) public view returns (bool) {
        return isExisting[_who];
    }

    /**
     * @dev Checks if user was participating in chosen pool
     * @param _pid Pool's unique ID.
     * @param _user Address of user.
     * @return If user participate in pool
     */
    function isActive(uint256 _pid, address _user) public view returns (bool) {
        return userInfo[_pid][_user].status;
    }

    /**
     * @dev Internal function is equivalent to deposit(address of _depositFor would be msg.sender)
     * and depositFor(address of user for which deposit is created)
     * @param _depositFor Address of user for which deposit is created
     * @param _pid Pool's unique ID.
     * @param _amount The amount to deposit.
     */
    function _deposit(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) internal {
        if (!isUserExisting(_depositFor)) {
            userList[userCount] = _depositFor;
            userCount++;
            isExisting[_depositFor] = true;
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_depositFor];
        updatePool(_pid);
        if (!isActive(_pid, _depositFor)) {
            user.status = true;
        }
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accSheeshaPerShare) / 1e12) -
                user.rewardDebt;
            if (pending > 0) {
                _safeSheeshaTransfer(_depositFor, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
            user.amount = user.amount + _amount;
        }
        user.rewardDebt = (user.amount * pool.accSheeshaPerShare) / 1e12;
        emit Deposit(_depositFor, _pid, _amount);
    }

    /**
     * @dev Internal function is used for safe transfer of pending rewards
     * @notice If reward amount is greater than contract balance - sends contract balance
     * @param _to Address of rewards receiver.
     * @param _amount Amount of rewards.
     */
    function _safeSheeshaTransfer(address _to, uint256 _amount) internal {
        uint256 sheeshaBal = sheesha.balanceOf(address(this));
        IERC20Upgradeable(address(sheesha)).safeTransfer(
            _to,
            MathUpgradeable.min(_amount, sheeshaBal)
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaVotesLocker {
    function unlockedSHOf(address member) external view returns (uint256);
    function unlockedLPOf(address member) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaVault {
    /**
     * @dev Emitted when a user deposits tokens.
     * @param user Address of user for which deposit was made.
     * @param pid Pool's unique ID.
     * @param amount The amount of deposited tokens.
     */
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @dev Emitted when a user withdraw tokens from staking.
     * @param user Address of user for which deposit was made.
     * @param pid Pool's unique ID.
     * @param amount The amount of deposited tokens.
     */
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @dev Emitted when a user withdraw tokens from staking without caring about rewards.
     * @param user Address of user for which deposit was made.
     * @param pid Pool's unique ID.
     * @param amount The amount of deposited tokens.
     */
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    function token() external view returns (address);

    function staked() external view returns (uint256);

    function stakedOf(address member) external view returns (uint256);

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function depositFor(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function pendingSheesha(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaAutocompound {
    event Deposit(address indexed sender, uint256 amount, uint256 shares);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender, uint256 time);

    function emergencyWithdraw() external;

    function harvest() external;

    function inCaseTokensGetStuck(address _token) external;

    function setLocker(address _locker) external;

    function updateApprovals() external;

    function calculateTotalPendingSheeshaRewards()
        external
        view
        returns (uint256);

    function staked() external view returns (uint256);

    function stakedOf(address _member) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}