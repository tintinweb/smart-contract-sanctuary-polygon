// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Dtelecom {
    event InitCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id, uint256 _price);
    event ConfirmCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id, uint256 _price);
    event StartCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id, uint256 _price);
    event AnswerCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id, uint256 _price);
    event EndCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id, uint256 _price);

    struct Node{
        string ip;
        string pattern;
        uint256 price;
        address owner;
        uint256 id;
    }

    struct Call{
        address from;
        string number;
        uint256 node_id;
        uint256 id;
        uint256 state;
        uint256 answerAt;
        uint256 endAt;
        uint256 price;
    }

    using Counters for Counters.Counter;

    Counters.Counter private _nodeSeqCounter;
    Counters.Counter private _callSeqCounter;

    IERC20 public busd;
    uint256 public minimal_prepay;
    uint256 public minimal_redeem;
    uint256 public minimal_duration;

    mapping(address => uint256) public prepay_values;
    mapping(uint256 => Node) public nodes;
    mapping(uint256 => Call) public calls;

    constructor(address _token_address, uint256 _minimal_prepay, uint256 _minimal_redeem, uint256 _minimal_duration) {
        busd = IERC20(_token_address);
        minimal_prepay = _minimal_prepay;
        minimal_redeem = _minimal_redeem;
        minimal_duration = _minimal_duration;
    }
    
    function prepay(uint256 value) public {
        require(value >= minimal_prepay, "Less than minimal_prepay");
        
        require(busd.balanceOf(msg.sender) >= value, "Not enough tokens");
        busd.transferFrom(msg.sender, address(this), value);

        prepay_values[msg.sender] += value;
    }
    
    function redeemPrepay() public {
        uint256 amount = prepay_values[msg.sender];
        require(amount >= minimal_redeem, "Less than minimal_redeem");

        busd.transfer(msg.sender, amount);

        prepay_values[msg.sender] = 0;
    }

    function addNode(string memory ip, string memory pattern, uint256 price) public {
        uint256 id = _nodeSeqCounter.current();
        nodes[id] = Node(
            ip,
            pattern,
            price,
            msg.sender,
            id
        );
        _nodeSeqCounter.increment();
    }

    function myBalance() public view returns (uint256) {
        return prepay_values[msg.sender];
    }

    function getNodes() public view returns(Node[] memory) {
        Node[] memory _toReturn;
        uint256 lastNodeId = _nodeSeqCounter.current();
        if (lastNodeId > 0) {
            _toReturn = new Node[](lastNodeId);
            for (uint i = 0; i < lastNodeId; i++) {
                _toReturn[i] = nodes[i];
            }
        }
        return _toReturn;
    }

    function initCall(string memory number, uint256 node_id, address from) public {
        Node memory node = nodes[node_id];
        require(node.owner == msg.sender, "Only node owner allowed");

        uint256 amount = prepay_values[from];
        uint256 min_amount = node.price * minimal_duration;
        require(amount >= min_amount, "Not enough balance");

        uint256 call_id = _callSeqCounter.current();
        calls[call_id] = Call(
            from,
            number,
            node_id,
            call_id,
            0,
            0,
            0,
            node.price
        );

        emit InitCall(from, number, node_id, call_id, node.price);
        _callSeqCounter.increment();
    }

    function confirmCall(uint256 call_id) public {
        Call memory call = calls[call_id];

        require(call.from == msg.sender, "Only call owner allowed");
        require(call.state == 0, "Available only for 0 state");

        calls[call_id].state = 1;

        emit ConfirmCall(call.from, call.number, call.node_id, call.id, call.price);
    }

    function startCall(uint256 call_id) public {
        Call memory call = calls[call_id];
        require(call.state == 1, "Available only for 1 state");

        Node memory node = nodes[call.node_id];
        require(node.owner == msg.sender, "Only node owner allowed");

        calls[call_id].state = 2;

        emit StartCall(call.from, call.number, call.node_id, call.id, call.price);
    }

    function answerCall(uint256 call_id) public {
        Call memory call = calls[call_id];
        require(call.state == 2, "Available only for 2 state");

        Node memory node = nodes[call.node_id];
        require(node.owner == msg.sender, "Only node owner allowed");

        calls[call_id].answerAt = block.timestamp;

        emit AnswerCall(call.from, call.number, call.node_id, call.id, call.price);
    }

    function endCall(uint256 call_id) public {
        Call memory call = calls[call_id];
        require(call.state == 2, "Available only for 2 state");

        Node memory node = nodes[call.node_id];
        require(node.owner == msg.sender, "Only node owner allowed");

        uint256 endAt = block.timestamp;

        if (call.answerAt > 0) {
            uint256 diff = endAt - call.answerAt;
            uint256 amount = diff * node.price;
            if (prepay_values[call.from] < amount) {
                amount = prepay_values[call.from];
            }
            prepay_values[msg.sender] += amount;
            prepay_values[call.from] -= amount;
        }

        calls[call_id].endAt = endAt;

        emit EndCall(call.from, call.number, call.node_id, call.id, call.price);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";