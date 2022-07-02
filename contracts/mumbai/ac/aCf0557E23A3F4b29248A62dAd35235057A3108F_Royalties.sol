//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IRoyalties, IERC20 } from "./IRoyalties.sol";
import { RoyalUtil } from "../shared/RoyalUtil.sol";
import { RoyalPausableUpgradeable } from "../utils/RoyalPausableUpgradeable.sol";
import { IRoyal1155LDA } from "../ldas/IRoyal1155LDA.sol";
import { EIP712Upgradeable, ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

/**
 * @title Royalties
 * @author Royal
 *
 * @notice Supports the distribution of periodic payments to ERC-1155 holders on a pro-rata basis.
 *
 *  - Anyone may make a deposit by specifying a tier ID and amount. Any given
 *    payment is split evenly among the token holders of a tier.
 *
 *  - Funds are assigned to token holders at the time that the payment is received in the smart
 *    contract.
 *
 *  How it works
 *  On deposit, we generate a deposit id `id`, a monotonic id scoped to a tier. We then map that `id` to
 *      - `_DEPOSIT_TO_REFUND_ADDRESS` — the refund address for the deposit `id`
 *      - `_DEPOSIT_TO_TIMESTAMP_` — the timestamp of the deposit
 *      - `_DEPOSIT_TO_DEPOSITOR_` — the depositor of the deposit
 *      - `_CLAIMS_BY_DEPOSIT_` — the number of shares that have claimed the funds from that deposit
 *      - `_CUMULATIVE_DEPOSITS_` — the cumulative deposits made for a tier at the time of the deposit. So if deposit 1 was made with $10, and deposit 2 was made with $15, then deposit 1 ⇒ $10 and deposit 2 ⇒ $25

 *  Later, when an account is settled (on LDA transfer or account claim), we update the following state:
 *      - We update the `claimable` , which is the amount a user can claim, based on their pro rata share of the deposits that have come in since the last settlement or reclaim. Here’s how it works:
 *      - If a reclaim has happened on a deposit id more recent than our last settled deposit id, we set the cached index to 0, since all cached claimable funds have been reclaimed
 *      - We then calculate a new claimable amount, based on the payment index diff between the last settled and most recent deposit ids, multiplied by our pro rata share of the tier, and add it to the cached index, returning the sum

 *  Later, on claim, we:
 *      - Update `_CLAIMS_BY_DEPOSIT_` for the current deposit id to add the number of tokens we are currently claiming for the user.
 *      - For each token being claimed, subtract one from the previous deposit that token was claimed at, if applicable.
 *      - Update `claimable = 0`, etc

 *  Finally, on reclaim, we:
 *      - Sweep from the most recent deposit to the last reclaimed deposit for a tier, marking the number of tokens that have been claimed for that tier
 *      - Once we get to the target deposit id, we reclaim / refund the percentage of the deposit that has not already been claimed, based on the sweeped value
 *      - We continue to refund all the deposits < the target deposit until we have either got to a deposit that is fully reclaimed, or already reclaimed.

 *  Future work:
 *      - Support for multiple or different ERC20s, or “migrate” to a different ERC20?
 *      - Generate yield from funds at rest.
 */

contract Royalties is
    IRoyalties,
    RoyalPausableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeCastUpgradeable for uint256;

    //------------------ Constants ------------------//

    uint256 constant public PRO_RATA_BASE = 10 ** 18;
    uint256 constant public EIGHTEEN_MONTHS = 47340000; // eighteen months in seconds, averaged
    bytes32 constant private _DEPOSIT_TYPEHASH =
        keccak256(
            "Deposit(address depositor,uint128 tierId,uint256 amount,address refundAddress,uint256 nonce,uint256 deadline)"
        );

    bytes32 constant private _CLAIM_TYPEHASH =
        keccak256(
            "Claim(address claimer,uint128[] tierIds,address recipient,uint256 nonce,uint256 deadline)"
        );

    //------------------ Storage ------------------//

    IERC20                                          internal _PAYMENT_ERC20_;
    IRoyal1155LDA                                   internal _LDA_;

    mapping(address => CountersUpgradeable.Counter) private _NONCES_;
    mapping(uint256 => uint256)                     private _LATEST_DEPOSIT_ID_; // tier => most recently used depositId
    mapping(uint256 => uint256)                     private _LAST_RECLAIMED_DEPOSITS_; // tierId => depositId
    mapping(uint256 => mapping(uint256 => address)) private _DEPOSIT_TO_REFUND_ADDRESS; // tierId => deposit => refund address
    mapping(uint256 => mapping(uint256 => address)) private _DEPOSIT_TO_DEPOSITOR_; // tierId => deposit => depositor
    mapping(uint256 => mapping(uint256 => uint256)) private _DEPOSIT_TO_TIMESTAMP_; // tierId => deposit => timestamp
    mapping(uint256 => mapping(uint256 => uint256)) private _CLAIMS_BY_DEPOSIT_; // tierId => deposit => num claimed shares
    mapping(uint256 => mapping(uint256 => uint256)) private _DEPOSIT_TO_AMOUNT_; // tierId => deposit => amount deposited
    mapping(uint256 => mapping(uint256 => uint256)) private _CUMULATIVE_DEPOSITS_; // tierId => deposit => cumulative deposit
    mapping(uint256 => mapping(address => uint256)) private _LAST_SETTLED_DEPOSITS_; // tierId => user => depositId
    mapping(uint256 => mapping(address => uint256)) private _LAST_CLAIMED_DEPOSITS_; // tierId => user => depositId
    mapping(uint256 => mapping(address => uint256)) private _CLAIMABLE_; // tierId => user => amount owed
    mapping(uint128 => uint256)                     private _CACHED_TOTAL_COUNT_FOR_TIER_; // tierId => total count
    mapping(uint128 => mapping(uint128 => uint256)) private _TOKEN_TO_TIER_TO_LAST_CLAIMED_DEPOSIT_; // tokenId => tierId => depositId

    //------------------ Initializer functions ------------------//

    function initialize(
        address ldaAddress,
        address paymentAddress
    )
        external
        initializer
    {
        __Royalties_init_unchained(ldaAddress, paymentAddress);
    }

    function __Royalties_init_unchained(
        address ldaAddress,
        address paymentAddress
    )
        internal
        initializer
    {
        __RoyalPausableUpgradeable_init();
        __EIP712_init("Royalties", "1");
        _PAYMENT_ERC20_ = IERC20(paymentAddress);
        _LDA_ = IRoyal1155LDA(ldaAddress);
        __ReentrancyGuard_init();
    }

    //------------------ External functions ------------------//

    /**
     *
     * @notice Deposit a specified amount of _PAYMENT_ERC20_ for a particular tierId, with any unclaimed funds reclaimable at refundAddress.
     *
     * @param  depositor                  The address of the depositor. Must be msg.sender.
     * @param  tierId                     The tierId to deposit funds to.
     * @param  amount                     The amount of _PAYMENT_ERC20_ to transfer from the depositor to the contract.
     * @param  refundAddress              If after 18 months, the deposit is fully or partially unclaimed, funds are reclaimable to the refund address.
     */

    function deposit(
        address depositor,
        uint128 tierId,
        uint256 amount,
        address refundAddress
    )
        override
        external
        nonReentrant
        returns (uint256)
    {
        require(
            depositor == msg.sender,
            "Invalid depositor"
        );
        return _deposit(depositor, tierId, amount, refundAddress);
    }


    /**
     *
     * @notice EIP-712 compliant function to deposit.
     * Deposit a specified amount of _PAYMENT_ERC20_ for a particular tierId, with any unclaimed funds reclaimable at refundAddress.
     *
     * @param  depositor                  The address of the depositor. Must be the signer.
     * @param  tierId                     The tierId to deposit funds to.
     * @param  amount                     The amount of _PAYMENT_ERC20_ to transfer from the depositor to the contract.
     * @param  refundAddress              If after 18 months, the deposit is fully or partially unclaimed, funds are reclaimable to the refund address.
     * @param  deadline                   Deadline for the signature to be valid, in unix seconds
     * @param  v                          Signature component V
     * @param  r                          Signature component R
     * @param  s                          Signature component S
     */

    function depositWithSig(
        address depositor,
        uint128 tierId,
        uint256 amount,
        address refundAddress,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        override
        external
        nonReentrant
        returns (uint256)
    {
        require(
            deadline >= block.timestamp,
            "Deadline past"
        );
        bytes32 structHash = keccak256(abi.encode(_DEPOSIT_TYPEHASH, depositor, tierId, amount, refundAddress, _useNonce(depositor), deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(digest, v, r, s);
        require(
            signer == depositor,
            "Invalid signer"
        );
        return _deposit(depositor, tierId, amount, refundAddress);
    }

    /**
     *
     * @notice Claims in batch all available deposits for the user for the given tierIds.
     *
     * @param  claimer                    The address of the claimer. Must be msg.sender.
     * @param  tierIds                    The tierIds to claim.
     */

    function claim(
        address claimer,
        uint128[] calldata tierIds,
        address recipient
    )
        override
        external
        nonReentrant
        returns (uint256[] memory)
    {
        require(
            claimer == msg.sender,
            "Invalid claimer"
        );
        return _claim(claimer, tierIds, recipient);
    }

    /**
     *
     * @notice EIP-712 compliant function to claim.
     * Claims in batch all available deposits for the user for the given tierIds.
     *
     * @param  claimer                    The address of the claimer. Must be msg.sender.
     * @param  tierIds                    The tierIds to claim.
     * @param  deadline                   Deadline for the signature to be valid, in unix seconds
     * @param  v                          Signature component V
     * @param  r                          Signature component R
     * @param  s                          Signature component S
     */

    function claimWithSig(
        address claimer,
        uint128[] calldata tierIds,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        override
        external
        nonReentrant
        returns (uint256[] memory)
    {
        require(
            deadline >= block.timestamp,
            "Deadline past"
        );
        bytes32 structHash = keccak256(abi.encode(_CLAIM_TYPEHASH, claimer, keccak256(abi.encodePacked(tierIds)), recipient, _useNonce(claimer), deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(digest, v, r, s);
        require(
            signer == claimer,
            "Invalid signer"
        );
        return _claim(claimer, tierIds, recipient);
    }

    /**
     *
     * @notice Reclaims in batch all funds in the (tierId, deposit) pair if the deposit is >= 18 months old
     * @dev depositIds and tierIds must be the same length, as there must be a 1 to 1 map between the tierId and the corresponding depositId to reclaim.
     * @param  depositIds                 The deposits for which to attempt reclaim
     * @param  tierIds                    The tierIds for which to reclaim.
     */

    function reclaim(
        uint256[] calldata depositIds,
        uint128[] calldata tierIds
    )
        override
        external
        nonReentrant
        returns (uint256[] memory)
    {
        return _reclaim(depositIds, tierIds);
    }

    /**
     *
     * @notice hook for the LDA contract to call on any token transfer (either mint or user -> user transfer)
     * @param  from                       The address of the user who currently owns the LDA, if any
     * @param  to                         The address of the user who, after the transaction, will own the LDA, if any
     * @param  tierId                     The tierId of the LDA that is being transferred
     */

    function onLdaTokenTransfer(
        address from,
        address to,
        uint128 tierId
    )
        override
        external
        nonReentrant
    {
        if (from != address(0)) {
            _settleAccount(from, tierId);
        }
        if (to != address(0)) {
            _settleAccount(to, tierId);
        }
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     */
    function incrementNonce(
        address owner
    )
        override
        external
        nonReentrant
        returns (uint256)
    {
        require(owner == msg.sender, "Forbidden increment");
        return _useNonce(owner);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */

    function nonces(
        address owner
    )
        override
        external
        view
        returns (uint256)
    {
        return _NONCES_[owner].current();
    }


    /**
     *
     * @notice The owner can increment the last reclaimed deposit id to an arbitrary valid depositId
     * @param  tierId                     The tier id to increment
     * @param  depositId                  The deposit id to set the last reclaimed index to
     */

    function setLastReclaimedDepositId(
        uint128 tierId,
        uint256 depositId
    )
        override
        external
        onlyOwner
    {
        require(depositId <= _LATEST_DEPOSIT_ID_[tierId], "Invalid deposit id");
        _LAST_RECLAIMED_DEPOSITS_[tierId] = depositId;
    }

    /**
     *
     * @notice View the last reclaimed deposit id for a tier.
     * @param  tierId                     The tier id for which to view the last reclaimed deposit id
     */

    function getLastReclaimedDepositId(
        uint128 tierId
    )
        override
        external
        view
        returns (uint256)
    {
        return _LAST_RECLAIMED_DEPOSITS_[tierId];
    }

    //------------------ Internal functions ------------------//

    /**
     * @dev Increment the _LATEST_DEPOSIT_ID_ for this tierid and return the new value
     */

    function _nextDepositId(
        uint128 tierId
    )
	    internal
        returns (uint256)
    {
        return ++_LATEST_DEPOSIT_ID_[tierId];
    }

    /**
     * @dev Try to fetch the cached max supply for tier, and on fallback query the LDA contract.
     * NOTE: This relies on there being an IMMUTABLE max supply for tier, which may or may not change in the future.
     */

    function _getMaxSupplyForTier(
        uint128 tierId
    )
        internal
        returns (uint256)
    {
        if (_CACHED_TOTAL_COUNT_FOR_TIER_[tierId] > 0) {
            return _CACHED_TOTAL_COUNT_FOR_TIER_[tierId];
        }
        uint256 totalCount = _LDA_.getTierTotalSupply(tierId);
        _CACHED_TOTAL_COUNT_FOR_TIER_[tierId] = totalCount;
        return totalCount;
    }



    /// @dev Internal function that takes a deposit, either by msg.sender or via an EIP-712 signature.
    function _deposit(
        address depositor,
        uint128 tierId,
        uint256 amount,
        address refundAddress
    )
        internal
        returns (uint256)
    {
        uint256 id = _nextDepositId(tierId);
        _DEPOSIT_TO_REFUND_ADDRESS[tierId][id] = refundAddress;
        _DEPOSIT_TO_TIMESTAMP_[tierId][id] = block.timestamp;
        _DEPOSIT_TO_DEPOSITOR_[tierId][id] = depositor; // allow EIP-712 as well
        _DEPOSIT_TO_AMOUNT_[tierId][id] = amount;
        _CUMULATIVE_DEPOSITS_[tierId][id] = _CUMULATIVE_DEPOSITS_[tierId][id - 1] + amount;
        _PAYMENT_ERC20_.transferFrom(depositor, address(this), amount);
        emit Deposited(depositor, tierId, amount, id);
        return id;
    }


    /**
     * @dev Internal function that receives a claim, either by msg.sender or via an EIP-712 signature.
     */

    function _claim(
        address claimer,
        uint128[] calldata tierIds,
        address recipient
    )
        internal
        returns (uint256[] memory)
    {
        uint256[] memory claimableArr = new uint256[](tierIds.length);
        uint256 i;
        for (i = 0; i < tierIds.length; i++) {
            uint128 tierId = tierIds[i];
            uint256 currDeposit = _LATEST_DEPOSIT_ID_[tierId];
            uint128[] memory ownedTokens = _LDA_.getOwnedTokens(tierId, claimer);
            uint256 numOwnedTokens = ownedTokens.length;
            uint256 claimableAmount = _settleAccount(claimer, tierId);
            // O(n) in number of tokens
            for (uint256 j = 0; j < numOwnedTokens; j++) {
                uint128 tokenId = ownedTokens[j];
                uint256 lastClaimedDepositId = _TOKEN_TO_TIER_TO_LAST_CLAIMED_DEPOSIT_[tokenId][tierId];
                if (lastClaimedDepositId > 0) {
                    _CLAIMS_BY_DEPOSIT_[tierId][lastClaimedDepositId] -= 1;
                }
                _CLAIMS_BY_DEPOSIT_[tierId][currDeposit] += 1;
                _TOKEN_TO_TIER_TO_LAST_CLAIMED_DEPOSIT_[tokenId][tierId] = currDeposit;
            }
            _PAYMENT_ERC20_.transfer(recipient, claimableAmount);
            _CLAIMABLE_[tierId][claimer] = 0;
            _LAST_CLAIMED_DEPOSITS_[tierId][claimer] = currDeposit;
            claimableArr[i] = claimableAmount;
            emit Claimed(claimer, tierId, claimableAmount, recipient);
        }
        return claimableArr;
    }

    /**
     * @dev Internal function to reclaim available deposits mapping 1 to 1 with the passed tierIds.
     */

    function _reclaim(
        uint256[] calldata depositIds,
        uint128[] calldata tierIds
    )
        internal
        returns (uint256[] memory)
    {
        uint256[] memory reclaimedArr = new uint256[](tierIds.length);
        require(
            depositIds.length == tierIds.length,
            "Invalid arrays"
        );
        for (uint256 i = 0; i < tierIds.length; i++) {
            uint128 tierId = tierIds[i];
            uint256 targetDepositId = depositIds[i];

            {
                // require that the deposit is older than 18 months old.
                require(
                    _DEPOSIT_TO_TIMESTAMP_[tierId][targetDepositId] + EIGHTEEN_MONTHS < block.timestamp,
                    "Deposit too recent"
                );
                require(
                    _LAST_RECLAIMED_DEPOSITS_[tierId] < targetDepositId,
                    "Already reclaimed"
                );
            }

            // sweep from most to least recent deposit, tallying claims made per tier.
            // if we have seen all claims made before the deposit id in question, abort
            // because there is nothing to reclaim.
            uint256 maxSupplyForTier = _getMaxSupplyForTier(tierId);
            uint256 unclaimedSupplyForTier = maxSupplyForTier;
            uint256 reclaimed = 0;
            for (uint256 j = _LATEST_DEPOSIT_ID_[tierId]; j > _LAST_RECLAIMED_DEPOSITS_[tierId]; j--) {
                unclaimedSupplyForTier -= _CLAIMS_BY_DEPOSIT_[tierId][j];
                if (unclaimedSupplyForTier <= 0) {
                    break;
                }
                // if we are at an eligible reclaimable deposit id
                if (j <= targetDepositId) {
                    address refundAddress = _DEPOSIT_TO_REFUND_ADDRESS[tierId][j];
                    uint256 depositAmount = _DEPOSIT_TO_AMOUNT_[tierId][j];
                    uint256 amountToReclaim = (depositAmount * unclaimedSupplyForTier) / maxSupplyForTier;
                    _PAYMENT_ERC20_.transfer(refundAddress, amountToReclaim);
                    reclaimed += amountToReclaim;
                    emit Reclaimed(j, refundAddress, tierId, amountToReclaim);
                }
            }

            _LAST_RECLAIMED_DEPOSITS_[tierId] = targetDepositId; // mark everything below this as reclaimed
            reclaimedArr[i] = reclaimed; // nothing to reclaim, all claimed
        }
        return reclaimedArr;
    }

    /**
     * @dev Internal function to calculate, with at leaset to PRO_RATA_BASE significant digits, the ownedTokenCount / totalCount
     */

    function _getProRataShare(
        uint256 ownedTokenCount,
        uint256 totalCount
    )
        internal
        pure
        returns (uint256)
    {
        return PRO_RATA_BASE * ownedTokenCount / totalCount;
    }

    /**
     * @dev Internal function that MUST run on every state mutation affecting users and their LDAs. Particularly,
     * on LDA transfer or deposit claiming, this must run to recalculate the owned percentage of the total claimable pie.
     * This function is idempotent, so settling it at any point should yield the same number of claimable units at claim time.
     */

    function _settleAccount(
        address ldaHolder,
        uint128 tierId
    )
        internal
        returns (uint256)
    {
        // Get total supply for the tier.
        uint256 totalCount = _getMaxSupplyForTier(tierId);

        // Get tokens owner by the account.
        uint128[] memory ownedTokens = _LDA_.getOwnedTokens(tierId, ldaHolder);
        uint256 numOwnedTokens = ownedTokens.length;

        uint256 lastDepositId = _LATEST_DEPOSIT_ID_[tierId];
        uint256 _LAST_RECLAIMED_DEPOSITS__ = _LAST_RECLAIMED_DEPOSITS_[tierId];

        if (_LAST_RECLAIMED_DEPOSITS__ > _LAST_SETTLED_DEPOSITS_[tierId][ldaHolder]) {
            // A reclaim occurred, so unclaimed rewards were lost.
            _CLAIMABLE_[tierId][ldaHolder] = 0;
        }

        uint256 startDepositId = MathUpgradeable.max(
            _LAST_SETTLED_DEPOSITS_[tierId][ldaHolder],
            _LAST_RECLAIMED_DEPOSITS__
        );

        _LAST_SETTLED_DEPOSITS_[tierId][ldaHolder] = lastDepositId;

        // short circuit for gas optimization
        if (startDepositId == lastDepositId) {
            return _CLAIMABLE_[tierId][ldaHolder];
        }

        uint256 paymentDiff = _CUMULATIVE_DEPOSITS_[tierId][lastDepositId] - _CUMULATIVE_DEPOSITS_[tierId][startDepositId];
        uint256	newlyClaimable = paymentDiff * _getProRataShare(numOwnedTokens, totalCount) / PRO_RATA_BASE;
        uint256 newClaimable = _CLAIMABLE_[tierId][ldaHolder] + newlyClaimable;

        // Write to storage.
        _CLAIMABLE_[tierId][ldaHolder] = newClaimable;
        return newClaimable;
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     */
    function _useNonce(
        address owner
    )
        internal
        virtual
        returns (uint256)
    {
        CountersUpgradeable.Counter storage nonce = _NONCES_[owner];
        uint256 current = nonce.current();
        nonce.increment();
        return current;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IRoyalties {
    event Deposited(
        address indexed payer,
        uint256 indexed tierId,
        uint256 amount,
        uint256 depositId
    );

    event Claimed(
        address indexed claimer,
        uint256 indexed tierId,
        uint256 amount,
        address recipient
    );

    event Reclaimed(
        uint256 indexed depositId,
        address indexed depositor,
        uint256 indexed tierId,
        uint256 amount
    );

    function depositWithSig(
        address depositor,
        uint128 tierId,
        uint256 amount,
        address refundAddress,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint256);

    function deposit(
        address depositor,
        uint128 tierId,
        uint256 amount,
        address refundAddress
    )
        external
        returns (uint256);

    function onLdaTokenTransfer(
        address from,
        address to,
        uint128 tierId
    )
        external;

    function claimWithSig(
        address claimer,
        uint128[] calldata tierIds,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint256[] memory);

    function claim(
        address claimer,
        uint128[] calldata tierIds,
        address recipient
    )
        external
        returns (uint256[] memory);

    function reclaim(
        uint256[] calldata depositIds,
        uint128[] calldata tierIds
    )
        external
        returns (uint256[] memory);

    function nonces(
        address owner
    )
        external
        view
        returns (uint256);

    function incrementNonce(
        address owner
    )
        external
        returns (uint256);

    function setLastReclaimedDepositId(
        uint128 tierId,
        uint256 depositId
    )
        external;

    function getLastReclaimedDepositId(
        uint128 tierId
    )
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library RoyalUtil {
    /**
     * ROYAL LDA ID FORMAT V2 OVERVIEW
     *
     * The ID of a royal LDA contains 3 pieces of information, the ID of the tier that
     * this token belongs too (GOLD, PLATINUM, DIAMOND etc). A TierID is globally
     * unique across all drops that we do.
     *
     * The second piece of information is the `version` field. It contains a uint16
     * value that represents the version number of this token (up to 65k versions /
     * token).
     *
     * Of course, the final field in this 256 bit field is the TokenID. This TokenID
     * represents the token # in the specific Tier. We generally start counting at
     * token #1 and count up to MaxSupply, but that isn't strictly necessary.
     *
     * [tier_id             | version | token_id         ]
     * [**** **** **** **** | **      | ** **** **** ****]
     * [128 bits            | 16 bits | 112 bits         ]
     */

    uint256 constant UPPER_ISSUANCE_ID_MASK = uint256(type(uint128).max) << 128;
    uint256 constant LOWER_TOKEN_ID_MASK = type(uint112).max;
    uint256 constant TOKEN_VERSION_MASK =
        uint256(type(uint128).max) ^ LOWER_TOKEN_ID_MASK;

    /**
    @dev Compose a raw ldaID from its two composite parts
     */
    function composeLDA_ID(
        uint128 tierID,
        uint256 version,
        uint128 tokenID
    )
        internal
        pure
        returns (uint256 ldaID)
    {
        require(
            tierID != 0 && tokenID != 0,
            "Invalid ldaID"
        ); // NOTE: TierID and TokenID > 0

        require(
            version <= type(uint16).max,
            "invalid version"
        );

        return (uint256(tierID) << 128) + (version << 112) + uint256(tokenID);
    }

    /**
    @dev Decompose a raw ldaID into its two composite parts
     */
    function decomposeLDA_ID(
        uint256 ldaID
    )
        internal
        pure
        returns (
            uint128 tierID,
            uint256 version,
            uint128 tokenID
        )
    {
        tierID = uint128(ldaID >> 128);
        tokenID = uint128(ldaID & LOWER_TOKEN_ID_MASK);
        version = (ldaID & TOKEN_VERSION_MASK) >> 112;
        require(
            tierID != 0 && tokenID != 0,
            "Invalid ldaID"
        ); // NOTE: TierID and TokenID > 0
    }

    /**
     * @notice Returns the “canonical” form of a token ID, which does not change even as extras
     *  are redeemed for a token.
     */
    function getCanonicalTokenId(
        uint256 tokenID
    )
        internal
        pure
        returns (uint256)
    {
        // tokenID AND (INVERTED tokenMask)
        return tokenID & (TOKEN_VERSION_MASK ^ type(uint256).max);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RoyalPausableUpgradeable is PausableUpgradeable, OwnableUpgradeable {

    function __RoyalPausableUpgradeable_init() internal initializer {
        __RoyalPausableUpgradeable_init_unchained();
    }

    function __RoyalPausableUpgradeable_init_unchained() internal initializer {
        __Pausable_init();
        __Ownable_init();
    }

    function pause() public virtual whenNotPaused onlyOwner {
        super._pause();
    }

    function unpause() public virtual whenPaused onlyOwner {
        super._unpause();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRoyal1155LDA {
    function setOwnedTokens(
        uint128 tierId,
        address[] calldata owners,
        uint128[][] calldata balances
    )
        external;

    function createTier(
        uint128 tierID,
        uint256 maxSupply
    )
        external;

    function bulkMintTierLDAsToOwner(
        address recipient,
        uint256[] calldata ldaIDs,
        bytes calldata data
    )
        external;

    function mintLDAToOwner(
        address recipient,
        uint256 ldaID,
        bytes calldata data
    )
        external;

    function setExtrasContract(
        address newExtrasContract
    )
        external;

    function setRoyaltiesContract(
        address newRoyaltiesContract
    )
        external;

    function getOwnedTokens(
        uint128 tierId,
        address owner
    )
        external
        view
        returns (uint128[] memory);

    function getTierTotalSupply(
        uint128 tierId
    )
        external
        view
        returns (uint256);

    function tierExists(
        uint128 tierID
    )
        external
        view
        returns (bool);

    function exists(
        uint256 ldaID
    )
        external
        view
        returns (bool);

    function decomposeLDA_ID(
        uint256 ldaID
    )
        external
        pure
        returns (
            uint128 tierID,
            uint256 version,
            uint128 tokenID
        );

    function composeLDA_ID(
        uint128 tierID,
        uint256 version,
        uint128 tokenID
    )
        external
        pure
        returns (uint256 ldaID);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}