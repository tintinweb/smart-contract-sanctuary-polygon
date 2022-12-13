pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "./lib/EIP712Base.sol";
import "./lib/SafeMath.sol";

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
		uint256 nonce;
		address from;
        bytes functionSignature;
	}

    constructor(string memory name, string memory version) public EIP712Base(name, version) {}

    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {

        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
	nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress, msg.sender));

        require(success, "Function call not successfull");
        emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal view returns (bytes32) {
		return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
	}

    function getNonce(address user) public view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
	return signer == user;
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes20 userAddress;
            bytes memory data = msg.data;
            uint256 dataLength = msg.data.length;
            assembly {
                calldatacopy(0x0, sub(dataLength, 40), sub(dataLength, 20))
                userAddress := mload(0x0)
            }
            sender = address(uint160(userAddress));
        } else {
            sender = msg.sender;
        }
    }

    function msgRelayer() internal view returns(address relayer) {
        if(msg.sender == address(this)) {
            bytes20 relayerAddress;
            bytes memory data = msg.data;
            uint256 dataLength = msg.data.length;
            assembly {
                calldatacopy(0x0, sub(dataLength, 20), dataLength)
                relayerAddress := mload(0x0)
            }
            relayer = address(uint160(relayerAddress));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.13;

pragma experimental ABIEncoderV2;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

import "./EIP712MetaTransaction.sol";

contract TestContract is EIP712MetaTransaction("TestContract", "1") {
    string public quote;
    address public owner;
    IERC20 usdt;
    IERC20 usdc;

    struct userbalance {
        uint256 usdt;
        uint256 usdc;
    }
    struct Bet {
        uint256 id;
        uint256 odds;
        uint256 stake;
        string bet_type;
        string bet_status; // Active, Claimable, Win, Loss
        uint256 currency;
    }
    mapping(address => userbalance) public balance;
    Bet[] public Betlist;
    mapping(address => Bet) public betlist;

    //["1","127","110","money3way","active","1"]

    constructor(address _usdt, address _usdc) public {
        usdt = IERC20(_usdt);
        usdc = IERC20(_usdc);
    }

    function depositusdt(address a, uint256 amount) public {
        usdt.transferFrom(msgSender(), a, amount);
        balance[msgSender()].usdt += amount;
        //TRANFER VALUES TO CONTRACT
    }

    function depositusdc(address a, uint256 amount) public {
        usdc.transferFrom(msgSender(), a, amount);
        balance[msgSender()].usdc += amount;
        //TRANFER VALUES TO CONTRACT
    }

    function palcebet(
        // uint256 amount,uint8 _option
        Bet memory _bet
    ) public {
        Bet memory bet = Bet(
            _bet.id,
            _bet.odds,
            _bet.stake,
            _bet.bet_type,
            _bet.bet_status,
            _bet.currency
        );
        Betlist.push(bet);
        if (_bet.currency == 0) {
            balance[msgSender()].usdt -= _bet.stake;
        } else {
            balance[msgSender()].usdt -= _bet.stake;
        }

        //state updation
    }

    function claim(uint256 amount, uint8 _option) public {
        if (_option == 0) {
            balance[msgSender()].usdt += amount;
        } else {
            balance[msgSender()].usdt += amount;
        }
        //state updation
    }

    function withdrawusdt(uint256 amount) public {
        usdt.transfer(msgSender(), amount);
        balance[msgSender()].usdt -= amount;
        //transfervalues from contract to userwallet of usdt
    }

    function withdrawusdc(uint256 amount) public {
        usdt.transfer(msgSender(), amount);
        balance[msgSender()].usdc -= amount;
        //transfervalues from contract to userwallet usdc
    }

    function getbet(address _user) external view returns (Bet memory) {
        return betlist[_user];
    }
}

pragma solidity ^0.5.13;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    bytes32 internal domainSeperator;

    constructor(string memory name, string memory version) public {
        domainSeperator = keccak256(abi.encode(
			EIP712_DOMAIN_TYPEHASH,
			keccak256(bytes(name)),
			keccak256(bytes(version)),
			getChainID(),
			address(this)
		));
    }

    function getChainID() internal pure returns (uint256 id) {
		assembly {
			id := 80001
		}
	}

    function getDomainSeperator() private view returns(bytes32) {
		return domainSeperator;
	}

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash));
    }

}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}