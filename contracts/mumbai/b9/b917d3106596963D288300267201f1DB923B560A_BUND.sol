// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";
import "./IProtectionStrategy.sol";

interface ILssController {
    // function getLockedAmount(ILERC20 _token, address _account)  returns (uint256);
    // function getAvailableAmount(ILERC20 _token, address _account) external view returns (uint256 amount);
    function retrieveBlacklistedFunds(address[] calldata _addresses, ILERC20 _token, uint256 _reportId) external returns(uint256);
    function whitelist(address _adr) external view returns (bool);
    function dexList(address _dexAddress) external returns (bool);
    function blacklist(address _adr) external view returns (bool);
    function admin() external view returns (address);
    function pauseAdmin() external view returns (address);
    function recoveryAdmin() external view returns (address);
    function guardian() external view returns (address);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function losslessGovernance() external view returns (ILssGovernance);
    function dexTranferThreshold() external view returns (uint256);
    function settlementTimeLock() external view returns (uint256);
    
    function pause() external;
    function unpause() external;
    function setAdmin(address _newAdmin) external;
    function setRecoveryAdmin(address _newRecoveryAdmin) external;
    function setPauseAdmin(address _newPauseAdmin) external;
    function setSettlementTimeLock(uint256 _newTimelock) external;
    function setDexTransferThreshold(uint256 _newThreshold) external;
    function setDexList(address[] calldata _dexList, bool _value) external;
    function setWhitelist(address[] calldata _addrList, bool _value) external;
    function addToBlacklist(address _adr) external;
    function resolvedNegatively(address _adr) external;
    function setStakingContractAddress(ILssStaking _adr) external;
    function setReportingContractAddress(ILssReporting _adr) external; 
    function setGovernanceContractAddress(ILssGovernance _adr) external;
    function proposeNewSettlementPeriod(ILERC20 _token, uint256 _seconds) external;
    function executeNewSettlementPeriod(ILERC20 _token) external;
    function activateEmergency(ILERC20 _token) external;
    function deactivateEmergency(ILERC20 _token) external;
    function setGuardian(address _newGuardian) external;
    function removeProtectedAddress(ILERC20 _token, address _protectedAddresss) external;
    function beforeTransfer(address _sender, address _recipient, uint256 _amount) external;
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external;
    function beforeApprove(address _sender, address _spender, uint256 _amount) external;
    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) external;
    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) external;
    function beforeMint(address _to, uint256 _amount) external;
    function beforeBurn(address _account, uint256 _amount) external;
    function setProtectedAddress(ILERC20 _token, address _protectedAddress, ProtectionStrategy _strategy) external;

    event AdminChange(address indexed _newAdmin);
    event RecoveryAdminChange(address indexed _newAdmin);
    event PauseAdminChange(address indexed _newAdmin);
    event GuardianSet(address indexed _oldGuardian, address indexed _newGuardian);
    event NewProtectedAddress(ILERC20 indexed _token, address indexed _protectedAddress, address indexed _strategy);
    event RemovedProtectedAddress(ILERC20 indexed _token, address indexed _protectedAddress);
    event NewSettlementPeriodProposal(ILERC20 indexed _token, uint256 _seconds);
    event SettlementPeriodChange(ILERC20 indexed _token, uint256 _proposedTokenLockTimeframe);
    event NewSettlementTimelock(uint256 indexed _timelock);
    event NewDexThreshold(uint256 indexed _newThreshold);
    event NewDex(address indexed _dexAddress);
    event DexRemoval(address indexed _dexAddress);
    event NewWhitelistedAddress(address indexed _whitelistAdr);
    event WhitelistedAddressRemoval(address indexed _whitelistAdr);
    event NewBlacklistedAddress(address indexed _blacklistedAddres);
    event AccountBlacklistRemoval(address indexed _adr);
    event NewStakingContract(ILssStaking indexed _newAdr);
    event NewReportingContract(ILssReporting indexed _newAdr);
    event NewGovernanceContract(ILssGovernance indexed _newAdr);
    event EmergencyActive(ILERC20 indexed _token);
    event EmergencyDeactivation(ILERC20 indexed _token);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILERC20 {
    function name() external view returns (string memory);
    function admin() external view returns (address);
    function getAdmin() external view returns (address);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
    
    function transferOutBlacklistedFunds(address[] calldata _from) external;
    function setLosslessAdmin(address _newAdmin) external;
    function transferRecoveryAdminOwnership(address _candidate, bytes32 _keyHash) external;
    function acceptRecoveryAdminOwnership(bytes memory _key) external;
    function proposeLosslessTurnOff() external;
    function executeLosslessTurnOff() external;
    function executeLosslessTurnOn() external;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NewAdmin(address indexed _newAdmin);
    event NewRecoveryAdminProposal(address indexed _candidate);
    event NewRecoveryAdmin(address indexed _newAdmin);
    event LosslessTurnOffProposal(uint256 _turnOffDate);
    event LosslessOff();
    event LosslessOn();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";
import "./ILosslessController.sol";

interface ILssGovernance {
    function LSS_TEAM_INDEX() external view returns(uint256);
    function TOKEN_OWNER_INDEX() external view returns(uint256);
    function COMMITEE_INDEX() external view returns(uint256);
    function committeeMembersCount() external view returns(uint256);
    function walletDisputePeriod() external view returns(uint256);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function losslessController() external view returns (ILssController);
    function isCommitteeMember(address _account) external view returns(bool);
    function getIsVoted(uint256 _reportId, uint256 _voterIndex) external view returns(bool);
    function getVote(uint256 _reportId, uint256 _voterIndex) external view returns(bool);
    function isReportSolved(uint256 _reportId) external view returns(bool);
    function reportResolution(uint256 _reportId) external view returns(bool);
    function getAmountReported(uint256 _reportId) external view returns(uint256);
    
    function setDisputePeriod(uint256 _timeFrame) external;
    function addCommitteeMembers(address[] memory _members) external;
    function removeCommitteeMembers(address[] memory _members) external;
    function losslessVote(uint256 _reportId, bool _vote) external;
    function tokenOwnersVote(uint256 _reportId, bool _vote) external;
    function committeeMemberVote(uint256 _reportId, bool _vote) external;
    function resolveReport(uint256 _reportId) external;
    function proposeWallet(uint256 _reportId, address wallet) external;
    function rejectWallet(uint256 _reportId) external;
    function retrieveFunds(uint256 _reportId) external;
    function retrieveCompensation() external;
    function claimCommitteeReward(uint256 _reportId) external;
    function setCompensationAmount(uint256 _amount) external;
    function losslessClaim(uint256 _reportId) external;

    event NewCommitteeMembers(address[] _members);
    event CommitteeMembersRemoval(address[] _members);
    event LosslessTeamPositiveVote(uint256 indexed _reportId);
    event LosslessTeamNegativeVote(uint256 indexed _reportId);
    event TokenOwnersPositiveVote(uint256 indexed _reportId);
    event TokenOwnersNegativeVote(uint256 indexed _reportId);
    event CommitteeMemberPositiveVote(uint256 indexed _reportId, address indexed _member);
    event CommitteeMemberNegativeVote(uint256 indexed _reportId, address indexed _member);
    event ReportResolve(uint256 indexed _reportId, bool indexed _resolution);
    event WalletProposal(uint256 indexed _reportId, address indexed _wallet);
    event CommitteeMemberClaim(uint256 indexed _reportId, address indexed _member, uint256 indexed _amount);
    event CommitteeMajorityReach(uint256 indexed _reportId, bool indexed _result);
    event NewDisputePeriod(uint256 indexed _newPeriod);
    event WalletRejection(uint256 indexed _reportId);
    event FundsRetrieval(uint256 indexed _reportId, uint256 indexed _amount);
    event CompensationRetrieval(address indexed _wallet, uint256 indexed _amount);
    event LosslessClaim(ILERC20 indexed _token, uint256 indexed _reportID, uint256 indexed _amount);
    event NewCompensationPercentage(uint256 indexed compensationPercentage);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessController.sol";

interface ILssReporting {
  function reporterReward() external returns(uint256);
  function losslessReward() external returns(uint256);
  function stakersReward() external returns(uint256);
  function committeeReward() external returns(uint256);
  function reportLifetime() external view returns(uint256);
  function reportingAmount() external returns(uint256);
  function reportCount() external returns(uint256);
  function stakingToken() external returns(ILERC20);
  function losslessController() external returns(ILssController);
  function losslessGovernance() external returns(ILssGovernance);
  function getVersion() external pure returns (uint256);
  function getRewards() external view returns (uint256 _reporter, uint256 _lossless, uint256 _committee, uint256 _stakers);
  function report(ILERC20 _token, address _account) external returns (uint256);
  function reporterClaimableAmount(uint256 _reportId) external view returns (uint256);
  function getReportInfo(uint256 _reportId) external view returns(address _reporter,
        address _reportedAddress,
        address _secondReportedAddress,
        uint256 _reportTimestamps,
        ILERC20 _reportTokens,
        bool _secondReports,
        bool _reporterClaimStatus);
  
  function pause() external;
  function unpause() external;
  function setStakingToken(ILERC20 _stakingToken) external;
  function setLosslessGovernance(ILssGovernance _losslessGovernance) external;
  function setReportingAmount(uint256 _reportingAmount) external;
  function setReporterReward(uint256 _reward) external;
  function setLosslessReward(uint256 _reward) external;
  function setStakersReward(uint256 _reward) external;
  function setCommitteeReward(uint256 _reward) external;
  function setReportLifetime(uint256 _lifetime) external;
  function secondReport(uint256 _reportId, address _account) external;
  function reporterClaim(uint256 _reportId) external;
  function retrieveCompensation(address _adr, uint256 _amount) external;

  event ReportSubmission(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId, uint256 _amount);
  event SecondReportSubmission(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId);
  event NewReportingAmount(uint256 indexed _newAmount);
  event NewStakingToken(ILERC20 indexed _token);
  event NewGovernanceContract(ILssGovernance indexed _adr);
  event NewReporterReward(uint256 indexed _newValue);
  event NewLosslessReward(uint256 indexed _newValue);
  event NewStakersReward(uint256 indexed _newValue);
  event NewCommitteeReward(uint256 indexed _newValue);
  event NewReportLifetime(uint256 indexed _newValue);
  event ReporterClaim(address indexed _reporter, uint256 indexed _reportId, uint256 indexed _amount);
  event CompensationRetrieve(address indexed _adr, uint256 indexed _amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessReporting.sol";
import "./ILosslessController.sol";

interface ILssStaking {
  function stakingToken() external returns(ILERC20);
  function losslessReporting() external returns(ILssReporting);
  function losslessController() external returns(ILssController);
  function losslessGovernance() external returns(ILssGovernance);
  function stakingAmount() external returns(uint256);
  function getVersion() external pure returns (uint256);
  function getIsAccountStaked(uint256 _reportId, address _account) external view returns(bool);
  function getStakerCoefficient(uint256 _reportId, address _address) external view returns (uint256);
  function stakerClaimableAmount(uint256 _reportId) external view returns (uint256);
  
  function pause() external;
  function unpause() external;
  function setLssReporting(ILssReporting _losslessReporting) external;
  function setStakingToken(ILERC20 _stakingToken) external;
  function setLosslessGovernance(ILssGovernance _losslessGovernance) external;
  function setStakingAmount(uint256 _stakingAmount) external;
  function stake(uint256 _reportId) external;
  function stakerClaim(uint256 _reportId) external;

  event NewStake(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId, uint256 _amount);
  event StakerClaim(address indexed _staker, ILERC20 indexed _token, uint256 indexed _reportID, uint256 _amount);
  event NewStakingAmount(uint256 indexed _newAmount);
  event NewStakingToken(ILERC20 indexed _newToken);
  event NewReportingContract(ILssReporting indexed _newContract);
  event NewGovernanceContract(ILssGovernance indexed _newContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ProtectionStrategy {
    function isTransferAllowed(address token, address sender, address recipient, uint256 amount) external;
}

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
pragma solidity ^0.8.13;

import "./LERC20Upgradeable.sol";

contract BUND is LERC20Upgradeable {
    function initialize(
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        address admin_,
        address recoveryAdmin_,
        uint256 timelockPeriod_,
        address lossless_
    ) public initializer {
        __LERC20_init(
            totalSupply_,
            name_,
            symbol_,
            admin_,
            recoveryAdmin_,
            timelockPeriod_,
            lossless_
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@losslesscash/lerc20/contracts/interfaces/ILosslessERC20.sol";
import "@losslesscash/lerc20/contracts/interfaces/ILosslessController.sol";

abstract contract LERC20Upgradeable is ContextUpgradeable, ILERC20 {
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;

    address public recoveryAdmin;
    address internal recoveryAdminCandidate;
    bytes32 internal recoveryAdminKeyHash;
    address override public admin;
    uint256 public timelockPeriod;
    uint256 public losslessTurnOffTimestamp;
    bool public isLosslessOn;
    ILssController public lossless;

    function __LERC20_init(
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        address admin_,
        address recoveryAdmin_,
        uint256 timelockPeriod_,
        address lossless_
    ) internal onlyInitializing {
        __LERC20_init_unchained(totalSupply_, name_, symbol_, admin_, recoveryAdmin_, timelockPeriod_, lossless_);
    }

    function __LERC20_init_unchained(
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        address admin_,
        address recoveryAdmin_,
        uint256 timelockPeriod_,
        address lossless_
    ) internal onlyInitializing {
        __Context_init_unchained();
        _mint(_msgSender(), totalSupply_);
        _name = name_;
        _symbol = symbol_;
        admin = admin_;
        isLosslessOn = true;
        recoveryAdmin = recoveryAdmin_;
        recoveryAdminCandidate = address(0);
        recoveryAdminKeyHash = "";
        timelockPeriod = timelockPeriod_;
        losslessTurnOffTimestamp = 0;
        lossless = ILssController(lossless_);
    }

    // --- LOSSLESS modifiers ---

    modifier lssAprove(address spender, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeApprove(_msgSender(), spender, amount);
        } 
        _;
    }

    modifier lssTransfer(address recipient, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeTransfer(_msgSender(), recipient, amount);
        } 
        _;
    }

    modifier lssTransferFrom(address sender, address recipient, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeTransferFrom(_msgSender(),sender, recipient, amount);
        }
        _;
    }

    modifier lssIncreaseAllowance(address spender, uint256 addedValue) {
        if (isLosslessOn) {
            lossless.beforeIncreaseAllowance(_msgSender(), spender, addedValue);
        }
        _;
    }

    modifier lssDecreaseAllowance(address spender, uint256 subtractedValue) {
        if (isLosslessOn) {
            lossless.beforeDecreaseAllowance(_msgSender(), spender, subtractedValue);
        }
        _;
    }

    modifier onlyRecoveryAdmin() {
        require(_msgSender() == recoveryAdmin, "LERC20: Must be recovery admin");
        _;
    }

    // --- LOSSLESS management ---
    function transferOutBlacklistedFunds(address[] calldata from) override external {
        require(_msgSender() == address(lossless), "LERC20: Only lossless contract");

        uint256 fromLength = from.length;
        uint256 totalAmount = 0;
        
        for(uint256 i = 0; i < fromLength;) {
            address fromAddress = from[i];
            uint256 fromBalance = _balances[fromAddress];
            _balances[fromAddress] = 0;
            totalAmount += fromBalance;
            emit Transfer(fromAddress, address(lossless), fromBalance);
            unchecked{i++;}
        }

        _balances[address(lossless)] += totalAmount;
    }

    function setLosslessAdmin(address newAdmin) override external onlyRecoveryAdmin {
        require(newAdmin != admin, "LERC20: Cannot set same address");
        emit NewAdmin(newAdmin);
        admin = newAdmin;
    }

    function transferRecoveryAdminOwnership(address candidate, bytes32 keyHash) override  external onlyRecoveryAdmin {
        recoveryAdminCandidate = candidate;
        recoveryAdminKeyHash = keyHash;
        emit NewRecoveryAdminProposal(candidate);
    }

    function acceptRecoveryAdminOwnership(bytes memory key) override external {
        require(_msgSender() == recoveryAdminCandidate, "LERC20: Must be canditate");
        require(keccak256(key) == recoveryAdminKeyHash, "LERC20: Invalid key");
        emit NewRecoveryAdmin(recoveryAdminCandidate);
        recoveryAdmin = recoveryAdminCandidate;
        recoveryAdminCandidate = address(0);
    }

    function proposeLosslessTurnOff() override external onlyRecoveryAdmin {
        require(losslessTurnOffTimestamp == 0, "LERC20: TurnOff already proposed");
        require(isLosslessOn, "LERC20: Lossless already off");
        losslessTurnOffTimestamp = block.timestamp + timelockPeriod;
        emit LosslessTurnOffProposal(losslessTurnOffTimestamp);
    }

    function executeLosslessTurnOff() override external onlyRecoveryAdmin {
        require(losslessTurnOffTimestamp != 0, "LERC20: TurnOff not proposed");
        require(losslessTurnOffTimestamp <= block.timestamp, "LERC20: Time lock in progress");
        isLosslessOn = false;
        losslessTurnOffTimestamp = 0;
        emit LosslessOff();
    }

    function executeLosslessTurnOn() override external onlyRecoveryAdmin {
        require(!isLosslessOn, "LERC20: Lossless already on");
        losslessTurnOffTimestamp = 0;
        isLosslessOn = true;
        emit LosslessOn();
    }

    function getAdmin() override public view virtual returns (address) {
        return admin;
    }

    // --- ERC20 methods ---

    function name() override public view virtual returns (string memory) {
        return _name;
    }

    function symbol() override public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() override public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override lssTransfer(recipient, amount) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override lssAprove(spender, amount) returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override lssTransferFrom(sender, recipient, amount) returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "LERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) override public virtual lssIncreaseAllowance(spender, addedValue) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) override public virtual lssDecreaseAllowance(spender, subtractedValue) returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "LERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "LERC20: transfer from the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "LERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "LERC20: mint to the zero address");
    
        _totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked { 
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}