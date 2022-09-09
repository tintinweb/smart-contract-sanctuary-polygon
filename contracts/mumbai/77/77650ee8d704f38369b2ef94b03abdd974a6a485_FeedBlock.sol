// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract FeedBlock {
    uint256 callId;
    mapping(uint256 => Call) public calls;
    mapping(address => mapping(address => uint256)) public balances;

    struct Call {
        uint256 id;
        address host;
        address guest;
        uint256 startTime;
        uint256 duration;
        uint256 paymentAmount;
        address paymentToken;
        bool accepted;
        bool cancelled;
        bool guestJoined;
        bool hostJoined;
        uint256 actualStartTimestamp;
        uint256 actualEndTimestamp;
    }

    event CallCreated(
        uint256 id,
        address host,
        address guest,
        uint256 startTime,
        uint256 duration,
        uint256 paymentAmount,
        address paymentToken
    );

    event CallAccepted(uint256 id);
    event CallCancelled(uint256 id);
    event GuestJoined(uint256 id);
    event HostJoined(uint256 id);
    event CallEnded(uint256 id, uint256 paymentAmount);

    function createCall(
        address guest,
        uint256 startTime,
        uint256 duration,
        uint256 paymentAmount,
        address paymentToken
    ) public {
        Call memory newCall;
        newCall.host = msg.sender;
        newCall.guest = guest;
        newCall.startTime = startTime;
        newCall.duration = duration;
        newCall.paymentAmount = paymentAmount;
        newCall.paymentToken = paymentToken;
        newCall.accepted = false;
        newCall.cancelled = false;
        newCall.guestJoined = false;
        newCall.hostJoined = false;
        newCall.actualStartTimestamp = 0;
        newCall.actualEndTimestamp = 0;

        calls[callId] = newCall;

        deposit(paymentToken, paymentAmount);

        emit CallCreated(
            callId,
            newCall.host,
            newCall.guest,
            newCall.startTime,
            newCall.duration,
            newCall.paymentAmount,
            newCall.paymentToken
        );
        callId++;
    }

    function acceptCall(uint256 id) public {
        require(calls[id].guest == msg.sender, "Message sender is not the call guest");
        calls[id].accepted = true;
        emit CallAccepted(id);
    }

    function cancelCall(uint256 id) public {
        require(
            (calls[id].guest == msg.sender || calls[id].host == msg.sender),
            "Message sender is not the call guest or host"
        );
        require(calls[id].actualStartTimestamp == 0, "Call is already started");

        withdraw(calls[id].paymentToken, calls[id].paymentAmount, calls[id].host, calls[id].host);

        calls[id].cancelled = true;
        emit CallCancelled(id);
    }

    function startCall(uint256 id) public {
        require(
            (calls[id].guest == msg.sender || calls[id].host == msg.sender),
            "Message sender is not the call guest or host"
        );
        require(block.timestamp > calls[id].startTime - 300, "Too early to start call");
        if (calls[id].guest == msg.sender) {
            calls[id].guestJoined = true;
            emit GuestJoined(id);
        } else {
            calls[id].hostJoined = true;
            emit HostJoined(id);
        }

        if (calls[id].guestJoined == true && calls[id].hostJoined == true) {
            calls[id].actualStartTimestamp = block.timestamp;
        }
    }

    function endCall(uint256 id, bool fullPayment) public {
        require((calls[id].host == msg.sender), "Message sender is not the call host");
        require(calls[id].actualStartTimestamp > 0, "Call was not started");

        calls[id].actualEndTimestamp = block.timestamp;

        uint256 paymentAmount = calls[id].paymentAmount;
        uint256 refundAmount = 0;

        if (!fullPayment) {
            paymentAmount = callPaymentAmount(id);
            refundAmount = calls[id].paymentAmount - paymentAmount;
        }

        withdraw(calls[id].paymentToken, paymentAmount, calls[id].host, calls[id].guest);
        withdraw(calls[id].paymentToken, refundAmount, calls[id].host, calls[id].host);

        emit CallEnded(id, paymentAmount);
    }

    function callPaymentAmount(uint256 id) internal view returns (uint256) {
        uint256 actualCallLength = calls[id].actualEndTimestamp - calls[id].actualStartTimestamp;

        uint256 paymentAmount = (actualCallLength * calls[id].paymentAmount) / calls[id].duration;
        return paymentAmount;
    }

    function withdraw(
        address token,
        uint256 amount,
        address from,
        address to
    ) internal {
        balances[token][from] -= amount;
        IERC20(token).transfer(to, amount);
    }

    function deposit(address token, uint256 amount) internal {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[token][msg.sender] += amount;
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