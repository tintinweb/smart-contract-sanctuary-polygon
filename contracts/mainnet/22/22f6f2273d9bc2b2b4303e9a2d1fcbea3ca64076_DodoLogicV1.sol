/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT


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
        
        
        

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https:
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https:
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https:
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
     * use https:
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
        
        if (returndata.length > 0) {
            
            
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity ^0.8.2;

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
 * 
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * https:
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity >=0.4.22 <0.9.0;

struct Prop {
  uint256 id; 
  string name; 
  uint256 price; 
  uint256 income; 
  uint256 required; 
}

library DodoConfig {

  

  
  function getKingAddress() internal pure returns (address) {
    return address(0x0fc81F797E98e1A97243eD35CBfb59Db021338c2);
  }

  
  function getFee() internal pure returns (uint256) {
    return  0.01 ether; 
  }

  
  function getBaseDecimals() internal pure returns (uint256) {
    return 4; 
  }

  
  function getBaseRate() internal pure returns (uint256) {
    return 10**4;
  }

  
  function getIncomeBase() internal pure returns (uint256) {
    return 1 ether; 
  }

  
  function getIncomeLevelRate() internal pure returns (uint256) {
    return 1000; 
  }

  
  function getBonusLevelRate() internal pure returns (uint256) {
    return 1000; 
  }

  
  function getIncomeUpgradeConfig() internal pure returns (uint256[] memory) {
    uint maxIncomeLevel = 30;
    uint256[] memory incomeUpgradeConfig = new uint256[](maxIncomeLevel);
    incomeUpgradeConfig[0] = 50 ether;
    incomeUpgradeConfig[1] = 90 ether;
    incomeUpgradeConfig[2] = 225 ether;
    incomeUpgradeConfig[3] = 545 ether;
    incomeUpgradeConfig[4] = 1170 ether;
    incomeUpgradeConfig[5] = 2250 ether;
    incomeUpgradeConfig[6] = 3965 ether;
    incomeUpgradeConfig[7] = 6525 ether;
    incomeUpgradeConfig[8] = 10170 ether;
    incomeUpgradeConfig[9] = 15170 ether;
    incomeUpgradeConfig[10] = 21825 ether;
    incomeUpgradeConfig[11] = 30465 ether;
    incomeUpgradeConfig[12] = 41450 ether;
    incomeUpgradeConfig[13] = 55170 ether;
    incomeUpgradeConfig[14] = 72045 ether;
    incomeUpgradeConfig[15] = 92525 ether;
    incomeUpgradeConfig[16] = 117090 ether;
    incomeUpgradeConfig[17] = 146250 ether;
    incomeUpgradeConfig[18] = 180545 ether;
    incomeUpgradeConfig[19] = 220545 ether;
    incomeUpgradeConfig[20] = 266850 ether;
    incomeUpgradeConfig[21] = 320090 ether;
    incomeUpgradeConfig[22] = 380925 ether;
    incomeUpgradeConfig[23] = 450045 ether;
    incomeUpgradeConfig[24] = 528170 ether;
    incomeUpgradeConfig[25] = 616050 ether;
    incomeUpgradeConfig[26] = 714465 ether;
    incomeUpgradeConfig[27] = 824225 ether;
    incomeUpgradeConfig[28] = 946170 ether;
    incomeUpgradeConfig[29] = 1081170 ether;
    incomeUpgradeConfig[30] = 1230125 ether;
    incomeUpgradeConfig[31] = 1393965 ether;
    incomeUpgradeConfig[32] = 1573650 ether;
    incomeUpgradeConfig[33] = 1770170 ether;
    incomeUpgradeConfig[34] = 1984545 ether;
    incomeUpgradeConfig[35] = 2217825 ether;
    incomeUpgradeConfig[36] = 2471090 ether;
    incomeUpgradeConfig[37] = 2745450 ether;
    incomeUpgradeConfig[38] = 3042045 ether;
    incomeUpgradeConfig[39] = 3362045 ether;
    return incomeUpgradeConfig;
  }

  
  function getBonusUpgradeConfig() internal pure returns (uint256[] memory) {
    uint maxBonusLevel = 30;
    uint256[] memory bonusUpgradeConfig = new uint256[](maxBonusLevel);
    bonusUpgradeConfig[0] = 50 ether;
    bonusUpgradeConfig[1] = 74 ether;
    bonusUpgradeConfig[2] = 155 ether;
    bonusUpgradeConfig[3] = 347 ether;
    bonusUpgradeConfig[4] = 722 ether;
    bonusUpgradeConfig[5] = 1370 ether;
    bonusUpgradeConfig[6] = 2399 ether;
    bonusUpgradeConfig[7] = 3935 ether;
    bonusUpgradeConfig[8] = 6122 ether;
    bonusUpgradeConfig[9] = 9250 ether;
    bonusUpgradeConfig[10] = 13115 ether;
    bonusUpgradeConfig[11] = 18299 ether;
    bonusUpgradeConfig[12] = 24890 ether;
    bonusUpgradeConfig[13] = 33122 ether;
    bonusUpgradeConfig[14] = 43247 ether;
    bonusUpgradeConfig[15] = 55535 ether;
    bonusUpgradeConfig[16] = 70274 ether;
    bonusUpgradeConfig[17] = 87770 ether;
    bonusUpgradeConfig[18] = 108347 ether;
    bonusUpgradeConfig[19] = 132347 ether;
    bonusUpgradeConfig[20] = 160130 ether;
    bonusUpgradeConfig[21] = 192074 ether;
    bonusUpgradeConfig[22] = 228575 ether;
    bonusUpgradeConfig[23] = 270047 ether;
    bonusUpgradeConfig[24] = 316922 ether;
    bonusUpgradeConfig[25] = 369650 ether;
    bonusUpgradeConfig[26] = 428699 ether;
    bonusUpgradeConfig[27] = 494555 ether;
    bonusUpgradeConfig[28] = 567722 ether;
    bonusUpgradeConfig[29] = 648722 ether;
    bonusUpgradeConfig[30] = 738095 ether;
    bonusUpgradeConfig[31] = 836399 ether;
    bonusUpgradeConfig[32] = 944210 ether;
    bonusUpgradeConfig[33] = 1062122 ether;
    bonusUpgradeConfig[34] = 1190747 ether;
    bonusUpgradeConfig[35] = 1330715 ether;
    bonusUpgradeConfig[36] = 1482674 ether;
    bonusUpgradeConfig[37] = 1647290 ether;
    bonusUpgradeConfig[38] = 1825247 ether;
    bonusUpgradeConfig[39] = 2017247 ether;
    return bonusUpgradeConfig;
  }

  
  function getProps() internal pure returns (Prop[] memory) {
    Prop[] memory props = new Prop[](19);
    props[0] = Prop(1, "Drinking Water", 5 ether, 1 ether, 5);
    props[1] = Prop(2, "Bread", 86 ether, 2 ether, 8);
    props[2] = Prop(3, "Apple", 278 ether, 3 ether, 27);
    props[3] = Prop(4, "Bobe", 653 ether, 3 ether, 64);
    props[4] = Prop(5, "Axe", 1301 ether, 4 ether, 125);
    props[5] = Prop(6, "Bicycle", 2330 ether, 5 ether, 216);
    props[6] = Prop(7, "Smartphone", 3866 ether, 7 ether, 343);
    props[7] = Prop(8, "Laptop", 6053 ether, 10 ether, 512);
    props[8] = Prop(9, "Motorcycle", 9053 ether, 15 ether, 729);
    props[9] = Prop(10, "Luxury Watch", 13046 ether, 18 ether, 1000);
    props[10] = Prop(11, "Car", 18230 ether, 25 ether, 1331);
    props[11] = Prop(12, "Apartment", 24821 ether, 30 ether, 1728);
    props[12] = Prop(13, "Yacht", 33053 ether, 40 ether, 2197);
    props[13] = Prop(14, "House", 43178 ether, 50 ether, 2744);
    props[14] = Prop(15, "Aircraft", 55466 ether, 65 ether, 3375);
    props[15] = Prop(16, "Mansion", 70205 ether, 80 ether, 4096);
    props[16] = Prop(17, "Rocket", 87701 ether, 95 ether, 4913);
    props[17] = Prop(18, "Space Shuttle", 108278 ether, 100 ether, 5832);
    props[18] = Prop(19, "Satellite", 132278 ether, 150 ether, 6859);
    return props;
  }

  
  function getBetMaxAmount() internal pure returns (uint256) {
    return 10000 ether;
  }

  

  
  function getPropExtraDataKey() internal pure returns (string memory) {
    return "prop";
  }

  
  function getLastBetResultKey() internal pure returns (string memory) {
    return "lastBetResult";
  }

  
  function getLastBetAmountKey() internal pure returns (string memory) {
    return "lastBetAmount";
  }

  
  function getInviterKey() internal pure returns (string memory) {
    return "inviter";
  }

  
  function getInviteTimesKey() internal pure returns (string memory) {
    return "inviteTimes";
  }

  
  function getInviteRewardKey() internal pure returns (string memory) {
    return "inviteReward";
  }

}

pragma solidity ^0.8.0;

interface IDodoCoin is IERC20, IERC20Metadata {
  function deductTokens(address from, address to, uint256 amount) external;
}

pragma solidity >=0.4.22 <0.9.0;

struct PlayerData {
    uint256 dataVersion; 
    uint256 gameTimes; 
    uint256 casinoTimes; 
    uint256 incomeLevel; 
    uint256 bonusLevel; 
    uint256 bonus; 
}

struct PlayerStorage {
    PlayerData data;
    mapping (string => uint256) extraData;
}

interface DodoStorageInterface {

    function getPlayerExtraData(address player, string memory key) external view returns (uint256);

    function setPlayerExtraData(address player, string memory key, uint256 value) external;

    function getPlayerData(address player) external view returns (PlayerData memory);

    function updatePlayerData(
        address player,
        uint256 dataVersion,
        int256 gameTimesDelta,
        int256 casinoTimesDelta,
        int256 incomeLevelDelta,
        int256 bonusLevelDelta,
        int256 bonusDelta
    ) external;

    function transferCoin(address to, uint256 amount) external;

}

pragma solidity >=0.4.22 <0.9.0;

contract DodoLogicV1 is Initializable {

  
  address private dataContract; 
  address private tokenContract; 
  address private owner; 
  uint private nonce; 

  
  event makeMoneyEvent(address indexed player, uint256 times, uint256 reward); 
  event buyPropEvent(address indexed player, uint256 propId); 
  event upgradeIncomEvent(address indexed player, uint256 level); 
  event upgradeBonusEvent(address indexed player, uint256 level); 
  event betEvent(address indexed player, uint256 amount, uint256 result, uint256 odds); 
  event inviteEvent(address indexed player, address indexed inviter, uint256 reward); 

  function initialize(address _dataContract, address _tokenContract) initializer public {
    
    dataContract = _dataContract;
    
    tokenContract = _tokenContract;
  }

  
  function getTokenContract() public view returns (address) {
    return tokenContract;
  }

  
  function name() public view returns (string memory) {
    return IDodoCoin(tokenContract).name();
  }

  function symbol() public view returns (string memory) {
    return IDodoCoin(tokenContract).symbol();
  }

  function decimals() public view returns (uint8) {
    return IDodoCoin(tokenContract).decimals();
  }

  function balanceOf(address account) public view returns (uint256) {
    return IDodoCoin(tokenContract).balanceOf(account);
  }

  function totalSupply() public view returns (uint256) {
    return IDodoCoin(tokenContract).totalSupply();
  }

  

  
  function getFee() public pure returns (uint256) {
    return DodoConfig.getFee();
  }

  
  function getBaseDecimals() public pure returns (uint256) {
    return DodoConfig.getBaseDecimals();
  }

  
  function getBetMaxAmount() public pure returns (uint256) {
    return DodoConfig.getBetMaxAmount();
  }

  

  
  
  
  

  
  function getIncome(address player) public view returns (uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    uint propsIndex = getPropsIndex(player);
    uint256 baseRate = DodoConfig.getBaseRate();
    uint256 incomeLevelRate = DodoConfig.getIncomeLevelRate();
    uint256 income = DodoConfig.getIncomeBase();
    
    Prop[] memory props = DodoConfig.getProps();
    for (uint i = 0; i < propsIndex; i++) {
      income += props[i].income;
    }
    return income + income * playerData.incomeLevel * incomeLevelRate / baseRate;
  }

  
  function getIncomeInfo(address player) public view returns (uint256, uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    return (DodoConfig.getIncomeBase(), playerData.incomeLevel * DodoConfig.getIncomeLevelRate());
  }

  
  function getBonus(address player) public view returns (uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    return playerData.bonusLevel * DodoConfig.getBonusLevelRate(); 
  }

  
  function getBonusInfo(address player) public view returns (uint256, uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    return (playerData.bonus, getBonus(player));
  }

  
  function getPropsIndex(address player) private view returns (uint) {
    string memory propExtraDataKey = DodoConfig.getPropExtraDataKey();
    return DodoStorageInterface(dataContract).getPlayerExtraData(player, propExtraDataKey);
  }

  
  function getPropsCanBuy(address player) public view returns (Prop memory) {
    uint propsIndex = getPropsIndex(player);
    Prop[] memory props = DodoConfig.getProps();
    if (propsIndex >= props.length) {
      return Prop(0, "", 0, 0, 0); 
    }
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    Prop memory nextProp = props[propsIndex];
    if (playerData.gameTimes < nextProp.required) {
      return Prop(0, "", 0, 0, 0); 
    }
    return nextProp;
  }

  
  function getPropsList(address player) public view returns (Prop[] memory) {
    uint propsIndex = getPropsIndex(player);
    Prop[] memory props = DodoConfig.getProps();
    Prop[] memory propsList = new Prop[](propsIndex);
    for (uint i = 0; i < propsIndex; i++) {
      propsList[i] = props[i];
    }
    return propsList;
  }

  
  function getInviteData(address player) public view returns (uint256, uint256) {
    string memory inviteTimesKey = DodoConfig.getInviteTimesKey();
    string memory inviteRewardKey = DodoConfig.getInviteRewardKey();
    DodoStorageInterface _dataContract = DodoStorageInterface(dataContract);
    return (
      _dataContract.getPlayerExtraData(player, inviteTimesKey), 
      _dataContract.getPlayerExtraData(player, inviteRewardKey) 
    );
  }

  
  function sendInviteBonus(address player, address inviter) internal {
     
    if (inviter != address(0) && inviter != player) {
      string memory inviterKey = DodoConfig.getInviterKey();
      DodoStorageInterface _dataContract = DodoStorageInterface(dataContract);
      uint256 _inviter = _dataContract.getPlayerExtraData(player, inviterKey);
      if (_inviter == 0) { 
        
        uint256 reward = getIncome(inviter);
        
        _dataContract.transferCoin(inviter, reward);
        
        _dataContract.setPlayerExtraData(player, inviterKey, uint160(inviter));
        
        string memory inviteTimesKey = DodoConfig.getInviteTimesKey();
        _dataContract.setPlayerExtraData(inviter, inviteTimesKey,
          _dataContract.getPlayerExtraData(inviter, inviteTimesKey) + 1
        );
        
        string memory inviteRewardKey = DodoConfig.getInviteRewardKey();
        _dataContract.setPlayerExtraData(inviter, inviteRewardKey, 
          _dataContract.getPlayerExtraData(inviter, inviteRewardKey) + reward
        );
        emit inviteEvent(player, inviter, reward);
      }
    }
  }

  
  function makeMoneyBatch(address inviter, uint times) public payable {
    
    require(msg.value == DodoConfig.getFee() * times, "DodoLogic: fee error");
    address player = msg.sender;
    DodoStorageInterface _dataContract = DodoStorageInterface(dataContract);
    
    PlayerData memory playerData = _dataContract.getPlayerData(player);
    uint256 reward = getIncome(player) * times;
    
    _dataContract.transferCoin(player, reward);
    
    uint256 bonus = getBonus(player) * times;
    _dataContract.updatePlayerData(
      player,  
      playerData.dataVersion, 
      int256(times), 
      0, 
      0, 
      0, 
      int256(bonus) 
    );
    
    emit makeMoneyEvent(player, times, reward);
    
    payable(DodoConfig.getKingAddress()).transfer(msg.value);
    
    sendInviteBonus(player, inviter);
  }

  
  function getPlayerUpgradeConfig(address player) public view returns (uint256, uint256, uint256, uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    uint256 incomeUpgradeCost;
    uint256 bonusUpgradeCost;
    uint256 incomeLevelRate = DodoConfig.getIncomeLevelRate();
    uint256 bonusLevelRate = DodoConfig.getBonusLevelRate();
    uint256[] memory incomeUpgradeConfig = DodoConfig.getIncomeUpgradeConfig();
    uint256[] memory bonusUpgradeConfig = DodoConfig.getBonusUpgradeConfig();
    if (playerData.incomeLevel >= incomeUpgradeConfig.length) {
      incomeUpgradeCost = 0;
      incomeLevelRate = 0;
    } else {
      incomeUpgradeCost = incomeUpgradeConfig[playerData.incomeLevel];
    }
    if (playerData.bonusLevel >= bonusUpgradeConfig.length) {
      bonusUpgradeCost = 0;
      bonusLevelRate = 0;
    } else {
      bonusUpgradeCost = bonusUpgradeConfig[playerData.bonusLevel];
    }
    return (
      incomeUpgradeCost, 
      bonusUpgradeCost, 
      incomeLevelRate, 
      bonusLevelRate 
    );
  }

  
  function upgradeIncomeLevel() public {
    address player = msg.sender;
    DodoStorageInterface _dataContract = DodoStorageInterface(dataContract);
    PlayerData memory playerData = _dataContract.getPlayerData(player);
    uint256[] memory incomeUpgradeConfig = DodoConfig.getIncomeUpgradeConfig();
    
    require(playerData.incomeLevel < incomeUpgradeConfig.length, "DodoLogic: income level max");
    
    uint256 balance = IDodoCoin(tokenContract).balanceOf(player);
    uint256 upgradeCost = incomeUpgradeConfig[playerData.incomeLevel];
    require(balance >= upgradeCost, "DodoLogic: balance not enough");
    _dataContract.updatePlayerData(
      player,  
      playerData.dataVersion, 
      0, 
      0, 
      1, 
      0, 
      0 
    );
    
    IDodoCoin(tokenContract).deductTokens(player, dataContract, upgradeCost);
  }

  
  function upgradeBonusLevel() public {
    address player = msg.sender;
    DodoStorageInterface _dataContract = DodoStorageInterface(dataContract);
    PlayerData memory playerData = _dataContract.getPlayerData(player);
    uint256[] memory bonusUpgradeConfig = DodoConfig.getBonusUpgradeConfig();
    
    require(playerData.bonusLevel < bonusUpgradeConfig.length, "DodoLogic: bonus level max");
    
    uint256 balance = IDodoCoin(tokenContract).balanceOf(player);
    uint256 upgradeCost = bonusUpgradeConfig[playerData.bonusLevel];
    require(balance >= upgradeCost, "DodoLogic: balance not enough");
    _dataContract.updatePlayerData(
      player,  
      playerData.dataVersion, 
      0, 
      0, 
      0, 
      1, 
      0 
    );
    
    IDodoCoin(tokenContract).deductTokens(player, dataContract, upgradeCost);
  }

  
  function receiveBonus() public {
    address player = msg.sender;
    DodoStorageInterface _dataContract = DodoStorageInterface(dataContract);
    PlayerData memory playerData = _dataContract.getPlayerData(player);
    uint256 baseRate = DodoConfig.getBaseRate();
    uint256 rewardMultiple = playerData.bonus / baseRate;
    
    require(rewardMultiple > 0, "DodoLogic: bonus not enough");
    
    uint256 reward = getIncome(player) * rewardMultiple;
    
    _dataContract.transferCoin(player, reward);
    
    _dataContract.updatePlayerData(
      player,  
      playerData.dataVersion, 
      0, 
      0, 
      0, 
      0, 
      -int256(rewardMultiple * baseRate) 
    );
  }

  
  function buyProp(uint256 propId) public {
    address player = msg.sender;
    Prop memory prop = getPropsCanBuy(player);
    
    require(prop.id == propId, "DodoLogic: prop not can buy");
    
    uint256 balance = IDodoCoin(tokenContract).balanceOf(player);
    require(balance >= prop.price, "DodoLogic: balance not enough");
    
    IDodoCoin(tokenContract).deductTokens(player, dataContract, prop.price);
    
    DodoStorageInterface(dataContract).setPlayerExtraData(player, DodoConfig.getPropExtraDataKey(), propId);
    
    emit buyPropEvent(player, propId);
  }

  
  function checkWin() internal view returns (uint256, uint256) {
    uint256 result = uint(keccak256(abi.encodePacked(
        block.timestamp, block.prevrandao, blockhash(block.number), msg.sender, nonce
      ))) % 1000;
    uint256 odds = 0;
    if (result==0) {
      return (result, odds);
    }
    
    if (result % 10 == 7 && result / 10 % 10 == 7 && result / 100 % 10 == 7) {
      odds = 20;
    } else if (result % 10 == 7 && result / 10 % 10 == 7) {
      odds = 5;
    } else if (result % 10 == 7 && result / 100 % 10 == 7) {
      odds = 5;
    } else if (result / 10 % 10 == 7 && result / 100 % 10 == 7) {
      odds = 5;
    } else if (result % 10 == result / 10 % 10 && result % 10 == result / 100 % 10) {
      odds = 5;
    } else if (result % 10 == result / 10 % 10) {
      odds = 2;
    } else if (result % 10 == result / 100 % 10) {
      odds = 2;
    } else if (result / 10 % 10 == result / 100 % 10) {
      odds = 2;
    }
    return (result, odds);
  }

  
  function casinoBet(uint256 amount) public {
    address player = msg.sender;
    DodoStorageInterface _dataContract = DodoStorageInterface(dataContract);
    
    require(amount >= 1 ether, "DodoLogic: amount must > 1 ether");
    require(amount <= DodoConfig.getBetMaxAmount(), "DodoLogic: amount must <= betMaxAmount");
    
    uint256 balance = IDodoCoin(tokenContract).balanceOf(player);
    require(balance >= amount, "DodoLogic: balance not enough");
    
    nonce++;
    
    
    (uint256 result, uint256 odds) = checkWin();
    if(odds == 0) {
      
      IDodoCoin(tokenContract).deductTokens(player, dataContract, amount);
    } else if (odds > 1) {
      
      _dataContract.transferCoin(player, amount * (odds-1));
    }
    
    PlayerData memory playerData = _dataContract.getPlayerData(player);
    _dataContract.updatePlayerData(
      player,  
      playerData.dataVersion, 
      0, 
      1, 
      0, 
      0, 
      0 
    );
    
    emit betEvent(player, amount, result, odds);
  }

}