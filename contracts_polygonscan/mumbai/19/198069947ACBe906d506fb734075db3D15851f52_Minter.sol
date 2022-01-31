/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

//SPDX-License-Identifier: AGPL-3.0-or-later


// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)




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

// File: contracts/ido/IERC721Mintable.sol

// 


interface IERC721Mintable {

    function mint(address reciever) external;

    function balanceOf(address owner) external returns (uint);

}

// File: contracts/ido/Minter.sol

// 




/**
    The only contract that can mint IDOAccessERC721 NFT.
    In order to mint an NFT a user should provide a correct secret which hash output exists in hashPuzzles map.
 */
contract Minter is Ownable {

    mapping( bytes32 => bool) public hashPuzzles;
    address public immutable erc721;

    /**
        @param _erc721 address of IDOAccessERC721 contract
     */
    constructor(address _erc721) {
        erc721 = _erc721;
    }

    /**
        @notice checks if can mint NFT using the provided secret
        @param secret secret
     */
    function canMint(bytes calldata secret) external view returns (bool) {

        bytes32 hash = keccak256(secret);
        return hashPuzzles[hash];
    }

    /**
        @notice mints NFT if the provided secret is correct reverts otherwise
        @param secret secret
     */
    function mint(bytes calldata secret) external {

        bytes32 hash = keccak256(secret);
        require(hashPuzzles[hash], 'Minter: Wrong secret');
        hashPuzzles[hash] = false;
        IERC721Mintable( erc721 ).mint(msg.sender);
    }

    /**
        @notice puts new answers or updates existing ones
        @param answers array of answers
        @param isActive isActive
     */
    function pushAnswers(bytes32[] calldata answers, bool isActive) external onlyOwner {

        for (uint i = 0; i < answers.length; i++) {
            hashPuzzles[answers[i]] = isActive;
        }
    }

}