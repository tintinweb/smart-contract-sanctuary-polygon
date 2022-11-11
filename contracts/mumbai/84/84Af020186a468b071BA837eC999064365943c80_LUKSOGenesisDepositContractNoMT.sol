// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.6.11;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// Based on official specification in https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}

// This is a rewrite of the Vyper Eth2.0 deposit contract in Solidity.
// It tries to stay as close as possible to the original source code.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
contract DepositContract is IDepositContract, ERC165 {
    uint256 constant DEPOSIT_CONTRACT_TREE_DEPTH = 32;
    // NOTE: this also ensures `deposit_count` will fit into 64-bits
    uint256 constant MAX_DEPOSIT_COUNT = 2**DEPOSIT_CONTRACT_TREE_DEPTH - 1;

    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] branch;
    uint256 deposit_count;

    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] zero_hashes;

    // to_little_endian_64(uint64(32 ether / 1 gwei))
    bytes constant amount_to_little_endian_64 = hex"0040597307000000";

    constructor() public {
        // Compute hashes in empty sparse Merkle tree
        for (
            uint256 height = 0;
            height < DEPOSIT_CONTRACT_TREE_DEPTH - 1;
            height++
        )
            zero_hashes[height + 1] = sha256(
                abi.encodePacked(zero_hashes[height], zero_hashes[height])
            );
    }

    function get_deposit_root() external view override returns (bytes32) {
        bytes32 node;
        uint256 size = deposit_count;
        for (
            uint256 height = 0;
            height < DEPOSIT_CONTRACT_TREE_DEPTH;
            height++
        ) {
            if ((size & 1) == 1)
                node = sha256(abi.encodePacked(branch[height], node));
            else node = sha256(abi.encodePacked(node, zero_hashes[height]));
            size /= 2;
        }
        return
            sha256(
                abi.encodePacked(
                    node,
                    to_little_endian_64(uint64(deposit_count)),
                    bytes24(0)
                )
            );
    }

    function get_deposit_count() external view override returns (bytes memory) {
        return to_little_endian_64(uint64(deposit_count));
    }

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) internal {
        // Emit `DepositEvent` log
        emit DepositEvent(
            pubkey,
            withdrawal_credentials,
            amount_to_little_endian_64,
            signature,
            to_little_endian_64(uint64(deposit_count))
        );

        // Compute deposit data root (`DepositData` hash tree root)
        // bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));
        // bytes32 signature_root = sha256(
        //     abi.encodePacked(
        //         sha256(abi.encodePacked(signature[:64])),
        //         sha256(abi.encodePacked(signature[64:], bytes32(0)))
        //     )
        // );
        // bytes32 node = sha256(
        //     abi.encodePacked(
        //         sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
        //         sha256(
        //             abi.encodePacked(
        //                 amount_to_little_endian_64,
        //                 bytes24(0),
        //                 signature_root
        //             )
        //         )
        //     )
        // );

        // Verify computed and expected deposit data roots match
        // require(
        //     node == deposit_data_root,
        //     "DepositContract: reconstructed DepositData does not match supplied deposit_data_root"
        // );

        // Avoid overflowing the Merkle tree (and prevent edge case in computing `branch`)
        // require(
        //     deposit_count < MAX_DEPOSIT_COUNT,
        //     "DepositContract: merkle tree full"
        // );

        // Add deposit data root to Merkle tree (update a single `branch` node)
        // deposit_count += 1;
        // uint256 size = deposit_count;
        // for (
        //     uint256 height = 0;
        //     height < DEPOSIT_CONTRACT_TREE_DEPTH;
        //     height++
        // ) {
        //     if ((size & 1) == 1) {
        //         branch[height] = node;
        //         return;
        //     }
        //     node = sha256(abi.encodePacked(branch[height], node));
        //     size /= 2;
        // }

        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        // assert(false);
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(ERC165).interfaceId ||
            interfaceId == type(IDepositContract).interfaceId;
    }

    function to_little_endian_64(uint64 value)
        internal
        pure
        returns (bytes memory ret)
    {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {DepositContract} from "./DepositContractNoMerkleTree.sol";

//import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

contract LUKSOGenesisDepositContractNoMT is DepositContract {
    // DO NOT FORGET TO CHANGE THIS ADDRESS, THIS IS MUMBAI LYXe
    address constant LYXeAddress = 0xad0c3Be112a2FbD18488b471810A01B27CB877C0;

    /**
     * @dev Storing all the deposit data which should be sliced
     * in order to get the following parameters:
     * - pubkey - the first 48 bytes
     * - withdrawal_credentials - the following 32 bytes
     * - signature - the following 96 bytes
     * - deposit_data_root - last 32 bytes
     */
    mapping(uint256 => bytes) deposit_data;

    /**
     * @dev Owner of the contract
     * Has access to `freezeContract()`
     */
    address private owner;

    /**
     * @dev Default value is false which allows people to send 32 LYXe
     * to this contract with valid data in order to register as Genesis Validator
     */
    bool private contractFrozen;

    /**
     * @dev Save the deployer as the owner of the contract
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Whenever this contract receives LYXe tokens, it must be for the reason of
     * being a Genesis Validator.
     *
     * Requirements:
     * - `amount` MUST be exactly 32 LYXe
     * - `userData` MUST be encoded properly
     * - `userData` MUST contain:
     *   • pubkey - the first 48 bytes
     *   • withdrawal_credentials - the following 32 bytes
     *   • signature - the following 96 bytes
     *   • deposit_data_root - last 32 bytes
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        require(!contractFrozen, "Contract is frozen");
        require(msg.sender == LYXeAddress, "Not called on LYXe transfer");
        require(
            amount == 32 ether,
            "Cannot send an amount different from 32 LYXe"
        );
        require(
            userData.length == (48 + 32 + 96 + 32),
            "Data not encoded properly"
        );

        deposit(
            userData[:48],
            userData[48:80],
            userData[80:176],
            convertBytesToBytes32(userData[176:208])
        );

        deposit_data[deposit_count] = userData;
    }

    /**
     * Maybe plit in packs of 1000 elements ??
     * @dev Get an array of all excoded deposit data
     */
    function getDepositData()
        public
        view
        returns (bytes[] memory returnedArray)
    {
        returnedArray = new bytes[](deposit_count);
        for (uint256 i = 0; i < deposit_count; i++)
            returnedArray[i] = deposit_data[i];
    }

    /**
     * @dev Get the encoded deposit data at the `index`
     */
    function getDepositDataByIndex(uint256 index)
        public
        view
        returns (bytes memory)
    {
        return deposit_data[index];
    }

    /**
     * @dev Freze the LUKSO Genesis Deposit Contract
     */
    function freezeContract() external {
        require(msg.sender == owner, "Caller not owner");
        contractFrozen = true;
    }

    /**
     * @dev convert sliced bytes to bytes32
     */
    function convertBytesToBytes32(bytes calldata inBytes)
        internal
        pure
        returns (bytes32 outBytes32)
    {
        if (inBytes.length == 0) {
            return 0x0;
        }
        bytes memory memoryInBytes = inBytes;
        assembly {
            outBytes32 := mload(add(memoryInBytes, 32))
        }
    }
}