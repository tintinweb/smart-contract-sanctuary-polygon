// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract rentMarket is Ownable {
    // blockHeight(2) * 30 * 60 * 24 * 30 (1 month) : 2,592,000
    uint256 private constant ONE_MONTH_BLOCK_HEIGHT = 2592000;

    struct rentRecord {
        address nftAddress;
        uint256 tokenId;
        uint256 rentFee;
        uint256 rentDurationBlock;
        // When user rent, this would be recorded.
        address rentOwner;
        uint256 rentStartBlock;
    }

    // rent NFT record data.
    rentRecord[] rentRecordArray;

    // rent owner record data.
    // key : string(nft_address + token_id)
    // address : rent owner address
    // rentRecord : rent NFT data structure
    mapping(string => rentRecord) public rentNFTMap;
    mapping(address => rentRecord[]) public rentOwnerMap;

    constructor() {}

    function registerNFT(
        address nftAddress,
        uint256[] memory tokenId,
        uint256 rentFee,
        uint256 rentDuration
    ) public {
        for (uint256 i = 0; i < tokenId.length; i++) {
            // response : (bool, bytes memory)
            bool response;
            bytes memory responseData;
            (response, responseData) = nftAddress.call(
                abi.encodeWithSignature("ownerOf(uint256)", tokenId[i])
            );
            address ownerAddress = abi.decode(responseData, (address));

            require(
                ownerAddress == msg.sender,
                "Sender is not the owner of NFT."
            );

            string memory keyString = string(
                abi.encodePacked(
                    Strings.toHexString(uint256(uint160(nftAddress))),
                    Strings.toString(tokenId[i])
                )
            );

            rentNFTMap[keyString] = rentRecord(
                nftAddress,
                tokenId[i],
                rentFee,
                rentDuration,
                // Set 0 as default.
                // So 0 means not-yet-rented.
                address(0),
                0
            );
        }
    }

    function unregisterNFT(address nftAddress, uint256[] memory tokenId)
        public
    {
        for (uint256 i = 0; i < tokenId.length; i++) {
            string memory keyString = string(
                abi.encodePacked(
                    Strings.toHexString(uint256(uint160(nftAddress))),
                    Strings.toString(tokenId[i])
                )
            );

            delete rentNFTMap[keyString];
        }
    }

    function rentNFT(address nftAddress, uint256 tokenId) public payable {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(nftAddress))),
                Strings.toString(tokenId)
            )
        );

        rentRecord memory rentNFTRecord = rentNFTMap[keyString];

        // Check rent owner.
        require(
            rentNFTRecord.rentOwner != address(0) &&
                rentNFTRecord.rentStartBlock != 0,
            "This NFT is already rented."
        );

        // Check rent fee.
        require(
            msg.value >= rentNFTRecord.rentFee,
            "Transaction value is under the rent fee."
        );

        rentNFTRecord.rentOwner = msg.sender;
        rentNFTRecord.rentStartBlock = block.number;

        rentOwnerMap[msg.sender].push(rentNFTRecord);
    }

    function unrentNFT(address nftAddress, uint256 tokenId) public {
        for (uint256 i = 0; i < rentOwnerMap[msg.sender].length; i++) {
            rentRecord memory recordData = rentOwnerMap[msg.sender][i];
            if (
                recordData.nftAddress == nftAddress &&
                recordData.tokenId == tokenId
            ) {
                rentOwnerMap[msg.sender][i] = rentOwnerMap[msg.sender][
                    rentOwnerMap[msg.sender].length - 1
                ];
                rentOwnerMap[msg.sender].pop();
            }
        }
    }

    function getRentedNFT(address ownerAddress)
        public
        view
        returns (rentRecord[] memory)
    {
        return rentOwnerMap[ownerAddress];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}