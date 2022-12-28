/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

// This contract handles RPTR bridging between RaptorChain and Polygon (might be forked to other chains in the future)
// Thus, it allows trading RPTR on polygon-based DEXes (e.g. SushiSwap/QuickSwap)

// calls follow the following path

// WRAP
// - RaptorChain-side custody contract (holds RPTR) calls RaptorChain-side datafeed (address(0xfeed))
// - RaptorChain-side datafeed throws a cross-chain message
// - a RaptorChain masternode includes it into a beacon block
// - beacon block gets forwarded to Polygon-side handler
// - handler unpacks call and calls token contract
// - token contract mints token

// UNWRAP
// - user calls `unwrap` method
// - contract burns polygon-side token
// - contract writes data to a slot on polygon-side datafeed (slots can be accessed by raptorchain-side contracts)
// - raptorchain-side custody contract calls raptorchain-side datafeed, which returns slot data
// - raptorchain-side custody contract marks slot as processed (to avoid getting it processed twice)
// - raptorchain-side custody sends RPTR to recipient

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

interface CrossChainFallback {
	function crossChainCall(address from, bytes memory data) external;
}

interface DataFeedInterface {
	function write(bytes32 variableKey, bytes memory slotData) external returns (bytes32);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
	event OwnershipRenounced();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
	
	function _chainId() internal pure returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}
	
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
	
	function renounceOwnership() public onlyOwner {
		owner = address(0);
		newOwner = address(0);
		emit OwnershipRenounced();
	}
}

contract BridgedRaptor is Owned {
	using SafeMath for uint256;

	address public operator;	// operator on other side of the bridge
	address public bridge;		// bridge
	
	uint256 systemNonce;
	uint256 public totalSupply;	// starts at 0, minted on bridging
	uint8 public decimals = 18;
	string public name = "Bridged RPTR";
	string public symbol = "RPTR";

	struct Account {
		uint256 balance;
		mapping(address => uint256) allowances;
		bytes32[] unwraps;	// unwrap history sorted by storage slot
	}
	
	mapping(address => Account) public accounts;
	
	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	
	event Wrap(address indexed to, uint256 tokens);
	event UnWrap(address indexed from, address indexed to, bytes32 indexed slotKey, uint256 tokens);

	event OperatorChanged(address indexed newOperator);
	event BridgeChanged(address indexed newBridge);

	modifier onlyOperator(address from) {
		require((msg.sender == bridge) && (from == operator), "ONLY_OPERATOR_CAN_DO_THAT");
		_;
	}
	
	function setOperator(address _operator) public onlyOwner {
		operator = _operator;
		emit OperatorChanged(_operator);
	}
	
	function setBridge(address _bridge) public onlyOwner {
		bridge = _bridge;
		emit BridgeChanged(_bridge);
	}
	
	// system private functions
	function _mint(address to, uint256 tokens) private {
		accounts[to].balance = accounts[to].balance.add(tokens);
		totalSupply = totalSupply.add(tokens);
		emit Transfer(address(0), to, tokens);
	}
	
	function _burn(address from, uint256 tokens) private {
		accounts[from].balance = accounts[from].balance.sub(tokens, "UNSUFFICIENT_BALANCE");
		totalSupply = totalSupply.sub(tokens);
		emit Transfer(from, address(0), tokens);
	}
	
	function _unwrap(address from, address to, uint256 tokens) private {
		_burn(from, tokens);
		bytes32 key = keccak256(abi.encodePacked(to, systemNonce));
		bytes memory data = abi.encode(to, tokens);
		bytes32 slotKey = DataFeedInterface(bridge).write(key, data);
		accounts[to].unwraps.push(slotKey);
		emit UnWrap(from, to, slotKey, tokens);
		systemNonce += 1;
	}
	
	function _transfer(address from, address to, uint256 tokens) private {
		if (to == address(0)) {
			_unwrap(from, from, tokens);
		} else {
			accounts[from].balance = accounts[from].balance.sub(tokens, "UNSUFFICIENT_BALANCE");
			accounts[to].balance = accounts[to].balance.add(tokens);
			emit Transfer(from, to, tokens);
		}
	}
	
	// cross-chain call handler	
	function crossChainCall(address from, bytes memory data) public onlyOperator(from) {
		(address to, uint256 tokens) = abi.decode(data, (address, uint256)); // encoder on raptorchain-side ; data = abi.encode(to, coins)
		_mint(to, tokens);
		emit Wrap(to, tokens);
	}
	
	// user-side view functions
	function allowance(address tokenOwner, address spender) public view returns (uint256) {
		return accounts[tokenOwner].allowances[spender];
	}
	
	function balanceOf(address tokenOwner) public view returns (uint256) {
		return accounts[tokenOwner].balance;
	}
	
	function unwrapHistoryOf(address tokenOwner) public view returns (bytes32[] memory) {
		return accounts[tokenOwner].unwraps;
	}
	
	
	// user-side functions
	function approve(address spender, uint256 tokens) public returns (bool) {
		Account storage ownerAcct = accounts[msg.sender];
		ownerAcct.allowances[spender] = ownerAcct.allowances[spender].add(tokens);
		emit Approval(msg.sender, spender, tokens);
		return true;
	}
	
	function transfer(address to, uint256 tokens) public returns (bool) {
		_transfer(msg.sender, to, tokens);
		return true;
	}
	
	function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
		Account storage ownerAcct = accounts[from];
		ownerAcct.allowances[msg.sender] = ownerAcct.allowances[msg.sender].sub(tokens, "UNSUFFICIENT_ALLOWANCE");
		_transfer(from, to, tokens);
		return true;
	}
	
	function unwrap(uint256 tokens) public {
		_unwrap(msg.sender, msg.sender, tokens);
	}
	
	function unwrap(address to, uint256 tokens) public {
		_unwrap(msg.sender, to, tokens);
	}
}