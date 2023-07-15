// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NFTMetadataViews} from "./NFTMetadataViews.sol";

contract MutagenResolver is Ownable {

    //----------- Error --------------//
    error NotAllowedTrait();
    error InvalidLengthOfArrays();

    /// Multipler value based on the metadata identifiers.
    ///
    /// Keep track of the multiplier value based on the trait name, Doesn't matter with
    /// the value of the trait.
    /// TraitType => multiplier
    mapping(string => uint256) public traitTypeToMultiplier;

    /// Keep track of the multiplier value based on the trait value. eg - 
    /// Dosage(trait name) = 10g, 30g, 50g would have different multipler value.
    /// Trait Name => (Trait value => multipler)
    mapping(string => mapping(bytes => uint256)) public traitValueToMultiplier;

    /// Keep track of the multipler value based of the rarity value.
    /// Trait Name => (Rarity score => multiplier)
    mapping(string => mapping(uint256 => uint256)) public rarityScoreToMultiplier;

    /// Keep track of the multipler value based on the rarity description of the trait of a NFT.
    /// Trait Name => (Rarity description => multiplier)
    mapping(string => mapping(string => uint256)) public rarityDescriptionToMultiplier;

    /// This mapping would set the allowed trait which would be used for fetching multipliers.
    /// Trait name => boolean value
    mapping(string => bool) public allowedTrait;

    /// Keep track of compatible project NFTs with mutagen.
    /// address of the project NFT => boolean value
    mapping(address => bool) public compatibleProjectNFTs;

    /// Keep track of compatible NFT Id, that can mutagensis with the project NFT.
    /// project NFT address => project NFT tokenId => boolean value.
    mapping(address => mapping(uint256 => bool)) public compatibleNFTId;

    /// If it returns true then all NFTs of a given project is compatible with the mutagen for mutagenisis.
    /// address of the project NFT => boolean
    mapping(address => bool) public hasAllNFTCompatible;

    /// This mapping would keep the track of the attributes and needs to store before creating the rule.
    /// Key 1 would be the UUID for the projectNFT and MutagenNFT combination
    /// i.e bytes32(abi.encode(address of projectNFT, address of Mutagen NFT))
    /// Key 2 would be increment no. like 1,2,3 ...65535
    mapping(bytes32 => mapping(uint16 => NFTMetadataViews.Attribute)) public mutagensisAttribute;

    /// This mapping will keep the the counter of added attributes
    mapping(bytes32 => uint16) public mutagensisResultCounter;


    /// @notice Add an mutagensis attribute into list before creating the rule.
    /// @dev Only be called by the owner of the Resolver.
    /// @param projectNFT Address of the project NFT.
    /// @param mutagenNFT Address of the mutagen NFT.
    /// @param results Attribute data to be added in the list.
    function addMutagensisResults(
        address projectNFT,
        address mutagenNFT,
        NFTMetadataViews.Attribute[] calldata results
    ) external onlyOwner {
        bytes32 uuid = _getUUID(projectNFT, mutagenNFT);
        uint16 counter = mutagensisResultCounter[uuid];
        uint256 length = results.length;
        for(uint256 i; i < length;) {
            ++counter;
            mutagensisAttribute[uuid][counter] = results[i];
            unchecked {
                ++i;
            }
        }
        mutagensisResultCounter[uuid] = counter;
    }

    function _getUUID(address projectNFT, address mutagenNFT) internal pure returns(bytes32) {
        return bytes32(abi.encode(projectNFT, mutagenNFT));
    }


    /// @notice Set project NFTs that are compatible with the given mutagen NFT.
    /// @dev Only be called by the owner of the Resolver.
    /// @param projectNFT Address of the project NFT.
    /// @param nftIds List of NFT tokenIds of a given project NFT.
    function setCompatibleNFTs(address projectNFT, uint256[] memory nftIds) external onlyOwner {
        if (nftIds.length == uint256(0)) {
            hasAllNFTCompatible[projectNFT] = true;
        } else {
            for (uint256 i = 0; i < nftIds.length; i++) {
                compatibleNFTId[projectNFT][nftIds[i]] = true;
            }
        }
        compatibleProjectNFTs[projectNFT] = true;
    }

    /// @notice Set the multiplier for the different trait value, It will help to calculate the price
    /// of the mutagen NFT.
    /// @param traitType Type of the trait that would be used to differentiate the multipler (at the end prices)
    ///                  if the trait exists in a given mutagen. Its effect is independent of the trait value.
    /// @param rarityDescriptions Rarity description of the trait would also be used to increase the total multipler value. It depends upon
    ///                    the traitType, If the provided traitType exists then only rarity description get checked.
    /// @param traitValues Value of the trait that would also increase the total multiplier value. It depends upon the
    ///                   traitType, If the provided traitType exists then only trait value get checked.
    /// @param rarityScores Rarity score of the trait would also be used to increase the total multipler value. It depends upon
    ///                    the traitType, If the provided traitType exists then only rarity score get checked.
    /// @param rarityDescriptionMultipliers Multiplier value for the rarity description of a trait.
    /// @param traitValueMultipliers Multiplier value of the trait.
    /// @param rarityScoreMultipliers Multiplier value of the rarity score of a trait.
    function setMutipliersOfTrait(
        string memory traitType,
        string[] memory rarityDescriptions,
        bytes[] memory traitValues,
        uint256[] memory rarityScores,
        uint256[] memory rarityDescriptionMultipliers,
        uint256[] memory traitValueMultipliers, 
        uint256[] memory rarityScoreMultipliers
    ) 
        external 
        onlyOwner 
    {   
        if (!allowedTrait[traitType]) {
            revert NotAllowedTrait();
        }
        bool isEqualLength = rarityDescriptions.length == traitValues.length
                            && traitValues.length == rarityScores.length
                            && rarityScores.length == rarityDescriptionMultipliers.length
                            && rarityDescriptionMultipliers.length == traitValueMultipliers.length
                            && traitValueMultipliers.length == rarityScoreMultipliers.length;
        if (!isEqualLength) {
            revert InvalidLengthOfArrays();
        }
        for (uint256 i = uint256(0); i < rarityScores.length; i++ ) {
            traitValueToMultiplier[traitType][traitValues[i]] = traitValueMultipliers[i];
            rarityScoreToMultiplier[traitType][rarityScores[i]] = rarityScoreMultipliers[i];
            rarityDescriptionToMultiplier[traitType][rarityDescriptions[i]] = rarityDescriptionMultipliers[i];
        }
    }

    /// @notice It would add traitType into allowed list, Once add in allowed list owner can add the corresponding multipliers.
    /// @dev If Geneative wants to set the traitTypeMultiplier then it can within the same call, It would be act as the additional multiplier.
    /// @param traitType Type of the trait which would get added in allowed list.
    /// @param traitTypeMultiplier Value of the multiplier for the trait. 
    function allowTraitMultiplier(string memory traitType,  uint256 traitTypeMultiplier) external onlyOwner {
        allowedTrait[traitType] = true;
        traitTypeToMultiplier[traitType] = traitTypeMultiplier;
    }

    /// @notice Forbid the traitType, It can't be used for fetching the multipliers anymore.
    /// @param traitType Type of the trait which would get forbid from allowed list.
    function forbidTraitMultiplier(string memory traitType) external onlyOwner {
        allowedTrait[traitType] = false;
        delete traitTypeToMultiplier[traitType];
    }

    /// @notice Remove the multipliers for a given traitType.
    /// @param traitType Type of the trait corresponds to which multipliers get removed.
    /// @param rarityDescriptions List of rarity descriptions that would get removed.
    /// @param traitValues List of trait values that would get removed.
    /// @param rarityScores List of rarity scores that would get removed.
    function removeMutipliersOfTrait(
        string memory traitType,
        string[] memory rarityDescriptions,
        bytes[] memory traitValues,
        uint256[] memory rarityScores
    ) 
        external 
        onlyOwner 
    {
        if (!allowedTrait[traitType]) {
            revert NotAllowedTrait();
        }
        bool isEqualLength = rarityDescriptions.length == traitValues.length
                            && traitValues.length == rarityScores.length;
        if (!isEqualLength) {
            revert InvalidLengthOfArrays();
        }
        for (uint256 i = uint256(0); i < rarityScores.length; i++ ) {
           delete traitValueToMultiplier[traitType][traitValues[i]];
           delete rarityScoreToMultiplier[traitType][rarityScores[i]];
           delete rarityDescriptionToMultiplier[traitType][rarityDescriptions[i]];
        }
    }

    /// @notice Return the base multiplier.
    /// @param metadata Metadata of the NFT to calculate the cummulative multiplier of the mutagen NFT.
    function getBaseMultiplier(NFTMetadataViews.NFTView memory metadata) external view returns(uint256 totalMultiplier) {
         NFTMetadataViews.Attributes memory allTraits = metadata.attributes;
        for (uint256 i = uint256(0); i < allTraits.attributes.length; i++) {
            NFTMetadataViews.Attribute memory attribute = allTraits.attributes[i];
            if (!allowedTrait[attribute.trait_type]) {
                continue;
            }
            totalMultiplier += traitTypeToMultiplier[attribute.trait_type]; 
            totalMultiplier += traitValueToMultiplier[attribute.trait_type][attribute.value];
            totalMultiplier += rarityScoreToMultiplier[attribute.trait_type][attribute.rarity.score];
            totalMultiplier += rarityDescriptionToMultiplier[attribute.trait_type][attribute.rarity.description];
        }
    }

    /// @notice Return the added attribute for rule
    function getMutagensisAttribute(bytes32 uuid, uint16 counter) external view returns(NFTMetadataViews.Attribute memory) {
        return mutagensisAttribute[uuid][counter];
    }

    /// @notice It tells whether the mutation is allowed or not for the givein `projectNFT` and `nftId`.
    /// @param projectNFT Address of the project NFT.
    /// @param nftId Id of the NFT.
    function isMutationAllowed(address projectNFT, uint256 nftId) external view returns(bool) {
        if (hasAllNFTCompatible[projectNFT] || compatibleNFTId[projectNFT][nftId]) {
            return true;
        }
        return false;
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
pragma solidity 0.8.15;

import {IMetadataViewResolver} from "./interfaces/IMetadataViewResolver.sol";
import { strings } from "@string-utils/strings.sol";

library NFTMetadataViews {

    using strings for *;

    // bytes32 constant rarityView = keccak256(abi.encode("Struct Rarity{uint256 score, uint256 max, string description}"));
    // bytes32 constant traitView = keccak256(abi.encode("Struct Trait{string name, bytes vaule, string dataType, string displayType, Rarity rarity}"));
    bytes32 constant traitsView = keccak256(abi.encode("Struct Attributes{Attribute[] attributes}"));
    bytes32 constant displayView = keccak256(abi.encode("Struct Display{string name, string description}"));

    /// View to expose rarity information for a single rarity
    /// Note that a rarity needs to have either score or description but it can 
    /// have both
    ///
    struct Rarity {
        /// The score of the rarity as a number
        uint256 score;

        /// The maximum value of score
        uint256 max;

        /// The description of the rarity as a string.
        ///
        /// This could be Legendary, Epic, Rare, Uncommon, Common or any other string value
        string description;
    }

    /// Helper to get Rarity view in a typesafe way
    ///
    /// @param nftContract: NFT contract to get the rarity
    /// @param nftId: NFT id
    /// @return Rarity 
    ///
    // function getRarity(address nftContract, uint256 nftId) external view returns(Rarity rarityMetadata){
    //     bytes rarity = IMetadataViewResolver(nftContract).resolveView(nftId, rarityView);
    //     if (rarity.length > 0) {
    //         rarityMetadata = abi.decode(rarity, (Rarity));
    //     }
    // }


    /// View to represent a single field of metadata on an NFT.
    /// This is used to get traits of individual key/value pairs along with some
    /// contextualized data about the trait
    ///
    struct Attribute {
        // The name of the trait. Like Background, Eyes, Hair, etc.
        string trait_type;

        // The underlying value of the trait, the rest of the fields of a trait provide context to the value.
        bytes value;

        // The data type of the underlying value.
        string data_type;

        // displayType is used to show some context about what this name and value represent
        // for instance, you could set value to a unix timestamp, and specify displayType as "Date" to tell
        // platforms to consume this trait as a date and not a number
        string display_type;

        // Rarity can also be used directly on an attribute.
        //
        // This is optional because not all attributes need to contribute to the NFT's rarity.
        Rarity rarity;
    }


    /// Wrapper view to return all the traits on an NFT.
    /// This is used to return traits as individual key/value pairs along with
    /// some contextualized data about each trait.
    struct Attributes {
        Attribute[] attributes;
    }

    /// Helper to get Traits view in a typesafe way
    ///
    /// @param nftContract: A reference to the resolver resource
    /// @param nftId: A reference to the resolver resource
    ///
    function getTraits(address nftContract, uint256 nftId) public returns(Attributes memory traitsMetadata) {
        bytes memory traits = IMetadataViewResolver(nftContract).resolveView(nftId, traitsView);
        if (traits.length > 0) {
            traitsMetadata = abi.decode(traits, (Attributes));
        }
    }

    /// View to expose a file stored on IPFS.
    /// IPFS images are referenced by their content identifier (CID)
    /// rather than a direct URI. A client application can use this CID
    /// to find and load the image via an IPFS gateway.
    ///
    struct IPFSFile {

        /// CID is the content identifier for this IPFS file.
        ///
        /// Ref: https://docs.ipfs.io/concepts/content-addressing/
        ///
        string cid;

        /// Path is an optional path to the file resource in an IPFS directory.
        ///
        /// This field is only needed if the file is inside a directory.
        ///
        /// Ref: https://docs.ipfs.io/concepts/file-systems/
        ///
        string path;
    }

    /// This function returns the IPFS native URL for this file.
    /// Ref: https://docs.ipfs.io/how-to/address-ipfs-on-web/#native-urls
    ///
    /// @return The string containing the file uri
    ///
    function getUri(IPFSFile memory ipfs) public pure returns(string memory) {
        string memory ipfs_default_location = "ipfs://".toSlice().concat(ipfs.cid.toSlice());
        if (bytes(ipfs.path).length == 0) {
            return (ipfs_default_location
                .toSlice()
                .concat("/".toSlice()))
                .toSlice()
                .concat(ipfs.path.toSlice());
        }
        return ipfs_default_location;
    }


    struct Display {
        /// The name of the object. 
        ///
        /// This field will be displayed in lists and therefore should
        /// be short an concise.
        ///
        string name;

        /// A written description of the object. 
        ///
        /// This field will be displayed in a detailed view of the object,
        /// so can be more verbose (e.g. a paragraph instead of a single line).
        ///
        string description;


        IPFSFile file;
    }


    function getDisplay(address nftContract, uint256 nftId) public returns(Display memory displayMetadata) {
        bytes memory display_content = IMetadataViewResolver(nftContract).resolveView(nftId, displayView);
        if (display_content.length > 0) {
            displayMetadata = abi.decode(display_content, (Display));
        }
    }

    struct NFTView {
        Display display;
        string uri;
        Attributes attributes;
    }

    function getNFTView(address nftContract, uint256 nftId) external returns(NFTView memory nftMetdata) {
        Display memory display = getDisplay(nftContract, nftId);
        return NFTView({
            display: display,
            uri: bytes(display.file.cid).length > 0? getUri(display.file): "" ,
            attributes: getTraits(nftContract, nftId)
        });
    }

    /// @dev This function has been created just to use in abi for the signature generation at FE
    function getView(NFTView[] memory nftView) external pure returns(string memory) {
        return "abc";
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMetadataViewResolver is IERC165 {

    function getViews(uint256 nftId) external view returns(bytes32[] memory);
    function resolveView(uint256 nftId, bytes32 viewType) external returns(bytes memory);

}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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