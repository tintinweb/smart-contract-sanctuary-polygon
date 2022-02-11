// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Dtelecom {
    event InitCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id);
    event ConfirmCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id);
    event StartCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id);
    event AnswerCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id);
    event EndCall(address indexed _from, string _number, uint256 _node_id, uint256 _call_id);

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
        uint256 startAt;
        uint256 answerAt;
        uint256 endAt;
    }

    using Counters for Counters.Counter;

    Counters.Counter private _nodeSeqCounter;
    Counters.Counter private _callSeqCounter;

    IERC20 public busd;
    uint256 public minimal_prepay;
    uint256 public minimal_redeem;

    mapping(address => uint256) public prepay_values;
    mapping(uint256 => Node) public nodes;
    mapping(uint256 => Call) public calls;

    constructor(address _token_address, uint256 _minimal_prepay, uint256 _minimal_redeem) {
        busd = IERC20(_token_address);
        minimal_prepay = _minimal_prepay;
        minimal_redeem = _minimal_redeem;
    }
    
    function prepay(uint256 value) public {
        require(value >= minimal_prepay);
        
        require(busd.balanceOf(msg.sender) >= value);
        busd.transferFrom(msg.sender, address(this), value);

        prepay_values[msg.sender] += value;
    }
    
    function redeemPrepay() public {
        uint256 amount = prepay_values[msg.sender];
        require(amount >= minimal_redeem);

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
        require(nodes[node_id].owner == msg.sender);
        uint256 amount = prepay_values[from];
        require(amount >= nodes[node_id].price);

        uint256 call_id = _callSeqCounter.current();
        calls[call_id] = Call(
            from,
            number,
            node_id,
            call_id,
            0,
            0,
            0,
            0
        );

        emit InitCall(from, number, node_id, call_id);
        _callSeqCounter.increment();
    }

    function confirmCall(uint256 call_id) public {
        require(calls[call_id].from == msg.sender);
        require(calls[call_id].state == 0);
        calls[call_id].state = 1;

        emit ConfirmCall(calls[call_id].from, calls[call_id].number, calls[call_id].node_id, calls[call_id].id);
    }

    function startCall(uint256 call_id) public {
        require(nodes[calls[call_id].node_id].owner == msg.sender);
        require(calls[call_id].state == 1);
        calls[call_id].state = 2;
        calls[call_id].startAt = block.timestamp;

        emit StartCall(calls[call_id].from, calls[call_id].number, calls[call_id].node_id, calls[call_id].id);
    }

    function answerCall(uint256 call_id) public {
        require(nodes[calls[call_id].node_id].owner == msg.sender);
        require(calls[call_id].state == 2);
        calls[call_id].answerAt = block.timestamp;

        emit AnswerCall(calls[call_id].from, calls[call_id].number, calls[call_id].node_id, calls[call_id].id);
    }

    function endCall(uint256 call_id) public {
        require(nodes[calls[call_id].node_id].owner == msg.sender);
        require(calls[call_id].state == 2);
        calls[call_id].endAt = block.timestamp;

        if (calls[call_id].answerAt > 0) {
            uint256 diff = calls[call_id].endAt - calls[call_id].answerAt;
            uint256 amount = diff * nodes[calls[call_id].node_id].price;
            prepay_values[msg.sender] += amount;
            prepay_values[calls[call_id].from] -= amount;
        }

        emit EndCall(calls[call_id].from, calls[call_id].number, calls[call_id].node_id, calls[call_id].id);
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