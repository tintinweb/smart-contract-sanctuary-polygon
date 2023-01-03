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

    /**
     * @dev Allows to set/change the admin of this contract.
     *
     * @notice Only the current {_admin} can invoke this function.
     *
     * @notice The VCAdmin smart contract is supposed to be the {_admin} of this contract.
     *
     * @param admin The address of the new admin.
     */
    function setAdmin(address admin) external;

    /**
     * @dev Allows to set/change the VCPool address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former VCPool address.
     *
     * @param pool The address of the new VCPool contract.
     */
    function setPool(address pool) external;

    /**
     * @dev Allows to set/change the VCProject template contract address.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Newly created projects will clone the new VCProject template, while already deployed projects
     * will retain the former VCProject template.
     *
     * @param newProjectTemplate The address of the newly deployed VCProject contract.
     */
    function setProjectTemplate(address newProjectTemplate) external;

    /**
     * @dev Allows to set/change the Core-Team address. The Core-Team account has special roles in this contract,
     * like whitelist/blacklist a laboratory and appove/reject new projects.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param newCoreTeam The address of the new Core-Team account.
     */
    function setCoreTeam(address newCoreTeam) external;

    /**
     * @dev Allows to set/change the Tx-Validator address. The Tx-Validator is a special account, whose pk is
     * hardcoded in the VC Backend and is used to automate some project/campaign related processes: start a new
     * campaign, publish campaign results, and close project.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param newTxValidator The address of the new Tx-Validator account.
     */
    function setTxValidator(address newTxValidator) external;

    /**
     * @dev Allows to set/change the ERC20 {_currency} address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former ERC20 {_currency} address.
     *
     * @param currency The address of the new ERC20 currency contract.
     */
    function setCurrency(IERC20 currency) external;

    /**
     * @dev Allows to set/change backers timeout.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice The amount of time backers have to withdraw their contribution if the campaign fails.
     *
     * @param newBackersTimeout The amount of time in seconds.
     */
    function setBackersTimeout(uint256 newBackersTimeout) external;

    /**
     * @dev Allows to set/change the VCPool fee. Any project/campaign donation is subject to a fee, which is
     * eventually transferred to VCPool.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former VCPool fee.
     *
     * @param newPoolFeeBps The VCPool fee in basis points.
     */
    function setPoolFeeBps(uint256 newPoolFeeBps) external;

    /**
     * @dev Allows to set an account (address) as a whitelisted lab.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @notice Initially, all accounts are set as blacklisted.
     *
     * @param lab The lab to whitelist.
     */
    function whitelistLab(address lab) external;

    /**
     * @dev Allows to set an account (address) as a blacklisted lab.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @notice Initially, all accounts are set as blacklisted.
     *
     * @param lab The lab to blacklist.
     */
    function blacklistLab(address lab) external;

    /**
     * @dev The are special accounts (e.g. VCPool, marketplaces) whose donations are not subject to any VCPool
     * fee. This function allows to mark addresses as 'no fee accounts'.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param accounts An array of account/contract addresses to be marked as 'no fee accounts'.
     */
    function addNoFeeAccounts(address[] memory accounts) external;

    /**
     * @dev Allows to set/change the minimum duration of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param minCampaignDuration The minimum duration of a campaign in seconds.
     */
    function setMinCampaignDuration(uint256 minCampaignDuration) external;

    /**
     * @dev Allows to set/change the maximum duration of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param maxCampaignDuration The maximum duration of a campaign in seconds.
     */
    function setMaxCampaignDuration(uint256 maxCampaignDuration) external;

    /**
     * @dev Allows to set/change the minimum target of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param minCampaignTarget The minimum target of a campaign in ERC20 {_currency}.
     */
    function setMinCampaignTarget(uint256 minCampaignTarget) external;

    /**
     * @dev Allows to set/change the maximum target of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param maxCampaignTarget The maximum target of a campaign in ERC20 {_currency}.
     */
    function setMaxCampaignTarget(uint256 maxCampaignTarget) external;

    /**
     * @dev Allows to set/change the soft target basis points. Then, the 'soft-target' of a campaign is computed
     * as target * {_softTargetBps}. The 'soft-target' is the minimum amount a campaign must raise in order to be
     * declared as FUNDED.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param softTargetBps The soft target percentage in basis points
     */
    function setSoftTargetBps(uint256 softTargetBps) external;

    /**
     * @dev Allows to set/change the VCPoCNft address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param pocNft The address of the new VCPoCNft contract.
     */
    function setPoCNft(address pocNft) external;

    /**
     * @dev Allows the {_coreTeam} to approve or reject the creation of a new project. The (whitelisted) lab had
     * to previously request the creation of the project, using 'createProjectRequest'.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @param lab The address of the lab who had requested the creation of a new project.
     * @param accepted True = accepted, false = rejected.
     *
     * @return newProject The address of the created (and deployed) project.
     */
    function createProject(address lab, bool accepted) external returns (address newProject);

    /**
     * @dev Allows a whitelist lab to request the creation of a project. The project will be effetively created
     * after the Core-Team accepts it.
     *
     * @notice Only whitelisted labs can invoke this function.
     */
    function createProjectRequest() external;

    /**
     * @dev Allows to fund a project directly, i.e. the contribution received is not linked to any of its
     * campaigns. The donation is made in the protocol ERC20 {_currency}. The donator recieves a PoCNFT for their
     * contribution.
     *
     * @param project The address of the project beneficiary of the donation.
     * @param amount The amount of the donation.
     */
    function fundProject(address project, uint256 amount) external;

    /**
     * @dev Allows to fund a project directly (the contribution received is not linked to any of its campaigns)
     * on behalf of another user/contract. The donation is made in the protocol ERC20 {_currency}. The donator
     * does not receive a PoCNFT for their contribution.
     *
     * @param user The address of the user on whose behalf the donation is made.
     * @param project The address of the project beneficiary of the donation.
     * @param amount The amount of the donation.
     */
    function fundProjectOnBehalf(address user, address project, uint256 amount) external;

    /**
     * @dev Allows the lab owner of a project to close it. A closed project cannot start new campaigns nor receive
     * new contributions. The Tx-Validator has to 'approve' this operation by providing a signed message.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @notice Only VCProjects with a zero balance (the lab owner must have previously withdrawn all funds) and
     * non-active campaigns can be closed.
     *
     * @param project The address of the project to be closed.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256(["address", "address"], [labAddress, projectAddress]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function closeProject(address project, bytes memory sig) external;

    /**
     * @dev Allows the lab owner of a project to start a new campaign.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project.
     * @param target The amount of ERC20 {_currency} expected to be raised.
     * @param duration The duration of the campaign in seconds.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256( ["address","address","uint256","uint256","uint256"],
     *    [labAddress, projectAddress, numberOfCampaigns, target, duration]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function startCampaign(
        address project,
        uint256 target,
        uint256 duration,
        bytes memory sig
    ) external returns (uint256 campaignId);

    /**
     * @dev Allows the lab owner of the project to publish the results of their research achievements
     * related to their latest SUCCEEDED campaign.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256(["address","address","uint256"],
     *      [labAddress, projectAddress, campaignId]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function publishCampaignResults(address project, bytes memory sig) external;

    /**
     * @dev Allows a user to fund the last running campaign, only when it is ACTIVE.
     *
     * @param project The address of the project.
     * @param amount The amount of ERC20 {_currency} donated by the user.
     */
    function fundCampaign(address project, uint256 amount) external;

    /**
     * @dev Allows a backer to mint a PoCO NFT in return for their contribution to a campaign. The campaign must
     * be FUNDED, or NOT_FUNDED and claming_time > {_backersDeadline} time.
     *
     * @param project The address of the project to which the campaign belongs.
     * @param campaignId The id of the campaign.
     */
    function backerMintPoCNft(address project, uint256 campaignId) external;

    /**
     * @dev Allows a user to withdraw funds previously contributed to the last running campaign, only when NOT
     * FUNDED.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function backerWithdrawDefeated(address project) external;

    /**
     * @dev Allows the lab owner of the project to withdraw the raised funds of the last running campaign, only
     * when FUNDED.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function labCampaignWithdraw(address project) external;

    /**
     * @dev Allows the lab owner of the project to withdraw funds raised from direct contributions.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function labProjectWithdraw(address project) external;

    /**
     * @dev Allows any user to transfer unclaimed campaign funds to VCPool after {_backersDeadline} date, only
     * when NOT FUNDED.
     *
     * @param _project The address of the project to which the campaign belongs.
     */
    function transferUnclaimedFunds(address _project) external;

    /**
     * @dev Users can send any ERC20 asset to this contract simply by interacting with the 'transfer' method of
     * the corresponding ERC20 contract. The funds received in this way do not count for the Project balance
     * and are allocated to VCPool. This function allows any user to transfer these funds to VCPool.
     *
     * @param project The address of the project.
     * @param currency The ERC20 currency of the funds to be transferred to VCPool.
     */
    function withdrawToPool(address project, IERC20 currency) external;

    /**
     * @dev Returns the Pool Fee in Basis Points
     */
    function poolFeeBps() external view returns (uint256);

    /**
     * @dev Returns Min Campaing duration in seconds.
     */
    function minCampaignDuration() external view returns (uint256);

    /**
     * @dev Returns Max Campaing duration in seconds.
     */
    function maxCampaignDuration() external view returns (uint256);

    /**
     * @dev Returns Min Campaign target in USD.
     */
    function minCampaignTarget() external view returns (uint256);

    /**
     * @dev Returns Max Campaign target is USD.
     */
    function maxCampaignTarget() external view returns (uint256);

    /**
     * @dev Returns Soft Target in basis points.
     */
    function softTargetBps() external view returns (uint256);

    /**
     * @dev Returns Fee Denominator in basis points.
     */
    function feeDenominator() external view returns (uint256);

    /**
     * @dev Returns the address of VCStarter {_admin}.
     *
     * @notice The admin of this contract is supposed to be the VCAdmin smart contract.
     */
    function getAdmin() external view returns (address);

    /**
     * @dev Returns the address of this contract ERC20 {_currency}.
     */
    function getCurrency() external view returns (address);

    /**
     * @dev Returns the campaign status of a given project.
     *
     * @param project The address of the project to which the campaign belongs.
     * @param campaignId The id of the campaign.
     *
     * @return currentStatus
     */
    function getCampaignStatus(
        address project,
        uint256 campaignId
    ) external view returns (IVCProject.CampaignStatus currentStatus);

    /**
     * @dev Checks if a given project (address) belongs to a given lab.
     *
     * @param lab The address of the lab.
     * @param project The address of the project.
     *
     * @return True if {_lab} is the owner of {_project}, false otherwise.
     */
    function isValidProject(address lab, address project) external view returns (bool);

    /**
     * @dev Checks if a certain laboratory (address) is whitelisted.
     *
     * @notice Only whitelisted labs can create projects and start new campaigns.
     *
     * @param lab The address of the lab.
     *
     * @return True if {_lab} is whitelisted, False otherwise.
     */
    function isWhitelistedLab(address lab) external view returns (bool);

    /**
     * @dev Checks if certain addresses correspond to active projects.
     *
     * @param projects An array of addresses.
     *
     * @return An array of booleans of the same length as {_projects}, where its ith position is set to true if
     * and only if {projects[i]} correspondes to an active project.
     */
    function areActiveProjects(address[] memory projects) external view returns (bool[] memory);
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
        uint256 minCampDuration,
        uint256 maxCampDuration,
        uint256 minCampTarget,
        uint256 maxCampTarget,
        uint256 softTrgtBps
    ) {
        _pool = pool;
        _admin = admin;
        _coreTeam = coreTeam;
        _txValidator = txValidator;
        _projectTemplate = projectTemplate;

        _minCampaignDuration = minCampDuration;
        _maxCampaignDuration = maxCampDuration;
        _minCampaignTarget = minCampTarget;
        _maxCampaignTarget = maxCampTarget;
        _softTargetBps = softTrgtBps;
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

    function setCurrency(IERC20 _newCurrency) external {
        _onlyAdmin();
        _currency = _newCurrency;
    }

    function setBackersTimeout(uint256 _newBackersTimeout) external {
        _onlyAdmin();
        _backersTimeout = _newBackersTimeout;
    }

    function setPoolFeeBps(uint256 _newPoolFeeBps) external {
        _onlyAdmin();
        _poolFeeBps = _newPoolFeeBps;
    }

    function whitelistLab(address _lab) external {
        _onlyCoreTeam();

        if (_isWhitelistedLab[_lab] == true) {
            revert SttrLabAlreadyWhitelistedError();
        }
        _isWhitelistedLab[_lab] = true;
        emit SttrWhitelistedLab(_lab);
    }

    function blacklistLab(address _lab) external {
        _onlyCoreTeam();

        if (_isWhitelistedLab[_lab] == false) {
            revert SttrLabAlreadyBlacklistedError();
        }
        _isWhitelistedLab[_lab] = false;
        emit SttrBlacklistedLab(_lab);
    }

    function addNoFeeAccounts(address[] memory _accounts) external {
        _onlyAdmin();
        for (uint256 i = 0; i < _accounts.length; i++) _noFeeAccounts[_accounts[i]] = true;
    }

    function setMinCampaignDuration(uint256 _newMinCampaignDuration) external {
        _onlyAdmin();
        if (_minCampaignDuration == _newMinCampaignDuration || _newMinCampaignDuration >= _maxCampaignDuration) {
            revert SttrMinCampaignDurationError();
        }
        _minCampaignDuration = _newMinCampaignDuration;
        emit SttrSetMinCampaignDuration(_newMinCampaignDuration);
    }

    function setMaxCampaignDuration(uint256 _newMaxCampaignDuration) external {
        _onlyAdmin();
        if (_maxCampaignDuration == _newMaxCampaignDuration || _newMaxCampaignDuration <= _minCampaignDuration) {
            revert SttrMaxCampaignDurationError();
        }
        _maxCampaignDuration = _newMaxCampaignDuration;
        emit SttrSetMaxCampaignDuration(_newMaxCampaignDuration);
    }

    function setMinCampaignTarget(uint256 _newMinCampaignTarget) external {
        _onlyAdmin();
        if (_minCampaignTarget == _newMinCampaignTarget || _newMinCampaignTarget >= _maxCampaignTarget) {
            revert SttrMinCampaignTargetError();
        }
        _minCampaignTarget = _newMinCampaignTarget;
        emit SttrSetMinCampaignTarget(_newMinCampaignTarget);
    }

    function setMaxCampaignTarget(uint256 _newMaxCampaignTarget) external {
        _onlyAdmin();
        if (_maxCampaignTarget == _newMaxCampaignTarget || _newMaxCampaignTarget <= _minCampaignTarget) {
            revert SttrMaxCampaignTargetError();
        }
        _maxCampaignTarget = _newMaxCampaignTarget;
        emit SttrSetMaxCampaignTarget(_newMaxCampaignTarget);
    }

    function setSoftTargetBps(uint256 _newSoftTargetBps) external {
        _onlyAdmin();
        if (_softTargetBps == _newSoftTargetBps || _newSoftTargetBps > _FEE_DENOMINATOR) {
            revert SttrSoftTargetBpsError();
        }
        _softTargetBps = _newSoftTargetBps;
        emit SttrSetSoftTargetBps(_newSoftTargetBps);
    }

    function setPoCNft(address _newPocNft) external {
        _onlyAdmin();
        _poCNft = IPoCNft(_newPocNft);
        emit SttrPoCNftSet(_newPocNft);
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

    function fundProjectOnBehalf(address _user, address _project, uint256 _amount) external {
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

    function poolFeeBps() external view returns (uint256) {
        return _poolFeeBps;
    }

    function minCampaignDuration() external view returns (uint256) {
        return _minCampaignDuration;
    }

    function maxCampaignDuration() external view returns (uint256) {
        return _maxCampaignDuration;
    }

    function minCampaignTarget() external view returns (uint256) {
        return _minCampaignTarget;
    }

    function maxCampaignTarget() external view returns (uint256) {
        return _maxCampaignTarget;
    }

    function softTargetBps() external view returns (uint256) {
        return _softTargetBps;
    }

    function feeDenominator() external pure returns (uint256) {
        return _FEE_DENOMINATOR;
    }

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function getCurrency() external view returns (address) {
        return address(_currency);
    }

    function getCampaignStatus(
        address _project,
        uint256 _campaignId
    ) public view returns (IVCProject.CampaignStatus currentStatus) {
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

    function _verifyPublishCampaignResults(address _project, uint256 _campaignId, bytes memory _sig) internal view {
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

    function _split(bytes memory _sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
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