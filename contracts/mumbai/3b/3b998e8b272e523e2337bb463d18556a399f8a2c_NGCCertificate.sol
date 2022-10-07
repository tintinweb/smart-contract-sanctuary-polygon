/**
 *Submitted for verification at polygonscan.com on 2022-10-06
*/

// File: Base64.sol


pragma solidity ^0.8.9;

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

// File: IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: IERC165.sol



pragma solidity ^0.8.9;


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


// File: ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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
// File: IERC721.sol



pragma solidity ^0.8.9;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File: IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
// File: IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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
// File: collections.sol



pragma solidity ^0.8.9;


contract CollectionDescriptor {
    
     constructor () {
     }

    function generateName(uint nr, bool redeemed) public pure returns (string memory) {
        if (redeemed) {
            return string(abi.encodePacked('Redeemed NGC ', 
            substring(toString(nr),0,7),
            '-',
            substring(toString(nr),7,10)
            ));
        }
        return string(abi.encodePacked('NGC ', 
            substring(toString(nr),0,7),
            '-',
            substring(toString(nr),7,10)
        ));
    }

     function generateCert(uint nr) public pure returns (string memory) {
        
        return string(abi.encodePacked(substring(toString(nr),0,7),
        '-',
        substring(toString(nr),7,10)
        ));
    }

    function generateTraits(uint256 tokenId, string memory _coin, string memory _grade, string memory _label) public pure returns (string memory) {
        return string(abi.encodePacked(
            '"attributes": [',
            '{"trait_type": "Coin", "value": "',
            _coin,
            '"},{"trait_type": "Grade", "value": "',
            _grade,
            '"},{"trait_type": "Label", "value": "',
            _label,
            '"},{"trait_type": "Certification Number", "value": "',
            generateCert(tokenId),
            '"}',
            ']'
        ));
    }

    function generateRGB(uint256 tokenId, uint256 hashIndex) public pure returns (uint256) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 fillr = uint256(toUint8(hash,hashIndex))*250/256;
        if (fillr < 100) {fillr = fillr + 100;}
        return fillr;
     }

    function generateOpacity(uint256 tokenId, uint256 hashIndex) public pure returns (uint256) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 fillr = uint256(toUint8(hash,hashIndex))*100/256;
        return fillr;
    }

    function returnRGB(uint256 tokenId,uint256 offset) public pure returns (string memory) {
        return string(
            abi.encodePacked(toString(generateRGB(tokenId,offset+0)), 
                ',', 
                toString(generateRGB(tokenId,offset+1)) , 
                ',', 
                toString(generateRGB(tokenId,offset+2)),
                ',0.',
                toString(generateOpacity(tokenId,offset+1))
            )
        );
    }

    function generateImage(uint256 actualTokenId, string memory _coin, string memory _label, string memory _grade, uint256 _blocknum, uint256 _blocktime) public pure returns (string memory) {
        return string(
            abi.encodePacked('<?xml version="1.0" encoding="UTF-8" standalone="no"?> <svg id="Layer_2" data-name="Layer 2" viewBox="0 0 219.83 324.52" version="1.1" sodipodi:docname="ngc.svg" inkscape:version="1.2.1 (9c6d41e4, 2022-07-14)" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><sodipodi:namedview id="namedview2121" pagecolor="#ffffff" bordercolor="#000000" borderopacity="0.25" inkscape:showpageshadow="2" inkscape:pageopacity="0.0" inkscape:pagecheckerboard="0" inkscape:deskcolor="#d1d1d1" showgrid="false" inkscape:zoom="3.164674" inkscape:cx="85.158851" inkscape:cy="151.5164" inkscape:window-width="1390" inkscape:window-height="1205" inkscape:window-x="668" inkscape:window-y="64" inkscape:window-maximized="0" inkscape:current-layer="Layer_2"/><defs id="defs1888"><style id="style1880">.cls-1{fill:none}.cls-2{clip-path:url(#clippath)}.cls-3{fill:#231f20}.cls-4{fill:#2e3192}.cls-5{clip-path:url(#clippath-1)}</style><clipPath id="clippath"><path class="cls-1" d="M11.41,0H207.72c6.29,0,11.4,5.09,11.41,11.39l.7,301.69c.01,6.31-5.1,11.44-11.41,11.44H11.41c-6.3,0-11.41-5.11-11.41-11.41V11.41C0,5.11,5.11,0,11.41,0Z" id="path1882"/></clipPath><clipPath id="clippath-1"><rect class="cls-1" x="-5" y="-5" width="229.83" height="334.52" id="rect1885"/></clipPath></defs><defs id="defs1899"><linearGradient id="Gradient1" gradientTransform="scale(0.82378954,1.1808421)" x1="226.94662" y1="24.836473" x2="29.162828" y2="244.35886" gradientUnits="userSpaceOnUse"><stop class="stop1" offset="0" id="stop1890" style="stop-color:navy;stop-opacity:1"/><stop class="stop1" offset="0.24279638" id="stop4630" style="stop-color:#d2b7fa;stop-opacity:1"/><stop class="stop1" offset="0.45097825" id="stop4632" style="stop-color:#e2dbe3;stop-opacity:1"/><stop class="stop2" offset="0.7921378" id="stop1892" style="stop-color:#caf;stop-opacity:1"/><stop class="stop3" offset="100%" id="stop1894" style="stop-color:navy;stop-opacity:1"/></linearGradient><style type="text/css" id="style1897">.stop1{stop-color:#a0c0fa}.stop2{stop-color:#a0c0fa;stop-opacity:0}.stop3{stop-color:#f2c28a}</style></defs><rect id="rect1" x="0" y="0" rx="14.620814" ry="14.969906" width="219.31221" height="314.36801" style="fill:url(#Gradient1);fill-opacity:1;stroke-width:.986289"/><text xml:space="preserve" style="font-size:10.6667px;fill:#000" x="16.115406" y="115.96771" id="text6866"><tspan sodipodi:role="line" id="tspan6864" x="16.115406" y="115.96771">Proof of Certification (PoC)</tspan></text><text xml:space="preserve" style="font-style:normal;font-variant:normal;font-weight:700;font-stretch:normal;font-size:8px;font-family:sans-serif;-inkscape-font-specification:sans-serif Bold;fill:#000" x="16.115404" y="125.44737" id="text6970"><tspan sodipodi:role="line" id="tspan6968" x="16.115404" y="125.44737">Cert #',
            generateCert(actualTokenId),
            '</tspan></text><text xml:space="preserve" style="font-style:normal;font-variant:normal;font-weight:400;font-stretch:normal;font-size:8px;font-family:sans-serif;-inkscape-font-specification:sans-serif;fill:#000" x="16.747383" y="160.52205" id="text6974"><tspan sodipodi:role="line" id="tspan6972" x="16.747383" y="160.52205">',
            _coin,
            '</tspan><tspan sodipodi:role="line" x="16.747383" y="170.52205" id="tspan6976">',
            _grade,
            '</tspan><tspan sodipodi:role="line" x="16.747383" y="180.52205" id="tspan6978">',
            _label,
            '</tspan></text><text xml:space="preserve" style="font-style:normal;font-variant:normal;font-weight:400;font-stretch:normal;font-size:6.66667px;font-family:sans-serif;-inkscape-font-specification:sans-serif;fill:#000" x="17.06337" y="206.97235" id="text6982"><tspan sodipodi:role="line" id="tspan6980" x="17.06337" y="206.97235"/><tspan sodipodi:role="line" x="17.06337" y="215.30569" id="tspan6986">Created ',
            toString(_blocknum),
            '</tspan><tspan sodipodi:role="line" x="17.06337" y="223.63902" id="tspan14153">Block #',
            toString(_blocktime),
            '</tspan></text><g id="Layer_1-2" data-name="Layer 1" transform="translate(21.781326,21.905457)"><path class="cls-1" d="M 10.73,2.89 0,30.19 c 0,0 2.73,7.53 10.73,7.25 8,-0.28 10.64,-6.96 10.64,-6.96 z" id="path9293" style="fill:#2e3192"/><path class="cls-1" d="M 36.17,2.89 25.44,30.18 c 0,0 2.73,7.53 10.73,7.25 8,-0.28 10.64,-6.96 10.64,-6.96 z" id="path9295" style="fill:#2e3192"/><path class="cls-1" d="m 10.73,2.89 c 0.47,-0.16 0.93,-0.31 1.4,-0.47 h 7.62 c 0,0 0.1,-2.42 3.73,-2.42 3.63,0 3.8,2.38 3.8,2.38 l 7.86,0.02 c 0,0 0.61,0.16 0.99,0.26 0.38,0.1 -7.11,0.85 -8.66,1.84 -1.55,0.99 -3.86,1.95 -3.88,2.68 -0.02,0.73 0.02,11.48 0.02,11.48 l 0.4,8.02 0.82,9.13 c 0,0 0.68,1.17 1.46,1.63 0.78,0.46 1.48,1.07 2.14,1.17 0.66,0.1 0.92,0.24 2.07,0.52 1.15,0.28 1.46,0.24 1.46,0.24 l 0.12,0.24 H 14.62 c 0.6,-0.09 1.45,-0.25 2.42,-0.56 2.03,-0.65 3.75,-1.2 4.66,-2.65 0.34,-0.53 0.49,-1.91 0.79,-4.67 0.11,-1 0.15,-1.7 0.18,-2.25 0.05,-1.09 0.03,-2.03 0,-2.77 L 22.88,18.69 22.95,7.21 C 21.68,5.83 20.46,5.1 19.59,4.69 18.18,4.02 16.38,3.74 12.84,3.2 11.95,3.07 11.22,2.96 10.73,2.9 Z" id="path9297" style="fill:#2e3192"/></g><g id="Layer_1-2-1" data-name="Layer 1" transform="translate(143.74172,262.20585)"><polygon class="cls-1" points="0,18.74 0,0 3.76,0 12.42,15.02 12.42,0 15.53,0 15.53,18.74 11.95,18.74 2.73,3.39 2.64,18.74 " id="polygon11522" style="fill:#2e3192"/><path class="cls-1" d="m 31.58,16.75 v -5.6 H 27.3 V 8.8 h 7.2 v 10.02 c 0,0 -3.44,0.99 -7.2,0.89 -3.76,-0.09 -7.15,-3.2 -7.15,-3.2 0,0 -2.49,-3.58 -2.4,-7.2 0.09,-3.62 2.45,-6.16 2.45,-6.16 0,0 2.96,-2.87 6.16,-3.06 3.2,-0.19 5.54,0 5.54,0 0,0 2.02,0.33 2.32,0.71 0.29,0.38 0.19,2.84 0.19,2.84 0,0 -2.04,-1.28 -5.88,-1.24 -3.84,0.04 -6.22,2.84 -6.22,2.84 0,0 -1.31,1.34 -1.38,3.73 -0.08,2.38 0.92,4.88 0.92,4.88 0,0 2.33,3 4.28,3.15 1.95,0.15 5.44,0.15 5.44,0.15 l 0.02,-0.39 z" id="path11524" style="fill:#2e3192"/><path class="cls-1" d="m 52.51,0.93 c 0,0 -1.63,-1.38 -6.02,-0.78 -4.39,0.6 -7.07,3.35 -7.07,3.35 0,0 -2.08,2.96 -2.08,5.44 0,2.48 0.65,6.28 3.13,8.19 2.48,1.91 2.87,2.01 4.46,2.36 1.59,0.35 7.2,0.42 7.59,-0.64 v -2.44 c 0,0 -4.53,1.32 -6.48,0.7 -1.95,-0.62 -5.09,-2.58 -5.5,-5.8 -0.41,-3.22 1.18,-6.74 3.13,-7.63 1.95,-0.89 4.61,-1.91 8.6,-0.29" id="path11526" style="fill:#2e3192"/></g></svg>'
            )
        );
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

        // from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
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

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}

// File: Context.sol


pragma solidity ^0.8.9;

 abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: Address.sol



pragma solidity ^0.8.9;


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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: Strings.sol



pragma solidity ^0.8.9;

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}
// File: ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * This is an internal function that does not check if the sender is authorized to operate on the token.
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
        delete _tokenApprovals[tokenId];

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
        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// File: ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
// File: ngc.sol



pragma solidity ^0.8.9;

/**
 * @dev String operations.
 */








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */

interface Authenticator {
    function authenticate(string memory tokenid, bytes32 data) external view returns(bool);
}

contract NGCCertificate is ERC721Enumerable {
    using Strings for uint256;

    address public owner; // for opensea integration. doesn't do anything else.
    mapping (address => bool) private isAdminAcct;
    bool private useArweave;
    string public ArweaveBase;

    address public collector; // address authorised to withdraw funds recipient
    address payable public recipient; // in this instance, it will be a mirror split on mainnet (to be deployed)

    modifier onlyOwner() {
        require(owner == _msgSender(), "Caller != owner.");
        _;
    }

    CollectionDescriptor public descriptor;
    Authenticator authenticator;
 

    mapping (uint => uint) public tokenIdHash;

    struct TokenMetaData {
        uint hash;
        bool redeemed;
        string coin;
        string grade;
        string label;
        uint256 blocknum;
        uint256 blocktime;

    }

    mapping (uint => TokenMetaData) public tokenmetadata;
    mapping (string => uint) public tokenIDLookupBySerial;

    uint public currentIndex = 1;


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, uint256 tokenid) ERC721(name_, symbol_) {
        owner = msg.sender;
        collector = address(msg.sender); 
        recipient = payable(msg.sender);
        descriptor = new CollectionDescriptor();
        //start admin wallet as owner
        isAdminAcct[owner] = true;
        useArweave = false;
        ArweaveBase = "https://qhh2so623wnxokkxkebnw6j3iyksmsx5ht4bpjnknzmes5fzlwxa.arweave.net/gc-pO9rdm3cpV1EC23k7RhUmSv08-Belqm5YSXS5Xa4/";

        // mint first claim UF. It's a known address in the merkle tree to populate NFT marketplaces before launch
        _createNFT(owner,'04:79:96:BA:75:74:81',tokenid,'2016 Eagle S$1','MS 69','ANA 125th Label');
    }


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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory name = descriptor.generateName(tokenId,tokenmetadata[tokenId].redeemed); 
        string memory description = "test nft";

        string memory image = generateBase64Image(tokenId);
        string memory attributes = generateTraits(tokenId);

        if (useArweave) {
             return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            ArweaveBase, 
                            toString(tokenId),'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
        }
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }
    

    function setAuthenticator(address _authenticator) external onlyOwner {
        authenticator = Authenticator(_authenticator);

    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(descriptor.generateImage(tokenId,tokenmetadata[tokenId].coin,tokenmetadata[tokenId].label,tokenmetadata[tokenId].grade,tokenmetadata[tokenId].blocknum,tokenmetadata[tokenId].blocktime));
        return Base64.encode(img);
        //return descriptor.generateImage(tokenIdHash[tokenId]);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(tokenId,tokenmetadata[tokenId].coin,tokenmetadata[tokenId].label,tokenmetadata[tokenId].grade,tokenmetadata[tokenId].blocknum,tokenmetadata[tokenId].blocktime);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(tokenId,tokenmetadata[tokenId].coin,tokenmetadata[tokenId].grade,tokenmetadata[tokenId].label);
    }

    function airDrop(address[] memory _airdropWallets, uint256[] memory _tokenid) public {
        require(isAdminAcct[_msgSender()], "You don't have proper access");
        for (uint256 i = 0; i < _airdropWallets.length; i++) {
            _mint(_airdropWallets[i],_tokenid[i]);
        }
    }

    function getTokenIdsByOwner(address _tokensOwner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_tokensOwner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }
        else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMints = totalSupply();
            uint256 resultIndex = 0;
            for (uint256 tid = 1; tid < totalMints+1; tid++)
                if (ownerOf(tid) == _tokensOwner) {
                    result[resultIndex] = tid;
                    resultIndex++;
                }
            return result;
        }
    }

    function updateAdmin(address _newAdmin, bool status) external onlyOwner {
        isAdminAcct[_newAdmin] = status;
    }

    function authenticate(string memory serialid, bytes32 data) external view returns(bool) {
        return authenticator.authenticate(serialid,data);
    }

    function updateArweaveBase(string memory _newBaseURI) public  {
        require(isAdminAcct[_msgSender()], "You don't have proper access");
        ArweaveBase = _newBaseURI;
    }

    function setArWeave(bool _usearweave) public {
        require(isAdminAcct[_msgSender()], "You don't have proper access");
        useArweave = _usearweave;
    }

    // internal mint
    function _mint(address _owner, string memory _serial, uint256 tokenid, string memory ngctype, string memory grade, string memory variety) internal {
        _createNFT(_owner,_serial,tokenid,ngctype,grade,variety);
    }

    function redeemTokens(uint[] memory _redeemTokens) public {
        require(isAdminAcct[_msgSender()], "You don't have proper access");
        for (uint256 i = 0; i < _redeemTokens.length; i++) {
            tokenmetadata[i].redeemed = true;
        }
    }

 function getARweaveURI(uint256 tokenId) public view returns(string memory){
         return string(
            abi.encodePacked(ArweaveBase,toString(tokenId))
         );
    }

    function lookupTokenIDbySerial(string memory _serial) public view returns(uint){
        require(isAdminAcct[_msgSender()], "You don't have proper access");
         return tokenIDLookupBySerial[_serial];
    }

    function updateTraits(uint256 tokenId, string memory _coin, string memory _grade, string memory _label) external onlyOwner {
        tokenmetadata[tokenId].coin = _coin;
        tokenmetadata[tokenId].grade = _grade;
        tokenmetadata[tokenId].label = _label;
    }

    function adminMint(address _owner, uint256 _tokenid, string memory _serial, string memory _coin, string memory _grade, string memory _label) public {
        require(isAdminAcct[_msgSender()], "You don't have proper access");
         _createNFT(_owner,_serial,_tokenid,_coin,_grade,_label);
    }

    function _createNFT(address _owner, string memory _serial, uint256 _tokenid, string memory _coin, string memory _grade, string memory _label) internal {
        uint256 tokenId = _tokenid;
        tokenIDLookupBySerial[_serial] = _tokenid;
        uint256 tokenHash = uint(keccak256(abi.encodePacked(block.timestamp, _owner, tokenId)));
        tokenIdHash[tokenId] = tokenHash;
        tokenmetadata[tokenId].hash = tokenHash;
        tokenmetadata[tokenId].coin = _coin;
        tokenmetadata[tokenId].grade = _grade;
        tokenmetadata[tokenId].label = _label;
        tokenmetadata[tokenId].blocknum = block.number;
        tokenmetadata[tokenId].blocktime = block.timestamp;
        currentIndex += 1;
        super._mint(_owner, tokenId);
    }

}