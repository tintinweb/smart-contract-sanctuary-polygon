// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IStakeValidator {
    /**
     * Validate that an incoming transfer notification is a valid stake operation
     * This most likely will involve packing the the input data, hashing it and then validate against
     * a signature provided in the "data" argument"
     *
     * If this method deems the staking operation to be invalid, it *must* revert (since there is no
     * return value)
     */
    function validateERC721(
        address tokenContract, address from, uint256 tokenId, bytes calldata data
    ) external view;

    /**
     * See above
     */
    function validateERC1155(
        address tokenContract, address from, uint256 id, uint256 value, bytes calldata data
    ) external view;

    /**
     * See above
     */
    function validateERC1155Batch(
        address tokenContract, address from, uint256[] calldata ids, uint256[] calldata values,
        bytes calldata data
    ) external view;

    /**
     * Validates a batch stake is a valid stake operation.
     */
    function validateBatchStake(
        address[] calldata contracts, uint256[][] calldata tokens, uint256[][] calldata amounts,
        bytes calldata data
    ) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IStakeValidator.sol";

/**
 * @dev Validates stake operations by signatures provided from an external source - e.g. our backend
 * Signatures must _not_ use ERC191 signed data. Since we fully control the data that is being
 * signed this is not used to save gas.
 */
contract SignatureStakeValidator is IStakeValidator {

    /**
     * @dev The address that validation is done against. Signatures have to be created from this
     * wallet.
     */
    address private validatingAddress;

    /**
     * @dev _validatingAddress The address that generates the signatures to validate. This does not
     * have to be in use on chain.
     */
    constructor(address _validatingAddress) {
        validatingAddress = _validatingAddress;
    }

    /**
     * @dev Validate an ERC721 staking request. This function reverts when validation fails.
     * @param tokenContract The address of the ERC721 token
     * @param tokenId The id of the ERC721 token to stake
     * @param data The arbitrary data from ERC721#safeTransferFrom. This must be a 97 bytes array
     * where the first 32 bytes are the timestamp in seconds that was signed and the last 65 bytes
     * are the signature.
     */
    function validateERC721(
        address tokenContract, address /* from */, uint256 tokenId, bytes calldata data
    ) external override view {
        // 32 bytes timestamp, 65 bytes signature
        require(data.length == 97, "invalid data length");
        // Validate the timestamp in the data
        uint256 time = validateTimestamp(data, block.timestamp);
        // Encode the data to verify the signature. Backend has to do the same encoding
        // We can use encodePacked here since the data is not of dynamic size. See
        // https://docs.soliditylang.org/en/v0.8.19/abi-spec.html#non-standard-packed-mode
        bytes memory toHash = abi.encodePacked(time, tokenContract, tokenId);
        // Calculate the hash of the packed data
        bytes32 hash = keccak256(toHash);
        // Slice out the 32 bytes that stored the timestamp, the rest is the signature
        validateHash(data[32:], hash);
    }

    /**
     * @dev Validate an ERC1155 staking request for a single token. This function reverts when
     * validation fails.
     * @param tokenContract The address of the ERC1155 token
     * @param id The id of the ERC1155 token to stake
     * @param amount The amount of the token to stake
     * @param data The arbitrary data from ERC1155#safeTransferFrom. This must be a 97 bytes array
     * where the first 32 bytes are the timestamp in seconds that was signed and the last 65 bytes
     * are the signature.
     */
    function validateERC1155(
        address tokenContract, address /* from */, uint256 id, uint256 amount, bytes calldata data
    ) external override view {
        // 32 bytes timestamp, 65 bytes signature
        require(data.length == 97, "invalid data length");
        // Validate the timestamp in the data
        uint256 time = validateTimestamp(data, block.timestamp);
        // Encode the data to verify the signature. Backend has to do the same encoding.
        bytes memory toHash = abi.encodePacked(time, tokenContract, id, amount);
        // Calculate the hash of the packed data
        bytes32 hash = keccak256(toHash);
        // Slice out the 32 bytes that stored the timestamp, the rest is the signature
        validateHash(data[32:], hash);
    }

    /**
     * @dev Validate an ERC1155 staking request for multiple tokens. This function reverts when
     * validation fails.
     * @param tokenContract The address of the ERC1155 token
     * @param ids The ids of the ERC1155 tokens to stake
     * @param amounts The amounts of the token to stake
     * @param data The arbitrary data from ERC1155#safeBatchTransferFrom. This must be a 97 bytes
     * array where the first 32 bytes are the timestamp in seconds that was signed and the last 65
     * bytes are the signature.
     */
    function validateERC1155Batch(
        address tokenContract, address /* from */, uint256[] calldata ids,
        uint256[] calldata amounts, bytes calldata data
    ) external override view {
        // 32 bytes timestamp, 65 bytes signature
        require(data.length == 97, "invalid data length");
        // Validate the timestamp in the data
        uint256 time = validateTimestamp(data, block.timestamp);
        // Encode the data to verify the signature. Backend has to do the same encoding.
        // Due to the dynamic data (two arrays) packed encoding cannot be used.
        bytes memory toHash = abi.encode(time, tokenContract, ids, amounts);
        // Calculate the hash of the packed data
        bytes32 hash = keccak256(toHash);
        // Slice out the 32 bytes that stored the timestamp, the rest is the signature
        validateHash(data[32:], hash);
    }

    /**
     * @dev Validate a mixed staking request for multiple tokens. This function reverts when
     * validation fails.
     * @param contracts The addresses of the tokens to stake, must be ERC721 and ERC1155 tokens.
     * @param tokens The ids of the tokens per contract to stake
     * @param amounts The amounts of the token per contract to stake. For each ERC721 an empty array
     * must be passed.
     * @param data The arbitrary data from Staking#stake. This must be a 97 bytes array where the
     * first 32 bytes are the timestamp in seconds that was signed and the last 65 bytes are the
     * signature.
     */
    function validateBatchStake(
        address[] calldata contracts, uint256[][] calldata tokens, uint256[][] calldata amounts,
        bytes calldata data
    ) external override view {
        // 32 bytes timestamp, 65 bytes signature
        require(data.length == 97, "invalid data length");
        // Validate the timestamp in the data
        uint256 time = validateTimestamp(data, block.timestamp);
        // Encode the data to verify the signature. Backend has to do the same encoding.
        // Due to the dynamic data (three arrays) packed encoding cannot be used.
        bytes memory toHash = abi.encode(time, contracts, tokens, amounts);
        // Calculate the hash of the packed data
        bytes32 hash = keccak256(toHash);
        // Slice out the 32 bytes that stored the timestamp, the rest is the signature
        validateHash(data[32:], hash);
    }

    /**
     * @dev Extracts a timestamp from data and validates it is not too old or in the future
     * @param data Must contain at least 32 bytes, the first 32 bytes will be interpreted as an
     * uint256 representing a UNIX timestamp in seconds.
     * @param timestamp The current block timestamp
     * @return The extracted timestamp in seconds
     */
    function validateTimestamp(
        bytes memory data, uint256 timestamp
    ) private pure returns (uint256) {
        uint256 time;
        // It's incredibly hard to convert bytes to uint256, mload makes it easy. The first 32
        // bytes of the array are the length, second 32 bytes is the timestamp. Skip the length and
        // load the next 32 bytes via mload into the uint256.
        assembly {
            time := mload(add(data, 32))
        }
        // Validate the next operation will not underflow
        require(time <= timestamp, "signature from the future");
        // Validate the timestamp is less than 1 hour (3600 seconds) in the past
        require(timestamp - time <= 3600, "stake signature expired");
        // Return the extracted timestamp as it will be required to create the hashes
        return time;
    }

    /**
     * @dev Validates that the given signature was created for the given hash by. This reverts if
     * the determined signer is not the validatingAddress. This can happen if the hash or the
     * signature is incorrect.
     * @param signature The signature, split into r (32 bytes)/s (32 bytes)/v (1 byte), so a 65 byte
     * array
     * @param hash A recreation of the hash that was signed
     */
    function validateHash(bytes memory signature, bytes32 hash) private view {
        // Unpack signature raw data - not straight forward
        // see https://ethereum.stackexchange.com/a/125167
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // The signature is a byte array. First 32 bytes are the length. Skip 32 bytes and load
            // the next word into byte32
            r := mload(add(signature, 32))
            // Now skip the first 64 bytes (string length + r)
            s := mload(add(signature, 64))
            // Now skip the first 96 bytes and get just the first byte
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        // Recover the signer from the hash and signature
        address signer = ecrecover(hash, v, r, s);
        // Check if the signer was the validating address.
        require(signer == validatingAddress, "stake not authorized");
    }
}