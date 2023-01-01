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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

// BlockTube Contract
contract BlockTube {
    // creating counter for counting the number of videos uploaded
    using Counters for Counters.Counter;
    Counters.Counter public numberVideos;

    // Structure for Video
    struct Video {
        uint256 id;
        uint256 date;
        string location;
        string title;
        string description;
        string category;
        address owner;
    }
    // Mapping videos to unique id's
    mapping(uint256 => Video) public Videos;

    // Event for uploading video
    event videoUploaded(
        uint256 id,
        uint256 date,
        string location,
        string title,
        string description,
        string category,
        address owner
    );

    /*
     * @dev Uploads the video (Save its info to Videos mapping)
     * @param _location is the ipfs address where video is saved
     * @param _title of the video
     * @param _description of the video
     * @param _category in which the video lies
     */
    function uploadVideo(
        string memory _location,
        string memory _title,
        string memory _description,
        string memory _category
    ) public {
        // Checks if the info about the video provided
        require(
            bytes(_location).length > 0 &&
                bytes(_title).length > 0 &&
                bytes(_description).length > 0 &&
                bytes(_category).length > 0,
            "Check if all the details are provided."
        );
        // Checks for the senders address
        assert(msg.sender != address(0));
        uint256 id = numberVideos.current();
        Videos[id] = Video(
            id,
            block.timestamp,
            _location,
            _title,
            _description,
            _category,
            msg.sender
        );
        numberVideos.increment();
        emit videoUploaded(
            id,
            block.timestamp,
            _location,
            _title,
            _description,
            _category,
            msg.sender
        );
    }
}