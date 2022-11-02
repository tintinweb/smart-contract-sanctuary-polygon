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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Admin is Ownable {

    /* ----------------------------- CONSTANT ----------------------------- */

    uint256 public constant MAX_FEES = 10000;

    /* ----------------------------- VARIABLES ----------------------------- */
    
    /**
    * @dev Constant of the fees to be paid to the treasury.
    */ 
    uint256 public fees = 200;

    /**
    * @dev The address of the treasury.
    */
    address public treasury;
    
    /**
    * @dev Map of the accepted tokens as payment.
    */
    mapping(address => bool) public acceptedTokens;
    
    /* ----------------------------- CONSTRUCTOR ----------------------------- */
    constructor(address _treasury, uint256 _fees) {
        require(_treasury != address(0), "Kinetix: treasury");
        require(_fees <= MAX_FEES, "Kinetix: fees");
        treasury = _treasury;
        fees = _fees;
    }

    /* ----------------------------- VIEW FUNCTIONS ----------------------------- */

    /**
    * @notice Returns if the token is accepted as payment.
    * @param _tokenAddress The token to be checked.
    * @return True if the token is accepted as payment, false otherwise.
    */
    function isAcceptedToken(address _tokenAddress) public view returns (bool) {
        return acceptedTokens[_tokenAddress];
    }

    /* ----------------------------- OWNER FUNCTIONS ----------------------------- */

    /**
    * @notice Sets the treasury address.
    * @param _treasury The address of the treasury.
    */
    function setTreasury(address _treasury) external onlyOwner {
         require(_treasury != address(0), "Kinetix: zero address" );
         treasury = _treasury;
    }

    /**
    * @notice Sets the fees percentage.
    * @param _fees The fees percentage.
    */
    function setFees(uint256 _fees) external onlyOwner {
        require(_fees <= MAX_FEES, "Kinetix: fees greater than max");
        fees = _fees;
    }

    /**
    * @notice Sets a new accepted tokens.
    * @param _tokenAddress Address of the token to be accepted as payment.
    */
    function addToken(address _tokenAddress) external onlyOwner {
        require(acceptedTokens[_tokenAddress] == false, "Kinetix: token exists" );
        acceptedTokens[_tokenAddress] = true;
    }

    /**
    * @notice Removes an accepted token.
    * @param _tokenAddress Address of the token to be removed.
    */
    function removeToken(address _tokenAddress) external onlyOwner {
        require(acceptedTokens[_tokenAddress] == true, "Kinetix: token not accepted" );
        acceptedTokens[_tokenAddress] = false;
    }

}