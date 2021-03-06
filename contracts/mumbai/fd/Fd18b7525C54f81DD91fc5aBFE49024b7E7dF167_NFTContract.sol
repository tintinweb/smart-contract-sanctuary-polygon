// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ERC721Buyable.sol";
import "./CDBCoin.sol";


contract NFTContract is ERC721Buyable {

    using Strings for uint;
    using Counters for Counters.Counter;


    Counters.Counter private supply;    
    CDBCoin TokenP2E; 


    mapping(uint256 => string) public name;
    mapping(uint256 => string) public img_data;

    constructor(CDBCoin _Token) ERC721("NFTContract", "NFTC") {
        TokenP2E = _Token;
    }

    // function mint(string memory _design) external payable returns(uint) {
    //     require(supply.current() < 100000, "Max supply exceeded");
    //     if(keccak256(abi.encodePacked((_design))) == keccak256(abi.encodePacked(("bronze")))){
    //         require(msg.value >= 10 ether);
    //     } else if(keccak256(abi.encodePacked((_design))) == keccak256(abi.encodePacked(("argent")))){
    //         require(msg.value >= 20 ether);
    //     } else if(keccak256(abi.encodePacked((_design))) == keccak256(abi.encodePacked(("or")))){
    //         require(msg.value >= 35 ether);
    //     } else if(keccak256(abi.encodePacked((_design))) == keccak256(abi.encodePacked(("diamond")))){
    //         require(msg.value >= 70 ether);
    //     }    
        
    //     supply.increment();        

    //     name[supply.current()] = (string(abi.encodePacked("AUBAY NFT - ", _design, " #", supply.current().toString())));
        
    //     img_data[supply.current()] = getSvg(_design);

    //     _safeMint(msg.sender, supply.current());

    //     return supply.current();
    // }

    function mint(string memory _design) external returns(uint) {
        require(supply.current() < 100000, "Max supply exceeded");
        uint amount; 
        if(keccak256(abi.encodePacked((_design))) == keccak256(abi.encodePacked(("bronze")))){
            require(TokenP2E.balanceOf(msg.sender) >= 10 ether);
            amount = 10 ether; 
        } else if(keccak256(abi.encodePacked((_design))) == keccak256(abi.encodePacked(("argent")))){
            require(TokenP2E.balanceOf(msg.sender) >= 20 ether);
            amount = 20 ether;
        } else if(keccak256(abi.encodePacked((_design))) == keccak256(abi.encodePacked(("or")))){
            require(TokenP2E.balanceOf(msg.sender) >= 35 ether);
            amount = 35 ether;
        } else if(keccak256(abi.encodePacked((_design))) == keccak256(abi.encodePacked(("diamant")))){
            require(TokenP2E.balanceOf(msg.sender) >= 70 ether);
            amount = 70 ether;
        }  
        
        supply.increment();        

        name[supply.current()] = (string(abi.encodePacked("AUBAY NFT - ", _design, " #", supply.current().toString())));
        
        img_data[supply.current()] = getSvg(_design);

        bool success = TokenP2E.transferFrom(msg.sender, address(this), amount);

        _safeMint(msg.sender, supply.current());

        return supply.current();
    }

    function totalSupply() public view returns (uint) {
        return supply.current();
    }

    function burn(uint _tokenId) external onlyTokenOwner(_tokenId) {
        _burn(_tokenId);
    }
    
    

    function getSvg(string memory _tokenId) private pure returns (string memory) {
        string memory base = "data:image/svg+xml;base64,";
        if (keccak256(abi.encodePacked((_tokenId))) == keccak256(abi.encodePacked(("bronze")))) {
            string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked('<svg width="200" viewBox="0 0 108 124" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="#C49C48" d="M.5.5h107v123H.5z"/><path fill="#D4B77B" stroke="#000" d="M10.5 10.5h87v103h-87z"/><path fill="#fff" stroke="#000" d="M14.5 14.5h79v95h-79z"/><path stroke="#000" d="m10.354 10.646 4 4m83-4.292-4 4m-82.708 99.292 4-4m78.708 0 4 4"/><path d="M72.844 80.697a2.8 2.8 0 0 0-2.801-2.801H37.957a2.8 2.8 0 0 0-2.8 2.8 2.8 2.8 0 0 0 2.8 2.801h32.086c1.548 0 2.8-1.257 2.8-2.8ZM32.33 58.027c.046 0 .087 0 .133-.006l4.44 16.071h34.194l4.44-16.07c.046 0 .087.004.133.004a3.332 3.332 0 0 0 0-6.66 3.332 3.332 0 0 0-3.168 4.353l-8.03 4.695-8.631-14.309a3.335 3.335 0 0 0 1.492-2.775 3.332 3.332 0 0 0-3.33-3.33 3.332 3.332 0 0 0-3.33 3.33c0 1.161.59 2.18 1.491 2.776l-8.631 14.308-8.03-4.695c.102-.32.163-.667.163-1.023a3.333 3.333 0 0 0-6.666 0 3.331 3.331 0 0 0 3.33 3.33Z" fill="#D4B77B"/><path stroke="#000" d="M.5.5h107v123H.5z"/></svg>'))));
            return string(abi.encodePacked(base, svgBase64Encoded));
        } else if (keccak256(abi.encodePacked((_tokenId))) == keccak256(abi.encodePacked(("argent")))) {
            string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked('<svg width="200" viewBox="0 0 108 124" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="#DCDCDC" d="M.5.5h107v123H.5z"/><path fill="#F0F0F0" stroke="#000" d="M10.5 10.5h87v103h-87z"/><path fill="#fff" stroke="#000" d="M14.5 14.5h79v95h-79z"/><path stroke="#000" d="m10.354 10.646 4 4m83-4.292-4 4m-82.708 99.292 4-4m78.708 0 4 4"/><path d="M77.007 76.412c-4.53 3.78-15.07 5.471-23.508 5.471-8.436 0-18.976-1.69-23.506-5.47a2.29 2.29 0 0 0-2.933 3.516c4.83 4.03 14.962 6.533 26.44 6.533 11.478 0 21.61-2.504 26.44-6.534a2.29 2.29 0 0 0-2.933-3.516Z" fill="#DCDCDC"/><path d="M81.222 51.401a1.527 1.527 0 0 0-1.69.13c-.04.031-3.998 3.089-9.006 3.089-6.501 0-11.75-5.082-15.601-15.103a1.525 1.525 0 0 0-2.85 0c-3.85 10.021-9.1 15.103-15.601 15.103-4.972 0-8.969-3.06-9.005-3.09a1.529 1.529 0 0 0-2.458 1.382l2.358 19.893c.046.384.235.736.53.985 4.637 3.925 14.447 6.363 25.601 6.363 11.153 0 20.964-2.438 25.601-6.362a1.53 1.53 0 0 0 .53-.986l2.358-19.893a1.528 1.528 0 0 0-.767-1.51ZM54.456 75.066l-2.597-3.918-2.023-3.052" fill="#DCDCDC"/><path d="M36.297 70.973c1.418 0 2.568-1.264 2.568-2.824 0-1.56-1.15-2.825-2.568-2.825-1.418 0-2.567 1.265-2.567 2.825 0 1.56 1.15 2.824 2.567 2.824Zm35.946 0c1.418 0 2.568-1.264 2.568-2.824 0-1.56-1.15-2.825-2.568-2.825-1.418 0-2.567 1.265-2.567 2.825 0 1.56 1.15 2.824 2.567 2.824ZM53.878 59l4.879 7.446-4.879 7.446L49 66.446 53.878 59Z" fill="#B0B0B0"/><path stroke="#000" d="M.5.5h107v123H.5z"/></svg>'))));
            return string(abi.encodePacked(base, svgBase64Encoded));
        } else if (keccak256(abi.encodePacked((_tokenId))) == keccak256(abi.encodePacked(("or")))) {
            string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked('<svg width="200" viewBox="0 0 108 124" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="#FFD500" d="M.5.5h107v123H.5z"/><path fill="#FFE140" stroke="#000" d="M10.5 10.5h87v103h-87z"/><path fill="#fff" stroke="#000" d="M14.5 14.5h79v95h-79z"/><path stroke="#000" d="m10.354 10.646 4 4m83-4.292-4 4m-82.708 99.292 4-4m78.708 0 4 4"/><g clip-path="url(#a)"><path d="M73.483 80.937H33.63c-.93 0-1.682.753-1.682 1.682v2.69c0 .93.753 1.682 1.682 1.682h39.854c.93 0 1.682-.753 1.682-1.682v-2.69c0-.929-.753-1.682-1.682-1.682Z" fill="#CA0"/><path d="M73.147 80.937H33.421l-2.422-27.616c0-1.095 1.458-1.473 1.99-.515l5.53 9.967 6.509-19.995c.318-.977 1.7-.977 2.018 0l6.51 14.21 6.51-14.21c.317-.977 1.7-.977 2.018 0l6.51 19.995 5.529-9.967c.531-.957 1.99-.58 1.99.515l-2.966 27.616Z" fill="#FFD500"/><path d="M31.835 52.27a2.018 2.018 0 1 0 0-4.036 2.018 2.018 0 0 0 0 4.036Zm43.33 0a2.018 2.018 0 1 0 0-4.036 2.018 2.018 0 0 0 0 4.036ZM46.022 42.045a2.018 2.018 0 1 0 0-4.036 2.018 2.018 0 0 0 0 4.036Zm15.114 0a2.018 2.018 0 1 0 0-4.036 2.018 2.018 0 0 0 0 4.036ZM53.243 75.41c2.396 0 4.338-2.724 4.338-6.084 0-3.36-1.942-6.084-4.338-6.084-2.397 0-4.34 2.724-4.34 6.084 0 3.36 1.943 6.084 4.34 6.084Zm10.514-3.553a2.109 2.109 0 1 0 0-4.218 2.109 2.109 0 0 0 0 4.218Zm-21.028 0a2.109 2.109 0 1 0 0-4.218 2.109 2.109 0 0 0 0 4.218Z" fill="#CA0"/></g><path stroke="#000" d="M.5.5h107v123H.5z"/><defs><clipPath id="a"><path fill="#fff" transform="translate(28 37)" d="M0 0h51v51H0z"/></clipPath></defs></svg>'))));
            return string(abi.encodePacked(base, svgBase64Encoded));
        } else if (keccak256(abi.encodePacked((_tokenId))) == keccak256(abi.encodePacked(("diamant")))){
            string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked('<svg width="200" viewBox="0 0 108 124" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="#0FF" d="M.5.5h107v123H.5z"/><path fill="#90FFFF" stroke="#000" d="M10.5 10.5h87v103h-87z"/><path fill="#fff" stroke="#000" d="M14.5 14.5h79v95h-79z"/><path stroke="#000" d="m10.354 10.646 4 4m83-4.292-4 4m-82.708 99.292 4-4m78.708 0 4 4"/><path d="M76 86.333H32c-1.1 0-2-.825-2-1.833s.9-1.833 2-1.833h44c1.1 0 2 .825 2 1.833s-.9 1.833-2 1.833ZM31 41.417c0 1.558-1.3 2.75-3 2.75s-3-1.192-3-2.75c0-1.559 1.3-2.75 3-2.75s3 1.191 3 2.75Zm26 0c0 1.558-1.3 2.75-3 2.75s-3-1.192-3-2.75c0-1.559 1.3-2.75 3-2.75s3 1.191 3 2.75Zm26 0c0 1.558-1.3 2.75-3 2.75s-3-1.192-3-2.75c0-1.559 1.3-2.75 3-2.75s3 1.191 3 2.75Zm-7 33.916H32c-1.1 0-2-.825-2-1.833s.9-1.833 2-1.833h44c1.1 0 2 .825 2 1.833s-.9 1.833-2 1.833Z" fill="#0CC"/><path d="M67 59.75 54 44.167 41 59.75 28 44.167l7 27.5h38l7-27.5L67 59.75ZM33 82.667h42v-7.334H33v7.334Z" fill="#0FF"/><path d="M58 60.667c0 3.575-1.8 6.416-4 6.416s-4-2.841-4-6.416 1.8-6.417 4-6.417 4 2.842 4 6.417Z" fill="#0CC"/><path stroke="#000" d="M.5.5h107v123H.5z"/></svg>'))));
            return string(abi.encodePacked(base, svgBase64Encoded));
        }
        return "";
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', name[_tokenId], '",',
                    '"description": "Aubay NFT",',
                    '"image_data": "', img_data[_tokenId], '"'
                    '}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function withdrawCDBCoin(address _to, uint _amount) external onlyOwner {
        TokenP2E.transfer(_to, _amount);
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721Buyable.sol";

/**
 * @title Onchain Buyable token
 * @author Aubay
 * @notice Put a token to sale onchain at the desired price.
 * @dev Make it possible to put a token to sale onchain and execute the transfer function
 * only if requirements are met without having to approve the token to any third party.
 */
abstract contract ERC721Buyable is ERC721, IERC721Buyable, Ownable {

    // Royalties to owner are to set in % (basis points per default but updatable inside `_royaltyDenominator()`, therefore 100% would be 10000)
    // Can only be reduced to avoid malicious manipulation
    uint internal _updatedRoyalty;
    bool private _firstRoyaltyUpdate = false;

    // Mapping from token ID to the desired selling price
    mapping(uint => uint) public prices;    


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Buyable).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * @dev See {IERC721Buyable-setPrice}.
     */
    function setPrice(uint _tokenId, uint _price) external virtual override onlyTokenOwner(_tokenId) {
        prices[_tokenId] = _price;
        emit UpdatePrice(_tokenId, _price);
    }

    /**
     * @dev See {IERC721Buyable-removeTokenSale}.
     */
    function removeTokenSale(uint _tokenId) external virtual override onlyTokenOwner(_tokenId) {
        delete prices[_tokenId];
        emit RemoveFromSale(_tokenId);
    }
    
    /**
     * @dev See {IERC721Buyable-buyToken}.
     */
    function buyToken(uint _tokenId) public virtual override payable {
        require(prices[_tokenId] != 0, "Token is not for sale");
        require(msg.value >= prices[_tokenId], "Insufficient funds to purchase this token");

        address seller = ownerOf(_tokenId);
        address buyer = msg.sender;

        uint royalties = (msg.value*_royalty())/_royaltyDenominator();

        if (seller == owner() || royalties == 0) {
            (bool success, ) = payable(seller).call{ value: msg.value }("");
            require(success, "Something happened when paying the token owner");
        } else {
            _payRoyalties(royalties);
            (bool success, ) = payable(seller).call{ value: msg.value-royalties }("");
            require(success, "Something happened when paying the token owner");
        }

        emit Purchase(buyer, seller, msg.value);

        _safeTransfer(seller, buyer, _tokenId, "");
    }


    /**
     * @dev The denominator to interpret the rate of royalties, defaults to 10000 so rate are expressed in basis points.
     * Base 10000, so 10000 = 100%, 0 = 0% , 2000 = 20%
     * May be customized with an override. 
     */
    function _royaltyDenominator() internal pure virtual returns(uint) {
        return 10000;
    }

    /**
     * @dev Royalty percentage per default at the contract creation expressed in basis points (per default between 0 and `_royaltyDenominator()`).
     * May be customized with an override.
     */
    function _defaultRoyalty() internal pure virtual returns(uint) {
        return 1000;
    }

    /**
     * @dev Return the current royalty : default royalty if not updated, otherwise return the updated one.
     * @return royalty uint within the range of `_royaltyDenominator` associated with the token.
     */
    function _royalty() internal view virtual returns(uint) {
        return _firstRoyaltyUpdate ? _updatedRoyalty : _defaultRoyalty();
    }

    /**
     * @dev See {IERC721Buyable-royaltyInfo}.
     */
    function royaltyInfo() external view virtual override returns(uint, uint) {
        return (_royalty(), _royaltyDenominator());
    }

    /**
     * @dev See {IERC721Buyable-setRoyalty}.
     */
    function setRoyalty(uint _newRoyalty) external virtual override onlyOwner() {
        require(_newRoyalty <= _royaltyDenominator(), "Royalty must be between 0 and _royaltyDenominator");
        require(_newRoyalty < _royalty(), "New royalty must be lower than previous one");

        _updatedRoyalty = _newRoyalty;

        if (!_firstRoyaltyUpdate) {
            _firstRoyaltyUpdate = true;
        }

        emit UpdateRoyalty(_newRoyalty);
    }

    /**
     * @dev Send to `_owner` of the contract a specific amount of ether as royalties.
     * @param _amount uint for the royalty payment.
     */
    function _payRoyalties(uint _amount) internal virtual {
        (bool success, ) = payable(owner()).call{ value:_amount }("");
        require(success, "Something happened when paying the royalties");
    }


    /**
     * @dev Transfer `tokenId`. See {ERC721-_transfer}.
     * Remove the token with the ID `tokenId` from the sale.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        delete prices[tokenId];
        ERC721._transfer(from, to, tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     * Remove the token with the ID `tokenId` from the sale.
     */
    function _burn(uint256 tokenId) internal virtual override {
        delete prices[tokenId];
        ERC721._burn(tokenId);
    }
    

    /** 
     * @dev Requirements:
     *
     * - Owner of `_tokenId` must be the caller
     *
     * @param _tokenId uint representing the token ID number.
     */
    modifier onlyTokenOwner(uint _tokenId) { 
        require(ownerOf(_tokenId) == msg.sender, "You don't own this token"); // also implies that it exists
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./charity.sol";

/**
*@title ERC720 charity Token
*@dev Extension of ERC720 Token that can be partially donated to a charity project
*
*This extensions keeps track of donations to charity addresses. The  whitelisted adress are from a another contract (Reserve)
 */

contract CDBCoin is ERC20Charity{
    constructor() ERC20("CDB Coin", "CDB") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    /** @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * @param to The address to assign the amount to.
     * @param amount The amount of token to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    
    //Test support for ERC-Charity
    bytes4 private constant _INTERFACE_ID_ERCcharity = type(IERC20Charity).interfaceId; // 0x557512b6
    //bytes4 private constant _INTERFACE_ID_ERCcharity =type(IERC165).interfaceId; // ERC165S
    function checkInterface(address _contract) external view returns (bool) {
    (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERCcharity);
    return success;
    }

    /*function InterfaceId() external returns (bytes4) {
    bytes4 _INTERFACE_ID = type(IERC20charity).interfaceId;
    return _INTERFACE_ID ;
    }*/

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Required interface of an ERC721Buyable compliant contract.
 * bytes4 private constant _INTERFACE_ID_ERC721Buyable = 0x8ce7e09d;
 */
interface IERC721Buyable is IERC721 {

    /**
     * @dev Emitted when `amount` of ether is transferred from `buyer` to `seller` when purchasing a token.
     */
    event Purchase(address indexed buyer, address indexed seller, uint indexed amount);

    /**
     * @dev Emitted when price of `tokenId` is set to `price`.
     */
    event UpdatePrice(uint indexed tokenId, uint indexed price);

    /**
     * @dev Emitted when `tokenId` is removed from the sale.
     */
    event RemoveFromSale(uint indexed tokenId);

    /**
     * @dev Emitted when royalty percentage is set to `royalty`.
     */
    event UpdateRoyalty(uint indexed royalty);


    /** 
     * @notice Puts a token to sale and set its price.
     * @dev Requirements:
     *
     * - Owner of `_tokenId` must be the caller
     *
     * Emits an {UpdatePrice} event.
     *
     * @param _tokenId uint representing the token ID number.
     * @param _price uint representing the price at which to sell the token.
     */
    function setPrice(uint _tokenId, uint _price) external;

    /** 
     * @notice Removes a token from the sale.
     * @dev Requirements:
     *
     * - Owner of `_tokenId` must be the caller
     *
     * Emits a {RemoveFromSale} event.
     *
     * @param _tokenId uint representing the token ID number.
     */
    function removeTokenSale(uint _tokenId) external;

    /** 
     * @notice Buys a specific token from its ID onchain.
     * @dev Amount of ether msg.value sent is transferred to `seller` of the token.
     * A percentage of the royalty allocution is sent to `_owner` of the contract.
     * The token of ID `_tokenId` is then transferred from `seller` to `buyer` (the msg.sender).
     * The token is then automatically removed from the sale.
     *
     * Requirements:
     *
     * - `_tokenId` must be put to sale
     * - Amount of ether `msg.value` sent must be greater than the selling price
     *
     * Emits a {Purchase} event.
     *
     * @param _tokenId uint representing the token Id number.
     */
    function buyToken(uint _tokenId) external payable;


    /**
     * @notice Return the current royalty and its denominator.
     * @dev Return the current royalty and its denominator.
     * @return _royalty uint within the range of `_royaltyDenominator` associated with the token.
     * @return _denominator uint denominator set in `_royaltyDenominator()`.
     */
    function royaltyInfo() external view returns(uint, uint);

    /** 
     * @notice Set the royalty percentage.
     * @dev Set or update the royalty percentage within the range of `_royaltyDenominator`.
     * Update the `_firstRoyaltyUpdate` boolean to true if previously false.
     *
     * Requirements:
     *
     * - caller must be `_owner` of the contract
     * - `_newRoyalty` must be between 0 and `_royaltyDenominator`
     * - `_newRoyalty` must be lower than current previous one
     *
     * Emits an {UpdateRoyalty} event.
     *
     * @param _newRoyalty uint within the range of `_royaltyDenominator` as new tokens royalties.
     */
    function setRoyalty(uint _newRoyalty) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20Charity.sol";

/**
*@title ERC720 charity Token
*@author Aubay
*@dev Extension of ERC720 Token that can be partially donated to a charity project
*
*This extensions keeps track of donations to charity addresses. The owner can chose the charity adresses listed.
*Users can active the donation option or not and specify a different pourcentage than the default one donate.
* A pourcentage af the amount of token transfered will be added and send to a charity address.
 */

abstract contract ERC20Charity is IERC20Charity, ERC20, Ownable {
    
    mapping(address => uint256) public whitelistedRate; //Keep track of the rate for each charity address
    mapping(address =>  mapping(address => uint256)) private _donation; //Keep track of the desired rate to donate for each user
    mapping (address =>address) private _defaultAddress; //keep track of each user's default charity address

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC20Charity).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
    *@dev The default rate of donation can be override
     */
    function _defaultRate() internal pure virtual returns (uint256) {
        return 10; // 0.1%
    }

    /**
    *@dev The denominator to interpret the rate of donation , defaults to 10000 so rate are expressed in basis points, but may be customized by an override. 
     * base 10000 , so 10000 =100% , 0 = 0% ,   2000 =20%
     */
    function _feeDenominator() internal pure virtual returns (uint256) {
        return 10000;
    }

    /**
    *@notice Add address to whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toAdd` cannot be the zero address.
     *
     * @param toAdd The address to whitelist.
     */
    function  addToWhitelist(address toAdd) override external virtual onlyOwner {
        whitelistedRate[toAdd]= _defaultRate();
        emit AddedToWhitelist(toAdd);
    }

    /**
    *@notice Remove the address from the whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toRemove` cannot be the zero address.
     *
     * @param toRemove The address to remove from whitelist.
     */
    function deleteFromWhitelist(address toRemove) override external virtual onlyOwner {
        //delete whitelisted[toRemove]; //whitelisted[toRemove]= false;
        delete whitelistedRate[toRemove]; //whitelistedRate[toRemove] =0;
        emit RemovedFromWhitelist(toRemove);
    }

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     *
     * @param whitelistedAddr The address to set as default.
     */
    function setSpecificDefaultAddress(address whitelistedAddr) override external virtual{
        require(whitelistedRate[whitelistedAddr]!=0  , "ERC20Charity: invalid whitelisted rate");
        _defaultAddress[msg.sender]= whitelistedAddr;
        _donation[msg.sender][whitelistedAddr]= whitelistedRate[whitelistedAddr];
        emit DonnationAddressChanged(whitelistedAddr);
    }

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The rate is specified by the user.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate 
     * or to the rate specified by the owner of this contract in {whitelistedRate}.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificDefaultAddressAndRate(address whitelistedAddr , uint256 rate) override external virtual{
        require(rate <= _feeDenominator(), "ERC20Charity: rate must be between 0 and _feeDenominator");
        require(rate >= _defaultRate(), "ERC20Charity: rate fee must exceed default rate");
        require(rate >= whitelistedRate[whitelistedAddr], "ERC20Charity: rate fee must exceed the fee set by the owner");
        require(whitelistedRate[whitelistedAddr]!=0, "ERC20Charity: invalid whitelisted address");
        _defaultAddress[msg.sender]= whitelistedAddr;
        _donation[msg.sender][whitelistedAddr]= rate;
        emit DonnationAddressAndRateChanged(whitelistedAddr, rate);
    }

    /**
    *@notice Set personlised rate for charity address in {whitelistedRate}.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificRate(address whitelistedAddr , uint256 rate) override external virtual onlyOwner{
        require(rate <= _feeDenominator(), "ERC20Charity: rate must be between 0 and _feeDenominator");
        require(rate >= _defaultRate(), "ERC20Charity: rate fee must exceed default rate");
        require(whitelistedRate[whitelistedAddr]!=0, "ERC20Charity: invalid whitelisted address");
        whitelistedRate[whitelistedAddr]= rate;
        emit ModifiedCharityRate(whitelistedAddr, rate);
    }

    /**
    *@notice Display for a user the default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
     */
    function SpecificDefaultAddress() override external virtual view returns (address) {
        return _defaultAddress[msg.sender]; 
    }

    /**
     * inherit IERC20charity
     */
    function charityInfo( address charityAddr) override external view virtual returns (bool, uint256 rate) {
        rate = whitelistedRate[charityAddr];
        if (rate != 0) {
            return(true, rate);
        }else{
            return(false,rate);
        }
    }

    /**
    *@notice Delete The Default Address and so deactivate donnations .
     */
    function DeleteDefaultAddress() override external virtual  {
        _defaultAddress[msg.sender] = address(0);
        emit DonnationAddressChanged(address(0));
    }

    /**
    *@notice Return the rate to donate.
    * @dev Requirements:
     *
     * - `from` cannot be the zero address
     *
     * @param from The address to get rate of donation.
     */
    function _returnRate(address from) internal virtual returns (uint256  rate){
        address whitelistedAddr =  _defaultAddress[from];
        rate= _donation[from][whitelistedAddr];
        if (whitelistedRate[whitelistedAddr]==0 || _defaultAddress[from] ==address(0)){
            rate =0;
        }
        return rate;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to, 
        uint256 amount
        ) public virtual override(IERC20, ERC20) returns (bool) {
        address owner = _msgSender();

        if(_defaultAddress[msg.sender] !=address(0)){
            address whitelistedAddr =  _defaultAddress[msg.sender];
            uint256 rate= _returnRate(msg.sender);
            uint256 donate = (amount * rate) /_feeDenominator();
            _transfer(owner, whitelistedAddr, donate);
        }
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override(IERC20, ERC20) returns (bool) {
        address spender = _msgSender(); 
        _spendAllowance(from, spender, amount);
        
        if(_defaultAddress[from] !=address(0)){
            address whitelistedAddr =  _defaultAddress[from];
            uint256 rate= _returnRate(from);
            uint256 donate = (amount * rate) /_feeDenominator();
            _spendAllowance(from, spender, donate);
            _transfer(from, whitelistedAddr, donate);
        }
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender, 
        uint256 amount
        ) public virtual override(IERC20, ERC20) returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        if(_defaultAddress[msg.sender] !=address(0)){
            uint256 rate= _returnRate(msg.sender);
            uint256 donate = (amount * rate) /_feeDenominator();
            _approve(owner, spender, (donate+amount));
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///
/// @dev Required interface of an ERC20 Charity compliant contract.
///
interface IERC20Charity is IERC20, IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    ///type(IERC20charity).interfaceId.interfaceId == 0x557512b6
    /// bytes4 private constant _INTERFACE_ID_ERCcharity = 0x557512b6;
    /// _registerInterface(_INTERFACE_ID_ERCcharity);

    
    /**
     * @dev Emitted when `toAdd` charity address is added to `whitelistedRate`.
     */
    event AddedToWhitelist (address toAdd);

    /**
     * @dev Emitted when `toRemove` charity address is deleted from `whitelistedRate`.
     */
    event RemovedFromWhitelist (address toRemove);

    /**
     * @dev Emitted when `_defaultAddress` charity address is modified and set to `whitelistedAddr`.
     */
    event DonnationAddressChanged (address whitelistedAddr);

    /**
     * @dev Emitted when `_defaultAddress` charity address is modified and set to `whitelistedAddr` 
    * and _donation is set to `rate`.
     */
    event DonnationAddressAndRateChanged (address whitelistedAddr,uint256 rate);

    /**
     * @dev Emitted when `whitelistedRate` for `whitelistedAddr` is modified and set to `rate`.
     */
    event ModifiedCharityRate(address whitelistedAddr,uint256 rate);
    
    /**
    *@notice Called with the charity address to determine if the contract whitelisted the address
    *and if it is the rate assigned.
    *@param addr - the Charity address queried for donnation information.
    *@return whitelisted - true if the contract whitelisted the address to receive donnation
    *@return defaultRate - the rate defined by the contract owner by default , the minimum rate allowed different from 0
    */
    function charityInfo(
        address addr
    ) external view returns (
        bool whitelisted,
        uint256 defaultRate
    );

    /**
    *@notice Add address to whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toAdd` cannot be the zero address.
     *
     * @param toAdd The address to whitelist.
     */
    function addToWhitelist(address toAdd) external;

    /**
    *@notice Remove the address from the whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toRemove` cannot be the zero address.
     *
     * @param toRemove The address to remove from whitelist.
     */
    function deleteFromWhitelist(address toRemove) external;

    /**
    *@notice Set personlised rate for charity address in {whitelistedRate}.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificRate(address whitelistedAddr , uint256 rate) external;

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     *
     * @param whitelistedAddr The address to set as default.
     */
    function setSpecificDefaultAddress(address whitelistedAddr) external;

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The rate is specified by the user.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate 
     * or to the rate specified by the owner of this contract in {whitelistedRate}.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificDefaultAddressAndRate(address whitelistedAddr , uint256 rate) external;

    /**
    *@notice Display for a user the default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
     */
    function SpecificDefaultAddress() external view returns (
        address defaultAddress
    );

    /**
    *@notice Delete The Default Address and so deactivate donnations .
     */
    function DeleteDefaultAddress() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";