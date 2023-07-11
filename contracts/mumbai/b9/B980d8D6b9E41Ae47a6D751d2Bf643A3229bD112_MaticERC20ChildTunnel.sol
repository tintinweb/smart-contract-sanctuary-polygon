// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
	/**
	 * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
	 *
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in approve() to indicate an approval event happened
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param value amount of tokens granted to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @return name of the token (ex.: USD Coin)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function name() external view returns (string memory);

	/**
	 * @return symbol of the token (ex.: USDC)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `2`, a balance of `505` tokens should
	 *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * @dev Tokens usually opt for a value of 18, imitating the relationship between
	 *      Ether and Wei. This is the value {ERC20} uses, unless this function is
	 *      overridden;
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including
	 *      {IERC20-balanceOf} and {IERC20-transfer}.
	 *
	 * @return token decimals
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function decimals() external view returns (uint8);

	/**
	 * @return the amount of tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) external view returns (uint256 balance);

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) external returns (bool success);

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

/**
 * @title Mintable/burnable ERC20 Extension
 *
 * @notice Adds mint/burn functions to ERC20 interface, these functions
 *      are usually present in ERC20 implementations, but these become
 *      a must for the bridged tokens in L2 since the bridge on L2
 *      needs to have a way to mint tokens deposited from L1 to L2
 *      and to burn tokens to be withdrawn from L2 to L1
 */
interface MintableBurnableERC20 is ERC20 {
	/**
	 * @dev Mints (creates) some tokens to address specified
	 * @dev The value specified is treated as is without taking
	 *      into account what `decimals` value is
	 *
	 * @param _to an address to mint tokens to
	 * @param _value an amount of tokens to mint (create)
	 * @return success true on success, false otherwise
	 */
	function mint(address _to, uint256 _value) external returns (bool success);

	/**
	 * @dev Burns (destroys) some tokens from the address specified
	 *
	 * @dev The value specified is treated as is without taking
	 *      into account what `decimals` value is
	 *
	 * @param _from an address to burn some tokens from
	 * @param _value an amount of tokens to burn (destroy)
	 * @return success true on success, false otherwise
	 */
	function burn(address _from, uint256 _value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC20Spec.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";

/**
 * @title Matic ERC20 Child Tunnel
 *
 * @notice Polygon network (child chain - L2) exit of the ERC20 tunnel,
 *      can be used for Polygon mainnet and Mumbai testnet networks
 *
 * @notice The tunnel is used to bridge specific ERC20 token between L1/L2;
 *      we call L1 -> L2 bridging a "deposit", L2 -> L1 a "withdrawal"
 *
 * @notice The tunnel has two "exits": L1 (MaticERC20RootTunnel) and L2 (MaticERC20ChildTunnel)
 *
 * @notice Deposit flow:
 *      1. The user initiates a deposit on the L1 exit by executing the deposit function
 *         `MaticERC20RootTunnel.deposit` or `MaticERC20RootTunnel.depositTo`
 *      2. Polygon messaging system picks up the event emitted by the `deposit` call
 *         and delivers it to L2 chain
 *      3. The deposit completes on the L2 exit when Polygon messaging system executes
 *         the `MaticERC20ChildTunnel.processMessageFromRoot` function
 *      Note: overall, user executes only one function and then just waits for the bridge
 *         operation to complete
 *
 * @notice Withdrawal flow:
 *      1. The user initiates a withdrawal on the L2 exit by executing the withdraw function
 *         `MaticERC20ChildTunnel.withdraw` or `MaticERC20ChildTunnel.withdrawTo`
 *      2. Polygon messaging system picks up the event emitted by the `withdraw` call
 *         and delivers it's proof to L1 chain
 *         This process takes much longer than `deposit` event delivery from L1 to L2 because
 *         of the high L1 gas costs deliveries happen in batches rarely
 *      3. The user completes the withdrawal on the L1 exit by executing the exit function
 *         `MaticERC20RootTunnel.receiveMessage` function
 *         a. Note the difference: the function is executed not by the Polygon messaging system
 *            but by the user themself, L1 gas cost is thus paid by the user
 *         b. The function expects the data from L2 as an input; this data can be obtained
 *            via Polygon proof generation API: https://github.com/maticnetwork/proof-generation-api
 *         c. See https://wiki.polygon.technology/docs/pos/design/bridge/l1-l2-communication/state-transfer#state-transfer-from-polygon--ethereum
 *
 * @dev see https://wiki.polygon.technology/docs/pos/design/bridge/l1-l2-communication/fx-portal
 * @dev see https://github.com/0xPolygon/fx-portal
 *
 * @author Basil Gorin
 */
contract MaticERC20ChildTunnel is FxBaseChildTunnel {
	/**
	 * @notice Child tunnel is strictly bound to the child ERC20 token
	 */
	MintableBurnableERC20 public immutable childToken;

	/**
	 * @dev Fired in `_processMessageFromRoot` (when token deposit completes)
	 *
	 * @param from token sender address in the root chain (L1)
	 * @param to token receiver address in the child chain (L2)
	 * @param value amount of tokens deposited
	 */
	event DepositComplete(address from, address to, uint256 value);

	/**
	 * @dev Fired in `withdraw` and `withdrawTo`
	 *
	 * @param from token sender address in the child chain (L2)
	 * @param to token receiver address in the root chain (L1)
	 * @param value amount of tokens withdrawn
	 */
	event WithdrawalInitiated(address from, address to, uint256 value);

	/**
	 * @dev Creates/deploys a Polygon network (L2) exit bound to
	 *      FxChild and child ERC20 token (mintable and burnable)
	 * @dev FxChild is a helper contract providing L1/L2 messaging infrastructure,
	 *      managed by the Polygon
	 *
	 * @param _fxChild FxChild contract address (maintained by Polygon)
	 * @param _childToken child ERC20 token address
	 */
	constructor(address _fxChild, address _childToken) FxBaseChildTunnel(_fxChild) {
		// verify the inputs are set
		require(_fxChild != address(0), "fx child not set");
		require(_childToken != address(0), "child token not set");

		// initialize contract internal state
		childToken = MintableBurnableERC20(_childToken);
	}

	/**
	 * @inheritdoc FxBaseChildTunnel
	 */
	function _processMessageFromRoot(
		uint256/* _stateId*/,
		address _fxRootTunnel,
		bytes memory _message
	) internal override validateSender(_fxRootTunnel) {
		// decode the message from the root
		// format: sender, recipient, amount
		(address _from, address _to, uint256 _value) = abi.decode(_message, (address, address, uint256));

		// mint the requested amount of tokens in the child chain
		childToken.mint(_to, _value);

		// emit an event
		emit DepositComplete(_from, _to, _value);
	}

	/**
	 * @notice Initiates the withdrawal from the child chain (L2) into the root chain (L1)
	 *      to the same address which initiated the withdrawal process
	 *
	 * @notice The process is finalized in the root chain (L1) by the user/initiator
	 *      via the `MaticERC20RootTunnel.receiveMessage` function
	 *
	 * @notice Specified amount of tokens is burned from the sender
	 *
	 * @param _value amount of tokens to withdraw
	 */
	function withdraw(uint256 _value) public {
		// delegate to `withdrawTo`
		withdrawTo(msg.sender, _value);
	}

	/**
	 * @notice Initiates the withdrawal from the child chain (L2) into the root chain (L1)
	 *
	 * @notice The process is finalized in the root chain (L1) by the user/initiator
	 *      via the `MaticERC20RootTunnel.receiveMessage` function
	 *
	 * @param _to token recipient in the root chain (L1)
	 * @param _value amount of tokens to withdraw
	 */
	function withdrawTo(address _to, uint256 _value) public {
		// burn the requested amount of tokens in the child chain
		childToken.burn(msg.sender, _value);

		// send message to the root to unlock equal amount of tokens in the root chain
		// format: sender, recipient, amount
		_sendMessageToRoot(abi.encode(msg.sender, _to, _value));

		// emit an event
		emit WithdrawalInitiated(msg.sender, _to, _value);
	}
}