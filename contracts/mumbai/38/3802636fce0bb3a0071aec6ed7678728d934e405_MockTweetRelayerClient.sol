//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/oracle/ITweetRelayerClient.sol";
import "../../src/oracle/ITweetRelayer.sol";


contract MockTweetRelayerClient is ITweetRelayerClient {
    bytes32 public requestId;
    uint public value;
    uint public value2;

    ITweetRelayer private immutable _tweetRelayer;

    constructor(address tweetRelayer_) {
        _tweetRelayer = ITweetRelayer(tweetRelayer_);
    }

    function onTweetInfoReceived(bytes32 requestId_, uint value_) public {
        requestId = requestId_;
        value = value_;
    }

    function onTweetPosted(bytes32 requestId_, uint createdAt_, uint tweetId_) public{
        requestId = requestId_;
        value = createdAt_;
        value2 = tweetId_;
    }

    function requestLikeCount(uint tweetId) public {
        requestId = _tweetRelayer.requestTweetLikeCount(tweetId);
    }

    function requestTweetPublication(bytes20 postId) public {
        requestId = _tweetRelayer.requestTweetPublication(postId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

interface ITweetRelayerClient {
    /** 
    /* @notice ensure that these functions can only be called by the Twitter Relayer. Also, note that these function needs to use less than 400000 gas.
    */
    function onTweetInfoReceived(bytes32 requestId_, uint value_) external;
    function onTweetPosted(bytes32 requestId_, uint createdAt_, uint tweetId_) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

interface ITweetRelayer {

    function requestTweetData(string memory tweetId_, string memory fields_, string memory path_) external returns (bytes32 requestId);
    function requestTweetLikeCount(uint tweetId_) external returns (bytes32 requestId);
    function requestTweetPublication(bytes20 postId_) external returns (bytes32 requestId);
}