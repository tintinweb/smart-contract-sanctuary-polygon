// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCPool {
    error PoolNotStarter();
    error PoolNotAdmin();
    error PoolUnexpectedAddress();
    error PoolERC20TransferError();
    error PoolAmountTooHigh();
    error PoolInvalidCurrency();

    event AdminChanged(address oldAmin, address newAdmin);
    event StarterChanged(address oldStarer, address newStarer);
    event PoCNftChanged(address oldPocNft, address newPocNft);
    event Funding(address indexed user, uint256 amount);
    event Withdrawal(IERC20 indexed currency, address indexed to, uint256 amount);

    function setPoCNft(address _poolNFT) external;

    function setCurrency(IERC20 currency) external;

    function setAdmin(address admin) external;

    function setStarter(address starter) external;

    function withdraw(
        IERC20 currency,
        address _to,
        uint256 _amount
    ) external;

    function withdrawToProject(address _project, uint256 _amount) external;

    function fund(uint256 _amount) external;

    function getCurrency() external view returns (IERC20);
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

    function init(
        address starter,
        address pool,
        address lab,
        uint256 poolFeeBps,
        IERC20 currency
    ) external;

    function fundProject(uint256 _amount) external;

    function closeProject() external;

    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256);

    function publishCampaignResults() external;

    function fundCampaign(address _user, uint256 _amount) external;

    function validateMint(uint256 _campaignId, address _user) external returns (uint256,uint256);

    function backerWithdrawDefeated(address _user)
        external
        returns (
            uint256,
            uint256,
            bool
        );

    function labCampaignWithdraw()
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function labProjectWithdraw() external returns (uint256);

    function withdrawToPool(IERC20 currency) external returns (uint256);

    function transferUnclaimedFunds() external returns (uint256, uint256);

    function getNumberOfCampaigns() external view returns (uint256);

    function getCampaignStatus(uint256 _campaignId) external view returns (CampaignStatus currentStatus);

    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        );

    function projectStatus() external view returns (bool);

    function lastCampaignBalance() external view returns (uint256);

    function outsideCampaignsBalance() external view returns (uint256);

    function campaignRaisedAmount(uint256 _campaignId) external view returns (uint256);

    function campaignResultsPublished(uint256 _campaignId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCProject.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCStarter {
    error SttrNotAdminError();
    error SttrNotWhitelistedLabError();
    error SttrNotLabOwnerError();
    error SttrNotCoreTeamError();
    error SttrLabAlreadyWhitelistedError();
    error SttrLabAlreadyBlacklistedError();
    error SttrFundingAmountIsZeroError();
    error SttrMinCampaignDurationError();
    error SttrMaxCampaignDurationError();
    error SttrMinCampaignTargetError();
    error SttrMaxCampaignTargetError();
    error SttrSoftTargetBpsError();
    error SttrLabCannotFundOwnProjectError();
    error SttrBlacklistedLabError();
    error SttrCampaignTargetError();
    error SttrCampaignDurationError();
    error SttrERC20TransferError();
    error SttrExistingProjectRequestError();
    error SttrNonExistingProjectRequestError();
    error SttrInvalidSignatureError();
    error SttrProjectIsNotActiveError();
    error SttrResultsCannotBePublishedError();

    event SttrWhitelistedLab(address indexed lab);
    event SttrBlacklistedLab(address indexed lab);
    event SttrSetMinCampaignDuration(uint256 minCampaignDuration);
    event SttrSetMaxCampaignDuration(uint256 maxCampaignDuration);
    event SttrSetMinCampaignTarget(uint256 minCampaignTarget);
    event SttrSetMaxCampaignTarget(uint256 maxCampaignTarget);
    event SttrSetSoftTargetBps(uint256 softTargetBps);
    event SttrPoCNftSet(address indexed poCNft);
    event SttrCampaignStarted(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        uint256 startTime,
        uint256 endTime,
        uint256 backersDeadline,
        uint256 target,
        uint256 softTarget
    );
    event SttrCampaignFunding(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        address user,
        uint256 amount,
        bool campaignFunded
    );
    event SttrLabCampaignWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        uint256 amount
    );
    event SttrLabWithdrawal(address indexed lab, address indexed project, uint256 amount);
    event SttrWithdrawToPool(address indexed project, IERC20 indexed currency, uint256 amount);
    event SttrBackerMintPoCNft(address indexed lab, address indexed project, uint256 indexed campaign, uint256 amount);
    event SttrBackerWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        uint256 amount,
        bool campaignDefeated
    );
    event SttrUnclaimedFundsTransferredToPool(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        uint256 amount
    );
    event SttrProjectFunded(address indexed lab, address indexed project, address indexed backer, uint256 amount);
    event SttrProjectClosed(address indexed lab, address indexed project);
    event SttrProjectRequest(address indexed lab);
    event SttrCreateProject(address indexed lab, address indexed project, bool accepted);
    event SttrCampaignResultsPublished(address indexed lab, address indexed project, uint256 campaignId);
    event SttrPoolFunded(address indexed user, uint256 amount);

    function setAdmin(address admin) external; // onlyAdmin

    function setPool(address pool) external; // onlyAdmin

    function setProjectTemplate(address _newProjectTemplate) external;

    function setCoreTeam(address _newCoreTeam) external;

    function setTxValidator(address _newTxValidator) external;

    function setCurrency(IERC20 currency) external;

    function setPoolFeeBps(uint256 _newPoolFeeBps) external;

    function whitelistLab(address lab) external;

    function blacklistLab(address lab) external;

    function addNoFeeAccounts(address[] memory _accounts) external;

    function setMinCampaignDuration(uint256 minCampaignDuration) external;

    function setMaxCampaignDuration(uint256 maxCampaignDuration) external;

    function setMinCampaignTarget(uint256 minCampaignTarget) external;

    function setMaxCampaignTarget(uint256 maxCampaignTarget) external;

    function setSoftTargetBps(uint256 softTargetBps) external;

    function setPoCNft(address _pocNft) external;

    function createProject(address _lab, bool _accepted) external returns (address newProject);

    function createProjectRequest() external;

    function fundProject(address _project, uint256 _amount) external;

    function fundProjectOnBehalf(
        address _user,
        address _project,
        uint256 _amount
    ) external;

    function closeProject(address _project, bytes memory _sig) external;

    function startCampaign(
        address _project,
        uint256 _target,
        uint256 _duration,
        bytes memory _sig
    ) external returns (uint256 campaignId);

    function publishCampaignResults(address _project, bytes memory _sig) external;

    function fundCampaign(address _project, uint256 _amount) external;

    function backerMintPoCNft(address _project, uint256 _campaignId) external;

    function backerWithdrawDefeated(address _project) external;

    function labCampaignWithdraw(address _project) external;

    function labProjectWithdraw(address _project) external;

    function transferUnclaimedFunds(address _project) external;

    function withdrawToPool(address project, IERC20 currency) external;

    function getAdmin() external view returns (address);

    function getCurrency() external view returns (address);

    function getCampaignStatus(address _project, uint256 _campaignId)
        external
        view
        returns (IVCProject.CampaignStatus currentStatus);

    function isValidProject(address _lab, address _project) external view returns (bool);

    function isWhitelistedLab(address _lab) external view returns (bool);

    function areActiveProjects(address[] memory _projects) external view returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCStarter.sol";
import "../tokens/IPoCNft.sol";
import "../pool/IVCPool.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../utils/CanWithdrawERC20.sol";

contract VCStarter is IVCStarter, CanWithdrawERC20 {
    /// @notice A project contract template cloned for each project
    address _projectTemplate;
    address _admin;
    address _coreTeam; // multisig of the VC CORE team
    address _pool;
    address _txValidator;

    IPoCNft _poCNft;

    /// @notice The list of laboratories
    mapping(address => bool) _isWhitelistedLab;

    mapping(address => bool) _noFeeAccounts;
    mapping(address => bool) _pendingProjectRequest;
    mapping(address => address) _projectToLab;
    mapping(address => bool) _activeProjects;

    IERC20 _currency;

    uint256 _minCampaignDuration;
    uint256 _maxCampaignDuration;
    uint256 _minCampaignTarget;
    uint256 _maxCampaignTarget;
    uint256 _softTargetBps;

    uint256 constant _FEE_DENOMINATOR = 10_000;

    /// @notice amount of seconds to wait for lab operation
    uint256 _backersTimeout = 15 days;
    uint256 _poolFeeBps = 2_000;

    constructor(
        address pool,
        address admin,
        address coreTeam,
        address txValidator,
        address projectTemplate,
        uint256 minCampaignDuration,
        uint256 maxCampaignDuration,
        uint256 minCampaignTarget,
        uint256 maxCampaignTarget,
        uint256 softTargetBps
    ) {
        _pool = pool;
        _admin = admin;
        _coreTeam = coreTeam;
        _txValidator = txValidator;
        _projectTemplate = projectTemplate;

        _minCampaignDuration = minCampaignDuration;
        _maxCampaignDuration = maxCampaignDuration;
        _minCampaignTarget = minCampaignTarget;
        _maxCampaignTarget = maxCampaignTarget;
        _softTargetBps = softTargetBps;
    }

    /*********** ONLY-ADMIN / ONLY-CORE_TEAM FUNCTIONS ***********/

    function setAdmin(address admin) external {
        _onlyAdmin();
        _admin = admin;
    }

    function setPool(address pool) external {
        _onlyAdmin();
        _setTo(pool);
        _pool = pool;
    }

    function setProjectTemplate(address _newProjectTemplate) external {
        _onlyAdmin();
        _projectTemplate = _newProjectTemplate;
    }

    function setCoreTeam(address _newCoreTeam) external {
        _onlyAdmin();
        _coreTeam = _newCoreTeam;
    }

    function setTxValidator(address _newTxValidator) external {
        _onlyAdmin();
        _txValidator = _newTxValidator;
    }

    function setCurrency(IERC20 currency) external {
        _onlyAdmin();
        _currency = currency;
    }

    function setPoolFeeBps(uint256 _newPoolFeeBps) external {
        _onlyAdmin();
        _poolFeeBps = _newPoolFeeBps;
    }

    function whitelistLab(address lab) external {
        _onlyCoreTeam();

        if (_isWhitelistedLab[lab] == true) {
            revert SttrLabAlreadyWhitelistedError();
        }
        _isWhitelistedLab[lab] = true;
        emit SttrWhitelistedLab(lab);
    }

    function blacklistLab(address lab) external {
        _onlyCoreTeam();

        if (_isWhitelistedLab[lab] == false) {
            revert SttrLabAlreadyBlacklistedError();
        }
        _isWhitelistedLab[lab] = false;
        emit SttrBlacklistedLab(lab);
    }

    function addNoFeeAccounts(address[] memory _accounts) external {
        _onlyAdmin();
        for (uint256 i = 0; i < _accounts.length; i++) _noFeeAccounts[_accounts[i]] = true;
    }

    function setMinCampaignDuration(uint256 minCampaignDuration) external {
        _onlyAdmin();
        if (_minCampaignDuration == minCampaignDuration || minCampaignDuration >= _maxCampaignDuration) {
            revert SttrMinCampaignDurationError();
        }
        _minCampaignDuration = minCampaignDuration;
        emit SttrSetMinCampaignDuration(_minCampaignDuration);
    }

    function setMaxCampaignDuration(uint256 maxCampaignDuration) external {
        _onlyAdmin();
        if (_maxCampaignDuration == maxCampaignDuration || maxCampaignDuration <= _minCampaignDuration) {
            revert SttrMaxCampaignDurationError();
        }
        _maxCampaignDuration = maxCampaignDuration;
        emit SttrSetMaxCampaignDuration(_maxCampaignDuration);
    }

    function setMinCampaignTarget(uint256 minCampaignTarget) external {
        _onlyAdmin();
        if (_minCampaignTarget == minCampaignTarget || minCampaignTarget >= _maxCampaignTarget) {
            revert SttrMinCampaignTargetError();
        }
        _minCampaignTarget = minCampaignTarget;
        emit SttrSetMinCampaignTarget(minCampaignTarget);
    }

    function setMaxCampaignTarget(uint256 maxCampaignTarget) external {
        _onlyAdmin();
        if (_maxCampaignTarget == maxCampaignTarget || maxCampaignTarget <= _minCampaignTarget) {
            revert SttrMaxCampaignTargetError();
        }
        _maxCampaignTarget = maxCampaignTarget;
        emit SttrSetMaxCampaignTarget(_maxCampaignTarget);
    }

    function setSoftTargetBps(uint256 softTargetBps) external {
        _onlyAdmin();
        if (_softTargetBps == softTargetBps || softTargetBps > _FEE_DENOMINATOR) {
            revert SttrSoftTargetBpsError();
        }
        _softTargetBps = softTargetBps;
        emit SttrSetSoftTargetBps(_softTargetBps);
    }

    function setPoCNft(address _pocNft) external {
        _onlyAdmin();
        _poCNft = IPoCNft(_pocNft);
        emit SttrPoCNftSet(_pocNft);
    }

    function createProject(address _lab, bool _accepted) external returns (address newProject) {
        _onlyCoreTeam();

        if (!_pendingProjectRequest[_lab]) {
            revert SttrNonExistingProjectRequestError();
        }
        _pendingProjectRequest[_lab] = false;

        if (_accepted) {
            newProject = Clones.clone(_projectTemplate);
            _activeProjects[newProject] = true;
            IVCProject(newProject).init(address(this), _pool, _lab, _poolFeeBps, _currency);
            _projectToLab[newProject] = _lab;
            emit SttrCreateProject(_lab, newProject, _accepted);
        } else {
            emit SttrCreateProject(_lab, address(0), _accepted);
        }
    }

    /*********** EXTERNAL AND PUBLIC METHODS ***********/

    function createProjectRequest() external {
        _onlyWhitelistedLab();

        if (_pendingProjectRequest[msg.sender]) {
            revert SttrExistingProjectRequestError();
        }
        _pendingProjectRequest[msg.sender] = true;
        emit SttrProjectRequest(msg.sender);
    }

    function fundProject(address _project, uint256 _amount) external {
        (uint256 amountToProject, uint256 amountToPool) = _fundProject(_project, _amount, msg.sender);
        _poCNft.mint(msg.sender, amountToProject, false);
        _poCNft.mint(msg.sender, amountToPool, true);
    }

    function fundProjectOnBehalf(
        address _user,
        address _project,
        uint256 _amount
    ) external {
        _fundProject(_project, _amount, _user);
    }

    function closeProject(address _project, bytes memory _sig) external {
        _onlyLabOwner(_project);

        _verifyCloseProject(_project, _sig);
        IVCProject(_project).closeProject();
        _activeProjects[_project] = false;
        emit SttrProjectClosed(msg.sender, _project);
    }

    function startCampaign(
        address _project,
        uint256 _target,
        uint256 _duration,
        bytes memory _sig
    ) external returns (uint256 campaignId) {
        _onlyWhitelistedLab();
        _onlyLabOwner(_project);

        uint256 numberOfCampaigns = IVCProject(_project).getNumberOfCampaigns();
        _verifyStartCampaign(_project, numberOfCampaigns, _target, _duration, _sig);

        if (_target == 0 || _target < _minCampaignTarget || _target > _maxCampaignTarget) {
            revert SttrCampaignTargetError();
        }
        if (_duration == 0 || _duration < _minCampaignDuration || _duration > _maxCampaignDuration) {
            revert SttrCampaignDurationError();
        }
        uint256 softTarget = (_target * _softTargetBps) / _FEE_DENOMINATOR;
        campaignId = IVCProject(_project).startCampaign(
            _target,
            softTarget,
            block.timestamp,
            block.timestamp + _duration,
            block.timestamp + _duration + _backersTimeout
        );
        emit SttrCampaignStarted(
            msg.sender,
            _project,
            campaignId,
            block.timestamp,
            block.timestamp + _duration,
            block.timestamp + _duration + _backersTimeout,
            _target,
            softTarget
        );
    }

    function publishCampaignResults(address _project, bytes memory _sig) external {
        _onlyLabOwner(_project);

        uint256 numberOfCampaigns = IVCProject(_project).getNumberOfCampaigns();
        if (numberOfCampaigns == 0) {
            revert SttrResultsCannotBePublishedError();
        }

        uint256 currentCampaignId = numberOfCampaigns - 1;
        _verifyPublishCampaignResults(_project, currentCampaignId, _sig);
        IVCProject(_project).publishCampaignResults();
        emit SttrCampaignResultsPublished(msg.sender, _project, currentCampaignId);
    }

    function fundCampaign(address _project, uint256 _amount) external {
        address lab = _checkBeforeFund(_project, _amount);

        (uint256 campaignId, uint256 amountToCampaign, uint256 amountToPool, bool isFunded) = IVCProject(_project)
            .getFundingAmounts(_amount);
        if (!_currency.transferFrom(msg.sender, _project, amountToCampaign)) {
            revert SttrERC20TransferError();
        }
        IVCProject(_project).fundCampaign(msg.sender, amountToCampaign);
        emit SttrCampaignFunding(lab, _project, campaignId, msg.sender, amountToCampaign, isFunded);

        if (amountToPool > 0) {
            if (!_currency.transferFrom(msg.sender, _pool, amountToPool)) {
                revert SttrERC20TransferError();
            }
            emit SttrPoolFunded(msg.sender, amountToPool);
        }
    }

    function backerMintPoCNft(address _project, uint256 _campaignId) external {
        (uint256 poolAmount, uint256 starterAmount) = IVCProject(_project).validateMint(_campaignId, msg.sender);

        _poCNft.mint(msg.sender, poolAmount, true);

        if (starterAmount > 0) {
            _poCNft.mint(msg.sender, starterAmount, false);
        }

        emit SttrBackerMintPoCNft(_projectToLab[_project], _project, _campaignId, poolAmount + starterAmount);
    }

    function backerWithdrawDefeated(address _project) external {
        (uint256 campaignId, uint256 backerAmount, bool campaignDefeated) = IVCProject(_project).backerWithdrawDefeated(
            msg.sender
        );
        emit SttrBackerWithdrawal(_projectToLab[_project], _project, campaignId, backerAmount, campaignDefeated);
    }

    function labCampaignWithdraw(address _project) external {
        _onlyLabOwner(_project);

        (uint256 campaignId, uint256 withdrawAmount, uint256 poolAmount) = IVCProject(_project).labCampaignWithdraw();

        emit SttrLabCampaignWithdrawal(msg.sender, _project, campaignId, withdrawAmount);
        emit SttrPoolFunded(msg.sender, poolAmount);
    }

    function labProjectWithdraw(address _project) external {
        _onlyLabOwner(_project);

        uint256 amount = IVCProject(_project).labProjectWithdraw();
        emit SttrLabWithdrawal(msg.sender, _project, amount);
    }

    function transferUnclaimedFunds(address _project) external {
        address lab = _projectToLab[_project];
        (uint256 campaignId, uint256 amountToPool) = IVCProject(_project).transferUnclaimedFunds();
        emit SttrUnclaimedFundsTransferredToPool(lab, _project, campaignId, amountToPool);
    }

    function withdrawToPool(address project, IERC20 currency) external {
        uint256 transferedAmount = IVCProject(project).withdrawToPool(currency);
        emit SttrWithdrawToPool(project, currency, transferedAmount);
    }

    /*********** VIEW FUNCTIONS ***********/

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function getCurrency() external view returns (address) {
        return address(_currency);
    }

    function getCampaignStatus(address _project, uint256 _campaignId)
        public
        view
        returns (IVCProject.CampaignStatus currentStatus)
    {
        return IVCProject(_project).getCampaignStatus(_campaignId);
    }

    function isValidProject(address _lab, address _project) external view returns (bool) {
        return _projectToLab[_project] == _lab;
    }

    function isWhitelistedLab(address _lab) external view returns (bool) {
        return _isWhitelistedLab[_lab];
    }

    function areActiveProjects(address[] memory _projects) external view returns (bool[] memory) {
        bool[] memory areActive = new bool[](_projects.length);
        for (uint256 i = 0; i < _projects.length; i++) {
            areActive[i] = _activeProjects[_projects[i]];
        }
        return areActive;
    }

    /*********** INTERNAL AND PRIVATE FUNCTIONS ***********/

    function _onlyAdmin() internal view {
        if (msg.sender != _admin) {
            revert SttrNotAdminError();
        }
    }

    function _onlyLabOwner(address _project) private view {
        if (msg.sender != _projectToLab[_project]) {
            revert SttrNotLabOwnerError();
        }
    }

    function _onlyWhitelistedLab() private view {
        if (_isWhitelistedLab[msg.sender] == false) {
            revert SttrNotWhitelistedLabError();
        }
    }

    function _onlyCoreTeam() private view {
        if (msg.sender != _coreTeam) {
            revert SttrNotCoreTeamError();
        }
    }

    function _checkBeforeFund(address _project, uint256 _amount) internal view returns (address lab) {
        lab = _projectToLab[_project];

        if (_amount == 0) {
            revert SttrFundingAmountIsZeroError();
        }
        if (_activeProjects[_project] == false) {
            revert SttrProjectIsNotActiveError();
        }
        if (lab == msg.sender) {
            revert SttrLabCannotFundOwnProjectError();
        }
        if (!_isWhitelistedLab[lab]) {
            revert SttrBlacklistedLabError();
        }
    }

    function _fundProject(
        address _project,
        uint256 _amount,
        address _user
    ) private returns (uint256 amountToProject, uint256 amountToPool) {
        // do we need to emit the lab address??
        address lab = _checkBeforeFund(_project, _amount);

        amountToProject = _amount;
        amountToPool = 0;

        if (!_noFeeAccounts[msg.sender]) {
            amountToPool = (amountToProject * _poolFeeBps) / _FEE_DENOMINATOR;
            amountToProject -= amountToPool;

            if (!_currency.transferFrom(msg.sender, _pool, amountToPool)) {
                revert SttrERC20TransferError();
            }
            emit SttrPoolFunded(_user, amountToPool);
        }

        if (!_currency.transferFrom(msg.sender, _project, amountToProject)) {
            revert SttrERC20TransferError();
        }

        emit SttrProjectFunded(lab, _project, _user, amountToProject);

        IVCProject(_project).fundProject(amountToProject);
    }

    function _verifyPublishCampaignResults(
        address _project,
        uint256 _campaignId,
        bytes memory _sig
    ) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project, _campaignId));
        _verify(messageHash, _sig);
    }

    function _verifyStartCampaign(
        address _project,
        uint256 _numberOfCampaigns,
        uint256 _target,
        uint256 _duration,
        bytes memory _sig
    ) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project, _numberOfCampaigns, _target, _duration));
        _verify(messageHash, _sig);
    }

    function _verifyCloseProject(address _project, bytes memory _sig) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project));
        _verify(messageHash, _sig);
    }

    function _verify(bytes32 _messageHash, bytes memory _sig) private view {
        // this can change later - "\x19Ethereum Signed Message:\n32"
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));

        if (_recover(ethSignedMessageHash, _sig) != _txValidator) {
            revert SttrInvalidSignatureError();
        }
    }

    function _recover(bytes32 _ethSignedMessageHash, bytes memory _sig) internal pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        signer = ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (_sig.length != 65) {
            revert SttrInvalidSignatureError();
        }

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPoCNft is IERC721 {
    struct Contribution {
        uint256 amount;
        uint256 timestamp;
    }

    struct Range {
        uint240 maxDonation;
        uint16 maxBps;
    }

    event PoCNFTMinted(address indexed user, uint256 amount, uint256 tokenId, bool isPool);
    event PoCBoostRangesChanged(Range[]);

    error PoCUnexpectedAdminAddress();
    error PoCOnlyAdminAllowed();
    error PoCUnexpectedBoostDuration();
    error PoCInvalidBoostRangeParameters();

    function setAdmin(address newAdmin) external; // onlyAdmin

    function grantMinterRole(address _address) external; // onlyAdmin

    function revokeMinterRole(address _address) external; // onlyAdmin

    function grantApproverRole(address _approver) external; // onlyAdmin

    function revokeApproverRole(address _approver) external; // onlyAdmin

    function setPool(address pool) external; // onlyAdmin

    function changeBoostDuration(uint256 newBoostDuration) external; // onlyAdmin

    function changeBoostRanges(Range[] calldata newBoostRanges) external; // onlyAdmin

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external; // only(APPROVER_ROLE)

    //function supportsInterface(bytes4 interfaceId) external view override returns (bool);

    function exists(uint256 tokenId) external returns (bool);

    function votingPowerBoost(address _user) external view returns (uint256);

    function denominator() external pure returns (uint256);

    function getContribution(uint256 tokenId) external view returns (Contribution memory);

    function mint(
        address _user,
        uint256 _amount,
        bool isPool
    ) external; // only(MINTER_ROLE)

    function transfer(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract CanWithdrawERC20 {
    error ERC20WithdrawalFailed();
    event ERC20Withdrawal(address indexed to, IERC20 indexed token, uint256 amount);

    address _to = 0x000000000000000000000000000000000000dEaD;
    mapping(IERC20 => uint256) _balanceNotWithdrawable;

    constructor() {}

    function withdraw(IERC20 _token) external {
        uint256 balanceWithdrawable = _token.balanceOf(address(this)) - _balanceNotWithdrawable[_token];

        if (balanceWithdrawable == 0 || !_token.transfer(_to, balanceWithdrawable)) {
            revert ERC20WithdrawalFailed();
        }
        emit ERC20Withdrawal(_to, _token, balanceWithdrawable);
    }

    function _setTo(address to) internal {
        _to = to;
    }
}