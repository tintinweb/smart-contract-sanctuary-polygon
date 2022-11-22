// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMetadataGenerated.sol";

contract MetadataGenerated is IMetadataGenerated, Ownable {
    Parts parts;

    string public ipfs = "https://ipfs.filebase.io/ipfs/";
    string public urlThumbnail = "https://pilots-thumbnail.rhizom.me/";

    constructor() {}

    function addBackground(string[] memory _parts) public onlyOwner {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.background.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addSmoke(string[] memory _parts) public onlyOwner {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.smoke.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addWings(string[] memory _parts) public onlyOwner {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.wings.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addBase(string[] memory _parts) public onlyOwner {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.base.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addJet(string[] memory _parts) public onlyOwner {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.jet.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addCockpit(string[] memory _parts) public onlyOwner {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.cockpit.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addDescription(string[] memory _parts) public onlyOwner {
        Parts storage part = parts;
        for (uint256 i = 0; i < _parts.length; ) {
            part.description.push(_parts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getParts(uint256 _idPart, uint256 _PositionPart)
        public
        view
        returns (string memory,uint)
    {
        Parts memory part = parts;
        if (_idPart == 0) {
            return (part.background[_PositionPart],part.background.length);
        }

        if (_idPart == 1) {
            return (part.smoke[_PositionPart],part.smoke.length);
        }

        if (_idPart == 2) {
            return (part.wings[_PositionPart],part.wings.length);
        }

        if (_idPart == 3) {
            return (part.base[_PositionPart],part.base.length);
        }

        if (_idPart == 4) {
            return (part.jet[_PositionPart],part.jet.length);
        }

        if (_idPart == 5) {
            return (part.cockpit[_PositionPart],part.cockpit.length);
        }

        if (_idPart == 6) {
            return (part.description[_PositionPart],part.description.length);
        }

        return ("",0);
    }

    function generateSeed(uint256 _pilotId)
        public
        view
        override
        returns (Seed memory)
    {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), _pilotId))
        );

        return
            Seed({
                background: uint40(
                    uint40(pseudorandomness) % parts.background.length
                ),
                smoke: uint40(
                    uint40(pseudorandomness >> 40) % parts.smoke.length
                ),
                wings: uint40(
                    uint40(pseudorandomness >> 80) % parts.wings.length
                ),
                base: uint40(
                    uint40(pseudorandomness >> 120) % parts.base.length
                ),
                jet: uint40(uint40(pseudorandomness >> 160) % parts.jet.length),
                cockpit: uint40(
                    uint40(pseudorandomness >> 200) % parts.cockpit.length
                ),
                description: uint40(
                    uint40(pseudorandomness >> 240) % parts.description.length
                )
            });
    }

    function svgGenerated(Seed calldata _seed)
        public
        view
        override
        returns (string memory)
    {
        string memory svg = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "<svg xmlns='http://www.w3.org/2000/svg' width='350' height='350' viewbox='0 0 350 350' fill='none'><a href='https://rhizom.me/' target='_blank'>",
                        renderPart(parts.background[_seed.background]),
                        renderPart(parts.smoke[_seed.smoke]),
                        renderPart(parts.wings[_seed.wings]),
                        renderPart(parts.base[_seed.base]),
                        renderPart(parts.jet[_seed.jet]),
                        renderPart(parts.cockpit[_seed.cockpit]),
                        "</a></svg>"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", svg));
    }

    function renderPart(string memory _parts)
        public
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<image height='100%' width='100%'  href='",
                    ipfs,
                    _parts,
                    "'/>"
                )
            );
    }

    function tokenURI(uint256 _tokenId, Seed calldata _seed)
        public
        view
        override
        returns (string memory)
    {
        string memory image = svgGenerated(_seed);
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "pilot ',
                        Strings.toString(_tokenId),
                        '","image":"',
                        thumbnailGenerator(_seed),
                        '", "description":"',
                        parts.description[_seed.description],
                        '", "animation_url": "',
                        image,
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function thumbnailGenerator(Seed calldata _seed)
        public
        view
        returns (string memory)
    {
        //0-0-0-0-0-0.png
        return
            string(
                abi.encodePacked(
                    urlThumbnail,
                    Strings.toString(_seed.background),
                    "-",
                    Strings.toString(_seed.smoke),
                    "-",
                    Strings.toString(_seed.wings),
                    "-",
                    Strings.toString(_seed.jet),
                    "-",
                    Strings.toString(_seed.base),
                    "-",
                    Strings.toString(_seed.cockpit),
                    ".png"
                )
            );
    }

    function setIpfsUri(string memory _uri) external onlyOwner {
        ipfs = _uri;
    }

    function setUrlThumbnail(string memory _uri) external onlyOwner {
        urlThumbnail = _uri;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



interface IMetadataGenerated {
    struct Seed {
          uint40 background;
          uint40 smoke;
          uint40 wings;
          uint40 base;
          uint40 jet;
          uint40 cockpit;
          uint40 description;
    }

    struct Parts {
        string[] background;
        string[] smoke;
        string[] wings;
        string[] base;
        string[] jet;
        string[] cockpit;
        string[] description;
    }
    
    function generateSeed(uint _pilotId) external view  returns(Seed memory);

    function svgGenerated(Seed calldata _seed) external view returns(string memory);

    function tokenURI(uint _tokenId,Seed calldata _seed) external view returns (string memory);
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