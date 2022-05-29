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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO: Remove duplicated declaration after merge w/ `panther-core`
struct G1Point {
    uint256 x;
    uint256 y;
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

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import { CIPHERTEXT1_WORDS, OUT_UTXOs, PATH_ELEMENTS_NUM } from "../common/Constants.sol";
import { G1Point } from "../common/Types.sol";
import "../interfaces/IPantherPoolV0.sol";

/// @dev It simulates `IPantherPoolV0`. See an example bellow.
contract FakePantherPoolV0 is IPantherPoolV0 {
    // solhint-disable var-name-mixedcase

    // Snark field size
    uint256 private constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    address public immutable override VAULT;
    uint256 public immutable EXIT_TIME;

    // solhint-enable var-name-mixedcase

    uint256 public fakeLeavesNum;

    mapping(bytes32 => bool) public isSpent;

    constructor(address anyVaultAddress, uint256 exitTime) {
        VAULT = anyVaultAddress;
        EXIT_TIME = exitTime;
    }

    // It fakes generation of deposits and emits
    function generateDeposits(
        address[OUT_UTXOs] calldata tokens,
        uint256[OUT_UTXOs] calldata tokenIds,
        uint256[OUT_UTXOs] calldata extAmounts,
        G1Point[OUT_UTXOs] calldata pubSpendingKeys,
        uint256[CIPHERTEXT1_WORDS][OUT_UTXOs] calldata secrets,
        uint32 createdAt
    ) external override returns (uint256 leftLeafId) {
        require(
            createdAt <= block.timestamp,
            "FakePantherPoolV0:TOO_LARGE_createdAt"
        );
        bytes32[OUT_UTXOs] memory commitments;
        bytes memory utxoData = "";

        for (uint256 utxoIndex = 0; utxoIndex < OUT_UTXOs; utxoIndex++) {
            require(
                pubSpendingKeys[utxoIndex].x < FIELD_SIZE,
                "FakePantherPoolV0:ERR_TOO_LARGE_PUBKEY.x"
            );
            require(
                pubSpendingKeys[utxoIndex].x < FIELD_SIZE,
                "FakePantherPoolV0:ERR_TOO_LARGE_PUBKEY.x"
            );
            require(
                tokenIds[utxoIndex] < FIELD_SIZE,
                "FakePantherPoolV0:TOO_LARGE_tokenId"
            );
            require(
                extAmounts[utxoIndex] < 2**96,
                "FakePantherPoolV0:ERR_TOO_LARGE_AMOUNT"
            );

            // Fake (!!!) the commitment
            commitments[utxoIndex] = bytes32(
                uint256(keccak256(abi.encode(block.timestamp, utxoIndex))) %
                    FIELD_SIZE
            );

            // No scaling (!!!)
            uint256 scaledAmount = extAmounts[utxoIndex];
            uint256 tokenAndAmount = (uint256(uint160(tokens[utxoIndex])) <<
                96) | scaledAmount;

            utxoData = bytes.concat(
                utxoData,
                abi.encodePacked(
                    uint8(0xAB), // UTXO_DATA_TYPE1
                    secrets[utxoIndex],
                    tokenAndAmount,
                    tokenIds[utxoIndex]
                )
            );
        }

        uint256 n = fakeLeavesNum;
        leftLeafId = ((n / 3) * 4) + (n % 3);
        fakeLeavesNum = n + OUT_UTXOs;

        emit NewCommitments(
            leftLeafId,
            block.timestamp, // creationTime,
            commitments,
            utxoData
        );
    }

    function exit(
        address, // token,
        uint256, // tokenId,
        uint256 amount,
        uint32, // creationTime,
        uint256 privSpendingKey,
        uint256 leafId,
        bytes32[PATH_ELEMENTS_NUM] calldata, // pathElements,
        bytes32, // merkleRoot,
        uint256 // cacheIndexHint
    ) external override {
        require(
            block.timestamp >= EXIT_TIME,
            "FakePantherPoolV0:ERR_TOO_EARLY_EXIT"
        );
        require(amount < 2**96, "FakePantherPoolV0:ERR_TOO_LARGE_AMOUNT");

        // Fake (!!!) nullifier
        bytes32 nullifier = bytes32(
            uint256(keccak256(abi.encode(privSpendingKey, leafId))) % FIELD_SIZE
        );

        require(!isSpent[nullifier], "FakePantherPoolV0:ERR_SPENT_NULLIFIER");
        isSpent[nullifier] = true;
        emit Nullifier(nullifier);
    }

    function grant(address grantee, bytes4 grantType)
        external
        override
        returns (uint256 prpAmount)
    {
        // bytes4(keccak256("forAdvancedStakeGrant"))
        require(
            grantType == bytes4(0x31a180d4),
            "FakePantherPoolV0: INVALID_GRANT_TYPE"
        );

        prpAmount = 1000;
        emit PrpGrantIssued(grantType, grantee, prpAmount);
    }
}

// TODO: write FakePantherPoolV0::generateDeposits u-test based on the following example
/*
Example:
```js
const {depositFakeInput: {tokens, tokenIds, extAmounts, pubSpendingKeys, secrets}, utxoData} = require(
    './test/assets/advancesStakingData.data.ts'
)
const [ createdAt, exitTime, vaultAddr ] = [ '0xb0bab0', '0x62626262', '0x6379dfD29D1b4bC713152F6B683223891ea118C2']
const FakePantherPoolV0 = await ethers.getContractFactory('FakePantherPoolV0')
const fakePool = await FakePantherPoolV0.deploy(vaultAddr, exitTime)
let tx = await fakePool.generateDeposits(tokens, tokenIds, extAmounts, pubSpendingKeys, secrets, createdAt)
let rcp = await tx.wait()
assert(!!rcp.logs[0].data.match(new RegExp(utxoData.replace('0x', ''))))
```
*/