/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0
// File: base64-sol/base64.sol



pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/interfaces/Planet-Universe-Interface-Gen2Alien.sol



pragma solidity ^0.8.0;


interface PlanetUniverseInterfaceGen2Alien is IERC721Enumerable {

  struct AlienGen2 {
        uint8[17] traitarray;
        uint8 generation;
        uint8 farmerWorkSpeed;
        uint8 carbonWorkSpeed;
        uint8 energyWorkSpeed;
        uint8 researchWorkSpeed;
        uint8 waterWorkSpeed;
        uint8 builderWorkSpeed;
    }

    function mint(address recipient, uint256 seed) external;
    function getTokenTraits(uint256 tokenId) external view returns (AlienGen2 memory);
    function makeFarmer(uint256 tokenId) external;
    function makeWater(uint256 tokenId) external;
    function makeCarbon(uint256 tokenId) external;
    function makeEnergy(uint256 tokenId) external;
    function makeResearch(uint256 tokenId) external;
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
}



// File: contracts/interfaces/Planet-Universe-Interface-Gen2Traits.sol



pragma solidity ^0.8.0;

interface PlanetUniverseInterfaceGen2Traits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Planet-Universe-Gen2Traits.sol


// Planet Universe

pragma solidity ^0.8.0;






contract Traits is Ownable, PlanetUniverseInterfaceGen2Traits {

  using Strings for uint256;

// struct to store each trait's data for metadata and rendering

  struct Trait {
    string name;
    string svg;
  }

// mapping from trait type (index) to its name
  string[16] private _traitTypes = [
    "Planet",
    "Craters",
    "River",
    "Flag",
    "Moon",
    "Rocket",
    "Alien",
    "Ring",
    "Alienbody",
    "Head",
    "Eyes",
    "Mouth",
    "Helmet",
    "Tatoo",
    "Flag",
    "Crown"
   ];

// storage of each traits name and base64 SVG data
  mapping(uint8 => mapping(uint8 => Trait)) public traitData;

//Some protection against the re-enter / view hax0r vermin. Creating a struct with some block timings
  struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

// Tracks the last block and timestamp that a caller has written to state to disallow some access to functions if they occur while a change is being written safety. Shoutout to @_MouseDev and @sum1eth
  mapping(address => LastWrite) private lastWriteAddress;
  mapping(uint256 => LastWrite) private lastWriteToken;

//Protection for Ratigan contracts
  mapping(address => bool) private rats; 

// Reference to Planet Universe NFT collection part of the CORE CONFIG immutables
PlanetUniverseInterfaceGen2Alien public PlanetUniverseGen2Alien;

constructor() {}

  function setPlanetNFT(address _gen2alien) external onlyOwner {
    PlanetUniverseGen2Alien = PlanetUniverseInterfaceGen2Alien(_gen2alien);
  }

// SVG GENERATOR Custom Ratigan @Planet Universe 2022 ©
// administrative to upload the names and images associated with each trait * @param traitType the trait type to upload the traits for (see traitTypes for a mapping) * @param traits the names and base64 encoded SVG for each trait
  function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    for (uint i = 0; i < traits.length; i++) {
      traitData[traitType][traitIds[i]] = Trait(
        traits[i].name,
        traits[i].svg
      );
    }
  }

// * generates a base64 encoded metadata response without referencing off-chain content * @param [tokenId] the ID of the token to generate the metadata for * @return a [base64 encoded JSON dictionary of the token's metadata and SVG]
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      'Planet Universe Gen2 #',
      tokenId.toString(),
      '", "description": "Planet Universe Gen 2 Collection | NO IPFS | NO API just the Polygon blockchain | P2E the right way with Planets and Aliens", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(compileBase64(tokenId)))
      ,
      '", "attributes":',
      compileAttributes(tokenId), 
      ']'
      "}"
    ));
    return string(abi.encodePacked(
      "data:application/json;base64,",
      Base64.encode(bytes(metadata))
    ));
  }

// Attributes *generates an attribute for the attributes array in the ERC721 metadata standard * @param [traitType] the trait type to reference as the metadata key * @param [value] the token's trait associated with the key
//  @return a JSON dictionary for the single attribute
  function singleAttributeBase64(string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(value));
  }

// The start of the base64 string for SVGs Custom Ratigan @Planet Universe 2022 ©
  function startbase() internal pure returns (string memory) {
    string memory base64start = '<svg version="1.1" id="Laag_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 750 750" style="enable-background:new 0 0 750 750;" xml:space="preserve">';
    return Base64.encode(bytes(base64start));
  }

// The end of the base64 string for SVGs Custom Ratigan @Planet Universe 2022 ©
  function endbase() internal pure returns (string memory) {
    string memory base64end = '</svg>';
    return Base64.encode(bytes(base64end));
  }

// Compile the base64 string and decode it Custom Ratigan @Planet Universe 2022 © No other game uses true SVG's we do!
  function compileBase64(uint256 tokenId) internal view returns (string memory) {
  PlanetUniverseInterfaceGen2Alien.AlienGen2 memory s = PlanetUniverseGen2Alien.getTokenTraits(tokenId);
    string memory traits;
    traits = string(abi.encodePacked(
        Base64.decode(startbase()),
        Base64.decode(singleAttributeBase64(traitData[0][s.traitarray[0]].svg)), 
        Base64.decode(singleAttributeBase64(traitData[1][s.traitarray[1]].svg)),
        Base64.decode(singleAttributeBase64(traitData[2][s.traitarray[2]].svg)),
        Base64.decode(singleAttributeBase64(traitData[3][s.traitarray[3]].svg)),
        Base64.decode(singleAttributeBase64(traitData[4][s.traitarray[4]].svg)),
        Base64.decode(singleAttributeBase64(traitData[5][s.traitarray[5]].svg)),
        Base64.decode(singleAttributeBase64(traitData[6][s.traitarray[6]].svg)),
        Base64.decode(singleAttributeBase64(traitData[7][s.traitarray[7]].svg))
        ));
    return string(abi.encodePacked(traits, '</svg>'));
  }

// ATTRIBUTES
// Generates a single reply for the attributes!
  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

// *generates an array composed of all the individual ATTRIBUTES * @param [tokenId] the ID of the token to compose the metadata for * @return a JSON array of all of the attributes for given token ID
  function compileAttributes(uint256 tokenId) internal view returns (string memory) {
    PlanetUniverseInterfaceGen2Alien.AlienGen2 memory s = PlanetUniverseGen2Alien.getTokenTraits(tokenId);
    string memory traits;
    traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[0][s.traitarray[0]].name), ',',
        attributeForTypeAndValue(_traitTypes[1], traitData[1][s.traitarray[1]].name), ',',
        attributeForTypeAndValue(_traitTypes[2], traitData[2][s.traitarray[2]].name), ',',
        attributeForTypeAndValue(_traitTypes[3], traitData[3][s.traitarray[3]].name), ',',
        attributeForTypeAndValue(_traitTypes[4], traitData[4][s.traitarray[4]].name), ',',
        attributeForTypeAndValue(_traitTypes[5], traitData[5][s.traitarray[5]].name), ',',
        attributeForTypeAndValue(_traitTypes[6], traitData[6][s.traitarray[6]].name)
        ));  
   return string(abi.encodePacked(
      '[',
      traits, ',',
      '{"trait_type":"Farmer Work Speed","value":',
      Strings.toString(s.farmerWorkSpeed),
      '},{"trait_type":"Energy Work Speed","value":',
      Strings.toString(s.energyWorkSpeed),
      '},{"trait_type":"Carbon Work Speed","value":',
      Strings.toString(s.carbonWorkSpeed),
      '},{"trait_type":"Water Work Speed","value":',
      Strings.toString(s.waterWorkSpeed),
      '},{"trait_type":"Research Work Speed","value":',
      Strings.toString(s.researchWorkSpeed), '}'
   ));
  }
}