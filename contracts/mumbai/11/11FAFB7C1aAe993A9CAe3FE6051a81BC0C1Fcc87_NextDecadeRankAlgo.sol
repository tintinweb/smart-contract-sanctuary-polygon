// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";

struct Like {
    uint256 timestamps;
}

struct Comment {
    uint256 timestamps;
    string value;
}

contract NextDecadeRankAlgo is Context {
    function name() public view virtual returns (string memory) {
        return "NextDecadeRankAlgoV1";
    }

    function run(
        Like[] memory likesReceived,
        Like[] memory likesGiven,
        Comment[] memory commentsReceived,
        Comment[] memory commentsGiven
    ) public view returns (uint256) {
        return likesReceived.length + likesGiven.length + commentsReceived.length + commentsGiven.length;
    }
}

// SPDX-License-Identifier: MIT
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