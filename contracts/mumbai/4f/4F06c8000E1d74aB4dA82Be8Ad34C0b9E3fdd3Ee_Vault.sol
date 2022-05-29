// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { ERC20_TOKEN_TYPE, ERC721_TOKEN_TYPE, ERC1155_TOKEN_TYPE } from "./common/Constants.sol";
import { ERR_INVALID_TOKEN_TYPE, ERR_ZERO_LOCK_TOKEN_ADDR } from "./common/ErrorMsgs.sol";
import { ERR_ZERO_EXT_ACCOUNT_ADDR, ERR_ZERO_EXT_AMOUNT } from "./common/ErrorMsgs.sol";
import "./common/ImmutableOwnable.sol";
import "./common/TransferHelper.sol";
import { LockData } from "./common/Types.sol";
import "./interfaces/IVault.sol";
import "./vault/OnERC1155Received.sol";
import "./vault/OnERC721Received.sol";

/**
 * @title Vault
 * @author Pantherprotocol Contributors
 * @notice Holder of assets (tokens) for `PantherPool` contract
 * @dev the contract is expected to transfer asset from user to
 * itself(Lock) and vice versa(Unlock). it uses
 * TransferHelper library to interact with tokens.
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

    // The caller (i.e. Owner) must guard against reentrancy
    function lockAsset(LockData calldata data)
        external
        override
        onlyOwner
        checkLockData(data)
    {
        if (data.tokenType == ERC20_TOKEN_TYPE) {
            data.token.safeTransferFrom(
                data.extAccount,
                address(this),
                data.extAmount
            );
        } else if (data.tokenType == ERC721_TOKEN_TYPE) {
            data.token.erc721SafeTransferFrom(
                data.tokenId,
                data.extAccount,
                address(this)
            );
        } else if (data.tokenType == ERC1155_TOKEN_TYPE) {
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

    // The caller (i.e. Owner) must guard against reentrancy
    function unlockAsset(LockData calldata data)
        external
        override
        onlyOwner
        checkLockData(data)
    {
        if (data.tokenType == ERC20_TOKEN_TYPE) {
            data.token.safeTransfer(data.extAccount, data.extAmount);
        } else if (data.tokenType == ERC721_TOKEN_TYPE) {
            data.token.erc721SafeTransferFrom(
                data.tokenId,
                address(this),
                data.extAccount
            );
        } else if (data.tokenType == ERC1155_TOKEN_TYPE) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Constants

uint256 constant IN_PRP_UTXOs = 1;
uint256 constant IN_UTXOs = 2 + IN_PRP_UTXOs;

uint256 constant OUT_PRP_UTXOs = 1;
uint256 constant OUT_UTXOs = 2 + OUT_PRP_UTXOs;

// Number of 32-bit words in the `secrets` of the `NewCommitment` events
uint256 constant UTXO_SECRETS = 4;
// Number of 32-bit words in the ciphertext in the "type 0" message
uint256 constant CIPERTEXT0_WORDS = 4;
// Number of 32-bit words in the ciphertext in the "type 1" message
uint256 constant CIPHERTEXT1_WORDS = 3;

// For overflow protection and circuits optimization
// (must be less than the FIELD_SIZE)
uint256 constant MAX_EXT_AMOUNT = 2**96;
uint256 constant MAX_IN_CIRCUIT_AMOUNT = 2**120;
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

// UTXO data (opeing values - encrypted and public) foromats
uint8 constant UTXO_DATA_TYPE_ZERO = 0xA0; // no data (for zero UTXO)
uint8 constant UTXO_DATA_TYPE0 = 0xAA;
uint8 constant UTXO_DATA_TYPE1 = 0xAB;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// ZAssetRegistry contract
string constant ERR_ASSET_ALREADY_REGISTERED = "AR:E1";
string constant ERR_UNKNOWN_ASSET = "AR:E2";
string constant ERR_WRONG_ASSET_STATUS = "AR:E3";
string constant ERR_ZERO_TOKEN_ADDRESS = "AR:E4";

// CommitmentsTrees contract
string constant ERR_TOO_LARGE_COMMITMENTS = "CT:E1"; // commitment exceeds maximum scalar field size

// Registry contract
string constant ERR_INVALID_PUBKEYS = "RG:E1"; // Unexpected format of Pub Keys

// PantherPool contract
string constant ERR_DEPOSIT_OVER_LIMIT = "PP:E1";
string constant ERR_DEPOSIT_FROM_ZERO_ADDRESS = "PP:E2";
string constant ERR_EXPIRED_TX_TIME = "PP:E3";
string constant ERR_INVALID_JOIN_INPUT = "PP:E4";
string constant ERR_INVALID_PROOF = "PP:E5";
string constant ERR_MISMATCHED_ARR_LENGTH = "PP:E6";
string constant ERR_PLUGIN_FAILURE = "PP:E7";
string constant ERR_SPENT_NULLIFIER = "PP:E8";
string constant ERR_TOO_EARLY_CREATED_AT = "PP:E9";
string constant ERR_TOO_LARGE_AMOUNT = "PP:E10";
string constant ERR_TOO_LARGE_COMMITMENT = "PP:E11";
string constant ERR_TOO_LARGE_NULLIFIER = "PP:E12";
string constant ERR_TOO_LARGE_ROOT = "PP:E13";
string constant ERR_TOO_LARGE_TIME = "PP:E14";
string constant ERR_TOO_SMALL_AMOUNT = "PP:E15";
string constant ERR_UNKNOWN_MERKLE_ROOT = "PP:E16";
string constant ERR_WITHDRAW_OVER_LIMIT = "PP:E17";
string constant ERR_WITHDRAW_TO_ZERO_ADDRESS = "PP:E18";
string constant ERR_WRONG_ASSET = "PP:E19";
string constant ERR_WRONG_ASSET_SCALE = "PP:20";
string constant ERR_ZERO_DEPOSIT = "PP:E21";
string constant ERR_ZERO_FEE_PAYER = "PP:E22";
string constant ERR_ZERO_TOKEN_EXPECTED = "PP:E23";
string constant ERR_ZERO_TOKEN_UNEXPECTED = "PP:E24";
string constant ERR_ZERO_TOKENID_EXPECTED = "PP:E25";

// (Specific to) PantherPoolV0 contract
string constant ERR_TOO_EARLY_EXIT = "P0:E1";
string constant ERR_TOO_LARGE_LEAFID = "P0:E2";
string constant ERR_TOO_LARGE_PRIVKEY = "P0:E3";
string constant ERR_WRONG_DEPOSIT = "P0:E4";

// PrpGrantor contract
string constant ERR_ZERO_CURATOR_ADDR = "GR:E1";
string constant ERR_ZERO_GRANTEE_ADDR = "GR:E2";
string constant ERR_GRANT_TYPE_EXISTS = "GR:E3";
string constant ERR_UNEXPECTED_GRANT_RECEIPIENT = "GR:E4";
string constant ERR_LOW_GRANT_BALANCE = "GR:E5";
string constant ERR_UKNOWN_GRANT_TYPE = "GR:E6";
string constant ERR_TOO_LARGE_GRANT_AMOUNT = "GR:E6";
string constant ERR_UNDEF_GRANT = "GR:E7";
string constant ERR_UNAUTHORIZED_CALL = "GR:Unauthorized";

// Vault contract
string constant ERR_INVALID_TOKEN_TYPE = "VA:E1";
string constant ERR_ZERO_LOCK_TOKEN_ADDR = "VA:E2";
string constant ERR_ZERO_EXT_ACCOUNT_ADDR = "VA:E3";
string constant ERR_ZERO_EXT_AMOUNT = "VA:E4";

// TriadIncrementalMerkleTrees contract
string constant ERR_ZERO_ROOT = "TT:E1"; // merkle tree root can not be zero

// CommitmentGenerator contract
string constant ERR_TOO_LARGE_PUBKEY = "CG:E1";

// MerkleProofVerifier
string constant ERR_MERKLE_PROOF_VERIFICATION_FAILED = "MP:E1";
string constant ERR_TRIAD_INDEX_MIN_VALUE = "MP:E2";
string constant ERR_TRIAD_INDEX_MAX_VALUE = "MP:E3";

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

// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable avoid-low-level-calls
pragma solidity >=0.6.0;

/// @title TransferHelper library
/// @dev Helper methods for interacting with ERC20, ERC721, ERC1155 tokens and sending ETH
/// Based on the Uniswap/solidity-lib/contracts/libraries/TransferHelper.sol
library TransferHelper {
    /// @dev Approve the `spender` to spend the `amount` of ERC20 token on behalf of `owner`.
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256('approve(address,uint256)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    /// @dev Transfer `value` ERC20 tokens from caller to `to`.
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256('transfer(address,uint256)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    /// @dev Transfer `value` ERC20 tokens on behalf of `from` to `to`.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256('transferFrom(address,address,uint256)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        _requireTransferSuccess(success, data);
    }

    /// @dev Transfer an ERC721 token with id of `tokenId` on behalf of `from` to `to`.
    function erc721SafeTransferFrom(
        address token,
        uint256 tokenId,
        address from,
        address to
    ) internal {
        // bytes4(keccak256('safeTransferFrom(address,address,uint256)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x42842e0e, from, to, tokenId)
        );
        _requireTransferSuccess(success, data);
    }

    /// @dev Transfer `amount` ERC1155 token with id of `tokenId` on behalf of `from` to `to`.
    function erc1155SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory _data
    ) internal {
        // bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xf242432a, from, to, tokenId, amount, _data)
        );
        _requireTransferSuccess(success, data);
    }

    /// @dev Transfer `value` Ether from caller to `to`.
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }

    function _requireTransferSuccess(bool success, bytes memory res)
        private
        pure
    {
        require(
            success && (res.length == 0 || abi.decode(res, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }
}

// SPDX-License-Identifier: MIT
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
    uint72 _unused;
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

pragma solidity ^0.8.4;

import { LockData } from "../common/Types.sol";

interface IVault {
    function lockAsset(LockData calldata data) external;

    function unlockAsset(LockData memory data) external;

    event Locked(LockData data);
    event Unlocked(LockData data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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