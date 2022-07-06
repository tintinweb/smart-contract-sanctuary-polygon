//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {
    ContextUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {
    IUniswapV2Pair
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import {
    ISheeshaDao,
    ISheeshaVaultInfo,
    ISheeshaVotes,
    ISheeshaVoting
} from "./utils/Interfaces.sol";
import {Bytes} from "./utils/Bytes.sol";

interface IERC20Meta {
    function decimals() external view returns (uint8);
}

contract SheeshaVotes is ISheeshaVotes, ContextUpgradeable {
    using Bytes for bytes;

    address public override dao;
    address public override SHVault;
    address public override LPVault;
    address public override SHToken;
    address public override LPToken;

    function(IUniswapV2Pair) internal view returns (uint256, uint256)
        private _getReserves;

    uint256 private _shDecimals;
    uint256 private _stDecimals;

    modifier onlyDao() {
        require(_msgSender() == dao, "SHV: only DAO call");
        _;
    }

    function initialize(address dao_, bytes calldata data_)
        external
        override
        initializer
    {
        __SheeshaVotes_init(dao_, data_);
    }

    /**
     * @dev Initialize vaults.
     */
    function __SheeshaVotes_init(address dao_, bytes calldata data_)
        internal
        onlyInitializing
    {
        __Context_init_unchained();
        __SheeshaVotes_init_unchained(dao_, data_);
    }

    /**
     * @dev Initialize vaults.
     */
    function __SheeshaVotes_init_unchained(address dao_, bytes calldata data_)
        internal
        onlyInitializing
    {
        dao = dao_;
        setVaults(data_);
    }

    function setVaults(bytes calldata data_) public override onlyDao {
        _setVaults(data_.sliceAddress(0), data_.sliceAddress(32));
    }

    function total() public view override returns (uint256) {
        (uint256 shPrice, uint256 lpPrice) = prices();
        return
            _calculateVotes(
                ISheeshaVaultInfo(SHVault).staked(),
                ISheeshaVaultInfo(LPVault).staked(),
                shPrice,
                lpPrice
            );
    }

    function locked() public view override returns (uint256 votes) {
        address voting = ISheeshaDao(dao).activeVoting();
        votes = voting == address(0) ? 0 : ISheeshaVoting(voting).votes();
    }

    function unlocked() public view override returns (uint256) {
        return total() - locked();
    }

    function totalOf(address member) public view override returns (uint256) {
        (uint256 shPrice, uint256 lpPrice) = prices();
        return
            _calculateVotes(
                ISheeshaVaultInfo(SHVault).stakedOf(member),
                ISheeshaVaultInfo(LPVault).stakedOf(member),
                shPrice,
                lpPrice
            );
    }

    function lockedOf(address member)
        public
        view
        override
        returns (uint256 votes)
    {
        address voting = ISheeshaDao(dao).activeVoting();
        votes = voting == address(0)
            ? 0
            : ISheeshaVoting(voting).votesOf(member);
    }

    function unlockedOf(address member) public view override returns (uint256) {
        uint256 total_ = totalOf(member);
        uint256 locked_ = lockedOf(member);
        return total_ > locked_ ? total_ - locked_ : 0;
    }

    function unlockedSHOf(address member)
        external
        view
        override
        returns (uint256 amount)
    {
        uint256 unlocked_ = unlockedOf(member);
        if (unlocked_ > 0) {
            (uint256 shPrice, ) = prices();
            // SHToken decimals = 18
            amount = ((10**_shDecimals) * unlocked_ * 1e16) / shPrice;
        }
    }

    function unlockedLPOf(address member)
        external
        view
        override
        returns (uint256 amount)
    {
        uint256 unlocked_ = unlockedOf(member);
        if (unlocked_ > 0) {
            (, uint256 lpPrice) = prices();
            // Uniswap pair decimals = 12
            amount = ((10**_pairDecimals()) * unlocked_ * 1e16) / (2 * lpPrice);
        }
    }

    /**
     * @notice Returns Sheesha token price and a LP(SHEESHA-USDT) token price
     */
    function prices()
        public
        view
        override
        returns (uint256 shPrice, uint256 lpPrice)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(LPToken);
        (uint256 reserveSH, uint256 reservePaired) = _getReserves(pair);
        if (reservePaired > 0) {
            // SHToken decimals = 18, USDT decimals = 6
            // Uniswap pair decimals = 12, (1e18 * sqrt(10**18 * 10**6))
            shPrice =
                (1e18 * reservePaired * (10**_shDecimals)) /
                (reserveSH * (10**_stDecimals));
            uint256 totalSupply = pair.totalSupply();
            if (totalSupply > 0) {
                // USDT decimals = 6 (100 * 10**6)
                lpPrice =
                    (2 * 1e18 * reservePaired * (10**_pairDecimals())) /
                    (totalSupply * (10**_stDecimals));
            }
        }
    }

    function _calculateVotes(
        uint256 shAmount,
        uint256 lpAmount,
        uint256 shPrice,
        uint256 lpPrice
    ) internal view returns (uint256) {
        // SHToken decimals = 18, USDT decimnals = 6
        // Uniswap pair decimals = 12 (sqrt(10**18 * 10**6)),
        return
            ((shAmount * shPrice) /
                (10**_shDecimals) +
                (2 * (lpAmount * lpPrice)) /
                (10**_pairDecimals())) / 1e16;
    }

    function _setVaults(address SHVault_, address LPVault_) internal {
        SHVault = SHVault_;
        LPVault = LPVault_;
        SHToken = ISheeshaVaultInfo(SHVault_).token();
        LPToken = ISheeshaVaultInfo(LPVault_).token();
        IUniswapV2Pair pair = IUniswapV2Pair(LPToken);
        _getReserves = SHToken == pair.token0() ? _getReserves1 : _getReserves2;
        (_shDecimals, _stDecimals) = SHToken == pair.token0()
            ? _tokenDecimals1()
            : _tokenDecimals2();
        emit SetVaults(SHVault_, LPVault_);
    }

    function _getReserves1(IUniswapV2Pair pair)
        internal
        view
        returns (uint256 reserveSH, uint256 reservePaired)
    {
        (reserveSH, reservePaired, ) = pair.getReserves();
    }

    function _getReserves2(IUniswapV2Pair pair)
        internal
        view
        returns (uint256 reserveSH, uint256 reservePaired)
    {
        (reservePaired, reserveSH) = _getReserves1(pair);
    }

    function _tokenDecimals1()
        internal
        view
        returns (uint256 shDecimals, uint256 stDecimals)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(LPToken);
        return (
            IERC20Meta(pair.token0()).decimals(),
            IERC20Meta(pair.token1()).decimals()
        );
    }

    function _tokenDecimals2()
        internal
        view
        returns (uint256 shDecimals, uint256 stDecimals)
    {
        (stDecimals, shDecimals) = _tokenDecimals1();
    }

    function _pairDecimals() internal view returns (uint256) {
        return (_shDecimals + _stDecimals) / 2;
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaDao {
    function votes() external view returns (address);

    function activeVoting() external view returns (address);

    function latestVoting() external view returns (address);

    function delegates(address who, address whom) external view returns (bool);

    function setVotes(address) external;

    function setVaults(bytes calldata data) external;

    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external;

    event SetVotes(address who, address votes);
    event Executed(address who, address target, uint256 value, bytes data);
}

interface ISheeshaDaoInitializable {
    function initialize(address dao, bytes calldata data) external;
}

interface ISheeshaRetroLPVault {
    function poolInfo(uint256 id)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 id, address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function userCount() external view returns (uint256);

    function userList(uint256) external view returns (address);
}

interface ISheeshaRetroSHVault {
    function poolInfo(uint256 id)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 id, address user)
        external
        view
        returns (uint256, uint256);

    function userCount() external view returns (uint256);

    function userList(uint256) external view returns (address);
}

interface ISheeshaVaultInfo {
    function token() external view returns (address);

    function staked() external view returns (uint256);

    function stakedOf(address member) external view returns (uint256);
}

interface ISheeshaVault is ISheeshaVaultInfo {
    function pendingSheesha(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function depositFor(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

interface ISheeshaVesting {
    /**
     * @dev Calculates available amount of tokens to withdraw for vesting types
     * which participate in staking for FE.
     * @return _leftover Recipient amount which wasn't withdrawn.
     * @return _amountAvailable Recipient available amount to withdraw.
     */
    function calculateAvailableAmountForStaking(address _recipient)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Emitted when withdraw of tokens was made on staking contract.
     * @param _recipient Address of user for which withdraw from staking.
     * @param _amount The amount of tokens which was withdrawn.
     */
    function withdrawFromStaking(address _recipient, uint256 _amount) external;
}

interface ISheeshaVotesLocker {
    function total() external view returns (uint256);

    function locked() external view returns (uint256);

    function unlocked() external view returns (uint256);

    function totalOf(address member) external view returns (uint256);

    function lockedOf(address member) external view returns (uint256);

    function unlockedOf(address member) external view returns (uint256);

    function unlockedSHOf(address member) external view returns (uint256);

    function unlockedLPOf(address member) external view returns (uint256);
}

interface ISheeshaVotes is ISheeshaDaoInitializable, ISheeshaVotesLocker {
    function dao() external view returns (address);

    function SHVault() external view returns (address);

    function LPVault() external view returns (address);

    function SHToken() external view returns (address);

    function LPToken() external view returns (address);

    function prices() external view returns (uint256 shPrice, uint256 lpPrice);

    function setVaults(bytes calldata data_) external;

    event SetVaults(address, address);
}

interface ISheeshaVoting is ISheeshaDaoInitializable {
    enum State {
        STATE_INACTIVE,
        STATE_ACTIVE,
        STATE_COMPLETED_NO_QUORUM,
        STATE_COMPLETED_NO_WINNER,
        STATE_COMPLETED,
        STATE_COMPLETED_EXECUTED
    }

    function dao() external view returns (address);

    function begin() external view returns (uint32);

    function end() external view returns (uint32);

    function quorum() external view returns (uint8);

    function threshold() external view returns (uint8);

    function votesOf(address member) external view returns (uint256);

    function votesOfFor(address member, uint256 candidate)
        external
        view
        returns (uint256);

    function votesFor(uint256) external view returns (uint256);

    function votesForNum() external view returns (uint256);

    function votes() external view returns (uint256);

    function hasQuorum() external view returns (bool);

    function state() external view returns (State);

    function winners() external view returns (uint256);

    function executed() external view returns (bool);

    function vote(bytes calldata data) external;

    function verify(address[] calldata members)
        external
        view
        returns (address[] memory);

    function cancel(address[] calldata members) external;

    function execute() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Bytes {
    function sliceUint(bytes memory bs, uint256 pos)
        internal
        pure
        returns (uint256)
    {
        require(bs.length >= pos + 32, "slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, pos)))
        }
        return x;
    }

    function sliceAddress(bytes memory bs, uint256 pos)
        internal
        pure
        returns (address)
    {
        return address(uint160(sliceUint(bs, pos)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
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