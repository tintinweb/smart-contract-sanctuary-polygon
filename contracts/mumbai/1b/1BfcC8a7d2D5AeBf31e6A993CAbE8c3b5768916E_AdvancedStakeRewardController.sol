// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./actions/AdvancedStakingDataDecoder.sol";
import "./actions/Constants.sol";
import "./actions/StakingMsgProcessor.sol";
import { PRP_VIRTUAL_CONTRACT } from "./common/Constants.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/INftGrantor.sol";
import "./interfaces/IPantherPoolV0.sol";
import "./interfaces/IRewardAdviser.sol";
import "./utils/Claimable.sol";
import "./utils/ImmutableOwnable.sol";
import "./utils/NonReentrant.sol";
import "./utils/Utils.sol";

/**
 * @title AdvancedStakeRewardController
 * @notice It generates UTXOs in the MASP as rewards to stakers for the "Advanced Staking"
 * @dev This contract is supposed to run on the Polygon. Unless otherwise mentioned, other smart
 * contracts are supposed to run on the Polygon also.
 * As the "Reward Adviser" on the "advanced" stakes, every time a new stake is being created, it
 * receives the `getRewardAdvice` call from the `RewardMaster` contract with the `STAKE` action
 * type and the stake data (the `message`) being the call parameters.
 * On the `getRewardAdvice` call received, this contract:
 * - computes the amount of the $ZKP reward to the staker
 * - calls `grant` on the `PantherPoolV0` with the `FOR_ADVANCED_STAKE_GRANT` as the "grant type",
 *  and the staker as the "grantee", getting the amount of PRPs granted from the response
 * - if the `NFT_TOKEN` is non-zero address, it calls `grantOneToken` on the NFT_TOKEN, and gets
 * the `tokenId` of the minted NFT token
 * - calls `generateDeposits` of the PantherPoolV0, providing amounts/parameters of $ZKP, PRP, and
 *   optional NFT as "deposits", as well as "spending pubKeys" and "secrets" (explained below)
 * - returns the "zero reward advice" (with zero `sharesToCreate`) to the RewardMaster.
 *
 * On the "zero" advice, the RewardMaster skips creating "treasure shares" for the staker. This way
 * rewarding gets orchestrated by this contract rather than the RewardMaster.
 *
 * Being called `generateDeposits`, the PantherPoolV0:
 * - requests the `Vault` to take (`transferFrom`) the $ZKP and NFT tokens from this contract
 * - "burns" the PRP grant
 * - generates "UTXOs" with the "spending pubKeys" and "secrets" provided (see bellow).
 *
 * Creating a new stake (i.e. calling the `stake`), the staker generates and provides the "pubKeys"
 * and "secrets" to the Staking. Both the Staking on the mainnet and the Staking on the Polygon
 * encodes them into the STAKE message and passes to the RewardMaster, which passes the message to
 * this contract with the `getRewardAdvice` call. So this contracts get pubKeys and secrets needed
 * for the `generateDeposits`.
 * For stakes on the Polygon, when all contracts (i.e. Staking, RewardMaster and this contract) run
 * on the same network, the RewardMaster on the Polygon calls this contract directly.
 * For stakes made on the mainnet, where the Staking and the RewardMaster run, but this contract is
 * on the Polygon, the RewardMaster on the mainnet sends the STAKE message to the RewardMaster on
 * the Polygon via the PoS bridge and mediator contracts. The RewardMaster on the Polygon handles a
 * bridged STAKE message (calling the `getRewardAdvice`) as if the message had been sent by the
 * Staking on the Polygon.
 *
 * As a prerequisite:
 * - this contract shall be authorized as:
 * -- "RewardAdviser" with the RewardMaster on Polygon for advanced stakes
 * -- "Curator" of the FOR_ADVANCED_STAKE_GRANT with the PantherPoolV0
 * -- "Minter" (or "grantor") with the NFT_TOKEN contract
 * - this contract shall hold enough $ZKP balance to reward stakers
 * - the Vault contract shall be approved to transfer $ZKPs and the NFT tokens from this contract
 * - the $ZKP and the NFT tokens shall be registered as zAssets on the PantherPoolV0.
 */
contract AdvancedStakeRewardController is
    ImmutableOwnable,
    NonReentrant,
    StakingMsgProcessor,
    AdvancedStakingDataDecoder,
    Utils,
    Claimable,
    IERC721Receiver,
    IRewardAdviser
{
    /// @dev Total amount of $ZKPs, PRPd and NFTs (ever) rewarded and staked
    struct Totals {
        uint96 zkpRewards;
        uint96 prpRewards;
        uint24 nftRewards;
        // Accumulated amount of $ZKP (ever) staked, scaled (divided) by 1e15
        uint40 scZkpStaked;
    }

    // solhint-disable var-name-mixedcase

    /// @notice RewardMaster contract instance
    address public immutable REWARD_MASTER;
    /// @notice PantherPoolV0 contract instance
    address public immutable PANTHER_POOL;

    // Address of the $ZKP token contract
    address private immutable ZKP_TOKEN;
    // Address of the NFT token contract
    address private immutable NFT_TOKEN;

    /// @notice (UNIX) Time when staking rewards start to accrue
    uint256 public immutable REWARDING_START;
    // Period (seconds since REWARDING_START) when stakes are rewarded
    // (this period shall not yet be in the past on the contract deployment)
    uint256 private immutable REWARDED_PERIOD;
    /// @notice (UNIX) Time when staking rewards accruals end
    uint256 public immutable REWARDING_END;

    // $ZKP APY at REWARDING_START (the APY declines from this value)
    uint256 private constant START_ZKP_APY = 70;
    // $ZKP APY at the end of (and after) the REWARDED_PERIOD
    // (the APY declines to this value)
    uint256 private constant FINAL_ZKP_APY = 40;
    // $ZKP APY drop (scaled by 1e9) per second of REWARDED_PERIOD
    uint256 private immutable sc_ZKP_APY_PER_SECOND_DROP;

    uint256 private constant ZKP_RESCUE_FORBIDDEN_PERIOD = 90 days;

    /// @notice Block when this contract is deployed
    uint256 public immutable START_BLOCK;

    // solhint-enable var-name-mixedcase

    /// @notice Amount of $ZKPs allocated for rewards
    /// @dev Unlike $ZKPs, PRPs and NFTs are unlimited (not allocated in advance)
    uint256 public zkpRewardsLimit;

    /// @notice Total amounts of $ZKP, PRP and NFT rewarded so far
    Totals public totals;

    uint8 private _reentrancyStatus;

    /// @dev Emitted when new $ZKPs are allocated to reward stakers
    event ZkpRewardLimitUpdate(uint256 newLimit);

    /// @dev Emitted when the reward for a stake is generated
    event RewardGenerated(
        address indexed staker,
        uint256 firstLeafId,
        uint256 zkp,
        uint256 prp,
        uint256 nft
    );

    // It does not change contract storage (only `immutable` values changed).
    constructor(
        address _owner,
        address rewardMaster,
        address pantherPool,
        address zkpToken,
        address nftToken,
        uint32 rewardingStart,
        uint32 rewardedPeriod
    ) ImmutableOwnable(_owner) {
        require(
            // nftToken may be zero address
            rewardMaster != address(0) &&
                pantherPool != address(0) &&
                zkpToken != address(0),
            "ARC:E1"
        );

        REWARD_MASTER = rewardMaster;
        PANTHER_POOL = pantherPool;

        ZKP_TOKEN = zkpToken;
        NFT_TOKEN = nftToken;

        require(
            uint256(rewardingStart) + uint256(rewardedPeriod) > timeNow(),
            "ARC:E4"
        );
        REWARDING_START = uint256(rewardingStart);
        REWARDED_PERIOD = uint256(rewardedPeriod);
        REWARDING_END = uint256(rewardingStart) + uint256(rewardedPeriod);

        sc_ZKP_APY_PER_SECOND_DROP =
            ((START_ZKP_APY - FINAL_ZKP_APY) * 1e9) /
            uint256(rewardedPeriod);

        START_BLOCK = block.number;
    }

    /// @dev To be called by the {RewardMaster} contract on "advanced" `STAKE` and `UNSTAKE` actions.
    /// The caller is trusted to never call w/ the STAKE acton:
    /// - twice for the same stake
    /// - after the rewarded period has ended
    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        override
        returns (Advice memory)
    {
        require(msg.sender == REWARD_MASTER, "ARC: unauthorized");

        if (action == ADVANCED_STAKE) {
            _generateRewards(message);
        } else {
            require(action == ADVANCED_UNSTAKE, "ARC: unsupported action");
        }

        // Return "zero" advice
        return
            Advice(
                address(0), // createSharesFor
                0, // sharesToCreate
                address(0), // redeemSharesFrom
                0, // sharesToRedeem
                address(0) // sendRewardTo
            );
    }

    /// @notice Return the APY for the $ZKP reward at a given time
    function getZkpApyAt(uint256 time) public view returns (uint256) {
        if (time < REWARDING_START) return 0;

        // overflow/underflow impossible due to uint32 input and `if` above
        unchecked {
            uint256 duration = time - REWARDING_START;
            if (duration >= REWARDED_PERIOD) return FINAL_ZKP_APY;

            return
                START_ZKP_APY - (sc_ZKP_APY_PER_SECOND_DROP * duration) / 1e9;
        }
    }

    /// @notice Allocate the $ZKP amount, which this contract holds, for rewards
    /// @dev Anyone may call it
    function setZkpRewardsLimit() external {
        // External calls here are to trusted contracts only - reentrancy guard unneeded

        // TODO: replace low-levels using with `library TransferHelper` in `panther-core`
        uint256 balance;
        {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory data) = ZKP_TOKEN.call(
                // bytes4(keccak256(bytes('balanceOf(address)')));
                abi.encodeWithSelector(0x70a08231, address(this))
            );
            require(success && (data.length != 0), "ARC:E5");
            balance = abi.decode(data, (uint256));
        }

        uint256 limit = zkpRewardsLimit;
        uint256 rewarded = uint256(totals.zkpRewards);
        uint256 remaining = limit - rewarded;

        if (balance > remaining) {
            // Update the limit and approve the Vault to spend from this contract balance
            uint256 newAllocation = balance - remaining;
            uint256 newLimit = limit + newAllocation;

            address vault = IPantherPoolV0(PANTHER_POOL).VAULT();

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory data) = ZKP_TOKEN.call(
                // bytes4(keccak256('approve(address,uint256)'));
                abi.encodeWithSelector(0x095ea7b3, vault, newLimit)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper::safeApprove: approve failed"
            );

            zkpRewardsLimit = limit + newAllocation;
            emit ZkpRewardLimitUpdate(zkpRewardsLimit);
        }
    }

    /// @notice Withdraws unclaimed rewards or accidentally sent token from this contract
    /// @dev May be only called by the {OWNER}
    function rescueErc20(
        address token,
        address to,
        uint256 amount
    ) external {
        require(_reentrancyStatus != 1, "ARC: can't be re-entered");
        _reentrancyStatus = 1;

        require(OWNER == msg.sender, "ARC: unauthorized");
        require(
            (token != ZKP_TOKEN) ||
                (block.timestamp >=
                    (REWARDING_START + ZKP_RESCUE_FORBIDDEN_PERIOD)),
            "ARC: too early withdrawal"
        );

        _claimErc20(token, to, amount);
        _reentrancyStatus = 2;
    }

    // Implementation of the {IERC721Receiver}. It accepts NFT_TOKEN transfers only.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external view override returns (bytes4) {
        return
            msg.sender == NFT_TOKEN
                ? this.onERC721Received.selector // accepted
                : bytes4(0); // rejected
    }

    /// Private and internal functions follow
    // Some of them declared `internal` rather than `private` to ease testing

    function _generateRewards(bytes memory message) internal {
        (
            address staker,
            uint96 stakeAmount, // stake id (irrelevant)
            ,
            uint32 stakedAt,
            uint32 lockedTill, // claimedAt (irrelevant)
            ,
            bytes memory data
        ) = _unpackStakingActionMsg(message);

        require(stakeAmount != 0, "ARC: unexpected zero stakeAmount");
        require(stakedAt >= REWARDING_START, "ARC: unexpected stakedAt");
        require(lockedTill > stakedAt, "ARC: unexpected lockedTill");

        uint256 zkpAmount = 0;
        uint256 prpAmount = 0;
        uint256 nftAmount = 0;
        uint256 nftTokenId = 0;
        {
            Totals memory _totals = totals;

            // Compute amount of the $ZKP reward  and check the limit
            {
                zkpAmount = _computeZkpReward(
                    stakeAmount,
                    lockedTill,
                    stakedAt
                );

                uint256 newTotalZkpReward = uint256(_totals.zkpRewards) +
                    zkpAmount;
                require(
                    zkpRewardsLimit >= newTotalZkpReward,
                    "ARC: too less rewards available"
                );
                _totals.zkpRewards = safe96(newTotalZkpReward);

                uint256 newScZkpStaked = uint256(_totals.scZkpStaked) +
                    uint256(stakeAmount) /
                    1e15;
                // Risk of overflow ignored as the $ZKP max total supply is 1e9 tokens
                _totals.scZkpStaked = uint40(newScZkpStaked);
            }

            // Register PRP grant to this contract (it will be "burnt" for PRP UTXO)
            prpAmount = IPantherPoolV0(PANTHER_POOL).grant(
                address(this),
                FOR_ADVANCED_STAKE_GRANT
            );
            // `prpAmount` values assumed to be too small to cause overflow
            _totals.prpRewards += uint96(prpAmount);

            // TODO: enhance PRP granting to save gas
            // Grant the total just once (for all stakes), then use a part (for every stake),
            // and finally burn unused grant amount, if it remains, in the end

            // If the NFT token contract defined, mint the NFT
            if (NFT_TOKEN != address(0)) {
                // trusted contract called - no reentrancy guard needed
                nftTokenId = INftGrantor(NFT_TOKEN).grantOneToken(
                    address(this)
                );
                nftAmount = 1;
                _totals.nftRewards += 1;
            }

            totals = _totals;
        }

        // Extract public spending keys and "secrets"
        (
            G1Point[OUT_UTXOs] memory pubSpendingKeys,
            uint256[CIPHERTEXT1_WORDS][OUT_UTXOs] memory secrets
        ) = unpackStakingData(data);

        // Finally, generate deposits (i.e. UTXOs with the MASP)
        address[OUT_UTXOs] memory tokens = [
            ZKP_TOKEN,
            PRP_VIRTUAL_CONTRACT,
            NFT_TOKEN
        ];
        uint256[OUT_UTXOs] memory tokenIds = [0, 0, nftTokenId];
        uint256[OUT_UTXOs] memory extAmounts = [
            zkpAmount,
            prpAmount,
            nftAmount
        ];
        uint32 createdAt = safe32TimeNow();
        uint256 leftLeafId = IPantherPoolV0(PANTHER_POOL).generateDeposits(
            tokens,
            tokenIds,
            extAmounts,
            pubSpendingKeys,
            secrets,
            createdAt
        );

        emit RewardGenerated(
            staker,
            leftLeafId,
            zkpAmount,
            prpAmount,
            nftAmount
        );
    }

    // Declared `internal` for testing
    // The calling code is assumed to ensure `lockedTill > stakedAt`
    function _computeZkpReward(
        uint256 stakeAmount,
        uint256 lockedTill,
        uint256 stakedAt
    ) internal view returns (uint256 zkpAmount) {
        // No rewarding after the REWARDING_END
        if (stakedAt > REWARDING_END) return 0;
        uint256 rewardedTill = lockedTill > REWARDING_END
            ? REWARDING_END
            : lockedTill;

        uint256 period = rewardedTill - stakedAt;
        uint256 apy = getZkpApyAt(stakedAt);
        // 3153600000 = 365 * 24 * 3600 seconds * 100 percents
        zkpAmount = (stakeAmount * apy * period) / 3153600000;
    }
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import { CIPHERTEXT1_WORDS, OUT_UTXOs, PUBKEY_WORDS } from "../common/Constants.sol";
import { G1Point } from "../common/Types.sol";

/***
 * @title AdvancedStakingDataDecoder
 * @dev It decodes (unpack) `bytes data` of the 'STAKED' message for "advanced staking"
 */
abstract contract AdvancedStakingDataDecoder {
    // in bytes
    uint256 private constant DATA_LENGTH =
        OUT_UTXOs * (PUBKEY_WORDS + CIPHERTEXT1_WORDS) * 32;
    // in 32-byte memory slots
    uint256 private constant NUM_DATA_SLOTS =
        (DATA_LENGTH / 32) + ((DATA_LENGTH % 32) & 1);

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function unpackStakingData(bytes memory data)
        internal
        pure
        returns (
            G1Point[OUT_UTXOs] memory pubSpendingKeys,
            uint256[CIPHERTEXT1_WORDS][OUT_UTXOs] memory secrets
        )
    {
        require(data.length == DATA_LENGTH, "SMP: unexpected msg length");

        // Let's read bytes as uint256 values
        uint256[NUM_DATA_SLOTS + 1] memory words;
        // the 1st slot is `data.length`, then slots with values follow
        for (uint256 i = 1; i <= NUM_DATA_SLOTS; ++i) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let offset := mul(i, 0x20)
                let word := mload(add(data, offset))
                mstore(add(words, offset), word)
            }
        }
        /*
            `bytes memory sample = 0x00010203..1f2021` stored in the memory like this:
            slot #0: 0x22 - length (34 bytes)
            slot #1: 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
            slot #2: 0x2021000000000000000000000000000000000000000000000000000000000000

            `bytes memory data` expected to be:
            concatenate( // each element is 32-bit long
                pubSpendingKeys[0].x, pubSpendingKeys[0].y,
                pubSpendingKeys[1].x, pubSpendingKeys[1].y,
                pubSpendingKeys[2].x, pubSpendingKeys[2].y,
                (secrets[0])[0], (secrets[0])[1], (secrets[0])[2],
                (secrets[1])[0], (secrets[1])[1], (secrets[1])[2],
                (secrets[2])[0], (secrets[2])[1], (secrets[2])[2],
            )
        */
        for (uint256 i = 0; i < OUT_UTXOs; i++) {
            pubSpendingKeys[i].x = words[i * PUBKEY_WORDS + 1];
            pubSpendingKeys[i].y = words[i * PUBKEY_WORDS + 2];
            for (uint256 k = 0; k < CIPHERTEXT1_WORDS; k++) {
                secrets[i][k] = words[
                    PUBKEY_WORDS * OUT_UTXOs + CIPHERTEXT1_WORDS * i + k + 1
                ];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// solhint-disable var-name-mixedcase

// The "stake type" for the "classic staking"
// bytes4(keccak256("classic"))
bytes4 constant CLASSIC_STAKE_TYPE = 0x4ab0941a;

// STAKE "action type" for the "classic staking"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("stake"), CLASSIC_STAKE_TYPE)))
bytes4 constant CLASSIC_STAKE = 0x1e4d02b5;

// UNSTAKE "action type" for the "classic staking"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("unstake"), CLASSIC_STAKE_TYPE)))
bytes4 constant CLASSIC_UNSTAKE = 0x493bdf45;

// The "stake type" for the "advance staking"
// bytes4(keccak256("advanced"))
bytes4 constant ADVANCED_STAKE_TYPE = 0x7ec13a06;

// STAKE "action type" for the "advanced staking"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("stake"), ADVANCED_STAKE_TYPE)))
bytes4 constant ADVANCED_STAKE = 0xcc995ce8;

// UNSTAKE "action type" for the "advanced staking"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("unstake"), ADVANCED_STAKE_TYPE)))
bytes4 constant ADVANCED_UNSTAKE = 0xb8372e55;

// PRP grant type for the "advanced" stake
// bytes4(keccak256("forAdvancedStakeGrant"))
bytes4 constant FOR_ADVANCED_STAKE_GRANT = 0x31a180d4;

// solhint-enable var-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "../interfaces/IStakingTypes.sol";

abstract contract StakingMsgProcessor {
    bytes4 internal constant STAKE_ACTION = bytes4(keccak256("stake"));
    bytes4 internal constant UNSTAKE_ACTION = bytes4(keccak256("unstake"));

    function _encodeStakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(STAKE_ACTION, stakeType)));
    }

    function _encodeUnstakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(UNSTAKE_ACTION, stakeType)));
    }

    function _packStakingActionMsg(
        address staker,
        IStakingTypes.Stake memory stake,
        bytes calldata data
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                staker, // address
                stake.amount, // uint96
                stake.id, // uint32
                stake.stakedAt, // uint32
                stake.lockedTill, // uint32
                stake.claimedAt, // uint32
                data // bytes
            );
    }

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function _unpackStakingActionMsg(bytes memory message)
        internal
        pure
        returns (
            address staker,
            uint96 amount,
            uint32 id,
            uint32 stakedAt,
            uint32 lockedTill,
            uint32 claimedAt,
            bytes memory data
        )
    {
        // staker, amount, id and 3 timestamps occupy exactly 48 bytes
        // (`data` may be of zero length)
        require(message.length >= 48, "SMP: unexpected msg length");

        uint256 stakerAndAmount;
        uint256 idAndStamps;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // the 1st word (32 bytes) contains the `message.length`
            // we need the (entire) 2nd word ..
            stakerAndAmount := mload(add(message, 0x20))
            // .. and (16 bytes of) the 3rd word
            idAndStamps := mload(add(message, 0x40))
        }

        staker = address(uint160(stakerAndAmount >> 96));
        amount = uint96(stakerAndAmount & 0xFFFFFFFFFFFFFFFFFFFFFFFF);

        id = uint32((idAndStamps >> 224) & 0xFFFFFFFF);
        stakedAt = uint32((idAndStamps >> 192) & 0xFFFFFFFF);
        lockedTill = uint32((idAndStamps >> 160) & 0xFFFFFFFF);
        claimedAt = uint32((idAndStamps >> 128) & 0xFFFFFFFF);

        uint256 dataLength = message.length - 48;
        data = new bytes(dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            data[i] = message[i + 48];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO: Remove duplicated declaration after merge w/ `panther-core`

uint256 constant OUT_PRP_UTXOs = 1;
uint256 constant OUT_UTXOs = 2 + OUT_PRP_UTXOs;

// Number of 32-bit words in the (uncompressed) spending PubKey
uint256 constant PUBKEY_WORDS = 2;

// Number of 32-bit words in the ciphertext in the "type 1" message
uint256 constant CIPHERTEXT1_WORDS = 3;

// Number of elements in `pathElements`
uint256 constant PATH_ELEMENTS_NUM = 16;

// Address of the "virtual token contract" for PRPs.
// Calculated as `keccak256('Privacy Reward Point') >> 96`.
address constant PRP_VIRTUAL_CONTRACT = 0x1afa2212970b809aE15D51AF00C502D5c8eB3bAf;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient,
     * the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INftGrantor {
    function grantOneToken(address to) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { G1Point } from "../common/Types.sol";
import { CIPHERTEXT1_WORDS, OUT_UTXOs, PATH_ELEMENTS_NUM } from "../common/Constants.sol";

/**
 * @notice (Truncated) Interface of the PantherPoolV0
 * @dev Only those functions and events included which the `AdvancedStakeRewardController` contract uses
 */
interface IPantherPoolV0 {
    /**
     * @notice Increase the "unused grants" amount (in PRPs) of the given grantee by the amount
     * defined by the given "grant type"
     * @return prpAmount The amount (in PRPs) of the grant
     * @dev An authorized "curator" may call with the enabled (added) "grant type" only
     */
    function grant(address grantee, bytes4 grantType)
        external
        returns (uint256 prpAmount);

    /**
     * @notice Transfer assets from the msg.sender to the VAULT and generate UTXOs in the MASP
     * @param tokens Address of the token contract for every UTXO
     * @dev For PRP granted the address ot this contract (proxy) is supposed to be used
     * @param tokenIds For ERC-721 and ERC-1155 - token ID or subId of the token, 0 for ERC-20
     * @param extAmounts Token amounts (external) to be deposited
     * @param pubSpendingKeys Public Spending Key for every UTXO
     * @param secrets Encrypted opening values for every UTXO
     * @param  createdAt Optional, if 0 network time used
     * @dev createdAt must be less (or equal) the network time
     * @return leftLeafId The `leafId` of the first UTXO (leaf) in the batch
     */
    function generateDeposits(
        address[OUT_UTXOs] calldata tokens,
        uint256[OUT_UTXOs] calldata tokenIds,
        uint256[OUT_UTXOs] calldata extAmounts,
        G1Point[OUT_UTXOs] calldata pubSpendingKeys,
        uint256[CIPHERTEXT1_WORDS][OUT_UTXOs] calldata secrets,
        uint32 createdAt
    ) external returns (uint256 leftLeafId);

    function exit(
        address token,
        uint256 tokenId,
        uint256 amount,
        uint32 creationTime,
        uint256 privSpendingKey,
        uint256 leafId,
        bytes32[PATH_ELEMENTS_NUM] calldata pathElements,
        bytes32 merkleRoot,
        uint256 cacheIndexHint
    ) external;

    /**
     * @return Address of the Vault
     */
    // solhint-disable-next-line func-name-mixedcase
    function VAULT() external view returns (address);

    /**
     * @dev Emitted on a new batch of Commitments
     * @param leftLeafId The `leafId` of the first leaf in the batch
     * @dev `leafId = leftLeafId + 1` for the 2nd leaf (`leftLeafId + 2` for the 3rd leaf)
     * @param commitments Commitments hashes
     * @param utxoData opening values (encrypted and public) for UTXOs
     */
    event NewCommitments(
        uint256 indexed leftLeafId,
        uint256 creationTime,
        bytes32[OUT_UTXOs] commitments,
        bytes utxoData
    );

    /**
     * @dev PRP grant issued
     * @param grantType "Type" of the PRP grant
     * @param grantee User to whom the grant is issued
     * @param prpAmount Amount of the grant in PRP
     */
    event PrpGrantIssued(
        bytes4 indexed grantType,
        address grantee,
        uint256 prpAmount
    );

    /**
     * Nullifier is seen (i.e. UTXO is spent)
     */
    event Nullifier(bytes32 nullifier);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardAdviser {
    struct Advice {
        // advice on new "shares" (in the reward pool) to create
        address createSharesFor;
        uint96 sharesToCreate;
        // advice on "shares" to redeem
        address redeemSharesFrom;
        uint96 sharesToRedeem;
        // advice on address the reward against redeemed shares to send to
        address sendRewardTo;
    }

    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        returns (Advice memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens from this contract.
 */
contract Claimable {
    bytes4 private constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "claimErc20: TRANSFER_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/// @title Staking
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/**
 * @title NonReentrant
 * @notice It provides reentrancy guard.
 * The code borrowed from openzeppelin-contracts.
 * Unlike original, this version requires neither `constructor` no `init` call.
 */
abstract contract NonReentrant {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _reentrancyStatus;

    modifier nonReentrant() {
        // Being called right after deployment, when _reentrancyStatus is 0 ,
        // it does not revert (which is expected behaviour)
        require(_reentrancyStatus != _ENTERED, "claimErc20: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

abstract contract Utils {
    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, "UNSAFE32");
        return uint32(n);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "UNSAFE96");
        return uint96(n);
    }

    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < 2**128, "UNSAFE128");
        return uint128(n);
    }

    function safe160(uint256 n) internal pure returns (uint160) {
        require(n < 2**160, "UNSAFE160");
        return uint160(n);
    }

    function safe32TimeNow() internal view returns (uint32) {
        return safe32(timeNow());
    }

    function safe32BlockNow() internal view returns (uint32) {
        return safe32(blockNow());
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Returns the current block number (added to ease testing)
    function blockNow() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO: Remove duplicated declaration after merge w/ `panther-core`
struct G1Point {
    uint256 x;
    uint256 y;
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

interface IStakingTypes {
    // Stake type terms
    struct Terms {
        // if stakes of this kind allowed
        bool isEnabled;
        // if messages on stakes to be sent to the {RewardMaster}
        bool isRewarded;
        // limit on the minimum amount staked, no limit if zero
        uint32 minAmountScaled;
        // limit on the maximum amount staked, no limit if zero
        uint32 maxAmountScaled;
        // Stakes not accepted before this time, has no effect if zero
        uint32 allowedSince;
        // Stakes not accepted after this time, has no effect if zero
        uint32 allowedTill;
        // One (at least) of the following three params must be non-zero
        // if non-zero, overrides both `exactLockPeriod` and `minLockPeriod`
        uint32 lockedTill;
        // ignored if non-zero `lockedTill` defined, overrides `minLockPeriod`
        uint32 exactLockPeriod;
        // has effect only if both `lockedTill` and `exactLockPeriod` are zero
        uint32 minLockPeriod;
    }

    struct Stake {
        // index in the `Stake[]` array of `stakes`
        uint32 id;
        // defines Terms
        bytes4 stakeType;
        // time this stake was created at
        uint32 stakedAt;
        // time this stake can be claimed at
        uint32 lockedTill;
        // time this stake was claimed at (unclaimed if 0)
        uint32 claimedAt;
        // amount of tokens on this stake (assumed to be less 1e27)
        uint96 amount;
        // address stake voting power is delegated to
        address delegatee;
    }
}