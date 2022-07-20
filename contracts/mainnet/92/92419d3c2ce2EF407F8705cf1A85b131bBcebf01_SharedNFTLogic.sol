// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64} from "base64-sol/base64.sol";
import {IPublicSharedMetadata} from "./IPublicSharedMetadata.sol";
import {Versions} from "./Versions.sol";

struct MediaData{
    string imageUrl;
    string animationUrl;
    string patchNotesUrl;
    uint8[3] label;
}

/// Shared NFT logic for rendering metadata associated with editions
/// @dev Can safely be used for generic base64Encode and numberToString functions
contract SharedNFTLogic is IPublicSharedMetadata {
    /// @param unencoded bytes to base64-encode
    function base64Encode(bytes memory unencoded)
        public
        pure
        override
        returns (string memory)
    {
        return Base64.encode(unencoded);
    }

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        public
        pure
        override
        returns (string memory)
    {
        return StringsUpgradeable.toString(value);
    }

    /// @notice converts address to string
    /// @param _address address to return as a string
    function addressToString(address _address) public pure returns(string memory) {
        bytes20 _bytes = bytes20(_address);
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i] & 0x0f)];
        }
        return string(_string);
    }

    // Proxy to olta's uintArray3ToString function
    function uintArray3ToString (uint8[3] memory label)
        public
        pure
        returns (string memory)
    {
        return Versions.uintArray3ToString(label);
    }

    /// Generate edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param name Name of NFT in metadata
    /// @param description Description of NFT in metadata
    /// @param media The image Url, animation Url and version label of the media to be rendered
    /// @param tokenOfEdition Token ID for specific token
    /// @param editionSize Size of entire edition to show
    /// @param tokenAddress Address of the NFT
    function createMetadataEdition(
        string memory name,
        string memory description,
        MediaData memory media,
        uint256 tokenOfEdition,
        uint256 editionSize,
        address tokenAddress
    ) external pure returns (string memory) {
        string memory _tokenMediaData = tokenMediaData(
            media,
            tokenOfEdition,
            tokenAddress
        );
        bytes memory json = createMetadataJSON(
            name,
            description,
            _tokenMediaData,
            tokenOfEdition,
            editionSize
        );
        return encodeMetadataJSON(json);
    }

    /// Generate edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param name Name of NFT in metadata
    /// @param description Description of NFT in metadata
    /// @param media The image Url, animation Url and version label of the media to be rendered
    /// @param tokenOfEdition Token ID for specific token
    /// @param editionSize Size of entire edition to show
    /// @param tokenAddress Address of the NFT
    function createMetadataEdition(
        string memory name,
        string memory description,
        MediaData memory media,
        uint256 tokenOfEdition,
        uint256 editionSize,
        address tokenAddress,
        uint256 tokenSeed
    ) external pure returns (string memory) {
        string memory _tokenMediaData = tokenMediaData(
            media,
            tokenOfEdition,
            tokenAddress,
            tokenSeed
        );
        bytes memory json = createMetadataJSON(
            name,
            description,
            _tokenMediaData,
            tokenOfEdition,
            editionSize
        );
        return encodeMetadataJSON(json);
    }

    /// Function to create the metadata json string for the nft edition
    /// @param name Name of NFT in metadata
    /// @param description Description of NFT in metadata
    /// @param mediaData Data for media to include in json object
    /// @param tokenOfEdition Token ID for specific token
    /// @param editionSize Size of entire edition to show
    function createMetadataJSON(
        string memory name,
        string memory description,
        string memory mediaData,
        uint256 tokenOfEdition,
        uint256 editionSize
    ) public pure returns (bytes memory) {
        bytes memory editionSizeText;
        if (editionSize > 0) {
            editionSizeText = abi.encodePacked(
                "/",
                numberToString(editionSize)
            );
        }
        return
            abi.encodePacked(
                '{"name": "',
                name,
                " ",
                numberToString(tokenOfEdition),
                editionSizeText,
                '", "',
                'description": "',
                description,
                '", "',
                mediaData,
                'properties": {"number": ',
                numberToString(tokenOfEdition),
                ', "name": "',
                name,
                '"}}'
            );
    }

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64Encode(json)
                )
            );
    }

    /// Generates edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param media urls of image and animation media with version label
    function tokenMediaData(
        MediaData memory media,
        uint256 tokenOfEdition,
        address tokenAddress
    ) public pure returns (string memory) {
        bool hasImage = bytes(media.imageUrl).length > 0;
        bool hasAnimation = bytes(media.animationUrl).length > 0;
        if (hasImage && hasAnimation) {
            return
                string(
                    abi.encodePacked(
                        imageUrl(
                            media.imageUrl,
                            tokenOfEdition
                        ),
                        animationUrl(
                            media.animationUrl,
                            tokenOfEdition,
                            tokenAddress
                        ),
                        version(
                            media.label,
                            media.patchNotesUrl
                        )
                    )
                );
        }
        if (hasImage) {
            return
                string(
                    abi.encodePacked(
                        imageUrl(
                            media.imageUrl,
                            tokenOfEdition
                        ),
                        version(
                            media.label,
                            media.patchNotesUrl
                        )
                    )
                );
        }
        if (hasAnimation) {
            return
                string(
                    abi.encodePacked(
                        animationUrl(
                            media.animationUrl,
                            tokenOfEdition,
                            tokenAddress
                        ),
                        version(
                            media.label,
                            media.patchNotesUrl
                        )
                    )
                );
        }

        return "";
    }

    /// Generates edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param media urls of image and animation media with version label
    function tokenMediaData(
        MediaData memory media,
        uint256 tokenOfEdition,
        address tokenAddress,
        uint256 tokenSeed
    ) public pure returns (string memory) {
        bool hasImage = bytes(media.imageUrl).length > 0;
        bool hasAnimation = bytes(media.animationUrl).length > 0;
        if (hasImage && hasAnimation) {
            return
                string(
                    abi.encodePacked(
                        imageUrl(
                            media.imageUrl,
                            tokenSeed
                        ),
                        animationUrl(
                            media.animationUrl,
                            tokenOfEdition,
                            tokenAddress,
                            tokenSeed
                        ),
                        version(
                            media.label,
                            media.patchNotesUrl
                        )
                    )
                );
        }
        if (hasImage) {
            return
                string(
                    abi.encodePacked(
                        imageUrl(
                            media.imageUrl,
                            tokenSeed
                        ),
                        version(
                            media.label,
                            media.patchNotesUrl
                        )
                    )
                );
        }
        if (hasAnimation) {
            return
                string(
                    abi.encodePacked(
                        animationUrl(
                            media.animationUrl,
                            tokenOfEdition,
                            tokenAddress,
                            tokenSeed
                        ),
                        version(
                            media.label,
                            media.patchNotesUrl
                        )
                    )
                );
        }

        return "";
    }

    function version(
        uint8[3] memory label,
        string memory patchNotesUrl
    ) public pure returns (string memory) {
        return string (
            abi.encodePacked(
                'media_version": "',
                uintArray3ToString(label),
                '", "'
                'patch_notes": "',
                patchNotesUrl,
                '", "'
            )
        );
    }

    function imageUrl(
        string memory url,
        uint256 id
    ) public pure returns (string memory) {
        return string (
            abi.encodePacked(
                'image": "',
                url,
                 "?id=", // if just url "/id" this will work with arweave pathmanifests
                numberToString(id),
                '", "'
            )
        );
    }

    function animationUrl(
        string memory url,
        uint256 tokenId,
        address tokenAddress
    ) public pure returns (string memory) {
        return string (
            abi.encodePacked(
                'animation_url": "',
                url,
                "?id=",
                numberToString(tokenId),
                "&address=",
                addressToString(tokenAddress),
                '", "'
            )
        );
    }

    function animationUrl(
        string memory url,
        uint256 tokenId,
        address tokenAddress,
        uint256 seed
    ) public pure returns (string memory) {
        return string (
            abi.encodePacked(
                'animation_url": "',
                url,
                "?id=",
                numberToString(tokenId),
                "&address=",
                addressToString(tokenAddress),
                "&seed=",
                numberToString(seed),
                '", "'
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/// Shared public library for on-chain NFT functions
interface IPublicSharedMetadata {
    /// @param unencoded bytes to base64-encode
    function base64Encode(bytes memory unencoded)
        external
        pure
        returns (string memory);

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        external
        pure
        returns (string memory);

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        external
        pure
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 @title A libary for versioning of NFT content and metadata
 @dev Provides versioning for nft content and follows the semantic labeling convention.
 Each version contains an array of content and content hash pairs as well as a version label.
 Versions can be added and urls can be updated along with getters to retrieve specific versions and history.

 Include with `using Versions for Versions.set;`
 @author george baldwin
 */

library Versions {

    struct UrlHashPair {
        string url;
        bytes32 sha256hash;
    }

    struct Version {
        UrlHashPair[] urls;
        uint8[3] label;
    }

    struct Set {
        string[] labels;
        mapping(string => Version) versions;
    }

    /**
     @dev creates a new version from array of url hashe pairs and a semantic label
     @param urls An array of urls with sha-256 hash of the content on that url
     @param label a version label in a semantic style
     */
    function createVersion(
        UrlHashPair[] memory urls,
        uint8[3] memory label
    )
        internal
        pure
        returns (Version memory)
    {
        Version memory version = Version(urls, label);
        return version;
    }

    /**
     @dev adds a version to a given set by pushing the version label to an array
        and mapping the version to a string of that label. Will revert if the label already exists.
     @param set the set to add the version to
     @param version the version that will be stored
     */
    function addVersion(
        Set storage set,
        Version memory version
    ) internal {

        string memory labelKey = uintArray3ToString(version.label);

        require(
            set.versions[labelKey].urls.length == 0,
            "#Versions: A version with that label already exists"
        );

        // add to labels array
        set.labels.push(labelKey);

        // store urls and hashes in mapping
        for (uint256 i = 0; i < version.urls.length; i++){
            set.versions[labelKey].urls.push(version.urls[i]);
        }

        // store label
        set.versions[labelKey].label = version.label;
    }

    /**
     @dev gets a version from a given set. Will revert if the version doesn't exist.
     @param set The set to get the version from
     @param label The label of the requested version
     @return version The version corrosponeding to the label
     */
    function getVersion(
        Set storage set,
        uint8[3] memory label
    )
        internal
        view
        returns (Version memory)
    {
        Version memory version = set.versions[uintArray3ToString(label)];
        require(
            version.urls.length != 0,
            "#Versions: The version does not exist"
        );
        return version;
    }

    /**
     @dev updates a url of a given version in a given set
     @param set The set containing the version of which the url will be updated
     @param label The label of the requested version
     @param index The index of the url
     @param newUrl The new url to be updated to
     */
    function updateVersionURL(
        Set storage set,
        uint8[3] memory label,
        uint256 index,
        string memory newUrl
    ) internal {
        string memory labelKey = uintArray3ToString(label);
        require(
            set.versions[labelKey].urls.length != 0,
            "#Versions: The version does not exist"
        );
        require(
            set.versions[labelKey].urls.length > index,
            "#Versions: The url does not exist on that version"
        );
        set.versions[labelKey].urls[index].url = newUrl;
    }

    /**
     @dev gets all the version labels of a given set
     @param set The set containing the versions
     @return labels an array of labels as strings
    */
    function getAllLabels(
        Set storage set
    )
        internal
        view
        returns (string[] memory)
    {
        return set.labels;
    }

    /**
     @dev gets all the versions of a given set
     @param set The set containing the versions
     @return versions an array of versions
    */
    function getAllVersions(
        Set storage set
    )
        internal
        view
        returns (Version[] memory)
    {
        return getVersionsFromLabels(set, set.labels);
    }

    /**
     @dev gets the versions of a given array of labels as strings, reverts if no labels are given
     @param set The set containing the versions
     @return versions an array of versions
    */
    function getVersionsFromLabels(
        Set storage set,
        string[] memory _labels
    )
        internal
        view
        returns (Version[] memory)
    {
        require(_labels.length != 0, "#Versions: No labels provided");
        Version[] memory versionArray = new Version[](_labels.length);

        for (uint256 i = 0; i < _labels.length; i++) {
                versionArray[i] = set.versions[_labels[i]];
        }

        return versionArray;
    }

    /**
     @dev gets the last added version of a given set, reverts if no versions are in the set
     @param set The set containing the versions
     @return version the last added version
    */
    function getLatestVersion(
        Set storage set
    )
        internal
        view
        returns (Version memory)
    {
        require(
            set.labels.length != 0,
            "#Versions: No versions exist"
        );
        return set.versions[
            set.labels[set.labels.length - 1]
        ];
    }

    /**
     @dev A helper function to convert a three length array of numbers into a semantic style verison label
     @param label the label as a uint8[3] array
     @return label the label as a string
    */
    function uintArray3ToString (uint8[3] memory label)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            StringsUpgradeable.toString(label[0]),
            ".",
            StringsUpgradeable.toString(label[1]),
            ".",
            StringsUpgradeable.toString(label[2])
        ));
    }
}