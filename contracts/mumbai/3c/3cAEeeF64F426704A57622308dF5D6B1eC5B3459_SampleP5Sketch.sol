// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721HtmlBased.sol";

contract SampleP5Sketch is ERC721HtmlBased, Ownable
{
  bytes32 constant KEY_FRONTCOLOR = "frontColor";
  bytes32 constant KEY_BACKCOLOR = "backColor";
  bytes32 constant KEY_RADIUS = "radius";

  using Counters for Counters.Counter;  

  Counters.Counter private _tokenIdCounter; 

  constructor() ERC721HtmlBased("P5Sketch", "P5S", "https://ipfs.io/ipfs/QmZBApzAghjsTxcS6UuPGqXNd6thuqkbWUrY5bhJJFQtWa/"){
    mint("white", "black", "30");
    mint("red", "pink", "60");
    mint("blue", "yellow", "100");
    mint("green", "lime", "130");
  } 

  function mint(string memory frontColor, string memory backColor, string memory radius) public onlyOwner {

        uint256 tokenId = _tokenIdCounter.current(); 
        _tokenIdCounter.increment(); 
        _safeMint(_msgSender(), tokenId);
        _setValue(tokenId, KEY_FRONTCOLOR, abi.encode(frontColor));
        _setValue(tokenId, KEY_BACKCOLOR, abi.encode(backColor));
        _setValue(tokenId, KEY_RADIUS, abi.encode(radius));
  }
 
  function tokenName(uint256 tokenId) internal view override returns (string memory){
      return string(abi.encodePacked(name(), ' #', Strings.toString(tokenId)));
  }

  function tokenDescription(uint256 tokenId) internal pure override returns (string memory){
      tokenId;
      return contractDescription();
  }

  function tokenImageURI(uint256 tokenId) internal view override returns (string memory){   
      return "";
      /*  string memory backColor = string(_getValue(tokenId, KEY_BACKCOLOR));
        string memory frontColor = string(_getValue(tokenId, KEY_FRONTCOLOR));
        string memory radius = string(_getValue(tokenId, KEY_RADIUS));
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(string(abi.encodePacked(
            '<svg height="350" width="350"><rect height="100%" width="100%" fill="', backColor, 
            '"/><circle cx="33%" cy="33%" r="', radius, '" stroke="', backColor, '" stroke-width="1" fill="', frontColor,
             '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 175 175" to="360 175 175" dur="2s" repeatCount="indefinite"/></circle> SVG not supported. </svg>'
        ))))));*/
  }

  function tokenProperties(uint256 tokenId) internal view override returns (string[] memory trait_type, string[] memory trait_value, string[] memory trait_display){   
      trait_type = new string[](3);
      trait_value = new string[](3);
      trait_display = new string[](3);
      trait_type[0] = 'Front Color'; trait_value[0] = string(abi.decode(_getValue(tokenId, KEY_FRONTCOLOR), (string)));
      trait_type[1] = 'Background Color'; trait_value[1] = string(abi.decode(_getValue(tokenId, KEY_BACKCOLOR), (string)));
      trait_type[2] = 'Radius'; trait_value[2] = string(abi.decode(_getValue(tokenId, KEY_RADIUS), (string)));
  }


  function contractName() internal view override returns (string memory){
      return name();
  }
  
  function contractDescription() internal pure override returns (string memory){
      return "HTML/JS-based on-chain metadata sample project";
  }

  function contractImageURI() internal pure override returns (string memory){
      return "";
      /* return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(string(abi.encodePacked(
            '<svg height="350" width="350"><rect height="100%" width="100%" fill="', 'black', 
            '"/><circle cx="33%" cy="33%" r="', '50', '" stroke="', 'black', '" stroke-width="1" fill="', 'white',
             '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 175 175" to="360 175 175" dur="2s" repeatCount="indefinite"/></circle> SVG not supported. </svg>'
        ))))));*/
  }

  function contractExternalURL() internal pure override returns (string memory){
      return "https://github.com/DanielAbalde/HtmlBasedNFT";
  }

  function contractSellerFee() internal pure override returns (uint256){
      return 200;
  }

  function contractFeeRecipient() internal view override returns (address){
      return owner();
  }

    function withdrawBalance(uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        // https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
* @title On-Chain NFT Metadata
* @author Daniel Gonzalez Abalde
* @dev Utility library to create NFT contracts with on-chain or dynamic metadata.
 */
library OnChainMetadata
{     
    /**
    * @dev TokenURI builder using on-chain data.
    * @param name of the token.
    * @param description of the token.
    * @param image URI of the token.
    */
    function tokenURI(string memory name, string memory description, string memory image) public pure returns (string memory){
        string[] memory trait_type = new string[](0);
        string[] memory trait_value = new string[](0);
        string[] memory trait_display = new string[](0);
        return tokenURI(name, description, image, '', '', trait_type, trait_value, trait_display, '', '');
    }
    
    /**
    * @dev TokenURI builder using on-chain data.
    * @param name of the token.
    * @param description of the token.
    * @param image URI of the token.
    * @param animation_url to a multi-media attachment.
    * @param external_url to view the token in the official site.
    */
    function tokenURI(string memory name, string memory description, string memory image, string memory animation_url, string memory external_url) public pure returns (string memory){
        string[] memory trait_type = new string[](0);
        string[] memory trait_value = new string[](0);
        string[] memory trait_display = new string[](0);
        return tokenURI(name, description, image, animation_url, external_url, trait_type, trait_value, trait_display, '', '');
    }
    
    /**
    * @dev TokenURI builder using on-chain data.
    * @param name of the token.
    * @param description of the token.
    * @param image URI of the token.
    * @param animation_url to a multi-media attachment.
    * @param external_url to view the token in the official site.
    * @param trait_type array, the name of the traits.
    * @param trait_value array, the value of the traits.
    * @param trait_display array, the type of the traits.
    */
    function tokenURI(string memory name, string memory description, string memory image, string memory animation_url, string memory external_url, string[] memory trait_type, string[] memory trait_value, string[] memory trait_display) public pure returns (string memory){
        return tokenURI(name, description, image, animation_url, external_url, trait_type, trait_value, trait_display, '', '');
    }

    /**
    * @dev TokenURI builder using on-chain data.
    * @param name of the token.
    * @param description of the token.
    * @param image URI of the token.
    * @param animation_url to a multi-media attachment.
    * @param external_url to view the token in the official site.
    * @param trait_type array, the name of the traits.
    * @param trait_value array, the value of the traits.
    * @param trait_display array, the type of the traits.
    * @param background_color of the token. For OpenSea must be a six-character hexadecimal without a pre-pended #
    * @param youtube_url to a YouTube video.
    */
    function tokenURI(string memory name, string memory description, string memory image, string memory animation_url, string memory external_url,
     string[] memory trait_type, string[] memory trait_value, string[] memory trait_display,
     string memory background_color, string memory youtube_url) public pure returns (string memory){
        require(trait_type.length == trait_value.length, "trait_type.length and trait_value.length must be equal");
        bytes memory attributes;
        if(trait_type.length > 0){
            attributes = '[';
            for(uint256 i=0; i<trait_type.length; i++){
                attributes = abi.encodePacked(attributes, i > 0 ? ',' : '', '{',
                bytes(trait_display[i]).length > 0 ? string(abi.encodePacked('"display_type": "' , trait_display[i], '",')) : '', 
                '"trait_type": "' , trait_type[i], '", "value": "' , trait_value[i], '"}');
            }
            attributes = abi.encodePacked(attributes, ']');
        } 
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{',
                '"name": "', name, '", ',
                '"description": "', description, '", ',
                '"image": "', image, '"',
                bytes(animation_url).length > 0 ? string(abi.encodePacked(', "animation_url": "', animation_url, '"')) : '',
                bytes(external_url).length > 0 ? string(abi.encodePacked(', "external_url": "', external_url, '"')) : '',
                bytes(attributes).length > 0 ? string(abi.encodePacked(', "attributes": ', attributes)) : '',
                bytes(background_color).length > 0 ? string(abi.encodePacked(', "background_color": ', background_color)) : '',
                bytes(youtube_url).length > 0 ? string(abi.encodePacked(', "youtube_url": ', youtube_url)) : '',
            '}'
            ))
        ));
    }
 
    /**
    * @dev Contract metadata builder for OpenSea.
    * @notice https://docs.opensea.io/docs/contract-level-metadata
    * @param name of the contract.
    * @param description of the contract.
    * @param imageURI of the contract.
    * @param external_link or official site.
    * @param sellerFeeBasisPoints, 100 indicates 1% seller fee.
    * @param feeRecipent, where seller fees will be paid to.
    */
    function contractURI(string memory name, string memory description, string memory imageURI, string memory external_link, uint256 sellerFeeBasisPoints, address feeRecipent) public pure returns (string memory) {
      return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
          '{',
              '"name": "', name, '"',
              ', "description": "', description, '"', 
              bytes(imageURI).length > 0 ? string(abi.encodePacked(', "image": "', imageURI, '"')) : '',
              bytes(external_link).length > 0 ? string(abi.encodePacked(', "external_link": "', external_link, '"')) : '',
              ', "seller_fee_basis_points": ', Strings.toString(sellerFeeBasisPoints), 
              ', "fee_recipient": "', Strings.toHexString(uint256(uint160(feeRecipent)), 20), '"',
          '}'
      ))));
    }

    /**
    * @dev HTML URL builder with parameters
    * @param baseURL of the webpage.
    * @param keys array of the parameter names.
    * @param values array of the parameter values.
    */
    function parametriceURL(string memory baseURL, string[] memory keys, string[] memory values) public pure returns(string memory){
        require(keys.length == values.length, "keys.length and values.length must be equal");
        if(keys.length == 0){
            return baseURL;
        }
        bytes memory parameters;
        for(uint256 i=0; i<keys.length; i++){
            if(bytes(keys[i]).length > 0){
                parameters = abi.encodePacked(parameters, i > 0 ? '&' : '', keys[i], '=', values[i]);
            } 
        }
        bytes memory baseURIbytes = bytes(baseURL);
        string memory separator = baseURIbytes[baseURIbytes.length - 1] != bytes1('/') ? '/' : '';
        return string(abi.encodePacked(baseURL, separator, '?', parameters));
    }
 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
  
/**
 * @title On-chain per token NFT metadata 
 * @dev Use this standard for on-chain and/or dynamic metadata
 * @notice 
 */
abstract contract NFTOnChainTokenMetadata 
{
    /**
     * @dev Returns the token name.
     */
    function tokenName(uint256 tokenId) internal virtual view returns (string memory);

    /**
     * @dev Returns the token description.
     */
    function tokenDescription(uint256 tokenId) internal virtual view returns (string memory);

    /**
     * @dev Returns the token image URI.
     */
    function tokenImageURI(uint256 tokenId) internal virtual view returns (string memory);

    /**
     * @dev Returns the token external URL, the official site to view the token.
     */
    function tokenExternalURL(uint256 tokenId) internal virtual view returns (string memory);

    /**
     * @dev Returns the token animation URL, for sites like OpenSea or Nftify to attach multi-media items (GLB, MP4, HTML...).
     */
    function tokenAnimationURL(uint256 tokenId) internal virtual view returns (string memory);

    /**
     * @dev Returns the token properties, the attributes to describe the details of the token.
     */
    function tokenProperties(uint256 tokenId) internal virtual view returns (string[] memory trait_type, string[] memory trait_value, string[] memory trait_display); 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
  
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension per token 
 * @dev Use this standard for on-chain and/or dynamic metadata
 * @notice 
 */
abstract contract NFTOnChainContractMetadata 
{
    /**
     * @dev Returns the token name.
     */
    function contractName() internal virtual view returns (string memory);

    /**
     * @dev Returns the token description.
     */
    function contractDescription() internal virtual view returns (string memory);

    /**
     * @dev Returns the token image URI.
     */
    function contractImageURI() internal virtual view returns (string memory);

    /**
     * @dev Returns the token external URL, the official site to view the token.
     */
    function contractExternalURL() internal virtual view returns (string memory);

    /**
     * @dev Returns the token animation URL, for sites like OpenSea or Nftify to attach multi-media items (GLB, MP4, HTML...).
     */
    function contractSellerFee() internal virtual view returns (uint256);

    /**
     * @dev Returns the token properties, the attributes to describe the details of the token.
     */
    function contractFeeRecipient() internal virtual view returns (address); 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
import "./OnChainMetadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./NFTOnChainTokenMetadata.sol";
import "./NFTOnChainContractMetadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721HtmlBased is ERC721, NFTOnChainTokenMetadata, NFTOnChainContractMetadata
{
  string internal _baseURL;
  mapping(uint256 => bytes32[]) internal _keys;
  mapping(uint256 => bytes[]) internal _values;

  constructor(string memory name, string memory symbol, string memory baseURL) ERC721(name, symbol){
    _baseURL = baseURL;
  }

  function _indexOfKey(uint256 tokenId, bytes32 key) internal view returns (uint256){
    bytes32[] memory keysBytes = _keys[tokenId];
    for (uint256 i = 0; i < keysBytes.length; i++) {
      if(keysBytes[i] == key){
        return i + 1;
      }
    }
    return 0;
  }
  function _getValue(uint256 tokenId, bytes32 key) internal view returns (bytes memory){
    uint256 index = _indexOfKey(tokenId, key);
    require(index > 0, "key not found"); 
    return _values[tokenId][index - 1];
  }
  function _setValue(uint256 tokenId, bytes32 key, bytes memory value) internal {
    uint256 index = _indexOfKey(tokenId, key);
    if(index == 0){
      _keys[tokenId].push(key);
      _values[tokenId].push(value);
    }else{
      _values[tokenId][index - 1] = value;
    } 
  }

  
  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory)
  {
      require(_exists(tokenId), "tokenId doesn't exist");
      (string[] memory trait_type, string[] memory trait_value, string[] memory trait_display) = tokenProperties(tokenId);
      return OnChainMetadata.tokenURI(tokenName(tokenId), tokenDescription(tokenId), tokenImageURI(tokenId), tokenAnimationURL(tokenId), tokenExternalURL(tokenId), trait_type, trait_value, trait_display);
  }
 
   function contractURI() public view virtual returns (string memory) {
        return OnChainMetadata.contractURI(contractName(), contractDescription(), contractImageURI(), contractExternalURL(), contractSellerFee(), contractFeeRecipient());
  }

  function tokenExternalURL(uint256 tokenId) internal view virtual override returns (string memory){ 
    return tokenAnimationURL(tokenId);
  }
 
  function tokenAnimationURL(uint256 tokenId) internal view virtual override returns (string memory){
    return "";
    bytes32[] memory keysBytes32 = _keys[tokenId];
    bytes[] memory valuesBytes = _values[tokenId];
    string[] memory keys = new string[](keysBytes32.length);
    string[] memory values = new string[](keysBytes32.length);
    for (uint256 i = 0; i < keysBytes32.length; i++) { 
        keys[i] = string(abi.encode(keysBytes32[i]));
        values[i] = string(abi.decode(valuesBytes[i], (string)));
    }
    return OnChainMetadata.parametriceURL(_baseURL, keys, values);
  }
 /*
 function TESTTokenAnimationURL(uint256 tokenId) public view returns(string memory){
     bytes32[] memory keysBytes32 = _keys[tokenId];
    bytes[] memory valuesBytes = _values[tokenId];
    string[] memory keys = new string[](keysBytes32.length);
    string[] memory values = new string[](keysBytes32.length);
    for (uint256 i = 0; i < keysBytes32.length; i++) { 
        keys[i] = string(abi.encode(keysBytes32[i]));
        values[i] = string(abi.decode(_getValue(tokenId, keysBytes32[i]), (string)));
    }
    bytes memory p;
    p = abi.encodePacked(p, 0 > 0 ? '&' : '', keys[0], '=', values[0]);
    p = abi.encodePacked(p, 1 > 0 ? '&' : '', keys[1], '=', values[1]);
    p = abi.encodePacked(p, 2 > 0 ? '&' : '', keys[2], '=', values[2]);
    string memory baseURL = "https://ipfs.io/ipfs/QmZBApzAghjsTxcS6UuPGqXNd6thuqkbWUrY5bhJJFQtWa";
    bytes memory baseURIbytes = bytes(baseURL);
    string memory separator = baseURIbytes[baseURIbytes.length - 1] != bytes1('/') ? '/' : '';
    return string(abi.encodePacked('data:application/json;base64,',
    Base64.encode(abi.encodePacked(baseURL, separator, '?', p))));
 }*/
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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