// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IWhitelist.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IZeroEx.sol";

contract OrderFiller is Initializable {
    address public whitelistContractAddress;
    address public exchangeProxyAddress;

    event ERC20Deposited(address tokenAddress, uint256 amount);
    event ERC20Withdrawn(address tokenAddress, uint256 amount);

    event OrderFilled(
        // orderReferenceId is the order id from the database
        uint64[] makerOrderReferenceId,
        uint64 takerOrderReferenceId,
        uint256[] makerTokenFilledAmount,
        uint256 takerTokenFilledAmount,
        address makerTokenAddress,
        address takerTokenAddress,
        address takerAddress,
        address[] makerAddress
    );

    modifier onlyAdmin() {
        require(IWhitelist(whitelistContractAddress).hasRoleAdmin(msg.sender), "Not an admin");
        _;
    }

    function initialize(address _whitelistContractAddress, address _exchangeProxyAddress) public initializer {
        whitelistContractAddress = _whitelistContractAddress;
        exchangeProxyAddress = _exchangeProxyAddress;
    }

    function updateExchangeProxy(address _newExchangeProxy) public onlyAdmin {
        exchangeProxyAddress = _newExchangeProxy;
    }

    function updateWhitelistContract(address _newWhitelistContract) public onlyAdmin {
        whitelistContractAddress = _newWhitelistContract;
    }

    function depositERC20(address _tokenAddress, uint256 _amount) public {
        IERC20 _ierc20 = IERC20(_tokenAddress);
        _ierc20.transferFrom(msg.sender, address(this), _amount);
        emit ERC20Deposited(_tokenAddress, _amount);
    }

    function withdrawERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) public onlyAdmin {
        IERC20 _ierc20 = IERC20(_tokenAddress);
        _ierc20.transfer(_recipient, _amount);
        emit ERC20Withdrawn(_tokenAddress, _amount);
    }

    function fillBuyOrder(
        // taker has stablecoin, execute maker orders first
        uint64[] memory makerOrderReferenceIds,
        uint64 takerOrderReferenceId,
        LimitOrder[] memory makerOrders,
        Signature[] memory makerSignatures,
        uint128[] memory makerTakerTokenFillAmounts,
        LimitOrder memory takerOrder,
        Signature memory takerSignature,
        uint128 takerTakerTokenFillAmount,
        uint256 totalMakerTokensToFill
    ) public onlyAdmin returns (uint128[] memory, uint128) {
        //require(
        //    IERC20(_takerToken).balanceOf(address(this)) >= nonTalentTokensTotal,
        //    "not enough tokens in contract to fill orders"
        //);

        uint128 makerOrdersToFill = uint128(makerTakerTokenFillAmounts.length);
        uint128[] memory MakerTokenAmountFilled = new uint128[](makerOrdersToFill);

        // Fill stablecoin orders first
        IERC20(takerOrder.takerToken).approve(exchangeProxyAddress, totalMakerTokensToFill);
        // For every order submitted
        for (uint256 i = 0; i < makerOrdersToFill; i++) {
            // call exchange proxy and fill orders
            (uint128 _takerFill, uint128 _makerFill) = IZeroEx(exchangeProxyAddress).fillLimitOrder(
                makerOrders[i],
                makerSignatures[i],
                makerTakerTokenFillAmounts[i]
            );
            require((_takerFill != 0) && (_makerFill != 0));
            MakerTokenAmountFilled[i] = _makerFill;
        }

        // Fill talent token orders
        IERC20(takerOrder.makerToken).approve(exchangeProxyAddress, takerOrder.makerAmount);
        // For every order submitted
        (uint128 _takerFill, uint128 _makerFill) = IZeroEx(exchangeProxyAddress).fillLimitOrder(
            takerOrder,
            takerSignature,
            takerTakerTokenFillAmount
        );
        require((_takerFill != 0) && (_makerFill != 0));
        //IERC20(takerAddress).approve(taker, takerTakerTokenFillAmount);
        //IERC20(takerAddress).transfer(taker, takerTakerTokenFillAmount);

        return (MakerTokenAmountFilled, _takerFill);
    }

    /*

    function fillBuyOrder(
        string[] memory makerOrders,
        string[] memory makerSignatures,
        uint128[] memory makerTakerTokenFillAmounts,
        string memory takerOrder,
        string memory takerSignature,
        uint128 takerTakerTokenFillAmount, 
        uint256 talentTokensTotal,
        uint256 nonTalentTokensTotal,
        address taker,
        address _makerToken,
        address _takerToken,
        bool buy
    ) public onlyAdmin returns (uint128[] memory, uint128[] memory) {
        IZeroEx exchangeProxy = IZeroEx(exchangeProxyAddress);
        IERC20 takerToken;
        IERC20 makerToken;

        if (buy) {
            takerToken = IERC20(_takerToken);
            makerToken = IERC20(_makerToken);
        } else {
            makerToken = IERC20(_takerToken);
            takerToken = IERC20(_makerToken);
        }

        require(
            takerToken.balanceOf(address(this)) >= nonTalentTokensTotal,
            "not enough tokens in contract to fill orders"
        );

        uint128 makerOrdersToFill = uint128(makerTakerTokenFillAmounts.length);
        uint128 takerOrdersToFill = uint128(takerTakerTokenFillAmounts.length);
        uint128[] memory makerMakerTokenAmountFilled = new uint128[](makerOrdersToFill);
        uint128[] memory makerTakerTokenAmountFilled = new uint128[](takerOrdersToFill);

        // Fill stablecoin orders first
        takerToken.approve(exchangeProxyAddress, nonTalentTokensTotal);
        // For every order submitted
        for (uint256 i = 0; i < takerOrdersToFill; i++) {
            // call exchange proxy and fill orders
            (uint128 _takerFill, uint128 _makerFill) = exchangeProxy.fillLimitOrder(
                takerOrders[i],
                takerSignatures[i],
                takerTakerTokenFillAmounts[i]
            );
            require((_takerFill != 0) && (_makerFill != 0));
            makerTakerTokenAmountFilled[i] = _makerFill;
        }

         // Fill talent token orders
        makerToken.approve(exchangeProxyAddress, talentTokensTotal);
        // For every order submitted
        for (uint256 i = 0; i < makerOrdersToFill; i++) {
            // call exchange proxy and fill orders
            (uint128 _takerFill, uint128 _makerFill) = exchangeProxy.fillLimitOrder(
                makerOrders[i],
                makerSignatures[i],
                makerTakerTokenFillAmounts[i]
            );
            require((_takerFill != 0) && (_makerFill != 0));
            makerMakerTokenAmountFilled[i] = _makerFill;
        }
        return (makerMakerTokenAmountFilled, makerTakerTokenAmountFilled);
    }
*/
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IWhitelist {
    function hasRoleUnderwriter(address _account) external view returns (bool);

    function hasRoleInvestor(address _account) external view returns (bool);

    function hasRoleAdmin(address _account) external view returns (bool);

    function hasRoleMinter(address _account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";

enum SignatureType {
    ILLEGAL,
    INVALID,
    EIP712,
    ETHSIGN,
    PRESIGNED
}

/// @dev Encoded EC signature.
struct Signature {
    // How to validate the signature.
    SignatureType signatureType;
    // EC Signature data.
    uint8 v;
    // EC Signature data.
    bytes32 r;
    // EC Signature data.
    bytes32 s;
}

struct LimitOrder {
    IERC20 makerToken;
    IERC20 takerToken;
    uint128 makerAmount;
    uint128 takerAmount;
    uint128 takerTokenFeeAmount;
    address maker;
    address taker;
    address sender;
    address feeRecipient;
    bytes32 pool;
    uint64 expiry;
    uint256 salt;
}

interface IZeroEx {
    function fillLimitOrder(
        LimitOrder memory order,
        Signature memory signature,
        uint128 takerTokenFillAmount
    ) external payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);
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