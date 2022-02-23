//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/utils/Counters.sol";

contract Blog {
    string public name;
    address public owner;
    using Counters for Counters.Counter;
    Counters.Counter private _postIds;

    struct Post {
      uint id;
      string title;
      string content;
      bool published;
    }

    mapping(uint => Post) private idToPost;
    mapping(string => Post) private hashToPost;

    event PostCreated(uint id, string title, string hash);
    event PostUpdated(uint id, string title, string hash, bool published);

    modifier onlyOwner() {
        require(msg.sender == owner, "This function is only for owner");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    }

    function updateName(string memory _name) public {
        name = _name;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function fetchPost(string memory hash) public view returns(Post memory){
        return hashToPost[hash];
    }

    function createPost(string memory title, string memory hash) public onlyOwner {
        _postIds.increment();
        uint postId = _postIds.current();

        Post storage post = idToPost[postId];

        post.id = postId;
        post.title = title;
        post.published = true;
        post.content = hash;
        hashToPost[hash] = post;

        emit PostCreated(postId, title, hash);
    }

    function updatePost(uint postId, string memory title, string memory hash, bool published) public onlyOwner {
        Post storage post =  idToPost[postId];

        post.title = title;
        post.published = published;
        post.content = hash;
        idToPost[postId] = post;
        hashToPost[hash] = post;
        
        emit PostUpdated(post.id, title, hash, published);
    }

    function fetchPosts() public view returns (Post[] memory) {
        uint itemCount = _postIds.current();
        uint currentIndex = 0;

        Post[] memory posts = new Post[](itemCount);

        for (uint i = 0; i < itemCount; i++) {
            uint currentId = i + 1;
            Post storage currentItem = idToPost[currentId];
            posts[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return posts;
    }

    receive() external payable {}

    function withdrawFunds() public payable onlyOwner {
        require(msg.sender != address(0), "Caller should be the owner");
        require(address(this).balance > 0, "No one tip you :(");
        payable(msg.sender).transfer(address(this).balance);
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