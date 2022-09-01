/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: MIT


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

// File: contracts/ShapeDropper.sol


pragma solidity ^0.8.0;


interface IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
interface IERC1155 {
  function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
  function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract ShapeDropper is Ownable{
    uint256 public cost = 1 ether;
    address public keyCollectionAddress;
    uint256 public keyID;

    function airdropERC721Key(IERC721 _token, address[] calldata _to, uint256[] calldata _id) external {
        uint256 keyOwned = IERC1155(keyCollectionAddress).balanceOf(msg.sender, keyID);
        require(keyOwned > 0, "Does not own key");

        bulkAirdropERC721(_token, _to, _id);
    }

    function airdropERC1155Key(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount) external {
        uint256 keyOwned = IERC1155(keyCollectionAddress).balanceOf(msg.sender, keyID);
        require(keyOwned > 0, "Does not own key");

        bulkAirdropERC1155(_token, _to, _id, _amount);
    }

    function airdropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) external payable {
        require(msg.value == cost, "Not enough MATIC to cover the cost");

        bulkAirdropERC721(_token, _to, _id);
    }

    function airdropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount) external payable {
        require(msg.value == cost, "Not enough MATIC to cover the cost");

        bulkAirdropERC1155(_token, _to, _id, _amount);
    }

    function bulkAirdropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) internal  {
        require(_to.length == _id.length, "Receivers and IDs are different length");
        for (uint256 i = 0; i < _to.length; i++) {
        _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
        }
    }

    function bulkAirdropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount) internal {
        require(_to.length == _id.length, "Receivers and IDs are different length");
        for (uint256 i = 0; i < _to.length; i++) {
        _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
        }
    }

    //cost functions
    function withdrawBalance() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setKeyCollectionAddress(address _address, uint _id) external onlyOwner {
        keyCollectionAddress = _address;
        keyID = _id;
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}