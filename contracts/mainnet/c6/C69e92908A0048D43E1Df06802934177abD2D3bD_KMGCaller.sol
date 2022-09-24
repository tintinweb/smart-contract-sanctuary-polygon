/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// File: @openzeppelin/contracts/utils/Base64.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/TeamAccess.sol

pragma solidity ^0.8.9;



contract TeamsAccess is Ownable {
   event SetAccess(address member, bool enable);
 
   mapping(address => bool) private teamMember;

   modifier onlyTeam() {
   require(teamMember[msg.sender], "Caller is not the Team");
   _;
   }

   //add team user
   function setAccess(address member ,bool enable) public onlyOwner {
      teamMember[member] = enable;
      emit SetAccess(member, enable);
   }

}


// File: contracts/MetaWrite.sol

pragma solidity ^0.8.16;

// 参照先のコントラクトをimport




//import "./Data.sol";
//import './Mikudashi_normal.sol';

interface KMGInterface {
  function setTokenMeta(uint256 tokenId, uint256 keyId, bytes[] memory values) external;
}

contract KMGCaller is Ownable, TeamsAccess {
    using Strings for uint256;
    KMGInterface KMGContract;

    struct attributes{
        bytes[] trait_value;
    }

    enum KeyId {
        name,
        description,
        image,
        animation_url,
        external_url,
        background_color,
        youtube_url,
        trait_type,
        trait_value,
        trait_display
   }

   string public imgURI;

    bytes[] trait_type = [bytes("EFFECT"),bytes("BACKGROUND"),bytes("HAIR"),bytes("BODY"),bytes("CLOTHES"),bytes("MOUTH"),bytes("EYEBROW"),bytes("EYES"),bytes("TEXT"),bytes("FACE PAINT"),bytes("RANK")];
    bytes[] trait_display;
    
    /*string[] rank;
    string[] eyes;
    string[] hair;
    string[] text;
    string[] eyebrow;
    string[] mouth;
    string[] clothes;
    string[] body;
    string[] background;
    string[] image;*/

    mapping(uint256 => string) private rank;
    mapping(uint256 => string) private eyes;
    mapping(uint256 => string) private hair;
    mapping(uint256 => string) private text;
    mapping(uint256 => string) private eyebrow;
    mapping(uint256 => string) private mouth;
    mapping(uint256 => string) private clothes;
    mapping(uint256 => string) private body;
    mapping(uint256 => string) private background;
    mapping(uint256 => string) private effect;
    mapping(uint256 => string) private paint;
    mapping(uint256 => string) private image;


   mapping(uint256 => attributes) _Attributes;  // token

    constructor(address _kmgAddr) {
        require(_kmgAddr != address(0));
        setAccess(_msgSender(), true);
        KMGContract = KMGInterface(_kmgAddr);
    }
    
    function kmg_SetContract(address _addr) public onlyOwner{
        KMGContract = KMGInterface(_addr);
    }

    function kmg_SetMetaAttributes(uint256 startId, uint256 count) public onlyTeam {
        uint256 _tokenId = startId;
        bytes[] memory attr = new bytes[](11);
        bytes[] memory img = new bytes[](1);
        for (uint256 i = 0; i < count; i++) {
            uint256 _id = _tokenId + i;
            uint256 _metaId = _tokenId + i - 1;
            attr[0] = bytes(effect[_metaId]);
            attr[1] = bytes(background[_metaId]);
            attr[2] = bytes(hair[_metaId]);
            attr[3] = bytes(body[_metaId]);
            attr[4] = bytes(clothes[_metaId]);
            attr[5] = bytes(mouth[_metaId]);
            attr[6] = bytes(eyebrow[_metaId]);
            attr[7] = bytes(eyes[_metaId]);
            attr[8] = bytes(text[_metaId]);
            attr[9] = bytes(paint[_metaId]);
            attr[10] = bytes(rank[_metaId]);
            img[0]  = bytes(image[_metaId]);
            KMGContract.setTokenMeta(_id, uint256(KeyId.trait_type), trait_type);
            KMGContract.setTokenMeta(_id, uint256(KeyId.trait_value), attr);
            KMGContract.setTokenMeta(_id, uint256(KeyId.image), img);
        }
    }

    function getTokenPropertyArray(uint256 _tokenId) public view virtual returns (string[] memory)
    {
        string[] memory attr = new string[](12);
        uint256 _metaId = _tokenId - 1;
        attr[0] = effect[_metaId];
        attr[1] = background[_metaId];
        attr[2] = hair[_metaId];
        attr[3] = body[_metaId];
        attr[4] = clothes[_metaId];
        attr[5] = mouth[_metaId];
        attr[6] = eyebrow[_metaId];
        attr[7] = eyes[_metaId];
        attr[8] = text[_metaId];
        attr[9] = paint[_metaId];
        attr[10] = rank[_metaId];
        attr[11]  = image[_metaId];
        return (attr);
    }

    function kmg_SetTraitType(bytes[] memory _trait_type) public onlyTeam {
        trait_type = _trait_type;
    }

    function kmg_SetTraitDisplay(bytes[] memory _trait_display) public onlyTeam {
        trait_display = _trait_display;
    }

    function kmg_SetRank(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            rank[_metaId] = _value[i];
        }
    }
    
    function kmg_SetBackground(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            background[_metaId] = _value[i];
        }
    }
    
    function kmg_SetHair(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            hair[_metaId] = _value[i];
        }
    }

    function kmg_SetBody(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            body[_metaId] = _value[i];
        }
    }
    
    function kmg_SetClothes(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            clothes[_metaId] = _value[i];
        }
    }
    
    function kmg_SetMouth(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            mouth[_metaId] = _value[i];
        }
    }
    
    function kmg_SetEyebrow(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            eyebrow[_metaId] = _value[i];
        }
    }
    
    function kmg_SetEyes(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            eyes[_metaId] = _value[i];
        }
    }
    
    function kmg_SetText(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            text[_metaId] = _value[i];
        }
    }

    function kmg_SetEffect(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            effect[_metaId] = _value[i];
        }
    }

    function kmg_SetPaint(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            paint[_metaId] = _value[i];
        }
    }
    
    function kmg_SetArweaveAddr(string memory _imgURI)public onlyTeam{
        imgURI = _imgURI;
    }

    function kmg_SetImage(uint256 start_tokenId , string[] memory _value) public onlyTeam {
        for (uint256 i = 0; i < _value.length; i++) {
            uint256 _metaId = start_tokenId + i - 1;
            image[_metaId] = _value[i];
        }
    }

    function kmg_SetImageURI(uint256 start_tokenId , uint256 count) public onlyTeam {
        for (uint256 i = 0; i <= count; i++) {
            uint256 _tokenId = start_tokenId + i;
            uint256 _metaId = start_tokenId + i - 1;
            image[_metaId] = string(abi.encodePacked(imgURI, _tokenId.toString(), ".png"));
        }
    }
    
}