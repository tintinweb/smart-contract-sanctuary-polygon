/**
 *Submitted for verification at polygonscan.com on 2023-01-29
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: ERC2272.sol


pragma solidity ^0.8.16;

// Define an ERC2272 smart contract that generates and manages fungible and non-fungible tokens.
// An ERC2272 contract has mostly the same interface as an ERC1155 contract, but implements few notable improvements:
// - allows easy iteration over all owners and tokens held by the contract, no need to watch the blockchain transactions anymore
// - owners can mark all/some of their tokens for sale and set token prices in the contract itself
// - defines a new 'buy' operation which allows token sales managed by the contract itself






// store the base URI for an ERC2272 contract,
// construct contract and token URIs:
// - contract URI: baseURI + "Contract.json"
// - token URI:    baseURI + "TokenXXID.json"
abstract contract ERC2272URI is Ownable
{
    // define the base URI for the contract
    string private _baseURI;

    // set the base URI when the contract is created
    constructor(string memory baseURI)
    {
        _baseURI = baseURI;
    } // constructor

    // change the base URI, only the owner can do this
    function setBaseURI(string memory baseURI) public onlyOwner
    {
        _baseURI = baseURI;
    } // setBaseURI
    
    // return the base URI
    function getBaseURI() public view 
        returns (string memory)
    {
        return _baseURI;
    } // getBaseURI

    // return the URI associated with the contract, default contract URI: baseURI + "Contract.json",
    // the default contract URI can be changed by overriding this function,
    // the name of this function cannot be changed since it is expected by OpenSea
    function contractURI() public view virtual 
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, "Contract.json"));
    } // contractURI

    // return the URI associated with the input token ID, default token URI: baseURI + "TokenXXID.json",
    // the default token URI can be changed by overriding this function,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function uri(uint256 tokenID) public view virtual 
        returns (string memory)
    {
        // add leading zeros
        bytes memory tokenIDStr = bytes(Strings.toString(tokenID));
        while (tokenIDStr.length < 4)
        { tokenIDStr = bytes.concat(bytes("0"), tokenIDStr); }

        // compose and return the full URI
        return string(abi.encodePacked(_baseURI, "Token", string(tokenIDStr), ".json"));
    } // uri
} // ERC2272URI

// store aproved ERC2272 operators for owner accounts
abstract contract ERC2272Operators
{
    // define an approval event
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    // map owner accounts to their aproved operators
    mapping(address => mapping(address => bool)) private _operatorApproval;

    // aprove the input operator for the input owner account
    function _setApprovalForAll(address account, address operator, bool approved) private
    {
        // check if the input data is valid
        require(account != operator, "ERC2272: cannot set approval status for self");
        
        // set the approval flag
        _operatorApproval[account][operator] = approved;
        
        // broadcast the approval event
        emit ApprovalForAll(account, operator, approved);
    } // _setApprovalForAll

    // aprove the input operator for the sender account,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function setApprovalForAll(address operator, bool approved) public
    {
        _setApprovalForAll(msg.sender, operator, approved);
    } // setApprovalForAll

    // check if the input operator is aproved for the input owner account,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function isApprovedForAll(address account, address operator) public view 
        returns (bool)
    {
        return _operatorApproval[account][operator];
    } // isApprovedForAll
} // ERC2272Operators

// store all token IDs minted by an ERC2272 contract, 
// includes the IDs of completely burnt tokens
abstract contract ERC2272MintedTokenIDs
{
    // list containing all minted token IDs, this is publicly accessible
    uint256[] public tokenIDList;

    // store a newly minted token ID
    function _storeMintedTokenID(uint256 tokenID) internal
    {
        tokenIDList.push(tokenID);
    } // _storeMintedTokenID

    // return the total number of token IDs minted,
    // note that this number includes the IDs of completely burnt tokens
    function getNumMintedTokenIDs() public view 
        returns (uint256)
    {
        return tokenIDList.length;
    } // getNumMintedTokenIDs
} // ERC2272MintedTokenIDs

// store the number of token IDs held by each owner, 
// used mostly by MetaMask
abstract contract ERC2272OwnedTokenIDs
{
    // map owner addresses to the number of token IDs held
    mapping(address => uint256) private _ownedTokenIDsMap;

    // increment the number of token IDs held by the input owner
    function _incrementOwnedTokenIDs(address account) internal
    {
        // update the number of token IDs
        _ownedTokenIDsMap[account] += 1;
    } // _incrementOwnedTokenIDs

    // decrement the number of token IDs held by the input owner
    function _decrementOwnedTokenIDs(address account) internal
    {
        // check if the owner data is valid
        require(_ownedTokenIDsMap[account] > 0, "ERC2272: the input owner doesn't have any token IDs to decrement");

        // update the number of token IDs
        unchecked {
            _ownedTokenIDsMap[account] -= 1;
        }
    } // _decrementOwnedTokenIDs

    // return the number of token IDs held by the input owner,
    // the name of this function cannot be changed since it is expected by MetaMask
    function balanceOf(address account) public view 
        returns (uint256)
    {
        return _ownedTokenIDsMap[account];
    } // balanceOf
} // ERC2272OwnedTokenIDs

// store owners, tokens, balances and prices for an ERC2272 contract
abstract contract ERC2272Data is ERC2272MintedTokenIDs, ERC2272OwnedTokenIDs, Ownable
{
    // define zero token ID and zero index, both are reserved
    uint256 private constant _zeroTokenIndex = 0;
    // define the default price for a token in Wei
    uint256 private _defaultTokenPrice = 100000000000000; // 0.0001 ETH or MATIC (0.0001 * 10 ** 18)

    // various info about a token
    struct TokenInfo
    {
        // the token's total supply
        uint256 tokenTotalSupply;

        // the index pointing to the token's first owner in the owner list
        uint256 tokenFirstIndex;
    } // TokenInfo

    // various info about a token's owner, a fungible token can have multiple owners
    struct TokenOwnerInfo
    {
        // the owner's address
        address tokenOwner;

        // the token's balance for this owner
        uint256 tokenBalance;
        
        // number of tokens put for sale by the owner
        uint256 tokenForSale;
        // the token's price in Wei as set by the owner, initially it will be set to the default price
        uint256 tokenPrice;

        // the index pointing to the token's next owner in the owner list
        uint256 tokenNextIndex;
    } // TokenOwnerInfo

    // map token IDs to their info, this is publicly accessible (note that maps are not iterable, so we need ERC2272MintedTokenIDs to go over all minted tokens)
    mapping(uint256 => TokenInfo) public tokenInfoMap;
    // list containing all token owners, this is publicly accessible
    TokenOwnerInfo[] public tokenOwnerList;   
    // map token IDs to account location in the above list of token owners
    mapping(uint256 => mapping(address => uint256)) private _tokenLocationMap;

    // initialize the data
    constructor()
    {
        // created a fake token slot that will store the original 
        // owner of the contract and the sum of all token supplies
        TokenInfo storage zeroTokenInfo = tokenInfoMap[_zeroTokenIndex]; // zero token ID is reserved
        zeroTokenInfo.tokenFirstIndex = _storeTokenOwner(msg.sender);    // zero index is reserved (this is the first entry in the owner list, so the index will be 0)
        zeroTokenInfo.tokenTotalSupply = 0;                              // initialize the sum of all token supplies
    } // constructor

    // store a new token's owner in the owner list
    function _storeTokenOwner(address account) private 
        returns (uint256)
    {
        // create a new owner info
        TokenOwnerInfo memory tokenOwnerInfo = TokenOwnerInfo({
            tokenOwner: account,            // store the token's owner
            tokenBalance: 0,                // initialize the token's balance
            tokenForSale: 0,                // initialize the number of tokens for sale
            tokenPrice: _defaultTokenPrice, // initialize the token's price in Wei, set it to the default price
            tokenNextIndex: _zeroTokenIndex // initialize the next owner's index
        });

        // store the token's new owner
        tokenOwnerList.push(tokenOwnerInfo);
    
        // return the index where the new owner was stored
        return tokenOwnerList.length - 1;
    } // _storeTokenOwner

    // update the number of tokens for sale for the input account
    function _updateTokenForSale(address account, uint256 tokenID, uint256 amount) private
    {
        // retrieve the input token's index in the owner list
        uint256 tokenIndex = _tokenLocationMap[tokenID][account];
        require(tokenIndex != _zeroTokenIndex, "ERC2272: the input account doesn't own the token");

        // retrieve the input token's info for the input account
        TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];

        // update the number of tokens for sale for the input account
        if (amount == 0)
        {
            if (tokenOwnerInfo.tokenForSale > tokenOwnerInfo.tokenBalance)
                tokenOwnerInfo.tokenForSale = tokenOwnerInfo.tokenBalance;
        }
        else if(amount >= tokenOwnerInfo.tokenForSale)
            tokenOwnerInfo.tokenForSale = 0;
        else
            tokenOwnerInfo.tokenForSale -= amount;
    } // _updateTokenForSale

    // create an association between the input account and token if necessary
    function _addTokenOwner(address account, uint256 tokenID) private
    {
        // nothing to do if the input account and token are already associated
        if (_tokenLocationMap[tokenID][account] != _zeroTokenIndex)
            return;
        
        // check the total supply for the input token
        TokenInfo storage tokenInfo = tokenInfoMap[tokenID];
        if (tokenInfo.tokenTotalSupply == 0)
        {
            // check if this is a newly minted token
            if (tokenInfo.tokenFirstIndex == _zeroTokenIndex)
                // this is the first and only owner for the input token right now, store it in the owner list
                tokenInfo.tokenFirstIndex = _storeTokenOwner(account);
            else // this token was minted before, but then is was completely burnt
            {
                // the token's first index should point to a free slot
                TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenInfo.tokenFirstIndex];
                require(tokenOwnerInfo.tokenOwner == address(0), "ERC2272: the input token should point to a free slot");

                // fill the slot for the input token's owner
                tokenOwnerInfo.tokenOwner = account;
                tokenOwnerInfo.tokenPrice = _defaultTokenPrice;
            }
            
            // store the index where the new owner was stored
            _tokenLocationMap[tokenID][account] = tokenInfo.tokenFirstIndex;
        }
        else
        {
            // retrieve the index of the first owner for the input token
            uint256 tokenIndex = tokenInfo.tokenFirstIndex;
            require(tokenIndex != _zeroTokenIndex, "ERC2272: the input account doesn't own any token");

            // find a free slot in the owner list
            while (true)
            {
                // check if the curent owner slot is free
                TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];
                if (tokenOwnerInfo.tokenOwner == address(0))
                {
                    // store the new owner in the free slot
                    tokenOwnerInfo.tokenOwner = account;
                    tokenOwnerInfo.tokenPrice = _defaultTokenPrice;

                    // store the index where the new owner was stored
                    _tokenLocationMap[tokenID][account] = tokenIndex;
                    break;
                }

                // check if we reached the last owner for the input token
                if (tokenOwnerInfo.tokenNextIndex == _zeroTokenIndex)
                {
                    // store the new owner in the owner list
                    tokenOwnerInfo.tokenNextIndex = _storeTokenOwner(account);

                    // store the index where the new owner was stored
                    _tokenLocationMap[tokenID][account] = tokenOwnerInfo.tokenNextIndex;
                    break;
                }

                // go to the next owner for the input token
                tokenIndex = tokenOwnerInfo.tokenNextIndex;
            }
        }

        // increment the number of token IDs held by the input account
        _incrementOwnedTokenIDs(account);
    } // _addTokenOwner

    // remove the association between the input account and token from the owner list
    function _deleteTokenOwner(address account, uint256 tokenID) private
    {
        // retrieve the input token's index in the owner list
        uint256 tokenIndex = _tokenLocationMap[tokenID][account];
        require(tokenIndex != _zeroTokenIndex, "ERC2272: the input account doesn't own the token");

        // free the slot for the input token's owner
        TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];
        require(tokenOwnerInfo.tokenBalance == 0, "ERC2272: the input account still owns the token");
        tokenOwnerInfo.tokenOwner = address(0);
        tokenOwnerInfo.tokenForSale = 0;
        tokenOwnerInfo.tokenPrice = 0;

        // delete the index where the input token's owner was stored
        _tokenLocationMap[tokenID][account] = _zeroTokenIndex;

        // decrement the number of token IDs held by the input account
        _decrementOwnedTokenIDs(account);
    } // _deleteTokenOwner

    // update token's info for the input account during a minting operation
    function _mintTokenUpdateInfo(address account, uint256 tokenID, uint256 amount) private
    {
        // check if this is a newly minted token
        TokenInfo storage tokenInfo = tokenInfoMap[tokenID];
        if (tokenInfo.tokenFirstIndex == _zeroTokenIndex)
            // store the new token ID
            _storeMintedTokenID(tokenID);
        
        // create an association between the input input account and the input token if necessary
        _addTokenOwner(account, tokenID);

        // update the total supply for the input token
        tokenInfo.tokenTotalSupply += amount;
        // update the sum of all token supplies
        tokenInfoMap[_zeroTokenIndex].tokenTotalSupply += amount;

        // update the number of tokens for sale for the input account
        _updateTokenForSale(account, tokenID, 0);
    } // _mintTokenUpdateInfo

    // update token's info for the input account during a burning operation
    function _burnUpdateTokenInfo(address account, uint256 tokenID, uint256 amount, uint256 tokenBalance) private
    {
        // update the total supply for the input token
        TokenInfo storage tokenInfo = tokenInfoMap[tokenID];
        tokenInfo.tokenTotalSupply -= amount;
        // update the sum of all token supplies
        tokenInfoMap[_zeroTokenIndex].tokenTotalSupply -= amount;

        // check if this is a completely burnt token
        if (tokenInfo.tokenTotalSupply == 0)
            // remove the association between the input account and the input token,
            // do not delete the token completely (keep all its slots) because it might be minted again in the future
            _deleteTokenOwner(account, tokenID);
        // check if this is a completely burnt token for the input account
        else if (tokenBalance == 0)
            // remove the association between the input account and the input token
            _deleteTokenOwner(account, tokenID);
        else
            // update the number of tokens for sale for the input account
            _updateTokenForSale(account, tokenID, 0);
    } // _burnUpdateTokenInfo

    // update token's info for the input accounts during a transfer operation
    function _transferUpdateTokenInfo(address accountFrom, address accountTo, uint256 tokenID, uint256 amount, uint256 tokenBalance) internal
    {
        // check if this is a completely transferred token for the 'accountFrom' account
        if (tokenBalance == 0)
            // remove the association between the 'accountFrom' account and the input token
            _deleteTokenOwner(accountFrom, tokenID);
        else
            // update the number of tokens for sale for the 'accountFrom' account
            _updateTokenForSale(accountFrom, tokenID, amount);

        // create an association between the 'accountTo' input account and the input token if necessary
        _addTokenOwner(accountTo, tokenID);
    } // _transferUpdateTokenInfo

   // mint a token for the input account
    function _mintToken(address account, uint256 tokenID, uint256 amount) internal
    {
        // update input token's info for the input account
        _mintTokenUpdateInfo(account, tokenID, amount);

        // retrieve the input token's index in the owner list
        uint256 tokenIndex = _tokenLocationMap[tokenID][account];
        require(tokenIndex != _zeroTokenIndex, "ERC2272: the input account doesn't own the token");
        
        // update the token's balance for the input account
        tokenOwnerList[tokenIndex].tokenBalance += amount;
    } // _mintToken
    
    // mint a batch of tokens for the input account
    function _mintTokenBatch(address account, uint256[] memory tokenIDs, uint256[] memory amounts) internal
    {
        // loop over the batch of tokens
        for (uint256 i = 0; i < tokenIDs.length; ++i)
            // mint the current token for the input account
            _mintToken(account, tokenIDs[i], amounts[i]);
    } // _mintTokenBatch

    // burn a token for the input account
    function _burnToken(address account, uint256 tokenID, uint256 amount) internal
    {
        // retrieve the input token's index in the owner list
        uint256 tokenIndex = _tokenLocationMap[tokenID][account];
        require(tokenIndex != _zeroTokenIndex, "ERC2272: the input account doesn't own the token");

        // check the token's balance for the input account
        uint256 tokenBalance = tokenOwnerList[tokenIndex].tokenBalance;
        require(tokenBalance >= amount, "ERC2272: burn amount exceeds balance");
        
        // update the token's balance for the input account
        unchecked {
            tokenBalance -= amount;
            tokenOwnerList[tokenIndex].tokenBalance = tokenBalance;
        }

        // update input token's info for the input account
        _burnUpdateTokenInfo(account, tokenID, amount, tokenBalance);
    } // _burnToken
    
    // burn a batch of tokens for the input account
    function _burnTokenBatch(address account, uint256[] memory tokenIDs, uint256[] memory amounts) internal
    {
        // loop over the batch of tokens
        for (uint256 i = 0; i < tokenIDs.length; ++i)
            // burn the current token for the input account
            _burnToken(account, tokenIDs[i], amounts[i]);
    } // _burnTokenBatch
    
    // transfer a token between the input accounts
    function _transferToken(address accountFrom, address accountTo, uint256 tokenID, uint256 amount) internal
    {
        // retrieve the 'accountFrom' token's index in the owner list
        uint256 tokenIndex = _tokenLocationMap[tokenID][accountFrom];
        require(tokenIndex != _zeroTokenIndex, "ERC2272: the source account doesn't own the token");

        // check the token's balance for the 'accountFrom' account
        uint256 tokenBalance = tokenOwnerList[tokenIndex].tokenBalance;
        require(tokenBalance >= amount, "ERC2272: insufficient balance for transfer");

        // update the token's balance for the 'accountFrom' account
        unchecked {
            tokenBalance -= amount;
            tokenOwnerList[tokenIndex].tokenBalance = tokenBalance;
        }

        // update input token's info for the input accounts
        _transferUpdateTokenInfo(accountFrom, accountTo, tokenID, amount, tokenBalance);

        // retrieve the 'accountTo' token's index in the owner list
        tokenIndex = _tokenLocationMap[tokenID][accountTo];
        require(tokenIndex != _zeroTokenIndex, "ERC2272: the destination account doesn't own the token");
        
        // update the token's balance for the 'accountTo' account 
        tokenOwnerList[tokenIndex].tokenBalance += amount;
    } // _transferToken

    // transfer a batch of tokens between the input accounts
    function _transferTokenBatch(address accountFrom, address accountTo, uint256[] memory tokenIDs, uint256[] memory amounts) internal
    {
        // loop over the batch of tokens
        for (uint256 i = 0; i < tokenIDs.length; ++i)
            // transfer the current token between the input accounts
            _transferToken(accountFrom, accountTo, tokenIDs[i], amounts[i]);
    } // _transferTokenBatch

    // return the token balance for the input account
    function _getTokenBalance(address account, uint256 tokenID) internal view 
        returns (uint256)
    {
        // retrieve the input token's index in the owner list
        require(account != address(0), "ERC2272: balance query for the zero address");
        uint256 tokenIndex = _tokenLocationMap[tokenID][account];
        if (tokenIndex == _zeroTokenIndex)
            // the input account doesn't own this token
            return 0;
        
        // return the token's balance from the owner list
        return tokenOwnerList[tokenIndex].tokenBalance;
    } // _getTokenBalance

    // check whether a token exists or not,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function exists(uint256 tokenID) public view 
        returns (bool)
    {
        // ignore zero token ID
        if (tokenID == _zeroTokenIndex)
            return false;
        
        // a token exists if its total supply is greater than 0
        return (tokenInfoMap[tokenID].tokenTotalSupply > 0);
    } // exists

    // return the total amount of tokens for a given ID,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function totalSupply(uint256 tokenID) public view 
        returns (uint256)
    {
        // ignore zero token ID
        if (tokenID == _zeroTokenIndex)
            return 0;

        // return the total supply for the input token
        return tokenInfoMap[tokenID].tokenTotalSupply;
    } // totalSupply

    // return the sum of all token supplies
    function totalSupply() public view 
        returns (uint256)
    {
        return tokenInfoMap[_zeroTokenIndex].tokenTotalSupply;
    } // totalSupply
    
    // return the total number of token owners,
    // if an account owns multiple tokens it will be counted multiple times
    function getNumberTokenOwners() public view 
        returns (uint256)
    {
        // note that this number includes accounts that no longer own some of the tokens,
        // also includes the owner of the contract from the first slot
        return tokenOwnerList.length;
    } // getNumberTokenOwners

    // change the default price of a new token in Wei, only the owner can do this
    function setDefaultPrice(uint256 tokenPrice) public onlyOwner
    {
        _defaultTokenPrice = tokenPrice;
    } // setDefaultPrice
    
    // return the default price of a new token in Wei
    function getDefaultPrice() public view 
        returns (uint256)
    {
        return _defaultTokenPrice;
    } // getDefaultPrice

    // change the price of tokens for the input account (in Wei)
    function _setPrice(address account, uint256 tokenID, uint256 tokenForSale, uint256 tokenPrice) internal
    {
        // check if the input data is valid
        require(tokenPrice > 0, "ERC2272: the price of a token must be greater than 0");

        // retrieve the input token's index in the owner list
        uint256 tokenIndex = _tokenLocationMap[tokenID][account];
        require(tokenIndex != _zeroTokenIndex, "ERC2272: the input account doesn't own the token");

        // retrieve the token from the owner list
        TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];
        require(tokenForSale <= tokenOwnerInfo.tokenBalance, "ERC2272: not enough tokens are available for sale");

        // set the number of tokens for sale and their price
        tokenOwnerList[tokenIndex].tokenForSale = tokenForSale;
        tokenOwnerList[tokenIndex].tokenPrice = tokenPrice;
    } // setPrice
    
    // return the price of a token for the input account (in Wei)
    function _getPrice(address account, uint256 tokenID) internal view 
        returns (uint256)
    {
        // retrieve the input token's index in the owner list
        uint256 tokenIndex = _tokenLocationMap[tokenID][account];
        if (tokenIndex == _zeroTokenIndex)
            // the input account doesn't own this token
            return 0;
        
        // return the token's price from the owner list
        return tokenOwnerList[tokenIndex].tokenPrice;
    } // getPrice

    // return various stats about the contract
    function computeStats() public view 
        returns (string memory)
    {
        // compute the total number of token owners
        uint256 numSlots = tokenOwnerList.length - 1;

        // loop over all token owners
        uint256 numFreeSlots = 0;
        for (uint i = 1; i < tokenOwnerList.length; ++i)
        {
            // count how many owner slots are free
            if (tokenOwnerList[i].tokenOwner == address(0))
                numFreeSlots += 1;
        }

        // compose and return the stats as a string
        return string(abi.encodePacked(Strings.toString(numFreeSlots), " free slots out of ", Strings.toString(numSlots)));
    } // computeStats
} // ERC2272Data

// define an ERC2272 smart contract that generates and manages fungible and non-fungible tokens,
// an ERC2272 contract has mostly the same interface as an ERC1155 contract, but implements few notable improvements:
// - allows easy iteration over all owners and tokens held by the contract
// - owners can mark all/some of their tokens for sale and set token prices in the contract itself
// - defines a new 'buy' operation which allows token sales managed by the contract itself
contract ERC2272 is ERC2272URI, ERC2272Operators, ERC2272Data, Pausable
{
    // define a transfer event
    event TransferSingle(address indexed operator, address indexed accountFrom, address indexed accountTo, uint256 tokenID, uint256 value);
    // define a batch transfer event
    event TransferBatch(address indexed operator, address indexed accountFrom, address indexed accountTo, uint256[] tokenIDs, uint256[] values);

    // create the contract, set the base URI
    constructor(string memory baseURI)
        ERC2272URI(baseURI)
    {
    } // constructor

    // create new non fungible tokens ('amount'=1) or fungible tokens ('amount'>1) identified
    // by the input 'tokenID' and assign them to the input 'account', only the owner can do this,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function mint(address account, uint256 tokenID, uint256 amount, bytes memory data) public onlyOwner
    {
        // check if the input data is valid
        require(account != address(0), "ERC2272: cannot mint to the zero address");
        require(tokenID > 0, "ERC2272: the minted token IDs must be greater than 0");
        require(amount > 0, "ERC2272: the amount of tokens minted must be greater than 0");

        // check if the mint operation can be performed
        address operator = msg.sender;
        _beforeTokenTransfer(operator, address(0), account, _convertToArray(tokenID), _convertToArray(amount), data);

        // mint the token for the input account
        _mintToken(account, tokenID, amount);

        // broadcast the mint event (transfer from zero address to account)
        emit TransferSingle(operator, address(0), account, tokenID, amount);

        // check if the mint operation was accepted
        _afterTransferAcceptanceCheck(operator, address(0), account, tokenID, amount, data);
    } // mint

    // create new batches of non fungible tokens ('amount'=1) or fungible tokens ('amount'>1) identified
    // by the input 'tokenIDs' and assign them to the input 'account', only the owner can do this,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function mintBatch(address account, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data) public onlyOwner
    {
        // check if the input data is valid
        require(account != address(0), "ERC2272: cannot mint to the zero address");
        require(tokenIDs.length == amounts.length, "ERC2272: token IDs and amounts length mismatch");
        for (uint256 i = 0; i < tokenIDs.length; ++i)
        {
            require(tokenIDs[i] > 0, "ERC2272: the minted token IDs must be greater than 0");
            require(amounts[i] > 0, "ERC2272: the amount of tokens minted must be greater than 0");
        }

        // check if the mint operation can be performed
        address operator = msg.sender;
        _beforeTokenTransfer(operator, address(0), account, tokenIDs, amounts, data);

        // mint the batch of tokens for the input account
        _mintTokenBatch(account, tokenIDs, amounts);

        // broadcast the mint event (transfer from zero address to account)
        emit TransferBatch(operator, address(0), account, tokenIDs, amounts);

        // check if the mint operation was accepted
        _afterBatchTransferAcceptanceCheck(operator, address(0), account, tokenIDs, amounts, data);
    } // mintBatch

    // burn a token value irreversibly,
    // the caller must own these tokens or be an approved operator,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function burn(address account, uint256 tokenID, uint256 amount) public virtual
    {
        // check if the input data is valid
        require(account != address(0), "ERC2272: cannot burn from the zero address");
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "ERC2272: caller is not owner nor approved");
        require(tokenID > 0, "ERC2272: the burnt token IDs must be greater than 0");
        require(amount > 0, "ERC2272: the amount of tokens burnt must be greater than 0");

        // check if the burn operation can be performed
        address operator = msg.sender;
        _beforeTokenTransfer(operator, account, address(0), _convertToArray(tokenID), _convertToArray(amount), "");

        // burn the token for the input account
        _burnToken(account, tokenID, amount);

        // broadcast the burn event (transfer from account to zero address)
        emit TransferSingle(operator, account, address(0), tokenID, amount);
    } // burn

    // burn a batch of token values irreversibly,
    // the caller must own these tokens or be an approved operator,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function burnBatch(address account, uint256[] memory tokenIDs, uint256[] memory amounts) public virtual
    {
        // check if the input data is valid
        require(account != address(0), "ERC2272: cannot burn from the zero address");
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "ERC2272: caller is not owner nor approved");
        require(tokenIDs.length == amounts.length, "ERC2272: token IDs and amounts length mismatch");
        for (uint256 i = 0; i < tokenIDs.length; ++i)
        {
            require(tokenIDs[i] > 0, "ERC2272: the burnt token IDs must be greater than 0");
            require(amounts[i] > 0, "ERC2272: the amount of tokens burnt must be greater than 0");
        }
        
        // check if the burn operation can be performed
        address operator = msg.sender;
        _beforeTokenTransfer(operator, account, address(0), tokenIDs, amounts, "");

         // burn the batch of tokens for the input account
        _burnTokenBatch(account, tokenIDs, amounts);

        // broadcast the burn event (transfer from account to zero address)
        emit TransferBatch(operator, account, address(0), tokenIDs, amounts);
    } // burnBatch

    // transfer some tokens, assumes that the payment was already provided by other means,
    // the caller must own these tokens or be an approved operator,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function safeTransferFrom(address accountFrom, address accountTo, uint256 tokenID, uint256 amount, bytes memory data) public virtual
    {
        // check if the input data is valid
        require(accountFrom == msg.sender || isApprovedForAll(accountFrom, msg.sender), "ERC2272: caller is not owner nor approved");
        require(accountTo != address(0), "ERC2272: cannot transfer to the zero address");
        require(accountFrom != accountTo, "ERC2272: buyer cannot be the same as seller");
        require(tokenID > 0, "ERC2272: the transfered token IDs must be greater than 0");
        require(amount > 0, "ERC2272: the amount of tokens transfered must be greater than 0");

        // check if the transfer operation can be performed
        address operator = msg.sender;
        _beforeTokenTransfer(operator, accountFrom, accountTo, _convertToArray(tokenID), _convertToArray(amount), data);

         // transfer the token between the input accounts
        _transferToken(accountFrom, accountTo, tokenID, amount);

        // broadcast the transfer event (transfer from accountFrom to accountTo)
        emit TransferSingle(operator, accountFrom, accountTo, tokenID, amount);

        // check if the transfer operation was accepted
        _afterTransferAcceptanceCheck(operator, accountFrom, accountTo, tokenID, amount, data);
    } // safeTransferFrom

    // transfer a batch of tokens, assumes that the payment was already provided by other means,
    // the caller must own these tokens or be an approved operator,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function safeBatchTransferFrom(address accountFrom, address accountTo, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data) public virtual
    {
        // check if the input data is valid
        require(accountFrom == msg.sender || isApprovedForAll(accountFrom, msg.sender), "RC1155: transfer caller is not owner nor approved");
        require(accountTo != address(0), "RC1155: cannot transfer to the zero address");
        require(accountFrom != accountTo, "RC1155: buyer cannot be the same as seller");
        require(tokenIDs.length == amounts.length, "RC1155: token IDs and amounts length mismatch");
        for (uint256 i = 0; i < tokenIDs.length; ++i)
        {
            require(tokenIDs[i] > 0, "RC1155: the transfered token IDs must be greater than 0");
            require(amounts[i] > 0, "RC1155: the amount of tokens transfered must be greater than 0");
        }

        // check if the transfer operation can be performed
        address operator = msg.sender;
        _beforeTokenTransfer(operator, accountFrom, accountTo, tokenIDs, amounts, data);

         // transfer the batch of tokens between the input accounts
        _transferTokenBatch(accountFrom, accountTo, tokenIDs, amounts);

        // broadcast the transfer event (transfer from accountFrom to accountTo)
        emit TransferBatch(operator, accountFrom, accountTo, tokenIDs, amounts);

        // check if the transfer operation was accepted
        _afterBatchTransferAcceptanceCheck(operator, accountFrom, accountTo, tokenIDs, amounts, data);
    } // safeBatchTransferFrom

    // buy some tokens by providing payment,
    // the caller can be anybody and doesn't require owner's approval to buy these tokens
    function safeBuyFrom(address payable accountFrom, uint256 tokenID, uint256 amount, bytes memory data) payable public
    {
        // retrieve the caller, which is the buyer in this case
        address accountTo = msg.sender;
        require(accountFrom != accountTo, "RC1155: buyer cannot be the same as seller");
        require(tokenID > 0, "RC1155: the bought token IDs must be greater than 0");
        require(amount > 0, "RC1155: the amount of tokens bought must be greater than 0");

        // check if the required payment was provided
        uint256 price = getPrice(accountFrom, tokenID);
        require(msg.value == price*amount);

        // check if the transfer operation can be performed
        address operator = msg.sender;
        _beforeTokenTransfer(operator, accountFrom, accountTo, _convertToArray(tokenID), _convertToArray(amount), data);

         // transfer the token between the input accounts
        _transferToken(accountFrom, accountTo, tokenID, amount);

        // broadcast the transfer event (transfer from accountFrom to accountTo)
        emit TransferSingle(operator, accountFrom, accountTo, tokenID, amount);

        // check if the transfer operation was accepted
        _afterTransferAcceptanceCheck(operator, accountFrom, accountTo, tokenID, amount, data);

        // pay the seller for the tranferred tokens
        accountFrom.transfer(msg.value);
    } // safeBuyFrom
    
    // buy a batch of tokens by providing payment,
    // the caller can be anybody and doesn't require owner's approval to buy these tokens
    function safeBatchBuyFrom(address payable accountFrom, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data) payable public
    {
        // retrieve the caller, which is the buyer in this case
        address accountTo = msg.sender;
        require(accountFrom != accountTo, "RC1155: buyer cannot be the same as seller");
        for (uint256 i = 0; i < tokenIDs.length; ++i)
        {
            require(tokenIDs[i] > 0, "RC1155: the bought token IDs must be greater than 0");
            require(amounts[i] > 0, "RC1155: the amount of tokens bought must be greater than 0");
        }
        
        // check if the required payment was provided
        uint256 paymentValue = 0;
        for (uint256 i = 0; i < tokenIDs.length; ++i)
        {
            uint256 price = getPrice(accountFrom, tokenIDs[i]);
            paymentValue += price*amounts[i];
        }
        
        // check if the required payment was provided
        require(msg.value == paymentValue);

        // check if the transfer operation can be performed
        address operator = msg.sender;
        _beforeTokenTransfer(operator, accountFrom, accountTo, tokenIDs, amounts, data);

         // transfer the batch of tokens between the input accounts
        _transferTokenBatch(accountFrom, accountTo, tokenIDs, amounts);

        // broadcast the transfer event (transfer from accountFrom to accountTo)
        emit TransferBatch(operator, accountFrom, accountTo, tokenIDs, amounts);

        // check if the transfer operation was accepted
        _afterBatchTransferAcceptanceCheck(operator, accountFrom, accountTo, tokenIDs, amounts, data);

        // pay the seller for the tranferred tokens
        accountFrom.transfer(msg.value);
    } // safeBatchBuyFrom

    // return the token balance for the input account,
     // the name of this function cannot be changed since it is a standard ERC1155 function name
    function balanceOf(address account, uint256 tokenID) public view virtual 
        returns (uint256)
    {
        return _getTokenBalance(account, tokenID);
    } // balanceOf
    
    // return the token balances for the input accounts,
     // the name of this function cannot be changed since it is a standard ERC1155 function name
    function balanceOfBatch(address[] memory accounts, uint256[] memory tokenIDs) public view virtual 
        returns (uint256[] memory)
    {
        // check if the input data is valid
        require(accounts.length == tokenIDs.length, "RC1155: accounts and ids length mismatch");

        // allocate the output list
        uint256[] memory tokenBalances = new uint256[](accounts.length);

        // loop over the accounts and retrieve their token balances
        for (uint256 i = 0; i < accounts.length; ++i)
            tokenBalances[i] = _getTokenBalance(accounts[i], tokenIDs[i]);

        // return token balances
        return tokenBalances;
    } // balanceOfBatch

    // change the price of tokens for the input account (in Wei),
    // the caller must own these tokens or be an approved operator
    function setPrice(address account, uint256 tokenID, uint256 tokenForSale, uint256 tokenPrice) public
    {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "RC1155: caller is not owner nor approved");
        _setPrice(account, tokenID, tokenForSale, tokenPrice);
    } // setPrice
    
    // return the price of a token for the input account (in Wei)
    function getPrice(address account, uint256 tokenID) public view 
        returns (uint256)
    {
        return _getPrice(account, tokenID);
    } // getPrice

    // trigger a stopped state for the contract, only the owner can do this,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function pause() public onlyOwner
    {
        _pause();
    } // pause

    // return to the normal state of the contract, only the owner can do this,
    // the name of this function cannot be changed since it is a standard ERC1155 function name
    function unpause() public onlyOwner
    {
        _unpause();
    } // unpause

    // hook that is called before any transfer of tokens, this includes minting and burning
    function _beforeTokenTransfer(address operator, address accountFrom, address accountTo, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data) internal whenNotPaused
    {
        // nothing else to do other than checking whenNotPaused modifier
    } // _beforeTokenTransfer

    // check if a transfer operation was accepted
    function _afterTransferAcceptanceCheck(address operator, address accountFrom, address accountTo, uint256 tokenID, uint256 amount, bytes memory data) private
    {
        // address.code.length is 0 for contracts in construction, 
        // since the code is only stored at the end of the constructor execution
        if (accountTo.code.length > 0)
        {
            try IERC1155Receiver(accountTo).onERC1155Received(operator, accountFrom, tokenID, amount, data) 
                returns (bytes4 response)
            {
                if (response != IERC1155Receiver.onERC1155Received.selector)
                    revert("RC1155: ERC1155Receiver rejected tokens");
            }
            catch Error(string memory reason)
            {
                revert(reason);
            }
            catch
            {
                revert("RC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    } // _afterTransferAcceptanceCheck

    // check if a batch transfer operation was accepted
    function _afterBatchTransferAcceptanceCheck(address operator, address accountFrom, address accountTo, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data) private
    {
        // address.code.length is 0 for contracts in construction, 
        // since the code is only stored at the end of the constructor execution
        if (accountTo.code.length > 0)
        {
            try IERC1155Receiver(accountTo).onERC1155BatchReceived(operator, accountFrom, tokenIDs, amounts, data) 
                returns (bytes4 response)
            {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector)
                    revert("RC1155: ERC1155Receiver rejected tokens");
            }
            catch Error(string memory reason)
            {
                revert(reason);
            }
            catch
            {
                revert("ERC2272: transfer to non ERC1155Receiver implementer");
            }
        }
    } // _afterBatchTransferAcceptanceCheck

    // construct an array containing only the input element
    function _convertToArray(uint256 element) private pure 
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    } // _convertToArray
} // ERC2272

// File: ERC2272_Tokens_DDomDiBion/DDomDiBion.sol


pragma solidity ^0.8.16;

// A smart contract based on ERC2272 which has mostly the same interface as ERC1155.



// define a smart contract that generates and manages fungible and non-fungible tokens
contract DDomDiBion is ERC2272
{
    // define the default base URI
    string private _defaultBaseURI = "ipfs://bafybeib4kreanekvdx264662kkyx3fmn7de5yf63a5vn2n3hg7wwcjmabu/DDomDiBion_";

    // create the contract, set the base URI
    constructor()
        ERC2272(_defaultBaseURI)
    {
    } // constructor
} // DDomDiBion