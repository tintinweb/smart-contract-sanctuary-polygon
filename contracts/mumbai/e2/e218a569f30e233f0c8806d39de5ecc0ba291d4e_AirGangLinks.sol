// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

/*
🇦​​​​​🇮​​​​​🇷​​​​​__🇬​​​​​🇦​​​​​🇳​​​​​🇬____​​​​​__🇦​​​​​🇮​​​​​🇷​​​​​__🇬​​​​​🇦​​​​​🇳​​​​​🇬​​​​​
███████████████████████████████████████
██████████   //_____ __      ██████████
██████████   @ )====// .\___ ██████████
██████████   \#\_\__(_/_\\_/ ██████████
██████████     / /       \\  ██████████
███████████████████████████████████████
🇦​​​​​🇮​​​​​🇷​​​​​__🇬​​​​​🇦​​​​​🇳​​​​​🇬____​​​​​__🇦​​​​​🇮​​​​​🇷​​​​​__🇬​​​​​🇦​​​​​🇳​​​​​🇬​​​​​
*/

// SPDX-License-Identifier: UNLICENSED
// Copyright (C) 2023 Air Gang
// This file is part of the Air Gang project and can not be copied and/or distributed without express permission.

pragma solidity ^0.8.18;

/** 
@title Air Gang Creator Interface
@author bilets.eth
@notice This interface represents a subset of the Air Gang Creator contract. It includes only the functions needed by Air Gang child contracts.
*/

interface AirGangCreatorInterface {
    /**
     *@notice Get the tax to mint/subscribe a child NFT within an Air Gang contract.
     *@return Current tax for minting/subscribing a child NFT
     */
    function nftChildTax() external view returns (uint256);

    /**
     *@notice Get the minimum cost to mint a child NFT within an Air Gang contract.
     *@return Current minimum cost for minting a child NFT
     */
    function nftChildMinCost() external view returns (uint256);

    /**
    @notice This function returns the name of an Air Gang.
    @param tokenId The ID of the token.
    @return The name of the Air Gang.
    */
    function tokenIdToName(
        uint256 tokenId
    ) external view returns (string memory);

    /**
    @notice This function returns the owner of a token.
    @param tokenId The ID of the token.
    @return The address of the owner of the token.
    */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Removes an Air Gang child contract address from the list of contracts owned by the provided owner.
     * @param owner Address of the wallet to remove holding childs status.
     * @param childAddress Air Gang child contract address.
     */
    function airGangChildFromOwnerRemove(
        address owner,
        address childAddress
    ) external;

    /**
     * @notice Adds an Air Gang child contract address to the list of contracts owned by the provided owner.
     * @param owner Address of the wallet to add holding childs status.
     * @param childAddress Air Gang child contract address.
     */
    function airGangChildToOwnerAdd(
        address owner,
        address childAddress
    ) external;

    /**
     * @notice Get the base URI.
     * @return The base URI.
     */
    function getBaseURI() external view returns (string memory);
}

/*
🇦​​​​​🇮​​​​​🇷​​​​​__🇬​​​​​🇦​​​​​🇳​​​​​🇬____​​​​​__🇦​​​​​🇮​​​​​🇷​​​​​__🇬​​​​​🇦​​​​​🇳​​​​​🇬​​​​​
███████████████████████████████████████
██████████   //_____ __      ██████████
██████████   @ )====// .\___ ██████████
██████████   \#\_\__(_/_\\_/ ██████████
██████████     / /       \\  ██████████
███████████████████████████████████████
🇦​​​​​🇮​​​​​🇷​​​​​__🇬​​​​​🇦​​​​​🇳​​​​​🇬____​​​​​__🇦​​​​​🇮​​​​​🇷​​​​​__🇬​​​​​🇦​​​​​🇳​​​​​🇬​​​​​
*/

// SPDX-License-Identifier: UNLICENSED
// Copyright (C) 2023 Air Gang
// This file is part of the Air Gang project and can not be copied and/or distributed without express permission.

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./AirGangCreatorInterface.sol";

/** 
@title Air Gang Links
@author bilets.eth
@notice This contract represents an Air Gang Links where users can edit links and nft image.
*/

contract AirGangLinks is Ownable, ReentrancyGuard {
    // Air Gang Creator contract.
    AirGangCreatorInterface public airGangCreatorContract =
        AirGangCreatorInterface(
            payable(0x3A61ecC8acDbf7cAebd7B1503d435DcE38347b6B)
        );

    // Struct to keep track of Air Gang Links.
    struct AirGangLinksData {
        string website;
        string twitter;
        string instagram;
        string discord;
        string telegram;
        string youtube;
        string imgUrl;
        string shortDesc;
    }

    // Mapping from Air Gang ID to whether an Air Gang Link NFT has been minted for it.
    mapping(uint256 => bool) public airGangIDToMinted;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public ownerOf;

    // Mapping owner address to token count
    mapping(address => uint256) public balanceOf;

    // Total supply of tokens
    uint256 public totalSupply;

    // Emitted when `tokenId` token is transferred from `from` to `to`.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // Mapping from Air Gang ID to its data.
    mapping(uint256 => AirGangLinksData) public airGangIDToData;

    constructor() {}

    /**********************************************************/
    /**********************************************************/
    /************ 🇵​​​​​🇺​​​​​🇧​​​​​🇱​​​​​🇮​​​​​🇨​​​​​ 🇫​​​​​🇺​​​​​🇳​​​​​🇨​​​​​🇹​​​​​🇮​​​​​🇴​​​​​🇳​​​​​🇸​​​​​ ************/
    /**********************************************************/
    /**********************************************************/

    function name() public pure returns (string memory) {
        return "Air Gang Links";
    }

    function symbol() public pure returns (string memory) {
        return "AGL";
    }

    /**
     * @notice Updates links associated with a specific Air Gang.
     * @param airGangID The Air Gang ID.
     * @param twitter Twitter link.
     * @param instagram Instagram Link.
     * @param discord Discord Link.
     * @param telegram Discord Link.
     * @param youtube Discord Link.
     * @param imgUrl Image Url.
     */
    function updateLinks(
        uint256 airGangID,
        string memory website,
        string memory twitter,
        string memory instagram,
        string memory discord,
        string memory telegram,
        string memory youtube,
        string memory imgUrl,
        string memory shortDesc
    ) public nonReentrant {
        address admin = airGangCreatorContract.ownerOf(airGangID);
        require(admin == msg.sender, "Caller is not the admin");

        if (!airGangIDToMinted[airGangID]) {
            emit Transfer(
                address(0),
                0x000000000000000000FEED000000000000000000,
                airGangID
            );
            airGangIDToMinted[airGangID] = true;
            totalSupply += 1;
            balanceOf[0x000000000000000000FEED000000000000000000] += 1;
            ownerOf[airGangID] = 0x000000000000000000FEED000000000000000000;
        }

        AirGangLinksData storage linksData = airGangIDToData[airGangID];
        linksData.website = website;
        linksData.twitter = twitter;
        linksData.instagram = instagram;
        linksData.discord = discord;
        linksData.telegram = telegram;
        linksData.youtube = youtube;
        linksData.imgUrl = imgUrl;
        linksData.shortDesc = shortDesc;
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        AirGangLinksData memory linksData = airGangIDToData[id];
        string memory tokenName = airGangCreatorContract.tokenIdToName(id);
        string memory imageUrl = string(
            abi.encodePacked("ipfs://", linksData.imgUrl)
        );
        string memory externalUrl = string(
            abi.encodePacked("https://app.airgang.io/", tokenName)
        );
        string memory json = _buildJSON(tokenName, imageUrl, externalUrl);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function _buildJSON(
        string memory tokenName,
        string memory imageUrl,
        string memory externalUrl
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name": "Air Gang Links @',
                    tokenName,
                    '", "image": "',
                    imageUrl,
                    '", "description": "This is a dynamic NFT representing the social links and NFT image of AirGang @',
                    tokenName,
                    '", "external_url": "',
                    externalUrl,
                    '"}'
                )
            );
    }
}