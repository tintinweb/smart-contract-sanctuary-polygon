//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "./interfaces/ISheeshaDao.sol";
import "./interfaces/ISheeshaERC20.sol";
import "./interfaces/ISheeshaVaultInfo.sol";
import "./interfaces/ISheeshaVotes.sol";
import "./interfaces/ISheeshaVoting.sol";
import "./utils/Bytes.sol";

contract SheeshaVotes is 
    ISheeshaVotes,
    ContextUpgradeable {
    using Bytes for bytes;

    address public override dao;
    address public override SHVault;
    address public override LPVault;
    address public override SHToken;
    address public override LPToken;

    function(IUniswapV2Pair) internal view returns (uint256, uint256) private _getReserves;

    uint256 private _shDecimals;
    uint256 private _stDecimals;

    modifier onlyDao() {
        require(_msgSender() == dao, "SHV: only DAO call");
        _;
    }

    function initialize(address dao_, bytes calldata data_) external override initializer {
        __SheeshaVotes_init(dao_, data_);
    }

    /**
     * @dev Initialize vaults.
     */
    function __SheeshaVotes_init(address dao_, bytes calldata data_) internal onlyInitializing {
        __Context_init_unchained();
        __SheeshaVotes_init_unchained(dao_, data_);
    }

    /**
     * @dev Initialize vaults.
     */
    function __SheeshaVotes_init_unchained(address dao_, bytes calldata data_) internal onlyInitializing {
        dao = dao_;
        _setVaults(data_.sliceAddress(0), data_.sliceAddress(32));
    }

    function setVaults(address SHVault_, address LPVault_) public override onlyDao {
        _setVaults(SHVault_, LPVault_);
        emit SetVaults(SHVault_, LPVault_);
    }

    function total() public view override returns (uint256) {
        (uint256 shPrice, uint256 lpPrice) = prices();
        return _calculateVotes(ISheeshaVaultInfo(SHVault).staked(), ISheeshaVaultInfo(LPVault).staked(), shPrice, lpPrice);
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
        return _calculateVotes(ISheeshaVaultInfo(SHVault).stakedOf(member), ISheeshaVaultInfo(LPVault).stakedOf(member), shPrice, lpPrice);
    }

    function lockedOf(address member) public view override returns (uint256 votes) {
        address voting = ISheeshaDao(dao).activeVoting();
        votes = voting == address(0) ? 0 : ISheeshaVoting(voting).votesOf(member);
    }

    function unlockedOf(address member) public view override returns (uint256) {
        uint256 total_ = totalOf(member); 
        uint256 locked_ = lockedOf(member); 
        return total_ > locked_ ? total_ - locked_ : 0;
    }

    function unlockedSHOf(address member) external view override returns (uint256 amount) {
        uint256 unlocked_ = unlockedOf(member);
        if (unlocked_ > 0) {
            (uint256 shPrice,) = prices();
            // SHToken decimals = 18
            amount = (10 ** _shDecimals) * unlocked_ / shPrice;
        }
    }

    function unlockedLPOf(address member) external view override returns (uint256 amount) {
        uint256 unlocked_ = unlockedOf(member);
        if (unlocked_ > 0) {
            (, uint256 lpPrice) = prices();
            // Uniswap pair decimals = 12
            amount = (10 ** _pairDecimals()) * unlocked_ / lpPrice;
        }
    }

    /**
    * @notice Returns Sheesha token price and a LP(SHEESHA-USDT) token price
    */
    function prices() public view override returns (uint256 shPrice, uint256 lpPrice) {
        IUniswapV2Pair pair = IUniswapV2Pair(LPToken);
        (uint256 reserveSH, uint256 reservePaired) = _getReserves(pair);
        if (reservePaired > 0) {
            // SHToken decimals = 18, USDT decimals = 6
            // Uniswap pair decimals = 12 (100 * sqrt(10**18 * 10**6)), 
            shPrice = reservePaired * 100 * (10 ** _pairDecimals()) / reserveSH;
            uint256 totalSupply = pair.totalSupply();
            if (totalSupply > 0) {
                // USDT decimals = 6 (100 * 10**6)
                lpPrice = 200 * (10 ** _stDecimals) * reservePaired / totalSupply;
            }
        }
    }

    function _calculateVotes(uint256 shAmount, uint256 lpAmount, uint256 shPrice, uint256 lpPrice) internal view returns (uint256) {
        // SHToken decimals = 18, USDT decimnals = 6
        // Uniswap pair decimals = 12 (sqrt(10**18 * 10**6)), 
        return (shAmount * shPrice) / (10 ** _shDecimals) + 2 * (lpAmount * lpPrice) / (10 ** _pairDecimals());
    }

    function _setVaults(address SHVault_, address LPVault_) internal {
        SHVault = SHVault_;
        LPVault = LPVault_;
        SHToken = ISheeshaVaultInfo(SHVault_).token();
        LPToken = ISheeshaVaultInfo(LPVault_).token();
        IUniswapV2Pair pair = IUniswapV2Pair(LPToken);
        _getReserves = SHToken == pair.token0() ? _getReserves1 : _getReserves2;
        (_shDecimals, _stDecimals) = SHToken == pair.token0() ? _tokenDecimals1() : _tokenDecimals2();
    }

    function _getReserves1(IUniswapV2Pair pair) internal view returns (uint256 reserveSH, uint256 reservePaired) {
        (reserveSH, reservePaired,) = pair.getReserves();
    }

    function _getReserves2(IUniswapV2Pair pair) internal view returns (uint256 reserveSH, uint256 reservePaired) {
        (reservePaired, reserveSH) = _getReserves1(pair);
    }

    function _tokenDecimals1() internal view returns (uint256 shDecimals, uint256 stDecimals) {
        IUniswapV2Pair pair = IUniswapV2Pair(LPToken);
        return (ISheeshaERC20(pair.token0()).decimals(), ISheeshaERC20(pair.token1()).decimals());
    }

    function _tokenDecimals2() internal view returns (uint256 shDecimals, uint256 stDecimals) {
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
    function execute(address target, uint256 value, bytes calldata data) external;

    event SetVotes(address who, address votes);
    event Executed(address who, address target, uint256 value, bytes data);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISheeshaERC20 is IERC20 {
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaVaultInfo {
    function token() external view returns (address);
    function staked() external view returns (uint256);
    function stakedOf(address member) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ISheeshaDaoInitializable.sol";
import "./ISheeshaVotesLocker.sol";

interface ISheeshaVotes is
    ISheeshaDaoInitializable,
    ISheeshaVotesLocker {
    function dao() external view returns (address);
    function SHVault() external view returns (address);
    function LPVault() external view returns (address);
    function SHToken() external view returns (address);
    function LPToken() external view returns (address);
    function prices() external view returns (uint256 shPrice, uint256 lpPrice);

    function setVaults(address SHVault_, address LPVault_) external;

    event SetVaults(address, address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ISheeshaDaoInitializable.sol";

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
    function votesOfFor(address member, uint256 candidate) external view returns (uint256);
    function votesFor(uint256) external view returns (uint256);
    function votesForNum() external view returns (uint256);
    function votes() external view returns (uint256);
    function hasQuorum() external view returns (bool);
    function state() external view returns (State);
    function winners() external view returns(uint256);
    function executed() external view returns (bool);

    function vote(bytes calldata data) external;
    function verify(address[] calldata members) external view returns (address[] memory);
    function cancel(address[] calldata members) external;
    function execute() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Bytes {
    function sliceUint(bytes memory bs, uint256 pos) internal pure returns (uint256) {
        require(bs.length >= pos + 32, "slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, pos)))
        }
        return x;
    }
    function sliceAddress(bytes memory bs, uint256 pos) internal pure returns (address) {
        return address(uint160(sliceUint(bs, pos)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaDaoInitializable {
    function initialize(address dao, bytes calldata data) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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