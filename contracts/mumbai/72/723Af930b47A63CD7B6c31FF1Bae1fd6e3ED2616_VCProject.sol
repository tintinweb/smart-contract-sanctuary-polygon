// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCProject {
    error ProjOnlyStarterError();
    error ProjBalanceIsZeroError();
    error ProjCampaignNotActiveError();
    error ProjERC20TransferError();
    error ProjZeroAmountToWithdrawError();
    error ProjCannotTransferUnclaimedFundsError();
    error ProjCampaignNotNotFundedError();
    error ProjCampaignNotFundedError();
    error ProjUserCannotMintError();
    error ProjResultsCannotBePublishedError();
    error ProjCampaignCannotStartError();
    error ProjBackerBalanceIsZeroError();
    error ProjAlreadyClosedError();
    error ProjBalanceIsNotZeroError();
    error ProjLastCampaignNotClosedError();

    struct CampaignData {
        uint256 target;
        uint256 softTarget;
        uint256 startTime;
        uint256 endTime;
        uint256 backersDeadline;
        uint256 raisedAmount;
        bool resultsPublished;
    }

    enum CampaignStatus {
        NOTCREATED,
        ACTIVE,
        NOTFUNDED,
        FUNDED,
        SUCCEEDED,
        DEFEATED
    }

    /**
     * @dev The initialization function required to init a new VCProject contract that VCStarter deploys using
     * Clones.sol (no constructor is invoked).
     *
     * @notice This function can be invoked at most once because uses the {initializer} modifier.
     *
     * @param starter The VCStarter contract address.
     * @param pool The VCPool contract address.
     * @param lab The address of the laboratory/researcher who owns this project.
     * @param poolFeeBps Pool fee in basis points. Any project/campaign donation is subject to a fee which is
     * transferred to VCPool.
     * @param currency The protocol {_currency} ERC20 contract address, which is used for all donations.
     * Donations in any other ERC20 currecy or of any other type are not allowed.
     */
    function init(
        address starter,
        address pool,
        address lab,
        uint256 poolFeeBps,
        IERC20 currency
    ) external;

    /**
     * @dev Allows to fund the project directly, i.e. the contribution received is not linked to any campaign.
     * The donation is made in the protocol ERC20 {_currency}, which is set at the time of deployment of the
     * VCProject contract.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param _amount The amount of the donation.
     */
    function fundProject(uint256 _amount) external;

    /**
     * @dev Allows the lab owner to close the project. A closed project cannot start new campaigns nor receive
     * new contributions.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @notice Only VCProjects with a zero balance (the lab ownwer must have previously withdrawn all funds) and
     * non-active campaigns can be closed.
     */
    function closeProject() external;

    /**
     * @dev Allows the lab owner of the project to start a new campaign.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @param _target The maximum amount of ERC20 {_currency} expected to be raised.
     * @param _softTarget The minimum amount of ERC20 {_currency} expected to be raised.
     * @param _startTime The starting date of the campaign in seconds since the epoch.
     * @param _endTime The end date of the campaign in seconds since the epoch.
     * @param _backersDeadline The deadline date (in seconds since the epoch) for backers to withdraw funds
     * in case the campaign turns out to be NOT FUNDED. After that date, unclaimed funds can only be transferred
     * to VCPool and backers can mint a PoCNFT for their contributions.
     *
     * @return currentId The Id of the started campaign.
     */
    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256 currentId);

    /**
     * @dev Allows the lab owner of the project to publish the results of their research achievements
     * related to their latest SUCCEEDED campaign.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @notice Lab owner must do this before starting a new campaign or closing the project.
     */
    function publishCampaignResults() external;

    /**
     * @dev Allows a user to fund the last running campaign, only when it is ACTIVE.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param _user The address of the user who makes the dontation.
     * @param _amount The amount of ERC20 {_currency} donated by the user.
     */
    function fundCampaign(address _user, uint256 _amount) external;

    /**
     * @dev Checks if {_user} can mint a PoCNFT for their contribution to a given campaign, and also
     * registers the mintage to forbid a user from claiming multiple PoCNFTs for the same contribution.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the function {backerMintPoCNft} of
     * VCStarter.
     *
     * @notice Two PoCNFTs are minted: one for the contribution to the Project and the other one for
     * the contribution to VCPool (fee).
     *
     * @param _campaignId The campaign Id for which {_user} claims the PoCNFTs.
     * @param _user The address of the user who claims the PoCNFTs.
     *
     * @return poolAmount The amount of the donation corresponding to VCPool.
     * @return starterAmount The amount of the donation corresponding to the Project.
     */
    function validateMint(uint256 _campaignId, address _user)
        external
        returns (uint256 poolAmount, uint256 starterAmount);

    /**
     * @dev Allows a user to withdraw funds previously contributed to the last running campaign, only when NOT
     * FUNDED.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @param _user The address of the user who is withdrawing funds.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return backerBalance The amount of ERC20 {_currency} donated by the user.
     * @return statusDefeated It is set to true only when the campaign balance reaches zero, indicating that all
     * backers have already withdrawn their funds.
     */
    function backerWithdrawDefeated(address _user)
        external
        returns (
            uint256 currentCampaignId,
            uint256 backerBalance,
            bool statusDefeated
        );

    /**
     * @dev Allows the lab owner of the project to withdraw the raised funds of the last running campaign, only
     * when FUNDED.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return withdrawAmount The withdrawn amount (raised funds minus pool fee).
     * @return poolAmount The fee amount transferred to VCPool.
     */
    function labCampaignWithdraw()
        external
        returns (
            uint256 currentCampaignId,
            uint256 withdrawAmount,
            uint256 poolAmount
        );

    /**
     * @dev Allows the lab owner of the project to withdraw funds raised from direct contributions.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @return amountToWithdraw The amount withdrawn, which corresponds to the total available project balance
     * excluding the balance raised from campaigns.
     */
    function labProjectWithdraw() external returns (uint256 amountToWithdraw);

    /**
     * @dev Users can send any ERC20 asset to this contract simply by interacting with the 'transfer' method of
     * the corresponding ERC20 contract. The funds received in this way do not count for the Project balance,
     * and are allocated to VCPool. This function allows any user to transfer these funds to VCPool.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param currency The ERC20 currency of the funds to be transferred to VCPool.
     *
     * @return amountAvailable The transferred amount of ERC20 {currency}.
     */
    function withdrawToPool(IERC20 currency) external returns (uint256 amountAvailable);

    /**
     * @dev Allows any user to transfer unclaimed campaign funds to VCPool after {_backersDeadline} date, only
     * when NOT FUNDED.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return amountToPool The amount of ERC20 {currency} transferred to VCPool.
     */
    function transferUnclaimedFunds() external returns (uint256 currentCampaignId, uint256 amountToPool);

    /**
     * @dev Returns the total number of campaigns created by this Project.
     *
     * @return numbOfCampaigns
     */
    function getNumberOfCampaigns() external view returns (uint256);

    /**
     * @dev Returns the current campaign status of any given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return currentStatus
     */
    function getCampaignStatus(uint256 _campaignId) external view returns (CampaignStatus currentStatus);

    /**
     * @dev Determines if the {_amount} contributed to the last running campaign exceeds the amount needed to
     * reach the campaign's target. In that case, the additional funds are allocated to VCPool.
     *
     * @notice Only VCStarter can invoke this function.
     *
     * @param _amount The amount of ERC20 {_currency} contributed by the backer.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return amountToCampaign The portion of the {_amount} contributed that is allocated to the campaign.
     * @return amountToPool The (possible) additional funds allocated to VCPool.
     * @return isFunded This boolean parameter is set to true only when the amount donated exceeds or equals the
     *  amount needed to reach the campaign's target, indicating that the campaign is now FUNDED.
     */
    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        );

    /**
     * @dev Returns the project status.
     *
     * @return prjctStatus True = active, false = closed.
     */
    function projectStatus() external view returns (bool prjctStatus);

    /**
     * @dev Returns the balance of the last created campaign.
     *
     * @notice Previous campaigns allways have a zero balance, because a laboratory is not allowed to start a new
     * campaign before withdrawing the balance of the last executed campaign.
     *
     * @return lastCampaignBal
     */
    function lastCampaignBalance() external view returns (uint256 lastCampaignBal);

    /**
     * @dev Returns the portion of project balance corresponding to direct contributions not linked to any campaign.
     *
     * @return outsideCampaignsBal
     */
    function outsideCampaignsBalance() external view returns (uint256 outsideCampaignsBal);

    /**
     * @dev Gives the raised amount of ERC20 {_currency} in a given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return campaignRaisedAmnt
     */
    function campaignRaisedAmount(uint256 _campaignId) external view returns (uint256 campaignRaisedAmnt);

    /**
     * @dev Returns true only when the lab that owns the project has already published the results of their
     * research achievements related to a given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return campaignResultsPub
     */
    function campaignResultsPublished(uint256 _campaignId) external view returns (bool campaignResultsPub);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCProject.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract VCProject is IVCProject, Initializable {
    address _starter;
    address _pool;
    address _lab;
    IERC20 _currency;
    bool _projectStatus;

    uint256 _poolFeeBps;
    uint256 constant _FEE_DENOMINATOR = 10_000;

    // Campaigns' info
    uint256 _numberOfCampaigns;
    mapping(uint256 => CampaignData) _campaigns;
    mapping(uint256 => mapping(address => uint256)) _backers;

    // Project balances: increase after funding and decrease after deposit
    uint256 _lastCampaignBalance;
    uint256 _outsideCampaignsBalance; // balance from fundProject() and fundProjectOnBehalf()

    constructor() {}

    function init(
        address starter,
        address pool,
        address lab,
        uint256 poolFeeBps,
        IERC20 currency
    ) external initializer {
        _starter = starter;
        _lab = lab;
        _pool = pool;
        _poolFeeBps = poolFeeBps;
        _projectStatus = true;
        _currency = currency;
    }

    ///////////////////////
    // PROJECT FUNCTIONS //
    ///////////////////////

    function fundProject(uint256 _amount) external {
        _onlyStarter();
        _outsideCampaignsBalance += _amount;
    }

    function closeProject() external {
        _onlyStarter();

        if (!_projectStatus) {
            revert ProjAlreadyClosedError();
        }
        if (_lastCampaignBalance + _outsideCampaignsBalance > 0) {
            revert ProjBalanceIsNotZeroError();
        }
        if (_numberOfCampaigns > 0) {
            uint256 lastCampaignId = _numberOfCampaigns - 1;
            CampaignStatus lastCampaignStatus = getCampaignStatus(lastCampaignId);
            bool canBeClosed = lastCampaignStatus == CampaignStatus.DEFEATED ||
                (lastCampaignStatus == CampaignStatus.SUCCEEDED && _campaigns[lastCampaignId].resultsPublished);
            if (!canBeClosed) {
                revert ProjLastCampaignNotClosedError();
            }
        }
        _projectStatus = false;
    }

    ////////////////////////
    // CAMPAIGN FUNCTIONS //
    ////////////////////////

    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256 currentId) {
        _onlyStarter();

        bool canStartCampaign = _projectStatus;
        if (_numberOfCampaigns > 0) {
            uint256 lastCampaignId = _numberOfCampaigns - 1;
            CampaignStatus lastCampaignStatus = getCampaignStatus(lastCampaignId);

            canStartCampaign =
                canStartCampaign &&
                (lastCampaignStatus == CampaignStatus.DEFEATED ||
                    (lastCampaignStatus == CampaignStatus.SUCCEEDED && _campaigns[lastCampaignId].resultsPublished));
        }

        if (!canStartCampaign) {
            revert ProjCampaignCannotStartError();
        }

        currentId = _numberOfCampaigns;
        _numberOfCampaigns++;

        _campaigns[currentId] = CampaignData(_target, _softTarget, _startTime, _endTime, _backersDeadline, 0, false);
    }

    function publishCampaignResults() external {
        _onlyStarter();

        uint256 currentCampaignId = _numberOfCampaigns == 0 ? 0 : _numberOfCampaigns - 1;

        if (
            getCampaignStatus(currentCampaignId) != CampaignStatus.SUCCEEDED ||
            _campaigns[currentCampaignId].resultsPublished
        ) {
            revert ProjResultsCannotBePublishedError();
        }

        _campaigns[currentCampaignId].resultsPublished = true;
    }

    function fundCampaign(address _user, uint256 _amount) external {
        _onlyStarter();
        uint256 currentCampaignId = _numberOfCampaigns - 1;

        _backers[currentCampaignId][_user] += _amount;
        _updateCampaignBalances(currentCampaignId, _amount, true);
    }

    function validateMint(uint256 _campaignId, address _user)
        external
        returns (uint256 poolAmount, uint256 starterAmount)
    {
        _onlyStarter();

        CampaignStatus currentCampaignStatus = getCampaignStatus(_campaignId);
        uint256 backersDeadline = _campaigns[_campaignId].backersDeadline;
        bool cannotMint = currentCampaignStatus == CampaignStatus.ACTIVE ||
            (currentCampaignStatus == CampaignStatus.NOTFUNDED && block.timestamp <= backersDeadline);

        if (cannotMint) {
            revert ProjUserCannotMintError();
        }

        uint256 backerBalance = _backers[_campaignId][_user];
        if (backerBalance == 0) {
            revert ProjBalanceIsZeroError();
        }
        _backers[_campaignId][_user] = 0;

        if (currentCampaignStatus == CampaignStatus.FUNDED || currentCampaignStatus == CampaignStatus.SUCCEEDED) {
            poolAmount = (backerBalance * _poolFeeBps) / _FEE_DENOMINATOR;
            starterAmount = backerBalance - poolAmount;
        } else {
            poolAmount = backerBalance;
        }
    }

    function backerWithdrawDefeated(address _user)
        external
        returns (
            uint256 currentCampaignId,
            uint256 backerBalance,
            bool statusDefeated
        )
    {
        _onlyStarter();

        currentCampaignId = _numberOfCampaigns == 0 ? 0 : _numberOfCampaigns - 1;

        uint256 backersDeadline = _campaigns[currentCampaignId].backersDeadline;
        bool canWithdraw = getCampaignStatus(currentCampaignId) == CampaignStatus.NOTFUNDED &&
            block.timestamp <= backersDeadline;

        if (!canWithdraw) {
            revert ProjCampaignNotNotFundedError();
        }

        backerBalance = _backers[currentCampaignId][_user];
        if (backerBalance == 0) {
            revert ProjBackerBalanceIsZeroError();
        }

        _backers[currentCampaignId][_user] = 0;
        _updateCampaignBalances(currentCampaignId, backerBalance, false);
        if (_lastCampaignBalance == 0) {
            statusDefeated = true;
        }

        if (!_currency.transfer(_user, backerBalance)) {
            revert ProjERC20TransferError();
        }
    }

    function labCampaignWithdraw()
        external
        returns (
            uint256 currentCampaignId,
            uint256 withdrawAmount,
            uint256 poolAmount
        )
    {
        _onlyStarter();

        currentCampaignId = _numberOfCampaigns == 0 ? 0 : _numberOfCampaigns - 1;

        if (getCampaignStatus(currentCampaignId) != CampaignStatus.FUNDED) {
            revert ProjCampaignNotFundedError();
        }

        uint256 totalAmount = _lastCampaignBalance;

        _updateCampaignBalances(currentCampaignId, totalAmount, false);

        poolAmount = (totalAmount * _poolFeeBps) / _FEE_DENOMINATOR;
        withdrawAmount = totalAmount - poolAmount;

        if (!_currency.transfer(_pool, poolAmount)) {
            revert ProjERC20TransferError();
        }
        if (!_currency.transfer(_lab, withdrawAmount)) {
            revert ProjERC20TransferError();
        }
    }

    function labProjectWithdraw() external returns (uint256 amountToWithdraw) {
        _onlyStarter();

        amountToWithdraw = _outsideCampaignsBalance;
        if (amountToWithdraw == 0) {
            revert ProjBalanceIsZeroError();
        }

        _outsideCampaignsBalance = 0;

        if (!_currency.transfer(_lab, amountToWithdraw)) {
            revert ProjERC20TransferError();
        }
    }

    function withdrawToPool(IERC20 currency) external returns (uint256 amountAvailable) {
        _onlyStarter();

        amountAvailable = currency.balanceOf(address(this));
        if (currency == _currency) {
            amountAvailable -= (_lastCampaignBalance + _outsideCampaignsBalance);
        }

        if (amountAvailable == 0) {
            revert ProjZeroAmountToWithdrawError();
        }
        if (!_currency.transfer(_pool, amountAvailable)) {
            revert ProjERC20TransferError();
        }
    }

    function transferUnclaimedFunds() external returns (uint256 currentCampaignId, uint256 amountToPool) {
        _onlyStarter();

        currentCampaignId = _numberOfCampaigns == 0 ? 0 : _numberOfCampaigns - 1;

        uint256 backersDeadline = _campaigns[currentCampaignId].backersDeadline;
        bool canTransfer = getCampaignStatus(currentCampaignId) == CampaignStatus.NOTFUNDED &&
            block.timestamp > backersDeadline;

        if (!canTransfer) {
            revert ProjCannotTransferUnclaimedFundsError();
        }

        amountToPool = _lastCampaignBalance;
        if (amountToPool == 0) {
            revert ProjBalanceIsZeroError();
        }

        _updateCampaignBalances(currentCampaignId, amountToPool, false);

        if (!_currency.transfer(_pool, amountToPool)) {
            revert ProjERC20TransferError();
        }
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    function getNumberOfCampaigns() external view returns (uint256 numbOfCampaigns) {
        numbOfCampaigns = _numberOfCampaigns;
    }

    function getCampaignStatus(uint256 _campaignId) public view returns (CampaignStatus currentStatus) {
        if (_campaignId >= _numberOfCampaigns) {
            return CampaignStatus.NOTCREATED;
        }

        CampaignData storage campaignData = _campaigns[_campaignId];

        uint256 target = campaignData.target;
        uint256 softTarget = campaignData.softTarget;
        uint256 raisedAmount = campaignData.raisedAmount;
        uint256 balance = _lastCampaignBalance;
        uint256 endTime = campaignData.endTime;

        uint256 currentTime = block.timestamp;
        bool isLastCampaign = _campaignId == (_numberOfCampaigns - 1);

        if ((raisedAmount == target) || (raisedAmount >= softTarget && currentTime > endTime)) {
            if (isLastCampaign && balance > 0) {
                return CampaignStatus.FUNDED;
            } else {
                return CampaignStatus.SUCCEEDED;
            }
        } else if (currentTime <= endTime) {
            return CampaignStatus.ACTIVE;
        } else {
            if (isLastCampaign && balance > 0) {
                return CampaignStatus.NOTFUNDED;
            } else {
                return CampaignStatus.DEFEATED;
            }
        }
    }

    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        )
    {
        _onlyStarter();

        currentCampaignId = _numberOfCampaigns == 0 ? 0 : _numberOfCampaigns - 1;

        if (getCampaignStatus(currentCampaignId) != CampaignStatus.ACTIVE) {
            revert ProjCampaignNotActiveError();
        }

        uint256 amountToTarget = _campaigns[currentCampaignId].target - _lastCampaignBalance;
        if (amountToTarget > _amount) {
            amountToCampaign = _amount;
            amountToPool = 0;
            isFunded = false;
        } else {
            amountToCampaign = amountToTarget;
            amountToPool = _amount - amountToCampaign;
            isFunded = true;
        }
    }

    //////////////////////////////
    // VIEW FUNCTIONS FOR TESTS //
    //////////////////////////////

    function projectStatus() external view returns (bool prjctStatus) {
        prjctStatus = _projectStatus;
    }

    function lastCampaignBalance() external view returns (uint256 lastCampaignBal) {
        lastCampaignBal = _lastCampaignBalance;
    }

    function outsideCampaignsBalance() external view returns (uint256 outsideCampaignsBal) {
        outsideCampaignsBal = _outsideCampaignsBalance;
    }

    function campaignRaisedAmount(uint256 _campaignId) external view returns (uint256 campaignRaisedAmnt) {
        campaignRaisedAmnt = _campaigns[_campaignId].raisedAmount;
    }

    function campaignResultsPublished(uint256 _campaignId) external view returns (bool campaignResultsPub) {
        campaignResultsPub = _campaigns[_campaignId].resultsPublished;
    }

    ////////////////////////////////
    // PRIVATE/INTERNAL FUNCTIONS //
    ////////////////////////////////

    function _onlyStarter() private view {
        if (msg.sender != _starter) {
            revert ProjOnlyStarterError();
        }
    }

    function _updateCampaignBalances(
        uint256 _campaignId,
        uint256 _amount,
        bool _fund
    ) private {
        if (_fund) {
            _lastCampaignBalance += _amount;
            _campaigns[_campaignId].raisedAmount += _amount;
        } else {
            _lastCampaignBalance -= _amount;
        }
    }
}