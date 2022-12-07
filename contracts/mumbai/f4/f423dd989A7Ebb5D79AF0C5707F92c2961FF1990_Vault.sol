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

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import { ERC20_TOKEN_TYPE, ERC721_TOKEN_TYPE, ERC1155_TOKEN_TYPE } from "../common/Constants.sol";
import "./errMsgs/VaultErrMsgs.sol";
import "../common/ImmutableOwnable.sol";
import "../common/TransferHelper.sol";
import { LockData } from "../common/Types.sol";
import "./interfaces/IVault.sol";
import "./vault/OnERC1155Received.sol";
import "./vault/OnERC721Received.sol";

/**
 * @title Vault
 * @author Pantherprotocol Contributors
 * @notice Holder of assets (tokens) for `PantherPool` contract
 * @dev It transfers assets from user to itself (Lock) and vice versa (Unlock).
 * `PantherPool` is assumed to be the `owner` that is authorized to trigger
 * locking/unlocking assets.
 */
contract Vault is
    ImmutableOwnable,
    OnERC721Received,
    OnERC1155Received,
    IVault
{
    using TransferHelper for address;

    // solhint-disable-next-line no-empty-blocks
    constructor(address _owner) ImmutableOwnable(_owner) {
        // Proxy-friendly: no storage initialization
    }

    // The caller (i.e. the owner) is supposed to apply reentrancy guard.
    // If an adversarial "token", being called by this function, re-enters it
    // directly, `onlyOwner` will revert as `msg.sender` won't be `owner`.
    function lockAsset(LockData calldata data)
        external
        override
        onlyOwner
        checkLockData(data)
    {
        if (data.tokenType == ERC20_TOKEN_TYPE) {
            // Owner, who only may call this code, is trusted to protect
            // against "Arbitrary from in transferFrom" vulnerability
            // slither-disable-next-line arbitrary-send-erc20,reentrancy-benign,reentrancy-events
            data.token.safeTransferFrom(
                data.extAccount,
                address(this),
                data.extAmount
            );
        } else if (data.tokenType == ERC721_TOKEN_TYPE) {
            // slither-disable-next-line reentrancy-benign,reentrancy-events
            data.token.erc721SafeTransferFrom(
                data.tokenId,
                data.extAccount,
                address(this)
            );
        } else if (data.tokenType == ERC1155_TOKEN_TYPE) {
            // slither-disable-next-line reentrancy-benign,reentrancy-events
            data.token.erc1155SafeTransferFrom(
                data.extAccount,
                address(this),
                data.tokenId,
                uint256(data.extAmount),
                new bytes(0)
            );
        } else {
            revert(ERR_INVALID_TOKEN_TYPE);
        }

        emit Locked(data);
    }

    // The caller (i.e. the owner) is supposed to apply reentrancy guard.
    // If an adversarial "token", being called by this function, re-enters it
    // directly, `onlyOwner` will revert as `msg.sender` won't be `owner`.
    function unlockAsset(LockData calldata data)
        external
        override
        onlyOwner
        checkLockData(data)
    {
        if (data.tokenType == ERC20_TOKEN_TYPE) {
            // slither-disable-next-line reentrancy-benign,reentrancy-events
            data.token.safeTransfer(data.extAccount, data.extAmount);
        } else if (data.tokenType == ERC721_TOKEN_TYPE) {
            // slither-disable-next-line reentrancy-benign,reentrancy-events
            data.token.erc721SafeTransferFrom(
                data.tokenId,
                address(this),
                data.extAccount
            );
        } else if (data.tokenType == ERC1155_TOKEN_TYPE) {
            // slither-disable-next-line reentrancy-benign,reentrancy-events
            data.token.erc1155SafeTransferFrom(
                address(this),
                data.extAccount,
                data.tokenId,
                data.extAmount,
                new bytes(0)
            );
        } else {
            revert(ERR_INVALID_TOKEN_TYPE);
        }

        emit Unlocked(data);
    }

    modifier checkLockData(LockData calldata data) {
        require(data.token != address(0), ERR_ZERO_LOCK_TOKEN_ADDR);
        require(data.extAccount != address(0), ERR_ZERO_EXT_ACCOUNT_ADDR);
        require(data.extAmount > 0, ERR_ZERO_EXT_AMOUNT);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

string constant ERR_INVALID_TOKEN_TYPE = "VA:E1";
string constant ERR_ZERO_LOCK_TOKEN_ADDR = "VA:E2";
string constant ERR_ZERO_EXT_ACCOUNT_ADDR = "VA:E3";
string constant ERR_ZERO_EXT_AMOUNT = "VA:E4";

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import { LockData } from "../../common/Types.sol";

interface IVault {
    function lockAsset(LockData calldata data) external;

    function unlockAsset(LockData memory data) external;

    event Locked(LockData data);
    event Unlocked(LockData data);
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

/// @dev Implementation of ERC1155:onERC1155Received interface
abstract contract OnERC1155Received {
    // It accepts all tokens
    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata /* data */
    ) external pure virtual returns (bytes4) {
        // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
        return 0xf23a6e61;
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

/// @dev Implementation of the ERC721TokenReceiver interface
abstract contract OnERC721Received {
    // It accepts all tokens
    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes memory // data
    ) external virtual returns (bytes4) {
        // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        return 0x150b7a02;
    }
}