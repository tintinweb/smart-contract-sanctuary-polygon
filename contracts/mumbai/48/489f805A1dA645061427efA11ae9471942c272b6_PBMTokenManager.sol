// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./IPBMTokenManager.sol";
import "./NoDelegateCall.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PBMTokenManager is Ownable, IPBMTokenManager, NoDelegateCall {
    using Strings for uint256;

    // counter used to create new token types
    uint256 internal tokenTypeCount = 0 ; 

    // structure representing all the details of a PBM type
    struct TokenConfig {
        string name ; 
        uint256 amount ; 
        uint256 expiry ; 
        address creator ; 
        uint256 balanceSupply ; 
        string uri ;
        string postExpiryURI;
    }

    // mapping of token ids to token details
    mapping (uint256 => TokenConfig) internal tokenTypes ; 

    constructor(){}

    /**
     * @dev See {IPBMTokenManager-createPBMTokenType}.
     *
     * Requirements:
     *
     * - caller must be owner ( PBM contract )
     * - contract must not be expired
     * - token expiry must be less than contract expiry
     * - `amount` should not be 0
     */ 
    function createTokenType(string memory companyName, uint256 spotAmount, uint256 tokenExpiry, address creator, string memory tokenURI, string memory postExpiryURI,uint256 contractExpiry)
    external 
    override 
    onlyOwner
    noDelegateCall
    {   
        require(tokenExpiry <= contractExpiry, "Invalid token expiry-1") ; 
        require(tokenExpiry > block.timestamp , "Invalid token expiry-2") ; 
        require(spotAmount != 0 , "Spot amount is 0") ;  

        string memory tokenName = string(abi.encodePacked(companyName,spotAmount.toString())) ; 
        tokenTypes[tokenTypeCount].name = tokenName ; 
        tokenTypes[tokenTypeCount].amount = spotAmount ; 
        tokenTypes[tokenTypeCount].expiry = tokenExpiry ; 
        tokenTypes[tokenTypeCount].creator = creator ; 
        tokenTypes[tokenTypeCount].balanceSupply = 0 ; 
        tokenTypes[tokenTypeCount].uri = tokenURI ;
        tokenTypes[tokenTypeCount].postExpiryURI = postExpiryURI ;

        emit NewPBMTypeCreated(tokenTypeCount, tokenName, spotAmount, tokenExpiry, creator);
        tokenTypeCount += 1 ;
    }

    /**
     * @dev See {IPBMTokenManager-revokePBM}.
     *
     * Requirements:
     *
     * - caller must be owner ( PBM contract )
     * - token must be expired
     * - `tokenId` should be a valid id that has already been created
     * - `sender` must be the token type creator
     */ 
    function revokePBM(uint256 tokenId, address sender)
    external
    override
    onlyOwner
    {
        
        require (sender == tokenTypes[tokenId].creator && block.timestamp >= tokenTypes[tokenId].expiry, "PBM not revokable") ;
        tokenTypes[tokenId].balanceSupply = 0 ; 
    }

    /**
     * @dev See {IPBMTokenManager-increaseBalanceSupply}.
     *
     * Requirements:
     *
     * - caller must be owner ( PBM contract )
     * - `tokenId` should be a valid id that has already been created
     * - `sender` must be the token type creator
     */ 
    function increaseBalanceSupply(uint256[] memory tokenIds, uint256[] memory amounts)
    external
    override
    onlyOwner
    {  
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenTypes[tokenIds[i]].amount!=0 && block.timestamp < tokenTypes[tokenIds[i]].expiry, "PBM: Invalid Token Id(s)"); 
            tokenTypes[tokenIds[i]].balanceSupply += amounts[i] ;
        }
    }

    /**
     * @dev See {IPBMTokenManager-decreaseBalanceSupply}.
     *
     * Requirements:
     *
     * - caller must be owner ( PBM contract )
     * - `tokenId` should be a valid id that has already been created
     * - `sender` must be the token type creator
     */ 
    function decreaseBalanceSupply(uint256[] memory tokenIds, uint256[] memory amounts)
    external 
    override
    onlyOwner
    {   
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenTypes[tokenIds[i]].amount!=0 && block.timestamp < tokenTypes[tokenIds[i]].expiry, "PBM: Invalid Token Id(s)"); 
            tokenTypes[tokenIds[i]].balanceSupply -= amounts[i] ;
        }
    }

    /**
     * @dev See {IPBMTokenManager-uri}.
     *
     */ 
    function uri(uint256 tokenId)
    external
    override
    view
    returns (string memory)
    {
        if (block.timestamp >= tokenTypes[tokenId].expiry){
            return tokenTypes[tokenId].postExpiryURI ;
        }
        return tokenTypes[tokenId].uri ; 
    }

    /**
     * @dev See {IPBMTokenManager-areTokensValid}.
     *
     */ 
    function areTokensValid(uint256[] memory tokenIds) 
    external 
    override
    view 
    returns (bool) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (block.timestamp > tokenTypes[i].expiry || tokenTypes[i].amount == 0){
                return false ; 
            }
        } 
        return true ; 
    }   

    /**
     * @dev See {IPBMTokenManager-getTokenDetails}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */ 
    function getTokenDetails(uint256 tokenId) 
    external 
    override
    view 
    returns (string memory, uint256, uint256, address) 
    {
        require(tokenTypes[tokenId].amount!=0, "PBM: Invalid Token Id(s)"); 
        return (tokenTypes[tokenId].name, tokenTypes[tokenId].amount, tokenTypes[tokenId].expiry, tokenTypes[tokenId].creator) ; 
    }

    /**
     * @dev See {IPBMTokenManager-getPBMRevokeValue}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */ 
    function getPBMRevokeValue(uint256 tokenId)
    external 
    override 
    view 
    returns (uint256)
    {
        require(tokenTypes[tokenId].amount!=0, "PBM: Invalid Token Id(s)"); 
        return tokenTypes[tokenId].amount*tokenTypes[tokenId].balanceSupply; 
    }

    /**
     * @dev See {IPBMTokenManager-getTokenValue}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */ 
    function getTokenValue(uint256 tokenId)
    external 
    override
    view 
    returns (uint256) {
        require(tokenTypes[tokenId].amount!=0 && block.timestamp < tokenTypes[tokenId].expiry, "PBM: Invalid Token Id(s)"); 
        return tokenTypes[tokenId].amount ; 
    }

    /**
     * @dev See {IPBMTokenManager-getTokenCount}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */ 
    function getTokenCount(uint256 tokenId)
    external 
    override
    view 
    returns (uint256) {
        require(tokenTypes[tokenId].amount!=0 && block.timestamp < tokenTypes[tokenId].expiry, "PBM: Invalid Token Id(s)"); 
        return tokenTypes[tokenId].balanceSupply ; 
    }

    /**
     * @dev See {IPBMTokenManager-getTokenCreator}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */ 
    function getTokenCreator(uint256 tokenId)
    external 
    override
    view 
    returns (address) {
        require(tokenTypes[tokenId].amount!=0 && block.timestamp < tokenTypes[tokenId].expiry, "PBM: Invalid Token Id(s)"); 
        return tokenTypes[tokenId].creator ; 
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original, "Delegate calls restricted");
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PBMTokenManager Interface. 
/// @notice The PBMTokenManager is the stores details of the different data types. 
interface IPBMTokenManager {
    /// @notice Returns the URI (metadata) for the PBM with the corresponding tokenId
    /// @param tokenId The id for the PBM in query
    /// @return Returns the metadata URI for the PBM
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Checks if tokens Ids have been created and are not expired
    /// @param tokenIds The ids for the PBM in query
    /// @return Returns true if all the tokenId are valid else false
    function areTokensValid(uint256[] memory tokenIds) external view returns (bool) ; 
    
    /// @notice gets the total value of underlying ERC20 tokens the PBM type holds 
    /// @param tokenId The id for the PBM in query
    /// @return Returns the total ERC20 amount
    function getPBMRevokeValue(uint256 tokenId) external view returns (uint256); 

    /// @notice gets the amount of underlying ERC20 tokens each of the the PBM type holds 
    /// @param tokenId The id for the PBM in query
    /// @return Returns the underlying ERC20 amount
    function getTokenValue(uint256 tokenId) external view returns (uint256); 

    /// @notice gets the count of the PBM type in supply 
    /// @param tokenId The id for the PBM in query
    /// @return Returns the count of the PBM
    function getTokenCount(uint256 tokenId) external view returns (uint256); 

    /// @notice gets the address of the creator of the PBM type 
    /// @param tokenId The id for the PBM in query
    /// @return Returns the address of the creator
    function getTokenCreator(uint256 tokenId) external view returns (address); 
    
    /// @notice Retreive the details for a PBM
    /// @param tokenId The id for the PBM in query
    /// @return name The name of the PBM type
    /// @return spotAmount Amount of underlying ERC20 held by the each of the PBM token
    /// @return expiry  Expiry time (in epoch) for the PBM type
    /// @return creator Creator for the PBM type
    function getTokenDetails(uint256 tokenId) external view returns (string memory name, uint256 spotAmount, uint256 expiry, address creator);

    /// @notice Creates a PBM token type, with all its necessary details
    /// @param companyName The name of the company/agency issuing this PBM type
    /// @param spotAmount The number of ERC-20 tokens that is used as the underlying currency for PBM
    /// @param tokenExpiry The expiry date (in epoch) of th PBM type
    /// @param creator The address of the account that creates the PBM type
    /// @param tokenURI the URI containting the metadata (opensea standard for ERC1155) for the  PBM type
    /// @param postExpiryURI the URI containting the metadata (opensea standard for ERC1155) for the expired PBM type
    /// @param contractExpiry the expiry time (in epoch) for the overall PBM contract
    function createTokenType(
        string memory companyName, 
        uint256 spotAmount, 
        uint256 tokenExpiry, 
        address creator,
        string memory tokenURI,
        string memory postExpiryURI,
        uint256 contractExpiry
    ) external ; 

    /// @notice increases the supply count for the PBM 
    /// @param tokenIds The ids for which the supply count needs to be increased
    /// @param amounts The amounts by whch the supply counnt needs to be increased
    function increaseBalanceSupply(
        uint256[] memory tokenIds, 
        uint256[] memory  amounts
    ) external;

    /// @notice decreases the supply count for the PBM 
    /// @param tokenIds The ids for which the supply count needs to be decreased
    /// @param amounts The amounts by whch the supply counnt needs to be decreased
    function decreaseBalanceSupply(
        uint256[] memory tokenIds, 
        uint256[] memory  amounts
    ) external;

    /// @notice  performs all the necessary actions required after the revoking of a PBM type
    /// @param tokenId The PBM tokenId which has been revoked
    /// @param sender updated token URI to convey revoking, if part of design
    function revokePBM(
        uint256 tokenId, 
        address sender
    ) external; 

    /// @notice Event emitted when a new PBM token type is created
    /// @param tokenId The account from which the tokens were sent, i.e. the balance decreased
    /// @param tokenName The account to which the tokens were sent, i.e. the balance increased
    /// @param amount The amount of tokens that were transferred
    /// @param expiry The time (in epoch) when the PBM type will expire
    /// @param creator The creator of the this PBM type
    event NewPBMTypeCreated(uint256 tokenId, string tokenName, uint256 amount, uint256 expiry, address creator);
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