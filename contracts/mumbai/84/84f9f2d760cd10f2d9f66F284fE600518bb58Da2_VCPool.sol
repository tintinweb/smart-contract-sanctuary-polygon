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

import "./IVCPool.sol";
import "../starter/IVCStarter.sol";
import "../tokens/IPoCNft.sol";

contract VCPool is IVCPool {
    address _admin;
    address _starter;
    IPoCNft _pocNft;
    IERC20 _currency;

    // REMARK OFF-CHAIN QUERIES:
    // 1) To obtain the balance of the Pool one has to call _currency.balanceOf(poolAddress)
    // 2) To obtain the totalRaisedFunds, one has to add to 1) the totalWithdrawnAmount obtained from the subgraph

    constructor(address admin) {
        if (admin == address(this) || admin == address(0)) {
            revert PoolUnexpectedAddress();
        }
        _admin = admin;
    }

    ///////////////////////////////////////////////
    //           ONLY-ADMIN FUNCTIONS
    ///////////////////////////////////////////////

    function setPoCNft(address pocNft) external {
        _onlyAdmin();
        if (pocNft == address(this) || pocNft == address(0) || pocNft == address(_pocNft)) {
            revert PoolUnexpectedAddress();
        }
        emit PoCNftChanged(address(_pocNft), pocNft);
        _pocNft = IPoCNft(pocNft);
    }

    function setCurrency(IERC20 currency) external {
        _onlyAdmin();
        _currency = currency;
    }

    function setStarter(address starter) external {
        _onlyAdmin();
        if (starter == address(this) || starter == address(0) || starter == _starter) {
            revert PoolUnexpectedAddress();
        }
        emit StarterChanged(_starter, starter);
        _starter = starter;
    }

    function setAdmin(address admin) external {
        _onlyAdmin();
        if (admin == address(this) || admin == address(0) || admin == address(_admin)) {
            revert PoolUnexpectedAddress();
        }
        emit AdminChanged(_admin, admin);
        _admin = admin;
    }

    function withdraw(
        IERC20 currency,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        if (!currency.transfer(_to, _amount)) {
            revert PoolERC20TransferError();
        }
        emit Withdrawal(currency, _to, _amount);
    }

    // for flash grants
    function withdrawToProject(address _project, uint256 _amount) external {
        _onlyAdmin();
        uint256 available = _currency.balanceOf(address(this));
        if (_amount > available) {
            revert PoolAmountTooHigh();
        }
        _currency.approve(_starter, _amount);
        IVCStarter(_starter).fundProjectOnBehalf(address(this), _project, _amount);
    }

    ///////////////////////////////////////////////
    //         EXTERNAL/PUBLIC FUNCTIONS
    ///////////////////////////////////////////////

    function fund(uint256 _amount) external {
        if (!_currency.transferFrom(msg.sender, address(this), _amount)) {
            revert PoolERC20TransferError();
        }
        _pocNft.mint(msg.sender, _amount, true);
        emit Funding(msg.sender, _amount);
    }

    function getCurrency() external view returns (IERC20) {
        return _currency;
    }

    ///////////////////////////////////////////////
    //        INTERNAL/PRIVATE FUNCTIONS
    ///////////////////////////////////////////////

    function _onlyAdmin() internal view {
        if (msg.sender != _admin) {
            revert PoolNotAdmin();
        }
    }

    function _onlyStarter() internal view {
        if (msg.sender != _starter) {
            revert PoolNotStarter();
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