/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/did/interfaces/IHashDB.sol

// 
pragma solidity ^0.8.9;

interface IPushItemSingle {
    function pushElement(bytes32 itemKey, bytes memory itemValue) external;
}

interface IRemoveElement {
    function removeElement(bytes32 itemKey) external;
}

interface IItemArray {
    function itemArrayLength(bytes32 itemKey) external view returns (uint256);

    function itemArraySlice(bytes32 itemKey, uint256 start, uint256 end) external view returns (bytes[] memory);
}

interface IGetElement {
    function getElement(bytes32 itemKey, uint256 idx) external view returns (bytes memory);
}

interface IGetFirstElement {
    function getFirstElement(bytes32 itemKey) external view returns (bytes memory);
}

interface IRemoveItemArray {
    function removeItemArray(bytes32 itemKey) external;
}

interface IReplaceItemArray {
    function replaceItemArray(bytes32 itemKey, bytes[] memory itemArray) external;
}

interface IReplaceItemArrayWithElement {
    function replaceItemArray(bytes32 itemKey, bytes memory itemValue) external;
}


// File contracts/did/interfaces/IDB.sol

// 

pragma solidity ^0.8.9;

interface ISetReverse {
    function setReverse(address owner, bytes32 node) external;
}

interface INodeStatus {
    function isNodeActive(bytes32 node) external view returns (bool);
    function isNodeExisted(bytes32 node) external view returns (bool);
}

interface IActivate {
    function activate(bytes32 parent, address owner, uint64 expire, string memory name, bytes memory _data)
        external
        returns (bytes32);
}

interface IDeactivate {
    function deactivate(bytes32 node) external;
}

interface NodeStruct {
    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 transfer;
        string name;
    }
}

interface INodeRecord is NodeStruct {
    function getNodeRecord(bytes32 node) external view returns (Node memory);
}

interface IIsNodeActive {
    function isNodeActive(bytes32 node) external view returns (bool);
}

interface IOwnerOf {
    function ownerOf(uint256 tokenId) external view returns (address);
}


// File contracts/did/lib/KeyEnumBase.sol

// 

pragma solidity ^0.8.9;

abstract contract KeyEnumBase {
    bytes32 public constant ROOT = bytes32(0);
    uint256 internal constant INDEX_NULL = 0;
    address internal constant ADDRESS_NULL = address(0);
    bytes32 internal constant KEY_NULL = bytes32(0);
    // encodeToKey(bytes32 node, address owner, bytes32 keyHash, bytes32 keySub)

    bytes32 internal constant KEY_BRAND = keccak256("KEY_BRAND");
    // contract address for a domain to set customized tokenURI function for subdomain

    bytes32 internal constant KEY_LIKE = keccak256("KEY_LIKE");
    // maxLength == 100
    // encodeToKey(node, address(0), KEY_LIKE, bytes32(0)) => [liker1, liker2, liker3...]
    // maxLength == Type(uint256).max
    // encodeToKey(node, address(0), KEY_LIKE, bytes32(1)) => [(likee1, timestamp1), (likee2, timestamp2)...]

    bytes32 internal constant KEY_ORDER = keccak256("KEY_ORDER");
    // => [(market address, taker address, expire time, fixed price)]

    bytes32 internal constant KEY_TTL = keccak256("KEY_TTL"); // => [time to live]

    // !!! order and ttl should be cleared before transfer !!!

    // bytes32 internal constant KEY_RESERVE = keccak256("KEY_RESERVE"); // => [marker]
}


// File contracts/did/lib/Parser.sol

// 

pragma solidity ^0.8.9;

library Parser {
    function encodeNameToNode(bytes32 parent, string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    // !!! keyHash must be a hash value, but keySub might be converted from a unit256 number directly !!!
    function encodeToKey(bytes32 node, address owner, bytes32 keyHash, bytes32 keySub)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, owner, keyHash, keySub));
    }

    function abiBytesToAddressTime(bytes memory bys) internal pure returns (address addr, uint64 time) {
        uint256 num = abiBytesToUint256(bys);
        addr = address(uint160(num >> 96));
        time = uint64(num & type(uint96).max);
    }

    //
    //    function abiBytesToAddress(bytes memory bys) internal pure returns (address ret) {
    //        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
    //        if (bys.length == 32) {
    //            ret = abi.decode(bys, (address));
    //        }
    //        return ret;
    //    }
    //
    //    function abiBytesToUint64(bytes memory bys) internal pure returns (uint64 ret) {
    //        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
    //        if (bys.length == 32) {
    //            ret = abi.decode(bys, (uint64));
    //        }
    //        return ret;
    //    }
    //
    function abiBytesToUint256(bytes memory bys) internal pure returns (uint256 ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (uint256));
        }
        return ret;
    }
    //
    //    function abiBytesToString(bytes memory bys) internal pure returns (string memory ret) {
    //        if (bys.length > 0) {
    //            ret = abi.decode(bys, (string));
    //        }
    //        return ret;
    //    }
    //

    function abiBytesCutToAddress(bytes memory bys) internal pure returns (address addr) {
        uint256 num = abiBytesToUint256(bys);
        addr = address(uint160(num >> 96));
    }
}


// File contracts/did/interfaces/IBeacon.sol

// 

pragma solidity ^0.8.9;

interface IDAOBeacon {
    function DAO() external view returns (address);
}

interface IDBBeacon {
    function DB() external view returns (address);
}

interface IEditorBeacon {
    function editor() external view returns (address);
}

interface IBufferBeacon {
    function buffer() external view returns (address);
}

interface IVaultBeacon {
    function vault() external view returns (address);
}

interface IBrandBeacon {
    function brand() external view returns (address);
}

interface IHookBeacon {
    function hook() external view returns (address);
}

interface IMarketBeacon {
    function market() external view returns (address);
}

interface IResolverBeacon {
    function resolver() external view returns (address);
}

interface IFilterBeacon {
    function filter() external view returns (address);
}

interface IValueMiningBeacon {
    function valueMining() external view returns (address);
}


// File contracts/did/platform/AccessControl.sol

// 

pragma solidity ^0.8.9;

abstract contract AccessControl {
    mapping(address => bool) public operators;

    address public beacon;

    event OperatorGranted(address operator, bool granted);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    modifier onlyDAO() {
        require(msg.sender == _DAO(), "Caller is not the DAO");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Caller is not an operator");
        _;
    }

    function _DAO() internal view virtual returns (address) {
        return IDAOBeacon(beacon).DAO();
    }

    function setOperator(address addr, bool granted) external onlyDAO {
        _setOperator(addr, granted);
    }

    function setOperators(address[] calldata addrs, bool granted) external onlyDAO {
        for (uint256 i = 0; i < addrs.length; i++) {
            _setOperator(addrs[i], granted);
        }
    }

    function _setOperator(address addr, bool granted) internal {
        operators[addr] = granted;
        emit OperatorGranted(addr, granted);
    }
}


// File contracts/lib/StringLib.sol

// 
pragma solidity ^0.8.9;

library StringLib {
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
}


// File contracts/did/Brand.sol

// 

pragma solidity ^0.8.0;






interface ITokenURT {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Brand is AccessControl, KeyEnumBase {
    using StringLib for uint256;

    string private _name;
    string private _symbol;

    string public baseURI;
    string public defaultURI;

    event NameSymbolChanged(string name_, string symbol_);
    event BaseURIChanged(string uri);

    constructor(address _beacon, string memory name_, string memory symbol_) AccessControl(_beacon) {
        _name = name_;
        _symbol = symbol_;
    }

    function setNameSymbol(string calldata name_, string calldata symbol_) public onlyDAO {
        _name = name_;
        _symbol = symbol_;
        emit NameSymbolChanged(name_, symbol_);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        tokenId;
        /*
        address db = IDBBeacon(beacon).DB();
        NodeStruct.Node memory n = INodeRecord(db).getNodeRecord(bytes32(tokenId));
        require(n.owner != address(0), "ERC721: URI query for nonexistent token");

        address pOwner = INodeRecord(db).getNodeRecord(n.parent).owner;
        bytes32 encodedKey = Parser.encodeToKey(n.parent, pOwner, KEY_BRAND, KEY_NULL);
        if (IItemArray(db).itemArrayLength(encodedKey) == 1) {
            address _brand = abi.decode(IGetFirstElement(db).getFirstElement(encodedKey), (address));
            return ITokenURT(_brand).tokenURI(tokenId);
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : defaultURI;
        */

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : makeURI();
    }

    function setBaseURI(string memory uri) public onlyDAO {
        baseURI = uri;
        emit BaseURIChanged(uri);
    }

    function setDefaultURI(string memory uri) public onlyDAO {
        defaultURI = uri;
    }

    function tokenImage() internal pure returns (bytes memory) {
        return
        abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 738.95 168.4"><defs><linearGradient id="change_14" x1="72.57" y1="155.38" x2="70.69" y2="11.03" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#c371fb"/><stop offset="0.14" stop-color="#bb6ffb"/><stop offset="0.34" stop-color="#a66afc"/><stop offset="0.6" stop-color="#8462fd"/><stop offset="0.88" stop-color="#5557fe"/><stop offset="1" stop-color="#3f52ff"/></linearGradient><linearGradient id="change_5" x1="435.91" y1="87.68" x2="536.94" y2="87.68" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#c371fb"/><stop offset="1" stop-color="#c371fc"/></linearGradient><linearGradient id="change_5-2" x1="318.12" y1="88.01" x2="418" y2="88.01" xlink:href="#change_5"/><linearGradient id="change_5-3" x1="267.43" y1="87.69" x2="316.68" y2="87.69" xlink:href="#change_5"/><linearGradient id="change_5-4" x1="164.86" y1="87.65" x2="265.89" y2="87.65" xlink:href="#change_5"/><linearGradient id="change_5-5" x1="523.86" y1="87.68" x2="630.36" y2="87.68" xlink:href="#change_5"/><linearGradient id="change_5-6" x1="634.64" y1="87.68" x2="738.95" y2="87.68" xlink:href="#change_5"/></defs><g id="layer_2" data-name="layer 2"><g id="layer_1-2" data-name="layer 1"><path d="M137,43.39q-7.37-16.53-18.92-26.24A65.39,65.39,0,0,0,92.14,3.72,110.86,110.86,0,0,0,64.38,0H0V168.4H66.64a91,91,0,0,0,30.6-5.06A65,65,0,0,0,121.82,148,74.69,74.69,0,0,0,138.26,122q6.11-15.58,6.11-36.47Q144.37,59.93,137,43.39Z" style="fill:url(#change_14)"/><path d="M454.92,38.77h44.91q13.28,0,20.75,3.61a26.36,26.36,0,0,1,11.5,10.34,35.09,35.09,0,0,1,4.69,15.68,71.05,71.05,0,0,1-1.28,18.95q-3,15.68-8.29,24.32a53.24,53.24,0,0,1-12.73,14.48,41,41,0,0,1-15.12,7.77,76.07,76.07,0,0,1-18.54,2.67h-44.9Zm25.92,22.16-10.39,53.44h7.41q9.48,0,13.89-2.1a18.89,18.89,0,0,0,7.7-7.34q3.29-5.24,5.57-17,3-15.54-.94-21.28t-15.7-5.74Z" style="fill:url(#change_5)"/><path d="M335.35,39.36l44.9-.82q13.28-.24,20.82,3.22a26.36,26.36,0,0,1,11.68,10.13,35.17,35.17,0,0,1,5,15.6,71.76,71.76,0,0,1-.93,19q-2.78,15.74-7.86,24.46a53,53,0,0,1-12.45,14.71,41,41,0,0,1-15,8.05,76,76,0,0,1-18.49,3l-44.9.82ZM361.67,61l-9.41,53.63,7.41-.13q9.46-.18,13.84-2.36a18.86,18.86,0,0,0,7.57-7.48q3.18-5.3,5.25-17.08Q389.08,72,385,66.35t-15.8-5.45Z" style="fill:url(#change_5-2)"/><polygon points="316.68 38.78 297.67 136.56 267.43 136.6 286.45 38.78 316.68 38.78" style="fill:url(#change_5-3)"/><path d="M183.87,38.74h44.91q13.28,0,20.75,3.6A26.38,26.38,0,0,1,261,52.69a35.09,35.09,0,0,1,4.69,15.68,71.08,71.08,0,0,1-1.28,18.95q-3,15.68-8.29,24.32a53.07,53.07,0,0,1-12.73,14.48,41,41,0,0,1-15.12,7.77,76.06,76.06,0,0,1-18.53,2.67H164.86Zm25.92,22.15L199.4,114.34h7.41q9.48,0,13.89-2.1a18.89,18.89,0,0,0,7.7-7.34q3.28-5.24,5.57-17,3-15.56-.94-21.29t-15.7-5.74Z" style="fill:url(#change_5-4)"/><path d="M597,120.45H562.63l-7.91,16.14H523.86l55.78-97.82h33l17.75,97.82H598.7Zm-2.16-21.16-4-35.16L573.31,99.29Z" style="fill:url(#change_5-5)"/><path d="M636.05,87.75q4.66-24,20.6-37.3t39.76-13.34q24.42,0,35.08,13.11T737.56,87q-3.33,17.14-11.23,28.12a54.61,54.61,0,0,1-20,17.09q-12.09,6.1-28.37,6.1-16.56,0-26.37-5.27t-14.34-16.68Q632.73,104.9,636.05,87.75Zm30.2.13q-2.88,14.82,1.37,21.29t13.72,6.47a22.54,22.54,0,0,0,16.31-6.34q6.57-6.33,9.77-22.75,2.69-13.81-1.65-20.18T691.89,60A22.34,22.34,0,0,0,676,66.47Q669.15,72.94,666.25,87.88Z" style="fill:url(#change_5-6)"/><path d="M0,84.54s0-.41,0-.41c1.78-.15,10.19-.08,20.32-.9,13.45-.93,28.73-3.68,37-11.36C69.09,61.76,71.12,40.2,71.74,20.46c.17-9.4.29-17.86.39-20,0,0,.12,0,.11,0C72.7,38.34,74.35,58.3,85.56,70.5c9.83,9.52,24.62,11.7,40.22,12.82,9.79.71,18,.79,18.58.81a2.84,2.84,0,0,1,0,.41c-14.81.44-41,.63-53.85,9.58-17.78,10.93-17.84,40.77-18.27,74.28l-.12,0c0-.78-.08-9-.33-19.53-1.15-19.35-1.83-40.56-14.3-52-7.77-7.14-21-10-33.62-11.11S0,84.54,0,84.54Z" style="fill:#fff"/></g></g></svg>'
                    )
                )
            )
        );
    }

    function makeURI() internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{',
                            '"name":"DAOG ID",',
                            '"description":"With DAOG ID, communicate, cooperate and exchange in Web3.",',
                            '"image":"',
                            tokenImage(),
                            '"'
                        '}'
                    )
                )
            )
        );
    }
}