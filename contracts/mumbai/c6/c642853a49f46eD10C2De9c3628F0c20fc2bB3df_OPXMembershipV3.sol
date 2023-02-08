// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OPXMembershipV3 is Initializable {
    address public owner;
    address public paymentTo;
    uint256 public totalMembers;
    uint256 public totalPayment;

    uint256 public divider;
    uint32 public oneMonth;

    mapping(address => bool) public isGovernor;

    mapping(uint256 => address) public userids;

    mapping(address => User) public users;
    mapping(address => address[]) public user_downlines;
    mapping(address => uint256) public total_earnings;

    ERC20 public payment0;
    ERC20 public payment1;
    ERC20 public payment2;

    uint256 public tokensPer1USD;
    UniswapV2Pair public pair;
    uint32 public directBonus;
    uint32 public cycleBonus;
    uint32 public secondLevel;
    uint32 public upperLevel;

    struct User {
        address referrer;
        uint32 join_date;
        uint32 expiration;
        uint32 userid;
    }

    function governanceToggle(address addr, bool perms) external onlyOwner {
        isGovernor[addr] = perms;
    }

    function manualMembership(
        address userAddress,
        address referrer,
        uint32 expiration,
        uint256 tokens,
        address[] memory downlines
    ) external onlyGovernors {
        User storage user = users[userAddress];
        require(user.join_date == 0, "User is already added.");
        user.join_date = uint32(block.timestamp) - oneMonth;

        user.expiration = expiration;
        user.userid = uint32(++totalMembers);
        userids[user.userid] = userAddress;

        if (referrer != address(0)) {
            user.referrer = referrer;
            user_downlines[referrer].push(userAddress);
        } else {
            user.referrer = owner;
        }

        tokenTransfer(userAddress, tokens);

        uint256 length = downlines.length;
        for (uint256 i = 0; i < length; ++i) {
            users[downlines[i]].referrer = userAddress;
            user_downlines[userAddress].push(downlines[i]);
        }
    }

    function transferMembership(
        address oldAddress,
        address newAddress
    ) external onlyGovernors {
        User storage oldUser = users[oldAddress];
        User storage newUser = users[newAddress];
        require(oldUser.join_date != 0, "Old Address isn't a member.");
        require(newUser.join_date == 0, "New User is already a member.");

        // Assigns properties of old user to the new user
        newUser.join_date = oldUser.join_date;
        newUser.referrer = oldUser.referrer;
        newUser.expiration = oldUser.expiration;
        newUser.userid = oldUser.userid;
        userids[oldUser.userid] = newAddress;

        // Updates downline's referrer from old Address to newAddress
        uint256 length = user_downlines[oldAddress].length;
        for (uint256 i = 0; i < length; ++i) {
            users[user_downlines[oldAddress][i]].referrer = newAddress;
            user_downlines[newAddress].push(user_downlines[oldAddress][i]);
        }

        // deletes old user's properties
        delete users[oldAddress];
        delete user_downlines[oldAddress];
    }

    function tokenTransfer(address addr, uint256 amount) public onlyGovernors {
        payment0.transfer(addr, amount);
    }

    function changeTokenPerUSD(uint256 val) public onlyGovernors {
        tokensPer1USD = val;
    }

    function myBalanceIn(
        uint256 index
    ) external view returns (uint256 balance, address addr) {
        addr = msg.sender;
        if (index == 0) {
            balance = payment0.balanceOf(msg.sender);
        } else if (index == 1) {
            balance = payment1.balanceOf(msg.sender);
        } else if (index == 2) {
            balance = payment2.balanceOf(msg.sender);
        }
    }

    function purchasePlan(
        uint256 plan,
        uint256 method,
        address referrer
    ) external payable {
        require(plan < 3 && method < 4, "Invalid Input");

        User storage user = users[msg.sender];

        uint256 priceAmount;
        uint32 dayAmount;

        if (plan == 0) {
            dayAmount = 3 * oneMonth;
            priceAmount = 50 ether;
        } else if (plan == 1) {
            dayAmount = 7 * oneMonth;
            priceAmount = 100 ether;
        } else if (plan == 2) {
            dayAmount = 12 * oneMonth;
            priceAmount = 150 ether;
        } else if (plan == 3) {
            require(
                user.join_date + 3 * oneMonth == user.expiration,
                "Only available for users who availed 3 months"
            );
            require(
                user.join_date + 3 * oneMonth > block.timestamp,
                "Only available within 3 months."
            );
            dayAmount = 9 * oneMonth;
            priceAmount = 100 ether;
        }

        totalPayment += priceAmount;

        if (method == 0) {
            payment0.governanceTransfer(
                msg.sender,
                address(this),
                tokensPer1USD * priceAmount
            );
        } else if (method == 1) {
            payment1.transferFrom(msg.sender, paymentTo, priceAmount);
        } else if (method == 2) {
            payment2.transferFrom(msg.sender, paymentTo, priceAmount);
        } else if (method == 3) {
            uint256 usdAmount = getMaticTOUSDRate(msg.value);
            if (usdAmount < priceAmount) {
                require(
                    100 - ((usdAmount * 100) / priceAmount) <= 3,
                    "Slippage exceeded"
                );
            }
            payable(paymentTo).transfer(msg.value);
        }

        User storage referrerUser;

        if (user.expiration > block.timestamp) {
            user.expiration += dayAmount;
        } else {
            user.expiration = uint32(block.timestamp) + dayAmount;
        }

        if (user.join_date == 0) {
            if (users[referrer].join_date == 0) referrer = owner;
            user.referrer = referrer;
            user.join_date = uint32(block.timestamp);

            user.userid = uint32(++totalMembers);
            userids[user.userid] = msg.sender;

            user_downlines[referrer].push(msg.sender);

            referrerUser = users[user.referrer];
            if (
                referrerUser.join_date + oneMonth > block.timestamp &&
                user_downlines[referrer].length == 5
            ) {
                user.expiration += 3 * oneMonth;
            }
        } else {
            referrer = user.referrer;
            referrerUser = users[user.referrer];
        }

        uint256 totalTokens = tokensPer1USD * priceAmount;

        processPayout(referrer, (totalTokens * directBonus) / divider);

        address upline = referrerUser.referrer;
        if (upline != address(0) && upline != referrer) {
            if (user_downlines[referrer].length % 5 == 0) {
                processPayout(upline, (totalTokens * cycleBonus) / divider);
            } else {
                processPayout(upline, (totalTokens * secondLevel) / divider);
            }
            for (uint256 i = 0; i < 8; ++i) {
                if (upline == users[upline].referrer) break;
                upline = users[upline].referrer;
                if (upline == address(0)) break;
                processPayout(upline, (totalTokens * upperLevel) / divider);
            }
        }
    }

    function getUserDownlinesLength(
        address addr
    ) external view returns (uint256) {
        return user_downlines[addr].length;
    }

    function getUserDownlines(
        uint256 offset,
        address addr
    ) external view returns (address[] memory, uint32[] memory) {
        uint256 length = user_downlines[addr].length;
        address[] memory downlines = new address[](10);
        uint32[] memory expirations = new uint32[](10);
        for (uint256 i = 0; i < 10; ++i) {
            if (i + offset <= length) break;
            downlines[i] = user_downlines[addr][i + offset];
            expirations[i] = users[downlines[i]].expiration;
        }
        return (downlines, expirations);
    }

    function getMaticTOUSDRate(uint256 amountIn) public view returns (uint256) {
        require(amountIn > 0, "Insufficient input amount");
        (uint112 reserveIn, uint112 reserveOut, ) = pair.getReserves();
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function getRequiredMaticForUSD(
        uint amountOut
    ) public view returns (uint amountIn) {
        require(amountOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 reserveIn, uint112 reserveOut, ) = pair.getReserves();
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    function processPayout(address addr, uint256 amount) internal {
        User memory user = users[addr];
        if (user.expiration > block.timestamp) {
            payment0.transfer(addr, amount);
            total_earnings[addr] += amount;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyGovernors() {
        require(msg.sender == owner || isGovernor[msg.sender]);
        _;
    }
}

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function governanceTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface UniswapV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
}