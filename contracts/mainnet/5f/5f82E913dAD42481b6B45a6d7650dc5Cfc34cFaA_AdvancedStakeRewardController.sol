// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

import "./TransferHelper.sol";

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens or ETH from this contract.
 */
abstract contract Claimable {
    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        // withdraw ERC20
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    // disabled since false positive
    // slither-disable-next-line dead-code
    function _claimEthOrErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            // withdraw ETH
            TransferHelper.safeTransferETH(to, amount);
        } else {
            // withdraw ERC20
            TransferHelper.safeTransfer(token, to, amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

// Constants

uint256 constant IN_PRP_UTXOs = 1;
uint256 constant IN_UTXOs = 2 + IN_PRP_UTXOs;

uint256 constant OUT_PRP_UTXOs = 1;
uint256 constant OUT_UTXOs = 2 + OUT_PRP_UTXOs;
uint256 constant OUT_MAX_UTXOs = OUT_UTXOs;
// Number of UTXOs given as a reward for an "advanced" stake
uint256 constant OUT_RWRD_UTXOs = 2;

// For overflow protection and circuits optimization
// (must be less than the FIELD_SIZE)
uint256 constant MAX_EXT_AMOUNT = 2**96;
uint256 constant MAX_IN_CIRCUIT_AMOUNT = 2**64;
uint256 constant MAX_TIMESTAMP = 2**32;
uint256 constant MAX_ZASSET_ID = 2**160;

// Token types
// (not `enum` to let protocol extensions use bits, if needed)
uint8 constant ERC20_TOKEN_TYPE = 0x00;
uint8 constant ERC721_TOKEN_TYPE = 0x10;
uint8 constant ERC1155_TOKEN_TYPE = 0x11;
// defined for every tokenId rather than for all tokens on the contract
// (unsupported in the V0 and V1 of the MASP)
uint8 constant BY_TOKENID_TOKEN_TYPE = 0xFF;

// ZAsset statuses
// (not `enum` to let protocol extensions use bits, if needed)
uint8 constant zASSET_ENABLED = 0x01;
uint8 constant zASSET_DISABLED = 0x02;
uint8 constant zASSET_UNKNOWN = 0x00;

// UTXO data (opening values - encrypted and public) formats
uint8 constant UTXO_DATA_TYPE5 = 0x00; // for zero UTXO (no data to provide)
uint8 constant UTXO_DATA_TYPE1 = 0x01; // for UTXO w/ zero tokenId
uint8 constant UTXO_DATA_TYPE3 = 0x02; // for UTXO w/ non-zero tokenId

// Number of 32-bit words of the CiphertextMsg for UTXO_DATA_TYPE1
// (ephemeral key (packed) - 32 bytes, encrypted `random` - 32 bytes)
uint256 constant CIPHERTEXT1_WORDS = 2;

// Number of 32-bit words in the (uncompressed) spending PubKey
uint256 constant PUBKEY_WORDS = 2;
// Number of elements in `pathElements`
uint256 constant PATH_ELEMENTS_NUM = 16;

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.0;

contract Killer {
    function kill(address _account) external {
        selfdestruct(payable(_account));
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

/// @title TransferHelper library
/// @dev Helper methods for interacting with ERC20, ERC721, ERC1155 tokens and sending ETH
/// Based on the Uniswap/solidity-lib/contracts/libraries/TransferHelper.sol
library TransferHelper {
    /// @dev Throws if the deployed code of the `token` is empty.
    // Low-level CALL to a non-existing contract returns `success` of 1 and empty `data`.
    // It may be misinterpreted as a successful call to a deployed token contract.
    // So, the code calling a token contract must insure the contract code exists.
    modifier onlyDeployedToken(address token) {
        uint256 codeSize;
        // slither-disable-next-line assembly
        assembly {
            codeSize := extcodesize(token)
        }
        require(codeSize > 0, "TransferHelper: zero codesize");
        _;
    }

    /// @dev Approve the `operator` to spend all of ERC720 tokens on behalf of `owner`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeSetApprovalForAll(
        address token,
        address operator,
        bool approved
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('setApprovalForAll(address,bool)'));
            abi.encodeWithSelector(0xa22cb465, operator, approved)
        );
        _requireSuccess(success, data);
    }

    /// @dev Get the ERC20 balance of `account`
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeBalanceOf(address token, address account)
        internal
        returns (uint256 balance)
    {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256(bytes('balanceOf(address)')));
            abi.encodeWithSelector(0x70a08231, account)
        );
        require(
            // since `data` can't be empty, `onlyDeployedToken` unneeded
            success && (data.length != 0),
            "TransferHelper: balanceOff call failed"
        );

        balance = abi.decode(data, (uint256));
    }

    /// @dev Approve the `spender` to spend the `amount` of ERC20 token on behalf of `owner`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('approve(address,uint256)'));
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` ERC20 tokens from caller to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('transfer(address,uint256)'));
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` ERC20 tokens on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('transferFrom(address,address,uint256)'));
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer an ERC721 token with id of `tokenId` on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function erc721SafeTransferFrom(
        address token,
        uint256 tokenId,
        address from,
        address to
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('safeTransferFrom(address,address,uint256)'));
            abi.encodeWithSelector(0x42842e0e, from, to, tokenId)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `amount` ERC1155 token with id of `tokenId` on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function erc1155SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory _data
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)'));
            abi.encodeWithSelector(0xf242432a, from, to, tokenId, amount, _data)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` Ether from caller to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransferETH(address to, uint256 value) internal {
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "TransferHelper: ETH transfer failed");
    }

    function _requireSuccess(bool success, bytes memory res) private pure {
        require(
            success && (res.length == 0 || abi.decode(res, (bool))),
            "TransferHelper: token contract call failed"
        );
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

struct G1Point {
    uint256 x;
    uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
    uint256[2] x;
    uint256[2] y;
}

// Verification key for SNARK
struct VerifyingKey {
    G1Point alpha1;
    G2Point beta2;
    G2Point gamma2;
    G2Point delta2;
    G1Point[2] ic;
}

struct SnarkProof {
    G1Point a;
    G2Point b;
    G1Point c;
}

struct PluginData {
    address contractAddress;
    bytes callData;
}

struct ElGamalCiphertext {
    G1Point c1;
    G1Point c2;
}

// For MASP V0 and V1
struct ZAsset {
    // reserved (for networkId, tokenIdPolicy. etc..)
    uint64 _unused;
    // 0x00 by default
    uint8 version;
    // Refer to Constants.sol
    uint8 status;
    // Refer to Constants.sol
    uint8 tokenType;
    // 0x00 - no scaling
    uint8 scale;
    // token contract address
    address token;
}

struct LockData {
    // Refer to Constants.sol
    uint8 tokenType;
    // Token contract address
    address token;
    // For ERC-721, ERC-1155 tokens
    uint256 tokenId;
    // The account to transfer the token from/to (on `lock`/`unlock`)
    address extAccount;
    // The token amount to transfer to/from the Vault (on `lock`/`unlock`)
    uint96 extAmount;
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

abstract contract Utils {
    // false positive
    // slither-disable-next-line timestamp
    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, "UNSAFE32");
        return uint32(n);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "UNSAFE96");
        return uint96(n);
    }

    // disabled since false positive
    // slither-disable-next-line dead-code
    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < 2**128, "UNSAFE128");
        return uint128(n);
    }

    // disabled since false positive
    // slither-disable-next-line dead-code
    function safe160(uint256 n) internal pure returns (uint160) {
        require(n < 2**160, "UNSAFE160");
        return uint160(n);
    }

    function safe32TimeNow() internal view returns (uint32) {
        return safe32(timeNow());
    }

    // disabled since false positive
    // slither-disable-next-line dead-code
    function safe32BlockNow() internal view returns (uint32) {
        return safe32(blockNow());
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Returns the current block number (added to ease testing)
    // disabled since false positive
    // slither-disable-next-line dead-code
    function blockNow() internal view virtual returns (uint256) {
        return block.number;
    }

    // disabled since false positive
    // slither-disable-next-line dead-code
    function revertZeroAddress(address account) internal pure {
        require(account != address(0), "UNEXPECTED_ZERO_ADDRESS");
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import { CIPHERTEXT1_WORDS, OUT_RWRD_UTXOs, PUBKEY_WORDS } from "../../common/Constants.sol";
import { G1Point } from "../../common/Types.sol";

/***
 * @title AdvancedStakingDataDecoder
 * @dev It decodes (unpack) `bytes data` of the 'STAKED' message for "advanced staking"
 */
abstract contract AdvancedStakingDataDecoder {
    // in bytes
    uint256 private constant DATA_LENGTH =
        OUT_RWRD_UTXOs * (PUBKEY_WORDS + CIPHERTEXT1_WORDS) * 32;
    // in 32-byte memory slots
    uint256 private constant NUM_DATA_SLOTS =
        (DATA_LENGTH / 32) + ((DATA_LENGTH % 32) & 1);

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function unpackStakingData(bytes memory data)
        internal
        pure
        returns (
            G1Point[OUT_RWRD_UTXOs] memory pubSpendingKeys,
            uint256[CIPHERTEXT1_WORDS][OUT_RWRD_UTXOs] memory secrets
        )
    {
        require(data.length == DATA_LENGTH, "SMP: unexpected msg length");

        // Let's read bytes as uint256 values
        uint256[NUM_DATA_SLOTS + 1] memory words;
        // the 1st slot is `data.length`, then slots with values follow
        for (uint256 i = 1; i <= NUM_DATA_SLOTS; ++i) {
            // solhint-disable no-inline-assembly
            // slither-disable-next-line assembly
            assembly {
                let offset := mul(i, 0x20)
                let word := mload(add(data, offset))
                mstore(add(words, offset), word)
            }
            // solhint-enable no-inline-assembly
        }
        /*
            `bytes memory sample = 0x00010203..1f2021` stored in the memory like this:
            slot #0: 0x22 - length (34 bytes)
            slot #1: 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
            slot #2: 0x2021000000000000000000000000000000000000000000000000000000000000

            If `OUT_RWRD_UTXOs == 2` and `CIPHERTEXT1_WORDS == 2`,
            `bytes memory data` expected to be:
            concatenate( // each element is 32-byte long
                pubSpendingKeys[0].x, pubSpendingKeys[0].y,
                pubSpendingKeys[1].x, pubSpendingKeys[1].y,
                (secrets[0])[0], (secrets[0])[1],
                (secrets[1])[0], (secrets[1])[1]
            )
        */
        for (uint256 i = 0; i < OUT_RWRD_UTXOs; i++) {
            pubSpendingKeys[i].x = words[i * PUBKEY_WORDS + 1];
            pubSpendingKeys[i].y = words[i * PUBKEY_WORDS + 2];
            for (uint256 k = 0; k < CIPHERTEXT1_WORDS; k++) {
                secrets[i][k] = words[
                    PUBKEY_WORDS *
                        OUT_RWRD_UTXOs +
                        CIPHERTEXT1_WORDS *
                        i +
                        k +
                        1
                ];
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
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

// The "stake type" for the "advance staking"
// bytes4(keccak256("advanced-v2"))
bytes4 constant ADVANCED_STAKE_V2_TYPE = 0x8496de05;

// STAKE "action type" for the "advanced staking V2"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("stake"), ADVANCED_STAKE_V2_TYPE)))
bytes4 constant ADVANCED_STAKE_V2 = 0x1954e321;

// UNSTAKE "action type" for the "advanced staking v2"
// bytes4(keccak256(abi.encodePacked(bytes4(keccak256("unstake"), ADVANCED_STAKE_V2_TYPE)))
bytes4 constant ADVANCED_UNSTAKE_V2 = 0x6a8ecb81;

// PRP grant type for the "advanced" stake
// bytes4(keccak256("forAdvancedStakeGrant"))
bytes4 constant FOR_ADVANCED_STAKE_GRANT = 0x31a180d4;

// solhint-enable var-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

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
        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            // the 1st word (32 bytes) contains the `message.length`
            // we need the (entire) 2nd word ..
            stakerAndAmount := mload(add(message, 0x20))
            // .. and (16 bytes of) the 3rd word
            idAndStamps := mload(add(message, 0x40))
        }
        // solhint-enable no-inline-assembly

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

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import "./actions/AdvancedStakingDataDecoder.sol";
import "./actions/Constants.sol";
import "./actions/StakingMsgProcessor.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/INftGrantor.sol";
import "./interfaces/IPantherPoolV0.sol";
import "./interfaces/IRewardAdviser.sol";
import "../common/Claimable.sol";
import "../common/ImmutableOwnable.sol";
import "../common/NonReentrant.sol";
import "../common/Utils.sol";
import "../common/TransferHelper.sol";
import "../common/Killer.sol";

/**
 * @title AdvancedStakeRewardController
 * @notice It generates UTXOs in the MASP as rewards to stakers for the "Advanced Staking"
 * @dev This contract is supposed to run on the Polygon. Unless otherwise mentioned, other smart
 * contracts are supposed to run on the Polygon also.
 * As the "Reward Adviser" on the "advanced" stakes, every time a new stake is being created, it
 * receives the `getRewardAdvice` call from the `RewardMaster` contract with the `STAKE` action
 * type and the stake data (the `message`) being the call parameters.
 * On the `getRewardAdvice` call received, this contract:
 * - computes the amounts of the $ZKP reward and the optional NFT reward
 * - if the `NFT_TOKEN` is non-zero address, it calls `grantOneToken` on the NFT_TOKEN, and gets
 * the `tokenId` of the minted NFT token
 * - calls `generateDeposits` of the PantherPoolV0, providing amounts/parameters of $ZKP, and
 *   optional NFT as "deposits", as well as "spending pubKeys" and "secrets" (explained below)
 * - returns the "zero reward advice" (with zero `sharesToCreate`) to the RewardMaster.
 *
 * On the "zero" advice, the RewardMaster skips creating "treasure shares" for the staker. This way
 * rewarding gets orchestrated by this contract rather than the RewardMaster.
 *
 * Being called `generateDeposits`, the PantherPoolV0:
 * - requests the `Vault` to take (`transferFrom`) the $ZKP and NFT tokens from this contract
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
 * - this contract shall:
 * -- be authorized as the "RewardAdviser" with the RewardMaster on the Polygon for advanced stakes
 * -- be authorized as "Minter" (aka "grantor") with the NFT_TOKEN contract
 * -- hold enough $ZKP to reward stakers
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
    IRewardAdviser,
    Killer
{
    using TransferHelper for address;

    /// @dev Total amount of $ZKP and NFTs (ever) rewarded and staked
    struct Totals {
        uint96 zkpRewards;
        uint24 nftRewards;
        // Accumulated amount of $ZKP (ever) staked, scaled (divided) by 1e15
        uint40 scZkpStaked;
    }

    /// @dev Maximum amounts of $ZKPs and NFTs which may be rewarded
    struct Limits {
        uint96 zkpRewards;
        uint24 nftRewards;
    }

    /// @dev Reward Timestamps and APYs
    struct RewardParams {
        /// @param (UNIX) Time when $ZKP rewards start to accrue
        uint32 startTime;
        /// @param (UNIX) Time when $ZKP rewards accruals end
        uint32 endTime;
        /// @param $ZKP reward APY at startTime (APY declines from this value)
        uint8 startZkpApy;
        /// @param $ZKP reward APY at endTime (APY declines to this value)
        uint8 endZkpApy;
    }

    // solhint-disable var-name-mixedcase
    // These three constants used to align with IPantherPool::generateDeposits API
    uint256 private constant ZERO_AMOUNT = 0;
    uint256 private constant ZERO_TOKEN_ID = 0;
    address private constant ZERO_TOKEN = address(0);

    /// @notice RewardMaster contract instance
    address public immutable REWARD_MASTER;
    /// @notice PantherPoolV0 contract instance
    address public immutable PANTHER_POOL;

    // Address of the $ZKP token contract
    address private immutable ZKP_TOKEN;
    // Address of the NFT token contract
    address private immutable NFT_TOKEN;

    /// @notice Block when this contract is deployed
    uint256 public immutable START_BLOCK;

    // solhint-enable var-name-mixedcase

    /// @notice Amounts of $ZKP and NFT allocated for rewards
    Limits public limits;

    /// @notice Total amounts of $ZKP and NFT rewarded so far
    Totals public totals;

    /// @notice Reward parameters (start and end point for time and APY)
    RewardParams public rewardParams;

    /// @dev Emitted when new amounts are allocated to reward stakers
    event RewardLimitUpdated(Limits newLimits);

    /// @dev Emitted when rewarding params updated
    event RewardParamsUpdated(RewardParams newRewardParams);

    /// @dev Emitted when the reward for a stake is generated
    event RewardGenerated(
        address indexed staker,
        uint256 firstLeafId,
        uint256 zkp,
        uint256 nft
    );

    constructor(
        address _owner,
        address rewardMaster,
        address pantherPool,
        address zkpToken,
        address nftToken
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

        START_BLOCK = block.number;
    }

    /// @dev To be called by the {RewardMaster} contract on "advanced" `STAKE` and `UNSTAKE` actions.
    /// The caller is trusted to never call w/ the STAKE acton:
    /// - twice for the same stake
    /// - after the rewarded period has ended
    function getRewardAdvice(
        bytes4 action,
        bytes memory message
    ) external override returns (Advice memory) {
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
    function getZkpApyAt(uint256 time) external view returns (uint256) {
        RewardParams memory _rewardParams = rewardParams;
        if (time < _rewardParams.startTime || time > _rewardParams.endTime)
            return 0;

        return _getZkpApyWithinRewardedPeriod(_rewardParams, time);
    }

    function updateRewardParams(
        RewardParams memory _newParams
    ) external onlyOwner {
        // Time comparison is acceptable in this case since block time accuracy is enough for this scenario
        // slither-disable-next-line timestamp
        require(
            _newParams.startTime != 0 &&
                _newParams.endTime > _newParams.startTime &&
                _newParams.endTime > timeNow(),
            "ARC: invalid time"
        );
        require(
            _newParams.startZkpApy >= _newParams.endZkpApy,
            "ARC: invalid APY"
        );

        rewardParams = _newParams;
        emit RewardParamsUpdated(_newParams);
    }

    /// @notice Allocate NFT rewards and approve the Vault to transfer them
    /// @dev Only owner may call it.
    function setNftRewardLimit(
        uint256 _desiredNftRewardsLimit
    ) external onlyOwner {
        if (NFT_TOKEN == address(0)) return;

        Limits memory _limits = limits;

        require(
            _desiredNftRewardsLimit > totals.nftRewards,
            "ARC: low nft rewards limit"
        );

        // known contract - no reentrancy guard needed
        // slither-disable-next-line reentrancy-benign,reentrancy-no-eth,reentrancy-events
        address vault = IPantherPoolV0(PANTHER_POOL).VAULT();

        bool isUpdated = _updateNftRewardsLimitAndAllowance(
            _desiredNftRewardsLimit,
            _limits,
            totals,
            vault
        );

        if (isUpdated) {
            limits = _limits;
            emit RewardLimitUpdated(_limits);
        }
    }

    /// @notice Allocate for rewards the entire $ZKP balance
    /// this contract has and approve the Vault to transfer $ZKP from this contract.
    /// @dev Anyone may call it.
    function updateZkpRewardsLimit() external {
        Limits memory _limits = limits;
        // known contract call - no reentrancy guard needed
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        address vault = IPantherPoolV0(PANTHER_POOL).VAULT();

        // Updating the rewards limits
        bool isUpdated = _updateZkpRewardsLimitAndAllowance(
            _limits,
            totals,
            vault
        );

        if (isUpdated) {
            limits = _limits;
            emit RewardLimitUpdated(_limits);
        }
    }

    /// @notice Withdraws unclaimed rewards or accidentally sent token from this contract
    /// @dev May be only called by the {OWNER}
    function rescueErc20(
        address token,
        address to,
        uint256 amount
    ) external nonReentrant {
        RewardParams memory _rewardParams = rewardParams;

        require(OWNER == msg.sender, "ARC: unauthorized");
        // Time comparison is acceptable in this case since block time accuracy is enough for this scenario
        // slither-disable-next-line timestamp
        require(
            (token != ZKP_TOKEN) || (block.timestamp > _rewardParams.endTime),
            "ARC: too early withdrawal"
        );

        _claimErc20(token, to, amount);
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

    // Private functions follow
    // Some of them declared `internal` rather than `private` to ease testing

    function _generateRewards(bytes memory message) internal {
        // (stakeId and claimedAt are irrelevant)
        (
            address staker,
            uint96 stakeAmount,
            ,
            uint32 stakedAt,
            uint32 lockedTill,
            ,
            bytes memory data
        ) = _unpackStakingActionMsg(message);

        require(stakeAmount != 0, "ARC: unexpected zero stakeAmount");
        require(lockedTill > stakedAt, "ARC: unexpected lockedTill");

        uint256 zkpAmount = 0;
        uint256 nftAmount = 0;
        uint256 nftTokenId = 0;
        {
            Totals memory _totals = totals;
            Limits memory _limits = limits;
            RewardParams memory _rewardParams = rewardParams;

            // Compute amount of the $ZKP reward  and check the limit
            {
                zkpAmount = _computeZkpReward(
                    stakeAmount,
                    lockedTill,
                    stakedAt,
                    _rewardParams
                );

                if (zkpAmount > 0) {
                    uint256 newTotalZkpReward = uint256(_totals.zkpRewards) +
                        zkpAmount;
                    require(
                        _limits.zkpRewards >= newTotalZkpReward,
                        "ARC: too less rewards available"
                    );
                    // Can't exceed uint96 here due to the `require` above
                    _totals.zkpRewards = uint96(newTotalZkpReward);
                }
                // update scSkpStaked in any case when stakeAmount > 0 which already been required
                uint256 newScZkpStaked = uint256(_totals.scZkpStaked) +
                    uint256(stakeAmount) /
                    1e15;
                // Overflow risk ignored as $ZKP max total supply is 1e9 tokens
                _totals.scZkpStaked = uint40(newScZkpStaked);
            }

            if (_totals.nftRewards < _limits.nftRewards) {
                // `_limits.nftRewards > 0` therefore `NFT_TOKEN != address(0)`
                // trusted contract called - no reentrancy guard needed
                // slither-disable-next-line reentrancy-benign,reentrancy-no-eth
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
            G1Point[OUT_RWRD_UTXOs] memory pubSpendingKeys,
            uint256[CIPHERTEXT1_WORDS][OUT_RWRD_UTXOs] memory secrets
        ) = unpackStakingData(data);

        // Finally, generate deposits (i.e. UTXOs in the MASP)
        address[OUT_MAX_UTXOs] memory tokens = [
            // PantherPool reverts if non-zero address provided for zero amount
            zkpAmount == 0 ? address(0) : ZKP_TOKEN,
            nftAmount == 0 ? address(0) : NFT_TOKEN,
            ZERO_TOKEN
        ];

        uint256[OUT_MAX_UTXOs] memory subIds = [0, nftTokenId, ZERO_TOKEN_ID];
        uint256[OUT_MAX_UTXOs] memory extAmounts = [
            zkpAmount,
            nftAmount,
            ZERO_AMOUNT
        ];

        uint32 createdAt = safe32TimeNow();
        // known contract call - no reentrancy guard needed
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        uint256 leftLeafId = IPantherPoolV0(PANTHER_POOL).generateDeposits(
            tokens,
            subIds,
            extAmounts,
            [
                pubSpendingKeys[0],
                pubSpendingKeys[1],
                pubSpendingKeys[1] // dummy public key - reused
            ],
            [
                secrets[0],
                secrets[1],
                secrets[1] // dummy secret - reused
            ],
            createdAt
        );

        emit RewardGenerated(staker, leftLeafId, zkpAmount, nftAmount);
    }

    // The calling code is assumed to ensure `lockedTill > stakedAt`
    function _computeZkpReward(
        uint256 stakeAmount,
        uint256 lockedTill,
        uint256 stakedAt,
        RewardParams memory _rewardParams
    ) internal pure returns (uint256 zkpAmount) {
        // No rewarding after `endTime`
        if (stakedAt >= _rewardParams.endTime) return 0;
        // No rewarding before `startTime`
        if (lockedTill <= _rewardParams.startTime) return 0;

        uint256 rewardedSince = _rewardParams.startTime > stakedAt
            ? _rewardParams.startTime
            : stakedAt;

        uint256 rewardedTill = lockedTill > _rewardParams.endTime
            ? _rewardParams.endTime
            : lockedTill;

        uint256 period = rewardedTill - rewardedSince;
        uint256 apy = _getZkpApyWithinRewardedPeriod(
            _rewardParams,
            rewardedSince
        );

        // 3153600000 = 365 * 24 * 3600 seconds * 100 percents
        // slither-disable-next-line too-many-digits
        zkpAmount = (stakeAmount * apy * period) / 3153600000;
        // round to 2nd digits after decimal point: X.YZ{0..0} x 1e18
        unchecked {
            // rounding (accuracy loss is assumed)
            // slither-disable-next-line divide-before-multiply
            zkpAmount = (zkpAmount / 1e16) * (1e16);
        }
    }

    // The calling code is assumed to ensure that
    // `startTime < time < endTime` and `startZkpApy >= endZkpApy`
    function _getZkpApyWithinRewardedPeriod(
        RewardParams memory _rewardParams,
        uint256 time
    ) private pure returns (uint256 apy) {
        unchecked {
            uint256 fullDrop = uint256(
                _rewardParams.startZkpApy - _rewardParams.endZkpApy
            );
            apy = uint256(_rewardParams.startZkpApy);

            if (fullDrop > 0) {
                uint256 dropDuration = time - _rewardParams.startTime;
                uint256 fullDuration = uint256(
                    _rewardParams.endTime - _rewardParams.startTime
                );
                uint256 apyDrop = (fullDrop * dropDuration) / fullDuration;

                apy -= apyDrop;
            }
        }
    }

    // Allocate for rewards the entire $ZKP balance this contract holds,
    // and update allowance for the VAULT to spend for $ZKP from the balance
    function _updateZkpRewardsLimitAndAllowance(
        Limits memory _limits,
        Totals memory _totals,
        address vault
    ) private returns (bool isUpdated) {
        // Reentrancy guard unneeded for the trusted contract call
        // slither-disable-next-line reentrancy-benign,reentrancy-events,reentrancy-no-eth
        uint256 balance = ZKP_TOKEN.safeBalanceOf(address(this));

        uint96 newLimit;
        (isUpdated, newLimit) = _getUpdatedLimit(
            balance,
            _limits.zkpRewards,
            _totals.zkpRewards
        );

        if (isUpdated) {
            _limits.zkpRewards = newLimit;

            // Approve the vault to transfer tokens from this contract
            // Reentrancy guard unneeded for the trusted contract call
            // slither-disable-next-line reentrancy-benign,reentrancy-events,reentrancy-no-eth
            ZKP_TOKEN.safeApprove(vault, uint256(newLimit));
        }
    }

    // Allocate for rewards the entire NFT amount this contract can mint,
    // and update allowance for the VAULT to spend that NFT
    function _updateNftRewardsLimitAndAllowance(
        uint256 _desiredNftRewardsLimit,
        Limits memory _limits,
        Totals memory _totals,
        address vault
    ) private returns (bool isUpdated) {
        uint96 newLimit;
        (isUpdated, newLimit) = _getUpdatedLimit(
            _desiredNftRewardsLimit,
            _limits.nftRewards,
            _totals.nftRewards
        );

        if (isUpdated) {
            bool isAllowanceToBeUpdated = _limits.nftRewards == 0;

            // Overflow is unrealistic and therefore ignored
            _limits.nftRewards = uint24(newLimit);

            if (isAllowanceToBeUpdated)
                // Approve the vault to transfer tokens from this contract
                // Reentrancy guard unneeded for the trusted contract call
                // slither-disable-next-line reentrancy-benign,reentrancy-no-eth,reentrancy-events
                NFT_TOKEN.safeSetApprovalForAll(vault, true);
        }
    }

    // Calculates and returns the updated reward limit
    function _getUpdatedLimit(
        uint256 available,
        uint96 currentLimit,
        uint96 usedLimit
    ) internal pure returns (bool isUpdated, uint96 limit) {
        uint256 unusedLimit = uint256(currentLimit) - uint256(usedLimit);

        if (available == unusedLimit) return (false, currentLimit);

        isUpdated = true;
        // underflow is impossible due to `if` checks
        unchecked {
            if (available > unusedLimit) {
                // new tokens for rewarding have been provided
                uint256 newAllocation = available - unusedLimit;
                limit = safe96(newAllocation + currentLimit);
            } else {
                // gracefully handle this unexpected situation
                uint96 shortage = safe96(unusedLimit - available);
                limit = currentLimit > shortage ? currentLimit - shortage : 0;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.16;

interface INftGrantor {
    function grantOneToken(address to) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { G1Point } from "../../common/Types.sol";
import { CIPHERTEXT1_WORDS, OUT_MAX_UTXOs, PATH_ELEMENTS_NUM } from "../../common/Constants.sol";

/**
 * @notice (Truncated) Interface of the PantherPoolV0
 * @dev Only those functions and events included which the `AdvancedStakeRewardController` contract uses
 */
interface IPantherPoolV0 {
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
        address[OUT_MAX_UTXOs] calldata tokens,
        uint256[OUT_MAX_UTXOs] calldata tokenIds,
        uint256[OUT_MAX_UTXOs] calldata extAmounts,
        G1Point[OUT_MAX_UTXOs] calldata pubSpendingKeys,
        uint256[CIPHERTEXT1_WORDS][OUT_MAX_UTXOs] calldata secrets,
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
        bytes32[OUT_MAX_UTXOs] commitments,
        bytes utxoData
    );

    /**
     * Nullifier is seen (i.e. UTXO is spent)
     */
    event Nullifier(bytes32 nullifier);
}

// SPDX-License-Identifier: MIT
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

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
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

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