// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/access/Ownable.sol";

contract Blog is Ownable {
    struct Post {
        string title;
        string ipfsUrl;
        uint256 timestamp;
    }

    mapping(uint256 => Post) public posts;
    uint256 _lastPostIndex;

    event PostCreated(uint256 id, string ipfsUrl, uint256 timestamp);

    function createPost(string memory _title, string memory _ipfsUrl) public onlyOwner {
      posts[_lastPostIndex] = Post(_title, _ipfsUrl, block.timestamp);
      _lastPostIndex++;
      emit PostCreated(_lastPostIndex - 1, _ipfsUrl, block.timestamp);
    }

    function updateTitle(uint256 _index, string memory _title) public onlyOwner {
      require(_index < _lastPostIndex, "Index out of bounds");
      Post storage post = posts[_index];
      post.title = _title;
    }

    function getAllPosts() public view returns (Post[] memory) {
      Post[] memory _posts = new Post[](_lastPostIndex);
      for (uint256 i = 0; i < _lastPostIndex; i++) {
        Post storage post = posts[i];
        _posts[i] = Post(post.title, post.ipfsUrl, post.timestamp);
      }
      return _posts;
    }

    function getPost(uint256 _index) public view returns (string memory title, string memory ipfsUrl, uint256 timestamp) {
      require(_index < _lastPostIndex, "Index out of bounds");
      Post memory post = posts[_index];
      return (post.title, post.ipfsUrl, post.timestamp);
    }

    function getPostsCount() public view returns (uint256) {
      return _lastPostIndex;
    }

    receive() external payable {
      address _owner = owner();
      uint256 amount = msg.value;

      (bool sent, ) =  _owner.call{value: amount}("");
      require(sent, "Failed to send Ether");
    }

    fallback() external payable {
      address _owner = owner();
      uint256 amount = msg.value;

      (bool sent, ) =  _owner.call{value: amount}("");
      require(sent, "Failed to send Ether");
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;

        (bool sent,) =  _owner.call{value: amount}("");

        require(sent, "Failed to send Ether");
    }
}