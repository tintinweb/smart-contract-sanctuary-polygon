// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

contract DWiki {
  using Counters for Counters.Counter;
  Counters.Counter private _videoCount;

  string public name = "DWiki";
  mapping(uint256 => Video) public videos;

  struct Video {
    uint256 id;
    string hash;
    string title;
    address author;
  }

  event VideoUploaded(
    uint indexed id,
    string hash,
    string title,
    address author
  );

  constructor() {}

  function uploadVideo(string memory _videoHash, string memory _title) public {
    // Make sure video hash exists
    require(bytes(_videoHash).length > 0);
    // Make sure video title exists
    require(bytes(_title).length > 0);
    // Make sure uploader address exists
    require(msg.sender != address(0));

    _videoCount.increment();

    // Add video to the contract
    videos[_videoCount.current()] = Video(_videoCount.current(), _videoHash, _title, msg.sender);
    emit VideoUploaded(_videoCount.current(), _videoHash, _title, msg.sender);
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