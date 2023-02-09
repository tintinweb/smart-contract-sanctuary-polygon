// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.2;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.2;

import "./AddressUpgradeable.sol";

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
    //
    // @dev Indicates that the contract has been initialized.
    // @custom:oz-retyped-from bool
    //
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
            require(
                _initialized < version,
                "Initializable: contract is already initialized"
            );
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./PreonMath.sol";
import "./SafeMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/ILiquityBase.sol";
import "./PreonCustomBase.sol";

/**
 * Base contract for TroveManager, TroveManagerLiquidations, TroveManagerRedemptions,
 * and BorrowerOperations.
 * Contains global system constants and common functions.
 */
contract LiquityBase is ILiquityBase, PreonCustomBase {
    using SafeMath for uint256;

    // Minimum collateral ratio for individual troves
    uint internal constant MCR = 11e17; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint internal constant CCR = 15e17; // 150%

    // Amount of STAR to be locked in gas pool on opening troves
    // This STAR goes to the liquidator in the event the trove is liquidated.
    uint internal constant STAR_GAS_COMPENSATION = 200e18;

    // Minimum amount of net STAR debt a must have
    uint internal constant MIN_NET_DEBT = 1800e18;

    // Minimum fee on issuing new debt, paid in STAR
    uint internal constant BORROWING_FEE_FLOOR = (DECIMAL_PRECISION / 1000) * 5; // 0.5%

    // Minimum fee paid on redemption, paid in STAR
    uint internal constant REDEMPTION_FEE_FLOOR =
        (DECIMAL_PRECISION / 1000) * 5; // 0.5%

    IActivePool internal activePool;

    IDefaultPool internal defaultPool;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    // --- Gas compensation functions ---

    /**
     * @notice Returns the total debt of a trove (net debt + gas compensation)
     * @dev The net debt is how much STAR the user can actually withdraw from the system.
     * The composite debt is the trove's total debt and is used for ICR calculations
     * @return Trove withdrawable debt (net debt) plus STAR_GAS_COMPENSATION
     */
    function _getCompositeDebt(uint _debt) internal pure returns (uint) {
        return _debt.add(STAR_GAS_COMPENSATION);
    }

    /**
     * @notice Returns the net debt, which is total (composite) debt of a trove minus gas compensation
     * @dev The net debt is how much STAR the user can actually withdraw from the system.
     * @return Trove total debt minus the gas compensation
     */
    function _getNetDebt(uint _debt) internal pure returns (uint) {
        return _debt.sub(STAR_GAS_COMPENSATION);
    }

    /**
     * @notice Return the system's Total Virtual Coin Balance
     * @dev Virtual Coins are a way to keep track of the system collateralization given
     * the collateral ratios of each collateral type
     * @return System's Total Virtual Coin Balance
     */
    function getEntireSystemColl() public view returns (uint) {
        return activePool.getVCSystem();
    }

    /**
     * @notice Calculate and return the System's Total Debt
     * @dev Includes debt held by active troves (activePool.getSTARDebt())
     * as well as debt from liquidated troves that has yet to be redistributed
     * (defaultPool.getSTARDebt())
     * @return Return the System's Total Debt
     */
    function getEntireSystemDebt() public view override returns (uint) {
        uint activeDebt = activePool.getSTARDebt();
        uint closedDebt = defaultPool.getSTARDebt();
        return activeDebt.add(closedDebt);
    }

    /**
     * @notice Calculate ICR given collaterals and debt
     * @dev ICR = VC(colls) / debt
     * @return ICR Return ICR of the given _colls and _debt
     */
    function _getICRColls(newColls memory _colls, uint _debt)
        internal
        view
        returns (uint ICR)
    {
        uint totalVC = _getVCColls(_colls);
        ICR = _computeCR(totalVC, _debt);
    }

    /**
     * @notice Calculate and AICR of the colls
     * @dev AICR = RVC(colls) / debt. Calculation is the same as
     * ICR except the collateral weights are different
     * @return AICR Return AICR of the given _colls and _debt
     */
    function _getAICRColls(newColls memory _colls, uint _debt)
        internal
        view
        returns (uint AICR)
    {
        uint totalRVC = _getRVCColls(_colls);
        AICR = _computeCR(totalRVC, _debt);
    }

    /**
     * @notice Calculate ICR given collaterals and debt
     * @dev ICR = VC(colls) / debt
     * @return ICR Return ICR of the given _colls and _debt
     */
    function _getICR(
        address[] memory _tokens,
        uint[] memory _amounts,
        uint _debt
    ) internal view returns (uint ICR) {
        uint totalVC = _getVC(_tokens, _amounts);
        ICR = _computeCR(totalVC, _debt);
    }

    /**
     * @notice Calculate and AICR of the colls
     * @dev AICR = RVC(colls) / debt. Calculation is the same as
     * ICR except the collateral weights are different
     * @return AICR Return AICR of the given _colls and _debt
     */
    function _getAICR(
        address[] memory _tokens,
        uint[] memory _amounts,
        uint _debt
    ) internal view returns (uint AICR) {
        uint totalRVC = _getRVC(_tokens, _amounts);
        AICR = _computeCR(totalRVC, _debt);
    }

    function _getVC(address[] memory _tokens, uint[] memory _amounts)
        internal
        view
        returns (uint totalVC)
    {
        totalVC = controller.getValuesVC(_tokens, _amounts);
    }

    function _getRVC(address[] memory _tokens, uint[] memory _amounts)
        internal
        view
        returns (uint totalRVC)
    {
        totalRVC = controller.getValuesRVC(_tokens, _amounts);
    }

    function _getVCColls(newColls memory _colls)
        internal
        view
        returns (uint totalVC)
    {
        totalVC = controller.getValuesVC(_colls.tokens, _colls.amounts);
    }

    function _getRVCColls(newColls memory _colls)
        internal
        view
        returns (uint totalRVC)
    {
        totalRVC = controller.getValuesRVC(_colls.tokens, _colls.amounts);
    }

    function _getUSDColls(newColls memory _colls)
        internal
        view
        returns (uint totalUSDValue)
    {
        totalUSDValue = controller.getValuesUSD(_colls.tokens, _colls.amounts);
    }

    function _getTCR() internal view returns (uint TCR) {
        (, uint256 entireSystemRVC) = activePool.getVCAndRVCSystem();
        uint256 entireSystemDebt = getEntireSystemDebt();
        TCR = _computeCR(entireSystemRVC, entireSystemDebt);
    }

    /**
     * @notice Returns recovery mode bool as well as entire system coll
     * @dev Do these together to avoid looping.
     * @return recMode Recovery mode bool
     * @return entireSystemCollVC System's Total Virtual Coin Balance
     * @return entireSystemCollRVC System's total Recovery ratio adjusted VC balance
     * @return entireSystemDebt System's total debt
     */
    function _checkRecoveryModeAndSystem()
        internal
        view
        returns (
            bool recMode,
            uint256 entireSystemCollVC,
            uint256 entireSystemCollRVC,
            uint256 entireSystemDebt
        )
    {
        (entireSystemCollVC, entireSystemCollRVC) = activePool
            .getVCAndRVCSystem();
        entireSystemDebt = getEntireSystemDebt();
        // Check TCR < CCR
        recMode = _computeCR(entireSystemCollRVC, entireSystemDebt) < CCR;
    }

    function _checkRecoveryMode() internal view returns (bool) {
        return _getTCR() < CCR;
    }

    // fee and amount are denominated in dollar
    function _requireUserAcceptsFee(
        uint _fee,
        uint _amount,
        uint _maxFeePercentage
    ) internal pure {
        return;
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee > max");
    }

    // checks coll has a nonzero balance of at least one token in coll.tokens
    function _collsIsNonZero(newColls memory _colls)
        internal
        pure
        returns (bool)
    {
        uint256 tokensLen = _colls.tokens.length;
        for (uint256 i; i < tokensLen; ++i) {
            if (_colls.amounts[i] != 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Calculates a new collateral ratio if debt is not 0 or the max uint256 value if it is 0
     * @dev Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
     * @param _coll Collateral
     * @param _debt Debt of Trove
     * @return The new collateral ratio if debt is greater than 0, max value of uint256 if debt is 0
     */
    function _computeCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt != 0) {
            uint newCollRatio = _coll.mul(1e18).div(_debt);
            return newCollRatio;
        } else {
            return 2**256 - 1;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./SafeMath.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IPreonController.sol";

/**
 * Contains shared functionality for many of the system files
 * PreonCustomBase is inherited by PoolBase2 and LiquityBase
 */

contract PreonCustomBase {
    using SafeMath for uint256;

    IPreonController internal controller;

    struct newColls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    uint256 public constant DECIMAL_PRECISION = 1e18;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /**
     * @notice Returns _coll1.amounts plus _coll2.amounts
     * @dev Invariant that _coll1.tokens and _coll2.tokens are sorted by whitelist order of token indices from the PreonController.
     *    So, if WAVAX is whitelisted first, then WETH, then USDC, then [WAVAX, USDC] is a valid input order but [USDC, WAVAX] is not.
     *    This is done for gas efficiency. We use a sliding window approach to increment the indices of the tokens we are adding together
     *    from _coll1 and from _coll2. We will start at tokenIndex1 and tokenIndex2. To keep the invariant of ordered collateral in
     *    each trove, we need to merge coll1 and coll2 in order based on the PreonController whitelist order. If the token indices
     *    line up, then they are the same and we add the sum. Otherwise we add the smaller index to keep them in order and move on.
     *    Once we reach the end of either tokens1 or tokens2, we add the remaining ones to the sum individually without summing.
     *    n is the number of tokens in the coll1, and m is the number of tokens in the coll2. k is defined as the number of tokens
     *    in the summed version. k = n + m - (overlap). The time complexity here depends on O(n + m) in the first loop and tail calls,
     *    and O(k) in the last loop. The total time complexity is O(n + m + k). If we assume that n is bigger than m(arbitrary between
     *    n and m), then since k is bounded by n we can say the time complexity is O(3n). This does not depend on all whitelisted tokens.
     */
    function _sumColls(newColls memory _coll1, newColls memory _coll2)
        internal
        view
        returns (newColls memory finalColls)
    {
        uint256 coll2Len = _coll2.tokens.length;
        uint256 coll1Len = _coll1.tokens.length;
        // If either is 0 then just return the other one.
        if (coll2Len == 0) {
            return _coll1;
        } else if (coll1Len == 0) {
            return _coll2;
        }
        // Create temporary n + m sized array.
        newColls memory coll3;
        coll3.tokens = new address[](coll1Len + coll2Len);
        coll3.amounts = new uint256[](coll1Len + coll2Len);

        // Tracker for the coll1 array.
        uint256 i = 0;
        // Tracker for the coll2 array.
        uint256 j = 0;
        // Tracker for nonzero entries.
        uint256 k = 0;

        uint256[] memory tokenIndices1 = controller.getIndices(_coll1.tokens);
        uint256[] memory tokenIndices2 = controller.getIndices(_coll2.tokens);

        // Tracker for token whitelist index for all coll1
        uint256 tokenIndex1 = tokenIndices1[i];
        // Tracker for token whitelist index for all coll2
        uint256 tokenIndex2 = tokenIndices2[j];

        // This loop will break out if either token index reaches the end inside the conditions.
        while (true) {
            if (tokenIndex1 < tokenIndex2) {
                // If tokenIndex1 is less than tokenIndex2 then that means it should be added first by itself.
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i];
                ++i;
                // If we reached the end of coll1 then we exit out.
                if (i == coll1Len) {
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
            } else if (tokenIndex2 < tokenIndex1) {
                // If tokenIndex2 is less than tokenIndex1 then that means it should be added first by itself.
                coll3.tokens[k] = _coll2.tokens[j];
                coll3.amounts[k] = _coll2.amounts[j];
                ++j;
                // If we reached the end of coll2 then we exit out.
                if (j == coll2Len) {
                    break;
                }
                tokenIndex2 = tokenIndices2[j];
            } else {
                // If the token indices match up then they are the same token, so we add them together.
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i].add(_coll2.amounts[j]);
                ++i;
                ++j;
                // If we reached the end of coll1 or coll2 then we exit out.
                if (i == coll1Len || j == coll2Len) {
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
                tokenIndex2 = tokenIndices2[j];
            }
            ++k;
        }
        ++k;
        // Add remaining tokens from coll1 if we reached the end of coll2 inside the previous loop.
        while (i < coll1Len) {
            coll3.tokens[k] = _coll1.tokens[i];
            coll3.amounts[k] = _coll1.amounts[i];
            ++i;
            ++k;
        }
        // Add remaining tokens from coll2 if we reached the end of coll1 inside the previous loop.
        while (j < coll2Len) {
            coll3.tokens[k] = _coll2.tokens[j];
            coll3.amounts[k] = _coll2.amounts[j];
            ++j;
            ++k;
        }

        // K is the resulting amount of nonzero entries that are in coll3, so we add them to finalTokens and return.
        address[] memory sumTokens = new address[](k);
        uint256[] memory sumAmounts = new uint256[](k);
        for (i = 0; i < k; ++i) {
            sumTokens[i] = coll3.tokens[i];
            sumAmounts[i] = coll3.amounts[i];
        }

        finalColls.tokens = sumTokens;
        finalColls.amounts = sumAmounts;
    }

    function _revertWrongFuncCaller() internal pure {
        revert("WFC");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./SafeMath.sol";

library PreonMath {
    using SafeMath for uint;
    using SafeMath for uint256;

    uint internal constant DECIMAL_PRECISION = 1e18;
    uint internal constant HALF_DECIMAL_PRECISION = 5e17;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /**
     * @notice Multiply two decimal numbers 
     * @dev Use normal rounding rules: 
        -round product up if 19'th mantissa digit >= 5
        -round product down if 19'th mantissa digit < 5
     */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(HALF_DECIMAL_PRECISION).div(DECIMAL_PRECISION);
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) TroveManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
        if (_minutes > 5256e5) {
            _minutes = 5256e5;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.2;
import "./Initializable.sol";

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

pragma solidity 0.8.2;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "div by 0");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "../Interfaces/ITroveManager.sol";
import "../Interfaces/IStabilityPool.sol";
import "../Interfaces/ICollSurplusPool.sol";
import "../Interfaces/ISTARToken.sol";
import "../Interfaces/ISortedTroves.sol";
import "../Interfaces/IPREONToken.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/ITroveManagerLiquidations.sol";
import "../Interfaces/ITroveManagerRedemptions.sol";
import "./LiquityBase.sol";

/**
 * Contains shared functionality of TroveManagerLiquidations, TroveManagerRedemptions, and TroveManager.
 * Keeps addresses to cache, events, structs, status, etc. Also keeps Trove struct.
 */

contract TroveManagerBase is LiquityBase {
    // --- Connected contract declarations ---

    // A doubly linked list of Troves, sorted by their sorted by their individual collateral ratios

    struct ContractsCache {
        IActivePool activePool;
        IDefaultPool defaultPool;
        ISTARToken starToken;
        ISortedTroves sortedTroves;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
        IPreonController controller;
    }

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    // Store the necessary data for a trove
    struct Trove {
        newColls colls;
        uint debt;
        mapping(address => uint) stakes;
        Status status;
        uint128 arrayIndex;
    }

    event TroveUpdated(
        address indexed _borrower,
        uint _debt,
        address[] _tokens,
        uint[] _amounts,
        TroveManagerOperation operation
    );
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event ActivePoolSTARDebtUpdated(uint _STARDebt);
    event ActivePoolCollateralBalanceUpdated(address _collateral, uint _amount);

    // --- Functions ---

    function sendCollaterals(
        address _to,
        address[] memory _tokens,
        uint[] memory _amounts
    ) external;

    function sendCollateralsUnwrap(
        address _to,
        address[] memory _tokens,
        uint[] memory _amounts
    ) external;

    function sendSingleCollateral(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function sendSingleCollateralUnwrap(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function getCollateralVC(address collateralAddress)
        external
        view
        returns (uint);

    function addCollateralType(address _collateral) external;

    function getAmountsSubsetSystem(address[] memory _collaterals)
        external
        view
        returns (uint256[] memory);

    function getVCSystem() external view returns (uint256 totalVCSystem);

    function getVCAndRVCSystem()
        external
        view
        returns (uint256 totalVC, uint256 totalRVC);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface ICollateralReceiver {
    function receiveCollateral(address[] memory _tokens, uint[] memory _amounts)
        external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "../Dependencies/PreonCustomBase.sol";
import "./ICollateralReceiver.sol";

interface ICollSurplusPool is ICollateralReceiver {
    // --- Events ---

    event CollBalanceUpdated(address indexed _account);
    event CollateralSent(address _to);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerLiquidationsAddress,
        address _troveManagerRedemptionsAddress,
        address _activePoolAddress,
        address _controllerAddress,
        address _starTokenAddress
    ) external;

    function getCollVC() external view returns (uint);

    function getTotalRedemptionBonus() external view returns (uint256);

    function getAmountClaimable(address _account, address _collateral)
        external
        view
        returns (uint);

    function getAmountsClaimable(address _account)
        external
        view
        returns (address[] memory, uint256[] memory);

    function hasClaimableCollateral(address _account)
        external
        view
        returns (bool);

    function getRedemptionBonus(address _account)
        external
        view
        returns (uint256);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral()
        external
        view
        returns (address[] memory, uint256[] memory);

    function accountSurplus(
        address _account,
        address[] memory _tokens,
        uint[] memory _amounts
    ) external;

    function accountRedemptionBonus(address _account, uint256 _amount) external;

    function claimCollateral() external;

    function addCollateralType(address _collateral) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolSTARDebtUpdated(uint256 _STARDebt);
    event DefaultPoolETHBalanceUpdated(uint256 _ETH);

    // --- Functions ---

    function sendCollsToActivePool(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external;

    function addCollateralType(address _collateral) external;

    function getCollateralVC(address collateralAddress)
        external
        view
        returns (uint256);

    function getAmountsSubset(address[] memory _collaterals)
        external
        view
        returns (uint256[] memory amounts, uint256[] memory controllerIndices);

    function getAllAmounts() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    // event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    // event Approval(
    //     address indexed owner,
    //     address indexed spender,
    //     uint256 value
    // );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 *
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to
     * a value in the near future. The deadline argument can be set to type(uint).max to
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);

    function version() external view returns (string memory);

    function permitTypeHash() external view returns (bytes32);

    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./IPriceFeed.sol";

interface ILiquityBase {
    function getEntireSystemDebt()
        external
        view
        returns (uint entireSystemDebt);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./ICollateralReceiver.sol";

// Common interface for the Pools.
interface IPool is ICollateralReceiver {
    // --- Events ---

    event ETHBalanceUpdated(uint _newBalance);
    event STARBalanceUpdated(uint _newBalance);
    event EtherSent(address _to, uint _amount);
    event CollateralSent(address _collateral, address _to, uint _amount);

    // --- Functions ---

    function getVC() external view returns (uint totalVC);

    function getVCAndRVC() external view returns (uint totalVC, uint totalRVC);

    function getCollateral(address collateralAddress)
        external
        view
        returns (uint);

    function getAllCollateral()
        external
        view
        returns (address[] memory, uint256[] memory);

    function getSTARDebt() external view returns (uint);

    function increaseSTARDebt(uint _amount) external;

    function decreaseSTARDebt(uint _amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface IPreonController {
    struct Addresses {
        address _activePoolAddress;
        address _defaultPoolAddress;
        address _stabilityPoolAddress;
        address _collSurplusPoolAddress;
        address _borrowerOperationsAddress;
        address _starTokenAddress;
        address _STARFeeRecipientAddress;
        address _preonFinanceTreasury;
        address _sortedTrovesAddress;
        address _vePREONAddress;
        address _troveManagerRedemptionsAddress;
        address _claimAddress;
        address _threeDayTimelock;
        address _twoWeekTimelock;
    }

    // ======== Mutable Only Owner-Instantaneous ========
    function setAddresses(Addresses memory _addresses) external;

    function endBootstrap() external;

    function deprecateAllCollateral() external;

    function deprecateCollateral(address _collateral) external;

    function setLeverUp(bool _enabled) external;

    function setFeeBootstrapPeriodEnabled(bool _enabled) external;

    function updateGlobalSTARMinting(bool _canMint) external;

    function removeValidSTARMinter(address _minter) external;

    function removeVePreonCaller(address _contractAddress) external;

    function updateRedemptionsEnabled(bool _enabled) external;

    function changeFeeCurve(address _collateral, address _feeCurve) external;

    // ======== Mutable Only Owner-3 Day TimeLock ========
    function addCollateral(
        address _collateral,
        uint256 _safetyRatio,
        uint256 _recoveryRatio,
        address _oracle,
        uint256 _decimals,
        address _feeCurve,
        bool _isWrapped,
        address _routerAddress
    ) external;

    function unDeprecateCollateral(address _collateral) external;

    function updateMaxCollsInTrove(uint _newMax) external;

    function changeRatios(
        address _collateral,
        uint256 _newSafetyRatio,
        uint256 _newRecoveryRatio
    ) external;

    function setDefaultRouter(address _collateral, address _router) external;

    function changePreonFinanceTreasury(address _newTreasury) external;

    function changeClaimAddress(address _newClaimAddress) external;

    function changeSTARFeeRecipient(address _newFeeRecipient) external;

    function changePreonFinanceTreasurySplit(uint256 _newSplit) external;

    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit) external;

    function updateAbsorptionColls(
        address[] memory _colls,
        uint[] memory _weights
    ) external;

    function changeOracle(address _collateral, address _oracle) external;

    // ======== Mutable Only Owner-2 Week TimeLock ========
    function addValidSTARMinter(address _minter) external;

    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor)
        external;

    function changeGlobalBoostMultiplier(uint256 _newBoostMinuteDecayFactor)
        external;

    function addVePreonCaller(address _contractAddress) external;

    function updateMaxSystemColls(uint _newMax) external;

    // ======= VIEW FUNCTIONS FOR COLLATERAL PARAMS =======
    function getValidCollateral() external view returns (address[] memory);

    function getOracle(address _collateral) external view returns (address);

    function getSafetyRatio(address _collateral)
        external
        view
        returns (uint256);

    function getRecoveryRatio(address _collateral)
        external
        view
        returns (uint256);

    function getIsActive(address _collateral) external view returns (bool);

    function getFeeCurve(address _collateral) external view returns (address);

    function getDecimals(address _collateral) external view returns (uint256);

    function getIndex(address _collateral) external view returns (uint256);

    function getIndices(address[] memory _colls)
        external
        view
        returns (uint256[] memory indices);

    function checkCollateralListSingle(address[] memory _colls, bool _deposit)
        external
        view;

    function checkCollateralListDouble(
        address[] memory _depositColls,
        address[] memory _withdrawColls
    ) external view;

    function isWrapped(address _collateral) external view returns (bool);

    function isWrappedMany(address[] memory _collaterals)
        external
        view
        returns (bool[] memory wrapped);

    function getDefaultRouterAddress(address _collateral)
        external
        view
        returns (address);

    // ======= VIEW FUNCTIONS FOR VC / USD VALUE =======
    function getPrice(address _collateral) external view returns (uint256);

    function getValuesVC(address[] memory _collaterals, uint[] memory _amounts)
        external
        view
        returns (uint);

    function getValuesRVC(address[] memory _collaterals, uint[] memory _amounts)
        external
        view
        returns (uint);

    function getValuesVCAndRVC(
        address[] memory _collaterals,
        uint[] memory _amounts
    ) external view returns (uint VC, uint256 RVC);

    function getValuesUSD(address[] memory _collaterals, uint[] memory _amounts)
        external
        view
        returns (uint256);

    function getValueVC(address _collateral, uint _amount)
        external
        view
        returns (uint);

    function getValueRVC(address _collateral, uint _amount)
        external
        view
        returns (uint);

    function getValueUSD(address _collateral, uint _amount)
        external
        view
        returns (uint256);

    function getValuesVCIndividual(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external view returns (uint256[] memory);

    // ======= VIEW FUNCTIONS FOR CONTRACT FUNCTIONALITY =======
    function getPreonFinanceTreasury() external view returns (address);

    function getPreonFinanceTreasurySplit() external view returns (uint256);

    function getRedemptionBorrowerFeeSplit() external view returns (uint256);

    function getSTARFeeRecipient() external view returns (address);

    function leverUpEnabled() external view returns (bool);

    function getMaxCollsInTrove() external view returns (uint);

    function getFeeSplitInformation()
        external
        view
        returns (
            uint256,
            address,
            address
        );

    function getClaimAddress() external view returns (address);

    function getAbsorptionCollParams()
        external
        view
        returns (address[] memory, uint[] memory);

    function getVariableDepositFee(
        address _collateral,
        uint _collateralVCInput,
        uint256 _collateralVCBalancePost,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external view returns (uint256 fee);

    // ======== Mutable Function For Fees ========
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemCollVC,
        uint256 _VCin,
        uint256 _VCout
    ) external returns (uint256 STARFee, uint256 boostFactor);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC20.sol";
import "./IERC2612.sol";

interface IPREONToken is IERC20, IERC2612 {
    function sendToSPREON(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface IPriceFeed {
    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    // function fetchPrice() external returns (uint);

    function fetchPrice_v() external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {
    // --- Functions ---

    function setParams(
        uint256 _size,
        address _TroveManagerAddress,
        address _borrowerOperationsAddress,
        address _troveManagerRedemptionsAddress,
        address _preonControllerAddress
    ) external;

    function insert(
        address _id,
        uint256 _ICR,
        address _prevId,
        address _nextId,
        uint256 _feeAsPercentOfTotal
    ) external;

    function remove(address _id) external;

    function reInsert(
        address _id,
        uint256 _newICR,
        address _prevId,
        address _nextId
    ) external;

    function reInsertWithNewBoost(
        address _id,
        uint256 _newAICR,
        address _prevId,
        address _nextId,
        uint256 _feeAsPercentOfAddedVC,
        uint256 _addedVCIn,
        uint256 _VCBeforeAdjustment
    ) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNode(address _id)
        external
        view
        returns (
            bool,
            address,
            address,
            uint256,
            uint256,
            uint256
        );

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function getOldBoostedAICR(address _id) external view returns (uint256);

    function getTimeSinceBoostUpdated(address _id)
        external
        view
        returns (uint256);

    function getBoost(address _id) external view returns (uint256);

    function getDecayedBoost(address _id) external view returns (uint256);

    function getUnderCollateralizedTrovesSize() external view returns (uint256);

    function validInsertPosition(
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (bool);

    function findInsertPosition(
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address);

    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor)
        external;

    function changeGlobalBoostMultiplier(uint256 _newGlobalBoostMultiplier)
        external;

    function updateUnderCollateralizedTrove(
        address _id,
        bool _isUnderCollateralized
    ) external;

    function reInsertMany(
        address[] memory _ids,
        uint256[] memory _newAICRs,
        address[] memory _prevIds,
        address[] memory _nextIds
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./ICollateralReceiver.sol";

/*
 * The Stability Pool holds STAR tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its STAR debt gets offset with
 * STAR in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of STAR tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a STAR loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total STAR in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- PREON ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An PREON issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued PREON in proportion to the deposit as a share of total deposits. The PREON earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#preon-issuance-to-stability-providers
 */
interface IStabilityPool is ICollateralReceiver {
    // --- Events ---

    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolSTARBalanceUpdated(uint _newBalance);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event DepositSnapshotUpdated(
        address indexed _depositor,
        uint _P,
        uint _S,
        uint _G
    );
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);

    event ETHGainWithdrawn(
        address indexed _depositor,
        uint _ETH,
        uint _STARLoss
    );
    event PREONPaidToDepositor(address indexed _depositor, uint _PREON);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Preon contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _starTokenAddress,
        address _sortedTrovesAddress,
        address _communityIssuanceAddress,
        address _controllerAddress,
        address _troveManagerLiquidationsAddress
    ) external;

    /*
     * Initial checks:
     * - _amount is not zero
     * ---
     * - Triggers a PREON issuance, based on time passed since the last issuance. The PREON issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (PREON, ETH) to depositor
     * - Sends the tagged front end's accumulated PREON gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a PREON issuance, based on time passed since the last issuance. The PREON issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (PREON, ETH) to depositor
     * - Sends the tagged front end's accumulated PREON gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;

    function claimRewardsSwap(uint256 _starMinAmountTotal)
        external
        returns (uint256 amountFromSwap);

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the STAR contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(
        uint _debt,
        address[] memory _assets,
        uint[] memory _amountsAdded
    ) external;

    //    /*
    //     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
    //     * to exclude edge cases like ETH received from a self-destruct.
    //     */
    //    function getETH() external view returns (uint);

    //*
    //     * Calculates and returns the total gains a depositor has accumulated
    //     */
    function getDepositorGains(address _depositor)
        external
        view
        returns (address[] memory assets, uint[] memory amounts);

    /*
     * Returns the total amount of VC held by the pool, accounted for by multipliying the
     * internal balances of collaterals by the price that is found at the time getVC() is called.
     */
    function getVC() external view returns (uint);

    /*
     * Returns STAR held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalSTARDeposits() external view returns (uint);

    /*
     * Calculate the PREON gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorPREONGain(address _depositor)
        external
        view
        returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedSTARDeposit(address _depositor)
        external
        view
        returns (uint);

    /*
     * Add collateral type to totalColl
     */
    function addCollateralType(address _collateral) external;

    function getDepositSnapshotS(address depositor, address collateral)
        external
        view
        returns (uint);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral()
        external
        view
        returns (address[] memory, uint256[] memory);

    function getEstimatedPREONPoolRewards(uint _amount, uint _time)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "../Interfaces/IERC20.sol";
import "../Interfaces/IERC2612.sol";

interface ISTARToken is IERC20, IERC2612 {
    // --- Events ---

    event STARTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(
        address _sender,
        address poolAddress,
        uint256 _amount
    ) external;

    function returnFromPool(
        address poolAddress,
        address user,
        uint256 _amount
    ) external;

    function updateMinting(bool _canMint) external;

    function addValidMinter(address _newMinter) external;

    function removeValidMinter(address _minter) external;

    function setMaxSTARMintable(uint256 _maxSTARMintable) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./ISTARToken.sol";
import "./IPREONToken.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";

// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {
    // --- Events ---

    event Redemption(
        uint _attemptedSTARAmount,
        uint _actualSTARAmount,
        uint STARfee,
        address[] tokens,
        uint[] amounts
    );
    event TroveLiquidated(
        address indexed _borrower,
        uint _debt,
        uint _coll,
        uint8 operation
    );
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(address token, uint _newTotalStakes);
    event SystemSnapshotsUpdated(
        uint _totalStakesSnapshot,
        uint _totalCollateralSnapshot
    );
    event LTermsUpdated(uint _L_ETH, uint _L_STARDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_STARDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    // --- Functions ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _sortedTrovesAddress,
        address _controllerAddress,
        address _troveManagerRedemptionsAddress,
        address _troveManagerLiquidationsAddress
    ) external;

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index)
        external
        view
        returns (address);

    function getCurrentICR(address _borrower) external view returns (uint);

    function getCurrentAICR(address _borrower) external view returns (uint);

    function liquidate(address _borrower) external;

    function batchLiquidateTroves(
        address[] calldata _troveArray,
        address _liquidator
    ) external;

    function redeemCollateral(
        uint _STARAmount,
        uint _STARMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations
    ) external;

    function redeemCollateralSingle(
        uint256 _STARamount,
        uint256 _STARMaxFee,
        address _target,
        address _upperHint,
        address _lowerHint,
        uint256 _hintAICR,
        address _collToRedeem
    ) external;

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower)
        external
        returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingCollRewards(address _borrower)
        external
        view
        returns (address[] memory, uint[] memory);

    function getPendingSTARDebtReward(address _borrower)
        external
        view
        returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function removeStakeAndCloseTrove(address _borrower) external;

    function updateTroveDebt(address _borrower, uint debt) external;

    function getRedemptionRate() external view returns (uint);

    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn)
        external
        view
        returns (uint);

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint STARDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _STARDebt)
        external
        view
        returns (uint);

    function decayBaseRateFromBorrowingAndCalculateFee(uint256 _STARDebt)
        external
        returns (uint);

    function getTroveStatus(address _borrower) external view returns (uint);

    function isTroveActive(address _borrower) external view returns (bool);

    function getTroveStake(address _borrower, address _token)
        external
        view
        returns (uint);

    function getTotalStake(address _token) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getL_Coll(address _token) external view returns (uint);

    function getL_STAR(address _token) external view returns (uint);

    function getRewardSnapshotColl(address _borrower, address _token)
        external
        view
        returns (uint);

    function getRewardSnapshotSTAR(address _borrower, address _token)
        external
        view
        returns (uint);

    function getTroveVC(address _borrower) external view returns (uint);

    function getTroveColls(address _borrower)
        external
        view
        returns (address[] memory, uint[] memory);

    function getCurrentTroveState(address _borrower)
        external
        view
        returns (
            address[] memory,
            uint[] memory,
            uint
        );

    function setTroveStatus(address _borrower, uint num) external;

    function updateTroveCollAndStakeAndTotalStakes(
        address _borrower,
        address[] memory _tokens,
        uint[] memory _amounts
    ) external;

    function increaseTroveDebt(address _borrower, uint _debtIncrease)
        external
        returns (uint);

    function decreaseTroveDebt(address _borrower, uint _collDecrease)
        external
        returns (uint);

    function getTCR() external view returns (uint);

    function checkRecoveryMode() external view returns (bool);

    function closeTroveRedemption(address _borrower) external;

    function closeTroveLiquidation(address _borrower) external;

    function removeStake(address _borrower) external;

    function updateBaseRate(uint newBaseRate) external;

    function calcDecayedBaseRate() external view returns (uint);

    function redistributeDebtAndColl(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _debt,
        address[] memory _tokens,
        uint[] memory _amounts
    ) external;

    function updateSystemSnapshots_excludeCollRemainder(
        IActivePool _activePool,
        address[] memory _tokens,
        uint[] memory _amounts
    ) external;

    function getEntireDebtAndColls(address _borrower)
        external
        view
        returns (
            uint,
            address[] memory,
            uint[] memory,
            uint,
            address[] memory,
            uint[] memory
        );

    function updateTroves(
        address[] calldata _borrowers,
        address[] calldata _lowerHints,
        address[] calldata _upperHints
    ) external;

    function updateUnderCollateralizedTroves(address[] memory _ids) external;

    function getMCR() external view returns (uint256);

    function getCCR() external view returns (uint256);

    function getSTAR_GAS_COMPENSATION() external view returns (uint256);

    function getMIN_NET_DEBT() external view returns (uint256);

    function getBORROWING_FEE_FLOOR() external view returns (uint256);

    function getREDEMPTION_FEE_FLOOR() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface ITroveManagerLiquidations {
    function batchLiquidateTroves(
        address[] memory _troveArray,
        address _liquidator
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface ITroveManagerRedemptions {
    function redeemCollateral(
        uint _STARamount,
        uint _STARMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        address _redeemSender
    ) external;

    function redeemCollateralSingle(
        uint256 _STARamount,
        uint256 _STARMaxFee,
        address _target,
        address _upperHint,
        address _lowerHint,
        uint256 _hintAICR,
        address _collToRedeem,
        address _redeemer
    ) external;

    function updateRedemptionsEnabled(bool _enabled) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/IPreonController.sol";
import "./Interfaces/ITroveManagerLiquidations.sol";
import "./Interfaces/ITroveManagerRedemptions.sol";
import "./Interfaces/IERC20.sol";
import "./Dependencies/TroveManagerBase.sol";
import "./Dependencies/ReentrancyGuardUpgradeable.sol";
import "./Dependencies/SafeMath.sol";


/**
 * @title Deals with state of all system troves
 * @notice It has all the external functions for liquidations, redemptions,
 * as well as functions called by BorrowerOperations function calls.
 */

contract TroveManager is
    TroveManagerBase,
    ITroveManager,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    address internal borrowerOperationsAddress;

    ITroveManager internal troveManager;

    ITroveManagerRedemptions internal troveManagerRedemptions;

    ITroveManagerLiquidations internal troveManagerLiquidations;

    ISortedTroves internal sortedTroves;

    bytes32 public constant NAME = "TroveManager";

    // --- Data structures ---

    uint256 internal constant SECONDS_IN_ONE_MINUTE = 60;

    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;
    uint256 public constant MAX_BORROWING_FEE = (DECIMAL_PRECISION * 5) / 100; // 5%

    // During bootsrap period redemptions are not allowed
    uint256 public constant BOOTSTRAP_PERIOD = 14 days;

    // See documentation for explanation of baseRate
    uint256 public baseRate;

    // The timestamp of the latest fee operation (redemption or new STAR issuance)
    uint256 public lastFeeOperationTime;

    // Mapping of all troves in the system
    mapping(address => Trove) Troves;

    // Total stakes keeps track of the sum of all stakes for each collateral, across all users.
    mapping(address => uint256) public totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    mapping(address => uint256) public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    mapping(address => uint256) public totalCollateralSnapshot;

    /*
     * L_Coll and L_STARDebt track the sums of accumulated liquidation rewards per unit staked. Each collateral type has
     * its own L_Coll and L_STARDebt.
     * During its lifetime, each stake earns:
     *
     * A Collateral gain of ( stake * [L_Coll[coll] - L_Coll[coll](0)] )
     * A STARDebt increase  of ( stake * [L_STARDebt - L_STARDebt(0)] )
     *
     * Where L_Coll[coll](0) and L_STARDebt(0) are snapshots of L_Coll[coll] and L_STARDebt for the active Trove taken at the instant the stake was made
     */
    mapping(address => uint256) public L_Coll;
    mapping(address => uint256) public L_STARDebt;

    // Map addresses with active troves to their RewardSnapshot
    mapping(address => RewardSnapshot) rewardSnapshots;

    // Object containing the reward snapshots for a given active trove
    struct RewardSnapshot {
        mapping(address => uint256) CollRewards;
        mapping(address => uint256) STARDebts;
    }

    // Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] public TroveOwners;

    // Error trackers for the trove redistribution calculation
    mapping(address => uint256) public lastCollError_Redistribution;
    mapping(address => uint256) public lastSTARDebtError_Redistribution;

    /*
     * --- Variable container structs for liquidations ---
     *
     * These structs are used to hold, return and assign variables inside the liquidation functions,
     * in order to avoid the error: "CompilerError: Stack too deep".
     **/

    // --- Events ---

    // event BaseRateUpdated(uint256 _baseRate);
    // event LastFeeOpTimeUpdated(uint256 _lastFeeOpTime);
    // event TotalStakesUpdated(address token, uint256 _newTotalStakes);
    event SystemSnapshotsUpdated(uint256 _unix);

    event Liquidation(
        uint256 liquidatedAmount,
        uint256 totalSTARGasCompensation,
        address[] totalCollTokens,
        uint256[] totalCollAmounts,
        address[] totalCollGasCompTokens,
        uint256[] totalCollGasCompAmounts
    );

    event LTermsUpdated(
        address _Coll_Address,
        uint256 _L_Coll,
        uint256 _L_STARDebt
    );
    event TroveSnapshotsUpdated(uint256 _unix);
    // event TroveIndexUpdated(address _borrower, uint256 _newIndex);
    // event TroveUpdated(
    //     address indexed _borrower,
    //     uint256 _debt,
    //     address[] _tokens,
    //     uint256[] _amounts,
    //     TroveManagerOperation operation
    // );

    bool private addressSet;

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _sortedTrovesAddress,
        address _controllerAddress,
        address _troveManagerRedemptionsAddress,
        address _troveManagerLiquidationsAddress
    ) external override {
        require(addressSet == false, "Addresses already set");
        addressSet = true;
        // __ReentrancyGuard_init();

        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        controller = IPreonController(_controllerAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        troveManagerRedemptions = ITroveManagerRedemptions(
            _troveManagerRedemptionsAddress
        );
        troveManagerLiquidations = ITroveManagerLiquidations(
            _troveManagerLiquidationsAddress
        );
    }

    // --- Trove Liquidation functions ---

    /**
     * @notice Single liquidation function. Closes the trove if its ICR is lower than the minimum collateral ratio.
     * @param _borrower The address of the Trove owner
     */
    function liquidate(address _borrower) external override nonReentrant {
        _requireTroveIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        troveManagerLiquidations.batchLiquidateTroves(borrowers, msg.sender);
    }

    /**
     * @notice Attempt to liquidate a custom list of troves provided by the caller.
     * @param _troveArray The list of Troves' Addresses
     * @param _liquidator The address of the liquidator
     */
    function batchLiquidateTroves(
        address[] memory _troveArray,
        address _liquidator
    ) external override nonReentrant {
        troveManagerLiquidations.batchLiquidateTroves(_troveArray, _liquidator);
    }

    // --- Liquidation helper functions ---

    /**
     * @notice Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
     */
    function _movePendingTroveRewardsToActivePool(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _STAR,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        _defaultPool.decreaseSTARDebt(_STAR);
        _activePool.increaseSTARDebt(_STAR);
        _defaultPool.sendCollsToActivePool(_tokens, _amounts);
    }

    /**
     * @notice Update position for a set of troves using latest price data. This can be called by anyone.
     * Preon Finance will also be running a bot to assist with keeping the list from becoming too stale.
     * @param _borrowers The list of addresses of the troves to update
     * @param _lowerHints The list of lower hints for the troves which are to be updated
     * @param _upperHints The list of upper hints for the troves which are to be updated
     */
    function updateTroves(
        address[] calldata _borrowers,
        address[] calldata _lowerHints,
        address[] calldata _upperHints
    ) external override {
        uint256 lowerHintsLen = _lowerHints.length;
        _revertLenInput(
            _borrowers.length == lowerHintsLen &&
                lowerHintsLen == _upperHints.length
        );

        uint256[] memory AICRList = new uint256[](lowerHintsLen);

        for (uint256 i; i < lowerHintsLen; ++i) {
            (
                address[] memory tokens,
                uint256[] memory amounts,
                uint256 debt
            ) = _getCurrentTroveState(_borrowers[i]);
            AICRList[i] = _getAICR(tokens, amounts, debt);
        }
        sortedTroves.reInsertMany(
            _borrowers,
            AICRList,
            _lowerHints,
            _upperHints
        );
    }

    /**
     * @notice Update a particular trove address in the underCollateralized troves list
     * @dev This function is called by the UpdateTroves bot if there are many underCollateralized troves
     * during congested network conditions where potentially it is tough to liquidate them all.
     * In this case, the function adds to the underCollateralizedTroves list so no SP withdrawal can happen.
     * If the trove is no longer underCollateralized then this function will remove
     * it from the list. This function calls sortedTroves' updateUnderCollateralizedTrove function.
     * Intended to be a cheap function call since it is going to be called when liquidations are not possible
     * @param _ids Trove ids
     */
    function updateUnderCollateralizedTroves(address[] memory _ids)
        external
        override
    {
        uint len = _ids.length;
        for (uint i; i < len; i++) {
            uint256 ICR = getCurrentICR(_ids[i]);
            // If ICR < MCR, is undercollateralized
            _updateUnderCollateralizedTrove(_ids[i], ICR < MCR);
        }
    }

    /**
     * @notice Send _STARamount STAR to the system and redeem the corresponding amount of collateral
     * from as many Troves as are needed to fill the redemption request. Applies pending rewards to a Trove before reducing its debt and coll.
     * @dev if _amount is very large, this function can run out of gas, specially if traversed troves are small. This can be easily avoided by
     * splitting the total _amount in appropriate chunks and calling the function multiple times.
     *
     * Param `_maxIterations` can also be provided, so the loop through Troves is capped (if it’s zero, it will be ignored).This makes it easier to
     * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
     * of the trove list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
     * costs can vary.
     *
     * All Troves that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
     * If the last Trove does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
     * A frontend should use getRedemptionHints() to calculate what the ICR of this Trove will be after redemption, and pass a hint for its position
     * in the sortedTroves list along with the ICR value that the hint was found for.
     *
     * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it is very
     * likely that the last (partially) redeemed Trove would end up with a different ICR than what the hint is for. In this case the redemption
     * will stop after the last completely redeemed Trove and the sender will keep the remaining STAR amount, which they can attempt to redeem later.
     * @param _STARamount The intended amount of STAR to redeem
     * @param _STARMaxFee The maximum accepted fee in STAR the user is willing to pay
     * @param _firstRedemptionHint The hint for the position of the first redeemed Trove in the sortedTroves list
     * @param _upperPartialRedemptionHint The upper hint for the position of the last partially redeemed Trove in the sortedTroves list
     * @param _lowerPartialRedemptionHint The lower hint for the position of the last partially redeemed Trove in the sortedTroves list
     * @param _partialRedemptionHintAICR The AICR of the last partially redeemed Trove in the sortedTroves list
     * @param _maxIterations The maximum number of iterations to perform. If zero, the function will run until it runs out of gas.
     */
    function redeemCollateral(
        uint256 _STARamount,
        uint256 _STARMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintAICR,
        uint256 _maxIterations
    ) external override nonReentrant {
        troveManagerRedemptions.redeemCollateral(
            _STARamount,
            _STARMaxFee,
            _firstRedemptionHint,
            _upperPartialRedemptionHint,
            _lowerPartialRedemptionHint,
            _partialRedemptionHintAICR,
            _maxIterations,
            msg.sender
        );
    }

    /** 
     * @notice Secondary function for redeeming collateral. See above for how STARMaxFee is calculated.
            Redeems one collateral type from only one trove. Included for gas efficiency of arbitrages. 
     * @param _STARamount is equal to the amount of STAR to actually redeem. 
     * @param _STARMaxFee is equal to the max fee in STAR that the sender is willing to pay
     * @param _target is the hint for the single trove to redeem against
     * @param _upperHint is the upper hint for reinsertion of the trove
     * @param _lowerHint is the lower hint for reinsertion of the trove
     * @param _hintAICR is the target hint AICR for the the trove redeemed
     * @param _collToRedeem is the collateral address to redeem. Only this token.
     * _STARamount + _STARMaxFee must be less than the balance of the sender.
     */
    function redeemCollateralSingle(
        uint256 _STARamount,
        uint256 _STARMaxFee,
        address _target,
        address _upperHint,
        address _lowerHint,
        uint256 _hintAICR,
        address _collToRedeem
    ) external override nonReentrant {
        troveManagerRedemptions.redeemCollateralSingle(
            _STARamount,
            _STARMaxFee,
            _target,
            _upperHint,
            _lowerHint,
            _hintAICR,
            _collToRedeem,
            msg.sender
        );
    }

    // --- Getters ---

    function getTroveOwnersCount() external view override returns (uint256) {
        return TroveOwners.length;
    }

    function getTroveFromTroveOwnersArray(uint256 _index)
        external
        view
        override
        returns (address)
    {
        return TroveOwners[_index];
    }

    // --- Helper functions ---

    /**
     * @notice Helper function to return the current individual collateral ratio (ICR) of a given Trove.
     * @dev Takes a trove's pending coll and debt rewards from redistributions into account.
     * @param _borrower The address of the Trove to get the ICR
     * @return ICR
     */
    function getCurrentICR(address _borrower)
        public
        view
        override
        returns (uint256 ICR)
    {
        (
            address[] memory tokens,
            uint256[] memory amounts,
            uint256 currentSTARDebt
        ) = _getCurrentTroveState(_borrower);

        ICR = _getICR(tokens, amounts, currentSTARDebt);
    }

    /**
     *   @notice Helper function to return the current recovery individual collateral ratio (AICR) of a given Trove.
     *           AICR uses recovery ratios which are higher for more stable assets like stablecoins.
     *   @dev Takes a trove's pending coll and debt rewards from redistributions into account.
     *   @param _borrower The address of the Trove to get the AICR
     *   @return AICR
     */
    function getCurrentAICR(address _borrower)
        external
        view
        override
        returns (uint256 AICR)
    {
        (
            address[] memory tokens,
            uint256[] memory amounts,
            uint256 currentSTARDebt
        ) = _getCurrentTroveState(_borrower);

        AICR = _getAICR(tokens, amounts, currentSTARDebt);
    }

    /**
     *   @notice Gets current trove state as colls and debt.
     *   @param _borrower The address of the Trove
     *   @return colls -- newColls of the trove tokens and amounts
     *   @return STARdebt -- the current debt of the trove
     */
    function _getCurrentTroveState(address _borrower)
        internal
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        newColls memory pendingCollReward = _getPendingCollRewards(_borrower);
        uint256 pendingSTARDebtReward = getPendingSTARDebtReward(_borrower);

        uint256 STARdebt = Troves[_borrower].debt.add(pendingSTARDebtReward);
        newColls memory colls = _sumColls(
            Troves[_borrower].colls,
            pendingCollReward
        );
        return (colls.tokens, colls.amounts, STARdebt);
    }

    /**
     * @notice Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
     * @param _borrower The address of the Trove
     */
    function applyPendingRewards(address _borrower) external override {
        _requireCallerIsBOorTMR();
        return _applyPendingRewards(activePool, defaultPool, _borrower);
    }

    /**
     * @notice Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
     * @param _borrower The address of the Trove
     */
    function _applyPendingRewards(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower
    ) internal {
        if (hasPendingRewards(_borrower)) {
            _requireTroveIsActive(_borrower);

            // Compute pending collateral rewards
            newColls memory pendingCollReward = _getPendingCollRewards(
                _borrower
            );
            uint256 pendingSTARDebtReward = getPendingSTARDebtReward(_borrower);

            // Apply pending rewards to trove's state
            Troves[_borrower].colls = _sumColls(
                Troves[_borrower].colls,
                pendingCollReward
            );
            Troves[_borrower].debt = Troves[_borrower].debt.add(
                pendingSTARDebtReward
            );

            _updateTroveRewardSnapshots(_borrower);

            // Transfer from DefaultPool to ActivePool
            _movePendingTroveRewardsToActivePool(
                _activePool,
                _defaultPool,
                pendingSTARDebtReward,
                pendingCollReward.tokens,
                pendingCollReward.amounts
            );

            emit TroveUpdated(
                _borrower,
                Troves[_borrower].debt,
                Troves[_borrower].colls.tokens,
                Troves[_borrower].colls.amounts,
                TroveManagerOperation.applyPendingRewards
            );
        }
    }

    /**
     * @notice Update borrower's snapshots of L_Coll and L_STARDebt to reflect the current values
     * @param _borrower The address of the Trove
     */
    function updateTroveRewardSnapshots(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        _updateTroveRewardSnapshots(_borrower);
    }

    /**
     * @notice Internal function to update borrower's snapshots of L_Coll and L_STARDebt to reflect the current values
     *         Called when updating trove reward snapshots or when applying pending rewards
     * @param _borrower The address of the Trove
     */
    function _updateTroveRewardSnapshots(address _borrower) internal {
        address[] memory allColls = Troves[_borrower].colls.tokens;
        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address asset = allColls[i];
            rewardSnapshots[_borrower].CollRewards[asset] = L_Coll[asset];
            rewardSnapshots[_borrower].STARDebts[asset] = L_STARDebt[asset];
        }
        emit TroveSnapshotsUpdated(block.timestamp);
    }

    /**
     * @notice Get the borrower's pending accumulated Coll rewards, earned by their stake
     * @dev Returned tokens and amounts are the length of controller.getValidCollateral()
     * @param _borrower The address of the Trove
     * @return The borrower's pending accumulated Coll rewards tokens
     * @return The borrower's pending accumulated Coll rewards amounts
     */
    function getPendingCollRewards(address _borrower)
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        newColls memory pendingCollRewards = _getPendingCollRewards(_borrower);
        return (pendingCollRewards.tokens, pendingCollRewards.amounts);
    }

    /**
     * @notice Get the borrower's pending accumulated Coll rewards, earned by their stake
     * @param _borrower The address of the Trove
     * @return pendingCollRewards
     */
    function _getPendingCollRewards(address _borrower)
        internal
        view
        returns (newColls memory pendingCollRewards)
    {
        if (Troves[_borrower].status != Status.active) {
            newColls memory emptyColls;
            return emptyColls;
        }

        address[] memory allColls = Troves[_borrower].colls.tokens;
        pendingCollRewards.amounts = new uint256[](allColls.length);
        pendingCollRewards.tokens = allColls;
        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address coll = allColls[i];
            uint256 snapshotCollReward = rewardSnapshots[_borrower].CollRewards[
                coll
            ];
            uint256 rewardPerUnitStaked = L_Coll[coll].sub(snapshotCollReward);
            if (rewardPerUnitStaked == 0) {
                pendingCollRewards.amounts[i] = 0;
                continue;
            }

            uint256 stake = Troves[_borrower].stakes[coll];
            uint256 dec = IERC20(coll).decimals();
            uint256 assetCollReward = stake.mul(rewardPerUnitStaked).div(
                10**dec
            );
            pendingCollRewards.amounts[i] = assetCollReward;
        }
    }

    /**
     * @notice : Get the borrower's pending accumulated STAR reward, earned by their stake
     * @param _borrower The address of the Trove
     */
    function getPendingSTARDebtReward(address _borrower)
        public
        view
        override
        returns (uint256 pendingSTARDebtReward)
    {
        if (Troves[_borrower].status != Status.active) {
            return 0;
        }
        address[] memory allColls = Troves[_borrower].colls.tokens;

        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address coll = allColls[i];
            uint256 snapshotSTARDebt = rewardSnapshots[_borrower].STARDebts[
                coll
            ];
            uint256 rewardPerUnitStaked = L_STARDebt[allColls[i]].sub(
                snapshotSTARDebt
            );
            if (rewardPerUnitStaked == 0) {
                continue;
            }

            uint256 stake = Troves[_borrower].stakes[coll];
            uint256 dec = IERC20(coll).decimals();
            uint256 assetSTARDebtReward = stake.mul(rewardPerUnitStaked).div(
                10**dec
            );
            pendingSTARDebtReward = pendingSTARDebtReward.add(
                assetSTARDebtReward
            );
        }
    }

    /**
     * @notice Checks if borrower has pending rewards
     * @dev A Trove has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
     * this indicates that rewards have occured since the snapshot was made, and the user therefore has pending rewards
     * @param _borrower The address of the Trove
     * @return True if Trove has pending rewards, False if Trove doesn't have pending rewards
     */
    function hasPendingRewards(address _borrower)
        public
        view
        override
        returns (bool)
    {
        if (Troves[_borrower].status != Status.active) {
            return false;
        }
        address[] memory assets = Troves[_borrower].colls.tokens;
        uint256 assetsLen = assets.length;
        for (uint256 i; i < assetsLen; ++i) {
            address token = assets[i];
            if (rewardSnapshots[_borrower].CollRewards[token] < L_Coll[token]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Gets the entire debt and collateral of a borrower
     * @param _borrower The address of the Trove
     * @return debt, collsTokens, collsAmounts, pendingSTARDebtReward, pendingRewardTokens, pendingRewardAmouns
     */
    function getEntireDebtAndColls(address _borrower)
        external
        view
        override
        returns (
            uint256,
            address[] memory,
            uint256[] memory,
            uint256,
            address[] memory,
            uint256[] memory
        )
    {
        uint256 debt = Troves[_borrower].debt;
        newColls memory colls = Troves[_borrower].colls;

        uint256 pendingSTARDebtReward = getPendingSTARDebtReward(_borrower);
        newColls memory pendingCollReward = _getPendingCollRewards(_borrower);

        debt = debt.add(pendingSTARDebtReward);

        // add in pending rewards to colls
        colls = _sumColls(colls, pendingCollReward);

        return (
            debt,
            colls.tokens,
            colls.amounts,
            pendingSTARDebtReward,
            pendingCollReward.tokens,
            pendingCollReward.amounts
        );
    }

    /**
     * @notice Borrower operations remove stake sum
     * @param _borrower The address of the Trove
     */
    function removeStakeAndCloseTrove(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        _removeStake(_borrower);
        _closeTrove(_borrower, Status.closedByOwner);
    }

    /**
     * @notice Remove borrower's stake from the totalStakes sum, and set their stake to 0
     * @param _borrower The address of the Trove
     */
    function _removeStake(address _borrower) internal {
        address[] memory borrowerColls = Troves[_borrower].colls.tokens;
        uint256 borrowerCollsLen = borrowerColls.length;
        for (uint256 i; i < borrowerCollsLen; ++i) {
            address coll = borrowerColls[i];
            uint256 stake = Troves[_borrower].stakes[coll];
            totalStakes[coll] = totalStakes[coll].sub(stake);
            Troves[_borrower].stakes[coll] = 0;
        }
    }

    function _updateStakeAndTotalStakes(address _borrower) internal {
        uint256 troveOwnerLen = Troves[_borrower].colls.tokens.length;
        for (uint256 i; i < troveOwnerLen; ++i) {
            address token = Troves[_borrower].colls.tokens[i];
            uint256 amount = Troves[_borrower].colls.amounts[i];

            uint256 newStake = _computeNewStake(token, amount);
            uint256 oldStake = Troves[_borrower].stakes[token];

            Troves[_borrower].stakes[token] = newStake;
            totalStakes[token] = totalStakes[token].sub(oldStake).add(newStake);

            emit TotalStakesUpdated(token, totalStakes[token]);
        }
    }

    /**
     * @notice Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
     * @dev The following assert() holds true because:
        - The system always contains >= 1 trove
        - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
        rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
     * @param token The token
     * @param _coll The collateral 
     * @return The New stake
     */
    function _computeNewStake(address token, uint256 _coll)
        internal
        view
        returns (uint256)
    {
        uint256 stake;
        if (totalCollateralSnapshot[token] == 0) {
            stake = _coll;
        } else {
            require(totalStakesSnapshot[token] != 0, "TM:stake=0");
            stake = _coll.mul(totalStakesSnapshot[token]).div(
                totalCollateralSnapshot[token]
            );
        }
        return stake;
    }

    /**
     * @notice Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
        error correction, to keep the cumulative error low in the running totals L_Coll and L_STARDebt:
     * @dev
        This function is only called in batchLiquidateTroves() in TroveManagerLiquidations.
        Debt that cannot be offset from the stability pool has to be redistributed to other troves.
        The collateral that backs this debt also gets redistributed to these troves.


        1) Form numerators which compensate for the floor division errors that occurred the last time this
        2) Calculate "per-unit-staked" ratios.
        3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        4) Store these errors for use in the next correction when this function is called.
        5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
     */
    function redistributeDebtAndColl(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _debt,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsTML();
        uint256 tokensLen = _tokens.length;
        _revertLenInput(tokensLen == _amounts.length);

        if (_debt == 0) {
            return;
        }

        uint256 totalCollateralVC = _getVC(_tokens, _amounts); // total collateral value in VC terms
        uint256[] memory collateralsVC = controller.getValuesVCIndividual(
            _tokens,
            _amounts
        ); // collaterals in VC terms
        for (uint256 i; i < tokensLen; ++i) {
            address token = _tokens[i];

            // Prorate debt per collateral by dividing each collateral value by cumulative collateral value and multiply by outstanding debt
            uint256 proratedDebt = collateralsVC[i].mul(_debt).div(
                totalCollateralVC
            );
            uint256 debtNumerator = proratedDebt.mul(DECIMAL_PRECISION).add(
                lastSTARDebtError_Redistribution[token]
            );

            if (totalStakes[token] != 0) {
                _updateStakesOnRedistribution(
                    token,
                    _amounts[i],
                    debtNumerator,
                    true
                );
            } else {
                // no other troves in the system with this collateral.
                // In this case we distribute the debt across
                // the absorptionCollaterals according to absorptionWeight

                (
                    address[] memory absColls,
                    uint[] memory absWeights
                ) = controller.getAbsorptionCollParams();
                uint unAllocatedAbsWeight;

                for (uint j; j < absColls.length; ++j) {
                    // Also can't redistribute to this token, save it for later.
                    if (totalStakes[absColls[j]] == 0) {
                        unAllocatedAbsWeight += absWeights[j];
                        absWeights[j] = 0;
                    }
                }

                // Should not be empty, and unallocated should not be all weight.
                require(
                    absColls.length != 0 && unAllocatedAbsWeight != 1e18,
                    "TM:absCollsInvalid"
                );

                for (uint j; j < absColls.length; ++j) {
                    // If there is no debt to be distributed for this abs coll, continue to next
                    if (absWeights[j] == 0) {
                        continue;
                    }
                    address absToken = absColls[j];
                    // First found eligible redistribute-able token, so give unallocated weight here.
                    if (unAllocatedAbsWeight != 0) {
                        absWeights[j] += unAllocatedAbsWeight;
                        unAllocatedAbsWeight = 0;
                    }
                    debtNumerator = proratedDebt.mul(absWeights[j]).add(
                        lastSTARDebtError_Redistribution[absToken]
                    );

                    _updateStakesOnRedistribution(
                        absToken,
                        0,
                        debtNumerator,
                        false
                    );
                }

                // send the collateral that can't be redistributed to anyone, to the claimAddress
                activePool.sendSingleCollateral(
                    controller.getClaimAddress(),
                    token,
                    _amounts[i]
                );

                // this collateral should no longer be sent from the active pool to the default pool:
                _amounts[i] = 0;
            }
        }

        // Transfer coll and debt from ActivePool to DefaultPool
        _activePool.decreaseSTARDebt(_debt);
        _defaultPool.increaseSTARDebt(_debt);
        _activePool.sendCollaterals(address(_defaultPool), _tokens, _amounts);
    }

    function _updateStakesOnRedistribution(
        address _token,
        uint256 _amount,
        uint256 _debtNumerator,
        bool _updateColl
    ) internal {
        uint256 dec = IERC20(_token).decimals();
        uint256 thisTotalStakes = totalStakes[_token];
        uint adjustedTotalStakes;
        if (dec > 18) {
            adjustedTotalStakes = thisTotalStakes.div(10**(dec - 18));
        } else {
            adjustedTotalStakes = thisTotalStakes.mul(10**(18 - dec));
        }

        uint256 STARDebtRewardPerUnitStaked = _debtNumerator.div(
            adjustedTotalStakes
        );

        lastSTARDebtError_Redistribution[_token] = _debtNumerator.sub(
            STARDebtRewardPerUnitStaked.mul(adjustedTotalStakes)
        );

        L_STARDebt[_token] = L_STARDebt[_token].add(
            STARDebtRewardPerUnitStaked
        );

        if (_updateColl) {
            uint256 CollNumerator = _amount.mul(DECIMAL_PRECISION).add(
                lastCollError_Redistribution[_token]
            );

            uint256 CollRewardPerUnitStaked = CollNumerator.div(
                adjustedTotalStakes
            );

            lastCollError_Redistribution[_token] = CollNumerator.sub(
                CollRewardPerUnitStaked.mul(adjustedTotalStakes)
            );

            // Add per-unit-staked terms to the running totals
            L_Coll[_token] = L_Coll[_token].add(CollRewardPerUnitStaked);
        }

        emit LTermsUpdated(_token, L_Coll[_token], L_STARDebt[_token]);
    }

    /**
     * @notice Closes trove by liquidation
     * @param _borrower The address of the Trove
     */
    function closeTroveLiquidation(address _borrower) external override {
        _requireCallerIsTML();
        return _closeTrove(_borrower, Status.closedByLiquidation);
    }

    /**
     * @notice Closes trove by redemption
     * @param _borrower The address of the Trove
     */
    function closeTroveRedemption(address _borrower) external override {
        _requireCallerIsTMR();
        return _closeTrove(_borrower, Status.closedByRedemption);
    }

    function _closeTrove(address _borrower, Status closedStatus) internal {
        require(
            closedStatus != Status.nonExistent && closedStatus != Status.active,
            "TM:invalid trove"
        );

        // Remove from UnderCollateralizedTroves if it was there.
        _updateUnderCollateralizedTrove(_borrower, false);

        uint256 TroveOwnersArrayLength = TroveOwners.length;
        _requireMoreThanOneTroveInSystem(TroveOwnersArrayLength);
        newColls memory emptyColls;

        // Zero all collaterals owned by the user and snapshots
        address[] memory allColls = Troves[_borrower].colls.tokens;
        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address thisAllColls = allColls[i];
            rewardSnapshots[_borrower].CollRewards[thisAllColls] = 0;
            rewardSnapshots[_borrower].STARDebts[thisAllColls] = 0;
        }

        Troves[_borrower].status = closedStatus;
        Troves[_borrower].colls = emptyColls;
        Troves[_borrower].debt = 0;

        _removeTroveOwner(_borrower, TroveOwnersArrayLength);
        sortedTroves.remove(_borrower);
    }

    /**
     * @notice Updates snapshots of system total stakes and total collateral,
     *  excluding a given collateral remainder from the calculation. Used in a liquidation sequence.
     * @dev The calculation excludes a portion of collateral that is in the ActivePool:
        the total Coll gas compensation from the liquidation sequence
        The Coll as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
     */
    function updateSystemSnapshots_excludeCollRemainder(
        IActivePool _activePool,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsTML();
        // Collect Active pool + Default pool balances of the passed in tokens and update snapshots accordingly
        uint256[] memory activeAndLiquidatedColl = _activePool
            .getAmountsSubsetSystem(_tokens);
        for (uint256 i; i < _tokens.length; ++i) {
            address token = _tokens[i];
            totalStakesSnapshot[token] = totalStakes[token];
            totalCollateralSnapshot[token] = activeAndLiquidatedColl[i].sub(
                _amounts[i]
            );
        }
        emit SystemSnapshotsUpdated(block.timestamp);
    }

    /**
     * @notice Push the owner's address to the Trove owners list, and record the corresponding array index on the Trove struct
     * @dev Max array size is 2**128 - 1, i.e. ~3e30 troves. No risk of overflow, since troves have minimum STAR
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 STAR dwarfs the value of all wealth in the world ( which is < 1e15 USD).
     * @param _borrower The address of the Trove
     * @return index Push Trove Owner to array
     */
    function addTroveOwnerToArray(address _borrower)
        external
        override
        returns (uint256)
    {
        _requireCallerIsBorrowerOperations();
        TroveOwners.push(_borrower);

        // Record the index of the new Troveowner on their Trove struct
        uint128 index = uint128(TroveOwners.length.sub(1));
        Troves[_borrower].arrayIndex = index;
        return uint256(index);
    }

    /**
     * @notice Remove a Trove owner from the TroveOwners array, not preserving array order.
     * @dev Removing owner 'B' does the following: [A B C D E] => [A E C D], and updates E's Trove struct to point to its new array index.
     * @param _borrower THe address of the Trove
     */
    function _removeTroveOwner(
        address _borrower,
        uint256 TroveOwnersArrayLength
    ) internal {
        Status troveStatus = Troves[_borrower].status;
        // It’s set in caller function `_closeTrove`
        require(
            troveStatus != Status.nonExistent && troveStatus != Status.active,
            "TM:invalid trove"
        );

        uint128 index = Troves[_borrower].arrayIndex;
        uint256 length = TroveOwnersArrayLength;
        uint256 idxLast = length.sub(1);

        require(index <= idxLast, "TM:index>last");

        address addressToMove = TroveOwners[idxLast];

        TroveOwners[index] = addressToMove;
        Troves[addressToMove].arrayIndex = index;
        emit TroveIndexUpdated(addressToMove, index);

        TroveOwners.pop();
    }

    // --- Recovery Mode and TCR functions ---

    // @notice Helper function for calculating TCR of the system
    function getTCR() external view override returns (uint256) {
        return _getTCR();
    }

    // @notice Helper function for checking recovery mode
    // @return True if in recovery mode, false otherwise
    function checkRecoveryMode() external view override returns (bool) {
        return _checkRecoveryMode();
    }

    // --- Redemption fee functions ---

    /**
     * @notice Updates base rate via redemption, called from TMR
     * @param newBaseRate The new base rate
     */
    function updateBaseRate(uint256 newBaseRate) external override {
        _requireCallerIsTMR();
        // After redemption, new base rate is always > 0
        require(newBaseRate != 0, "TM:BR!=0");
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);
        _updateLastFeeOpTime();
    }

    function getRedemptionRate() external view override returns (uint256) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay()
        public
        view
        override
        returns (uint256)
    {
        return _calcRedemptionRate(calcDecayedBaseRate());
    }

    function _calcRedemptionRate(uint256 _baseRate)
        internal
        pure
        returns (uint256)
    {
        return
            PreonMath._min(
                REDEMPTION_FEE_FLOOR.add(_baseRate),
                DECIMAL_PRECISION // cap at a maximum of 100%
            );
    }

    function getRedemptionFeeWithDecay(uint256 _STARRedeemed)
        external
        view
        override
        returns (uint256)
    {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _STARRedeemed);
    }

    function _calcRedemptionFee(uint256 _redemptionRate, uint256 _STARRedeemed)
        internal
        pure
        returns (uint256)
    {
        uint256 redemptionFee = _redemptionRate.mul(_STARRedeemed).div(
            DECIMAL_PRECISION
        );
        require(redemptionFee < _STARRedeemed, "TM:RedempFee>colls");
        return redemptionFee;
    }

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint256) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay()
        public
        view
        override
        returns (uint256)
    {
        return _calcBorrowingRate(calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint256 _baseRate)
        internal
        pure
        returns (uint256)
    {
        return
            PreonMath._min(
                BORROWING_FEE_FLOOR.add(_baseRate),
                MAX_BORROWING_FEE
            );
    }

    function getBorrowingFee(uint256 _STARDebt)
        external
        view
        override
        returns (uint256)
    {
        return _calcBorrowingFee(getBorrowingRate(), _STARDebt);
    }

    function getBorrowingFeeWithDecay(uint256 _STARDebt)
        external
        view
        override
        returns (uint256)
    {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _STARDebt);
    }

    function _calcBorrowingFee(uint256 _borrowingRate, uint256 _STARDebt)
        internal
        pure
        returns (uint256)
    {
        return _borrowingRate.mul(_STARDebt).div(DECIMAL_PRECISION);
    }

    // @notice Updates the baseRate state variable based on time elapsed since the last redemption
    // or STAR borrowing operation
    function decayBaseRateFromBorrowingAndCalculateFee(uint256 _STARDebt)
        external
        override
        returns (uint256)
    {
        _requireCallerIsBorrowerOperations();

        uint256 decayedBaseRate = calcDecayedBaseRate();
        require(decayedBaseRate <= DECIMAL_PRECISION, "TM:BR>1e18"); // The baseRate can decay to 0

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();
        return _calcBorrowingFee(getBorrowingRate(), _STARDebt);
    }

    // --- Internal fee functions ---

    // @notice Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint256 timePassed = block.timestamp.sub(lastFeeOperationTime);

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function calcDecayedBaseRate() public view override returns (uint256) {
        uint256 minutesPassed = _minutesPassedSinceLastFeeOp();
        uint256 decayFactor = PreonMath._decPow(
            MINUTE_DECAY_FACTOR,
            minutesPassed
        );

        return baseRate.mul(decayFactor).div(DECIMAL_PRECISION);
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint256) {
        return
            (block.timestamp.sub(lastFeeOperationTime)).div(
                SECONDS_IN_ONE_MINUTE
            );
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        if (msg.sender != borrowerOperationsAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBOorTMR() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != address(troveManagerRedemptions)
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsTMR() internal view {
        if (msg.sender != address(troveManagerRedemptions)) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsTML() internal view {
        if (msg.sender != address(troveManagerLiquidations)) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsTMLorTMR() internal view {
        if (
            msg.sender != address(troveManagerLiquidations) &&
            msg.sender != address(troveManagerRedemptions)
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireTroveIsActive(address _borrower) internal view {
        require(Troves[_borrower].status == Status.active, "TM:trove inactive");
    }

    function _requireMoreThanOneTroveInSystem(uint256 TroveOwnersArrayLength)
        internal
        pure
    {
        require(TroveOwnersArrayLength > 1, "TM:last trove");
    }

    function _updateUnderCollateralizedTrove(
        address _borrower,
        bool _isUnderCollateralized
    ) internal {
        sortedTroves.updateUnderCollateralizedTrove(
            _borrower,
            _isUnderCollateralized
        );
    }

    // --- Trove property getters ---

    function getTroveStatus(address _borrower)
        external
        view
        override
        returns (uint256)
    {
        return uint256(Troves[_borrower].status);
    }

    function isTroveActive(address _borrower)
        external
        view
        override
        returns (bool)
    {
        return Troves[_borrower].status == Status.active;
    }

    function getTroveStake(address _borrower, address _token)
        external
        view
        override
        returns (uint256)
    {
        return Troves[_borrower].stakes[_token];
    }

    function getTroveDebt(address _borrower)
        external
        view
        override
        returns (uint256)
    {
        return Troves[_borrower].debt;
    }

    // -- Trove Manager State Variable Getters --

    function getTotalStake(address _token)
        external
        view
        override
        returns (uint256)
    {
        return totalStakes[_token];
    }

    function getL_Coll(address _token)
        external
        view
        override
        returns (uint256)
    {
        return L_Coll[_token];
    }

    function getL_STAR(address _token)
        external
        view
        override
        returns (uint256)
    {
        return L_STARDebt[_token];
    }

    function getRewardSnapshotColl(address _borrower, address _token)
        external
        view
        override
        returns (uint256)
    {
        return rewardSnapshots[_borrower].CollRewards[_token];
    }

    function getRewardSnapshotSTAR(address _borrower, address _token)
        external
        view
        override
        returns (uint256)
    {
        return rewardSnapshots[_borrower].STARDebts[_token];
    }

    /**
     * @notice recomputes VC given current prices and returns it
     * @param _borrower The address of the Trove
     * @return The Trove's VC
     */
    function getTroveVC(address _borrower)
        external
        view
        override
        returns (uint256)
    {
        return _getVCColls(Troves[_borrower].colls);
    }

    function getTroveColls(address _borrower)
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        return (
            Troves[_borrower].colls.tokens,
            Troves[_borrower].colls.amounts
        );
    }

    function getCurrentTroveState(address _borrower)
        external
        view
        override
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        return _getCurrentTroveState(_borrower);
    }

    // --- Called by TroveManagerRedemptions Only ---

    function updateTroveDebt(address _borrower, uint256 debt)
        external
        override
    {
        _requireCallerIsTMR();
        Troves[_borrower].debt = debt;
    }

    function removeStake(address _borrower) external override {
        _requireCallerIsTMLorTMR();
        _removeStake(_borrower);
    }

    // --- Trove property setters, called by BorrowerOperations ---

    function setTroveStatus(address _borrower, uint256 _num) external override {
        _requireCallerIsBorrowerOperations();
        Troves[_borrower].status = Status(_num);
    }

    /**
     * @notice Update borrower's stake based on their latest collateral value. Also update their
     * trove state with new tokens and amounts. Called by BO or TMR
     * @dev computed at time function is called based on current price of collateral
     * @param _borrower The address of the Trove
     * @param _tokens The array of tokens to set to the borrower's trove
     * @param _amounts The array of amounts to set to the borrower's trove
     */
    function updateTroveCollAndStakeAndTotalStakes(
        address _borrower,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsBOorTMR();
        _revertLenInput(_tokens.length == _amounts.length);
        (Troves[_borrower].colls.tokens, Troves[_borrower].colls.amounts) = (
            _tokens,
            _amounts
        );
        _updateStakeAndTotalStakes(_borrower);
    }

    function increaseTroveDebt(address _borrower, uint256 _debtIncrease)
        external
        override
        returns (uint256)
    {
        _requireCallerIsBorrowerOperations();
        uint256 newDebt = Troves[_borrower].debt.add(_debtIncrease);
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseTroveDebt(address _borrower, uint256 _debtDecrease)
        external
        override
        returns (uint256)
    {
        _requireCallerIsBorrowerOperations();
        uint256 newDebt = Troves[_borrower].debt.sub(_debtDecrease);
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }

    function _revertLenInput(bool _lenInput) internal pure {
        require(_lenInput, "TM:Len input");
    }

    // --- System param getter functions ---

    function getMCR() external view override returns (uint256) {
        return MCR;
    }

    function getCCR() external view override returns (uint256) {
        return CCR;
    }

    function getSTAR_GAS_COMPENSATION()
        external
        view
        override
        returns (uint256)
    {
        return STAR_GAS_COMPENSATION;
    }

    function getMIN_NET_DEBT() external view override returns (uint256) {
        return MIN_NET_DEBT;
    }

    function getBORROWING_FEE_FLOOR() external view override returns (uint256) {
        return BORROWING_FEE_FLOOR;
    }

    function getREDEMPTION_FEE_FLOOR()
        external
        view
        override
        returns (uint256)
    {
        return REDEMPTION_FEE_FLOOR;
    }
}