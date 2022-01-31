// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Proprietor.sol";

/**
 * @title TCAP Treasury
 * @author Cryptex.finance
 * @notice This contract will hold the assets generated on L2 networks.
 */
contract ITreasury is Proprietor {
	/// @notice An event emitted when a transaction is executed
	event TransactionExecuted(
		address indexed target,
		uint256 value,
		string signature,
		bytes data
	);


	/**
	 * @notice Constructor
	 * @param _owner the owner of the contract
	 */
	constructor(address _owner) Proprietor(_owner) {}

	/**
	 * @notice Allows the owner to execute custom transactions
	 * @param target address
	 * @param value uint256
	 * @param signature string
	 * @param data bytes
	 * @dev Only owner can call it
	 */
	function executeTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data
	) external payable onlyOwner returns (bytes memory) {
		bytes memory callData;
		if (bytes(signature).length == 0) {
			callData = data;
		} else {
			callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
		}

		require(
			target != address(0),
			"ITreasury::executeTransaction: target can't be zero"
		);

		// solium-disable-next-line security/no-call-value
		(bool success, bytes memory returnData) =
		target.call{value : value}(callData);
		require(
			success,
			"ITreasury::executeTransaction: Transaction execution reverted."
		);

		emit TransactionExecuted(target, value, signature, data);
		(target, value, signature, data);

		return returnData;
	}

	/**
	 * @notice Retrieves the eth stuck on the treasury
	 * @param _to address
	 * @dev Only owner can call it
	 */
	function retrieveETH(address _to) external onlyOwner {
		require(
			_to != address(0),
			"ITreasury::retrieveETH: address can't be zero"
		);
		uint256 amount = address(this).balance;
		payable(_to).transfer(amount);
	}

	/// @notice Allows the contract to receive ETH
	receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Proprietor {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address _owner) {
        require(_owner != address(0), "Proprietor::constructor: address can't be zero");
        owner = _owner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() virtual {
        require(owner == msg.sender, "Proprietor: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Proprietor: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import { Context } from "@openzeppelin/contracts/GSN/Context.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
			uint256 stateId,
			address rootMessageSender,
			bytes calldata data
		) external;
}

contract PolygonL2Messenger is
	IFxMessageProcessor,
	ReentrancyGuard {
	/// @notice Address of the contract that is allowed to make calls to this contract.
	address public fxRootSender;

	/// @notice Address of the polygon FxChild contract.
	address public fxChild;

	/// @notice An event emitted when the fxRootSender is updated
	event FxRootSenderUpdate(address previousFxRootSender, address newFxRootSender);

	/// @notice An event emitted when the fxChild is updated
  event FxChildUpdate(address previousFxChild, address newFxChild);

	// The default x-domain message sender being set to a non-zero value makes
	// deployment a bit more expensive, but in exchange the refund on every call to
	// `processMessageFromRoot` by the L1 and L2 messengers will be higher.
	address internal constant DEFAULT_XDOMAIN_SENDER = 0x000000000000000000000000000000000000dEaD;

	/// @notice temporarily stores the cross domain sender address when processMessageFromRoot is called
	address public xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

	/**
	 * @notice Throws if called by any account other than this contract.
	**/
	modifier onlyThis() {
    require(msg.sender == address(this), 'UNAUTHORIZED_ORIGIN_ONLY_THIS');
    _;
  }

	/**
   * @notice Throws if called by any account other than the fxChild.
  **/
	modifier onlyFxChild() {
    require(msg.sender == fxChild, 'UNAUTHORIZED_CHILD_ORIGIN');
    _;
  }

	constructor(address _fxRootSender, address _fxChild) {
		fxRootSender = _fxRootSender;
		fxChild = _fxChild;
	}

	/// @inheritdoc IFxMessageProcessor
	function processMessageFromRoot(
		uint256, /* stateId */
		address rootMessageSender,
		bytes calldata data
	) override
		nonReentrant
		onlyFxChild
		external {
		require(
			rootMessageSender == fxRootSender,
			"PolygonL2Messenger::processMessageFromRoot:UNAUTHORIZED_ROOT_ORIGIN"
		);

		(address target,  bytes memory callData) = abi.decode(data, (address, bytes));

		xDomainMsgSender = rootMessageSender;
		(bool success, ) = target.call(callData);
		xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

		require(
      success,
      "PolygonL2Messenger::processMessageFromRoot: Message execution reverted."
    );
	}

	/**
   * @dev Get the xDomainMsgSender address
   * @return xDomainMsgSender the address that sent the cross-domain transaction
  **/
	function xDomainMessageSender()
		public
		view
		returns (
				address
		) {
			require(xDomainMsgSender != DEFAULT_XDOMAIN_SENDER, "xDomainMessageSender is not set");
			return xDomainMsgSender;
	}

	/**
   * @dev Update the expected address of contract originating from a cross-chain transaction
   * @param _fxRootSender contract originating a cross-chain transaction- likely the cryptex timelock
  **/
  function updateFxRootSender(address _fxRootSender) external onlyThis {
		require(_fxRootSender != address(0), "PolygonL2Messenger: _fxRootSender is the zero address");
		emit FxRootSenderUpdate(fxRootSender, _fxRootSender);
		fxRootSender = _fxRootSender;
  }

  /**
   * @dev Update the address of the FxChild contract
   * @param _fxChild the address of the contract used to foward cross-chain transactions on Polygon
  **/
  function updateFxChild(address _fxChild) external onlyThis {
		require(_fxChild != address(0), "PolygonL2Messenger: _fxChild is the zero address");
		emit FxChildUpdate(fxChild, _fxChild);
		fxChild = _fxChild;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../ITreasury.sol";
import "./PolygonL2Messenger.sol";

/**
 * @title TCAP Polygon Treasury
 * @author Cryptex.finance
 * @notice This contract will hold the assets generated by the polygon network.
 */
contract PolygonTreasury is ITreasury {

	/// @notice Address of the polygonMessenger contract.
	PolygonL2Messenger public polygonMessenger;

	/// @notice event emitted when polygonMessenger is updated.
	event UpdatedPolygonMessenger(
		PolygonL2Messenger oldPolygonMessenger,
		PolygonL2Messenger newPolygonMessenger
	);

	/**
	 * @notice Constructor
	 * @param _owner the owner of the contract
	 * @param _polygonMessenger address of the polygon PolygonL2Messenger
	 */
	constructor(
		address _owner,
		address _polygonMessenger
	) ITreasury(_owner) {
		require(
			_polygonMessenger != address(0),
			"PolygonTreasury::constructor: address can't be zero"
		);
		polygonMessenger = PolygonL2Messenger(_polygonMessenger);
	}

	// @notice Throws if called by an account different from the owner
	// @dev call needs to come from PolygonL2Messenger
	modifier onlyOwner() override {
		require(
			msg.sender == address(polygonMessenger)
			&& polygonMessenger.xDomainMessageSender() == owner,
			"PolygonTreasury: caller is not the owner"
		);
		_;
	}

	/**
	 * @notice updates the polygonMessenger instance
	 * @param newPolygonMessenger address of the new PolygonL2Messenger contract
	**/
	function updatePolygonMessenger(address newPolygonMessenger) external onlyOwner {
		require(
			newPolygonMessenger != address (0),
			"PolygonTreasury: new owner is the zero address"
		);
		emit UpdatedPolygonMessenger(polygonMessenger, PolygonL2Messenger(newPolygonMessenger));
		polygonMessenger = PolygonL2Messenger(newPolygonMessenger);
	}

}