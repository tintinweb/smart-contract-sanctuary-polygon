// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @author     Concretio Apps Team
/// @title      Rebel Organization Contract Helper Library

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library RebelLibrary {
    using Strings for uint32;

    /// @dev To store acknowledgements that volunteer gets awarded for his/her work
    struct Acknowledgement {
        string _title; // Title of acknowledgement
        string _uom; // Unit of measurement by which acknowledgement duration is measured Eg. week(s), day(s), times, etc
    }

    /// @dev To store the Volunteer details on-chain
    struct VolCert {
        string _name;
        string _role;
        string _addressedBy; // she/he/?
        string _issuedOn;
        address _walletAddress; // on which address it should be minted
        uint32 _lastUpdatedOn;
        uint8[] _acknowledgementIds;
        uint8[] _servedDurations; // duration served in uom corresponding to acknowledgementIds 
    }

    /// @dev Event to emit when a certificate is minted
    event VolCertIssued(
        string role,
        string name,
        string addressedBy,
        string issuedOn,
        address walletAddress,
        uint32 lastUpdatedOn,
        uint8[] volAcknowledgementIds,
        uint8[] servedDurations
    );

    /// @dev Function to Emit event when a certificate is minted
    function emitVolDetails(
        string memory role,
        string memory name,
        string memory addressedBy,
        string memory issuedOn,
        address walletAddress,
        uint32 lastUpdatedOn,
        uint8[] memory volAcknowledgementIds,
        uint8[] memory servedDurations
    ) public {

        // Emit a NewVolunteer event with details about the Volunteer.
        emit VolCertIssued(
            role,
            name,
            addressedBy,
            issuedOn,
            walletAddress,
            lastUpdatedOn,
            volAcknowledgementIds,
            servedDurations
        );

    }

    /// @dev Function creates Token URI in base64 json encoded format for the Volunteer who's NFT is getting minted
    /// @param tokenId Id of current token 
    /// @param volDetail Details of Volunteer who's certificate to mint
    /// @param acknowledgementById List of acknowledgements given to the current volunteer who's certificate getting minted
    /// @return string Containing Token URI in base64 json encoded format
    function getTokenURI(
        uint16 tokenId,
        VolCert memory volDetail, 
        mapping(uint8 => Acknowledgement) storage acknowledgementById
    ) public view returns (string memory) {

        bytes memory dataURI = abi.encodePacked(
            "{",
                '"name": "#', uint32(tokenId).toString(), '",',
                '"description": "Appreciation certificate issued to ', volDetail._name, ' for their amazing support with our noble cause",',
                '"image": "', generateSVG(volDetail, acknowledgementById), ((volDetail._acknowledgementIds.length == 0) ? '"' : '",'),
                ((volDetail._acknowledgementIds.length == 0) ? '' : string(generateNFTMetadataAttribs(volDetail, acknowledgementById))),
            "}"
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }


    /**
        Generates ERC721 NFT metadata for a given NFT, based on stunts done by them for Rebel Club
        Ref: https://docs.opensea.io/docs/metadata-standards

        "attributes": [
            {
            "trait_type": "Base", 
            "value": "Starfish"
            }, 
            ...
            ...
            {
            "display_type": "boost_number", 
            "trait_type": "Aqua Power", 
            "value": 40
            }, 
            {
            "display_type": "boost_percentage", 
            "trait_type": "Stamina Increase", 
            "value": 10
            }, 
            {
            "display_type": "number", 
            "trait_type": "Generation", 
            "value": 2
            }
        ]
    */
    /// @dev This function creates attributes according to metadata standards for ERC721 or ERC1155 NFTs. Refer the following link to know more about:
    /*  https://docs.opensea.io/docs/metadata-standards  */
    /// @param volDetail Details of volunteer to add on metadata
    /// @param acknowledgementById Acknowledgements awarded to the volunteer to add on metadata
    function generateNFTMetadataAttribs(VolCert memory volDetail, mapping(uint8 => Acknowledgement) storage acknowledgementById) private view returns (bytes memory) {
        bytes memory attributesJson = '"attributes": [';
        attributesJson = abi.encodePacked(attributesJson,
            '{',
                '"display_type": "date",',
                '"trait_type": "Last Updated On",',
                '"value": "' , (uint32(volDetail._lastUpdatedOn)).toString() , '"',
            '},'
        );
        for (uint8 i = 0; i < volDetail._acknowledgementIds.length; i++) {            
            RebelLibrary.Acknowledgement memory acknowledgementValue = acknowledgementById[uint8(volDetail._acknowledgementIds[i])];

            /*
                Generates a JSON of following structure, for all possible stunts
                {
                    "trait_type": "Background",
                    "value": "Green"
                },
             */
            attributesJson = abi.encodePacked(attributesJson, 
                '{',
                    //ex. "trait_type": "Tasks Performed",
                    '"trait_type": "' , acknowledgementValue._title, '",',
                    '"value": "for ', (uint32(volDetail._servedDurations[i])).toString(), ' ', acknowledgementValue._uom, '"',
                (i == (volDetail._acknowledgementIds.length - 1)? '}' : '},')
            );
        }
        attributesJson = abi.encodePacked(attributesJson, "]");
        return attributesJson;
    }

    /// @dev This function creates the SVG image on-chain for the volunteer Certificate NFT
    /// @param volDetail Details of the volunteer to add on Certificate
    /// @param acknowledgementById Map of all the acknowledgements present
    function generateSVG(
        VolCert memory volDetail,
        mapping(uint8 => Acknowledgement) storage acknowledgementById
    ) private view returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<?xml version="1.0" encoding="UTF-8" standalone="no"?> <svg version="1.1" width="840pt" height="600pt" viewBox="0 0 840 600" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">',
            '<g enable-background="new"> <g clip-path="url(#cp2)"> <path transform="scale(0.7497773)" d="M 0,0 H 1123 V 794 H 0 Z"/></g></g>',
            '<text fill="#ff1616" text-anchor="middle" font-size="50px" font-family="Cambria" x="420" y="70">CERTIFICATE</text>',
            // generateSVGText('fill="#ff1616" text-anchor="middle" font-size="50px" font-family="Cambria"', 420, 70, 'CERTIFICATE'),
            '<text fill="#ffffff" text-anchor="middle" font-size="30px" font-family="Trebuchet MS" x="420" y="120">of appreciation</text>',
            '<text fill="#ff1616" font-size="16px" font-weight="bold" font-family="Trebuchet MS" x="195" y="160">THE REBEL CLUB</text>',
            '<text fill="#ffffff" font-size="16px" font-family="Trebuchet MS" x="327" y="160">proudly presents this certificate to our Rebel</text>',
            '<text fill="#ffffff" text-anchor="middle" font-size="50px" font-family="Brush Script MT" y="240" x="420">', volDetail._name ,'</text>',
            '<text fill="#ffffff" font-size="20px" font-family="Goudy Old Style" x="50" y="320">', volDetail._addressedBy ,' supported the club by:</text>',
            generateAcknowledgements(volDetail, acknowledgementById),
            '<text fill="#ffffff" font-size="16px" font-family="Trebuchet MS" x="50" y="530">', volDetail._issuedOn ,'</text>',
            '<text fill="#ffffff" text-anchor="end" font-size="16px" font-family="Trebuchet MS" x="790" y="530">', volDetail._name ,'</text>',
            '<text fill="#ff1616" font-size="20px" font-family="Trebuchet MS" x="50" y="500">Issued on</text>',
            '<text fill="#ff1616" text-anchor="end" font-size="20px" font-family="Trebuchet MS" x="790" y="500">Signed By</text>',
            '<text fill="#ff1616" text-anchor="end" font-size="16px" font-family="Arial Narrow" x="790" y="550">', Strings.toHexString(uint256(uint160(volDetail._walletAddress)), 20) ,'</text>',
            '</svg>'
        );
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
    }

    /// @dev Helper function to create list items of volunteer's acknowledgements.
    /// @param volDetail Details of volunteer to fetch his/her acknowledgement Ids and corresponding duration.
    /// @param acknowledgementById Map of all the acknowledgements stored on chain to fetch current volunteer acknowledgements.
    function generateAcknowledgements(VolCert memory volDetail, mapping(uint8 => Acknowledgement) storage acknowledgementById) internal view returns (string memory) {
        bytes memory attributesJson;
        for (uint8 i = 0; i < volDetail._acknowledgementIds.length; i++) {
            attributesJson = abi.encodePacked(attributesJson,
                '<text fill="#ffffff" font-size="20px" font-family="Goudy Old Style" x="80" y="', uint32(i*35 + 355).toString() ,'">&#9825; ', acknowledgementById[volDetail._acknowledgementIds[i]]._title ,' for ', (uint32(volDetail._servedDurations[i])).toString() ,' ', acknowledgementById[volDetail._acknowledgementIds[i]]._uom ,'.</text>'
            );
        }
        return string(attributesJson);
    }

    // function generateSVGText(string memory _styleProperties, uint56 _positionX, uint56 _positionY, string memory _innerText) private pure returns (string memory) {
    //     bytes memory svgText = abi.encodePacked(
    //         '<text ', _styleProperties ,' x="', _positionX ,'" y="', _positionY ,'">', _innerText ,'</text>'
    //     );
    //     return string(svgText);
    // }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}