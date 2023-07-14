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

import "./ERC20Spec.sol";
import "./ERC165Spec.sol";

/**
 * @title ERC1363 Interface
 *
 * @dev Interface defining a ERC1363 Payable Token contract.
 *      Implementing contracts MUST implement the ERC1363 interface as well as the ERC20 and ERC165 interfaces.
 */
interface ERC1363 is ERC20, ERC165  {
	/*
	 * Note: the ERC-165 identifier for this interface is 0xb0202a11.
	 * 0xb0202a11 ===
	 *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
	 *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
	 *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
	 *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
	 *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
	 *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
	 */

	/**
	 * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @return true unless throwing
	 */
	function transferAndCall(address to, uint256 value) external returns (bool);

	/**
	 * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @param data bytes Additional data with no specified format, sent in call to `to`
	 * @return true unless throwing
	 */
	function transferAndCall(address to, uint256 value, bytes memory data) external returns (bool);

	/**
	 * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
	 * @param from address The address which you want to send tokens from
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @return true unless throwing
	 */
	function transferFromAndCall(address from, address to, uint256 value) external returns (bool);


	/**
	 * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
	 * @param from address The address which you want to send tokens from
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @param data bytes Additional data with no specified format, sent in call to `to`
	 * @return true unless throwing
	 */
	function transferFromAndCall(address from, address to, uint256 value, bytes memory data) external returns (bool);

	/**
	 * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
	 * and then call `onApprovalReceived` on spender.
	 * @param spender address The address which will spend the funds
	 * @param value uint256 The amount of tokens to be spent
	 */
	function approveAndCall(address spender, uint256 value) external returns (bool);

	/**
	 * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
	 * and then call `onApprovalReceived` on spender.
	 * @param spender address The address which will spend the funds
	 * @param value uint256 The amount of tokens to be spent
	 * @param data bytes Additional data with no specified format, sent in call to `spender`
	 */
	function approveAndCall(address spender, uint256 value, bytes memory data) external returns (bool);
}

/**
 * @title ERC1363Receiver Interface
 *
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *      from ERC1363 token contracts.
 */
interface ERC1363Receiver {
	/*
	 * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
	 * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
	 */

	/**
	 * @notice Handle the receipt of ERC1363 tokens
	 *
	 * @dev Any ERC1363 smart contract calls this function on the recipient
	 *      after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
	 *      transfer. Return of other than the magic value MUST result in the
	 *      transaction being reverted.
	 *      Note: the token contract address is always the message sender.
	 *
	 * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
	 * @param from address The address which are token transferred from
	 * @param value uint256 The amount of tokens transferred
	 * @param data bytes Additional data with no specified format
	 * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
	 *      unless throwing
	 */
	function onTransferReceived(address operator, address from, uint256 value, bytes memory data) external returns (bytes4);
}

/**
 * @title ERC1363Spender Interface
 *
 * @dev Interface for any contract that wants to support `approveAndCall`
 *      from ERC1363 token contracts.
 */
interface ERC1363Spender {
	/*
	 * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
	 * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
	 */

	/**
	 * @notice Handle the approval of ERC1363 tokens
	 *
	 * @dev Any ERC1363 smart contract calls this function on the recipient
	 *      after an `approve`. This function MAY throw to revert and reject the
	 *      approval. Return of other than the magic value MUST result in the
	 *      transaction being reverted.
	 *      Note: the token contract address is always the message sender.
	 *
	 * @param owner address The address which called `approveAndCall` function
	 * @param value uint256 The amount of tokens to be spent
	 * @param data bytes Additional data with no specified format
	 * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
	 *      unless throwing
	 */
	function onApprovalReceived(address owner, uint256 value, bytes memory data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
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
import "../interfaces/ERC1363Spec.sol";
import "../utils/AccessControl.sol";
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
 * @notice The tunnel has two "exits": Root/L1 (MaticERC20RootTunnel) and Child/L2 (MaticERC20ChildTunnel)
 *
 * @notice Child exit is always open, while root exit is always open only as exit,
 *      entrance into the root tunnel exit may get paused or even closed permanently
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
contract MaticERC20ChildTunnel is FxBaseChildTunnel, AccessControl, ERC1363Receiver {
	/**
	 * @notice Child tunnel is strictly bound to the child ERC20 token
	 */
	MintableBurnableERC20 public immutable childToken;

	/**
	 * @notice People do mistakes and may send tokens by mistake
	 *
	 * @notice Rescue manager is responsible for "rescuing" ERC20/ERC721 tokens
	 *      accidentally sent to the smart contract
	 *
	 * @dev Role ROLE_RESCUE_MANAGER allows withdrawing non-bridged ERC20/ERC721
	 *      tokens stored on the smart contract balance via `rescueTokens` function
	 */
	uint32 public constant ROLE_RESCUE_MANAGER = 0x0010_0000;

	/**
	 * @dev Fired in `_processMessageFromRoot` (when token deposit completes)
	 *
	 * @param stateId unique tx identifier submitted from the root chain (L1)
	 * @param from token sender address in the root chain (L1)
	 * @param to token receiver address in the child chain (L2)
	 * @param value amount of tokens deposited
	 */
	event DepositComplete(uint256 indexed stateId, address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in `withdraw` and `withdrawTo`
	 *
	 * @param from token sender address in the child chain (L2)
	 * @param to token receiver address in the root chain (L1)
	 * @param value amount of tokens withdrawn
	 */
	event WithdrawalInitiated(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Creates/deploys a Polygon network (L2) exit bound to
	 *      FxChild and child ERC20 token (mintable and burnable)
	 * @dev FxChild is a helper contract providing L1/L2 messaging infrastructure,
	 *      managed by the Polygon
	 *
	 * @param _fxChild FxChild contract address (maintained by Polygon)
	 * @param _childToken child ERC20 token address
	 */
	constructor(address _fxChild, address _childToken) FxBaseChildTunnel(_fxChild) AccessControl(msg.sender) {
		// verify the inputs are set
		require(_fxChild != address(0), "fx child not set");
		require(_childToken != address(0), "child token not set");

		// initialize contract internal state
		childToken = MintableBurnableERC20(_childToken);
	}

	/**
	 * @inheritdoc FxBaseChildTunnel
	 */
	function setFxRootTunnel(address _fxRootTunnel) public override {
		// `setFxRootTunnel` must be executed during the deployment process by
		// the same account which is making a deployment (full admin)
		require(isSenderInRole(type(uint256).max), "access denied");

		// verify the address is set (not zero)
		require(_fxRootTunnel != address(0), "zero address");

		// delegate to parent `setFxRootTunnel` won't work
		// copy-paste the function `setFxRootTunnel` contents since it is declared `external`
		// --------------------------
		require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
		fxRootTunnel = _fxRootTunnel;
		// --------------------------
	}

	/**
	 * @notice L2 Tunnel Exit.
	 *      L2 Tunnel is always open in both directions.
	 *
	 * @inheritdoc FxBaseChildTunnel
	 */
	function _processMessageFromRoot(
		uint256 _stateId,
		address _fxRootTunnel,
		bytes memory _message
	) internal override validateSender(_fxRootTunnel) {
		// decode the message from the root
		// format: sender, recipient, amount
		(address _from, address _to, uint256 _value) = abi.decode(_message, (address, address, uint256));

		// mint the requested amount of tokens in the child chain
		childToken.mint(_to, _value);

		// emit an event
		emit DepositComplete(_stateId, _from, _to, _value);
	}

	/**
	 * @notice L2 Tunnel Entrance (fast lane).
	 *      L2 Tunnel is always open in both directions.
	 *
	 * @notice Initiates the withdrawal from the child chain (L2) into the root chain (L1)
	 *      to the same address which initiated the withdrawal process
	 *
	 * @notice The process is finalized in the root chain (L1) by the user/initiator
	 *      via the `MaticERC20RootTunnel.receiveMessage` function
	 *
	 * @notice Specified amount of tokens is burned in the tunnel
	 *
	 * @dev If specified, `data` field is decoded into tokens destination address `to` (`withdrawTo` mode),
	 *      if not specified, tokens are sent to the same owner address 'from' (`withdraw` mode)
	 *
	 * @inheritdoc ERC1363Receiver
	 */
	function onTransferReceived(
		address,
		address from,
		uint256 value,
		bytes memory data
	) public override returns (bytes4) {
		// verify the message comes from the trusted contract
		require(msg.sender == address(childToken), "access denied");

		// burn the accepted amount of tokens in the child chain
		childToken.burn(address(this), value);

		// by default the funds will be sent to the same owner address
		address to = from;
		// if however data field is specified
		if(data.length > 0) {
			// try to decode the address from the data field
			to = abi.decode(data, (address));
		}

		// notify the L2 about the deposit
		__withdrawalNotify(from, to, value);

		// return ERC1363Receiver "magic value"
		return ERC1363Receiver.onTransferReceived.selector;
	}

	/**
	 * @notice L2 Tunnel Entrance.
	 *      L2 Tunnel is always open in both directions.
	 *
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
	 * @notice L2 Tunnel Entrance.
	 *      L2 Tunnel is always open in both directions.
	 *
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

		// notify the L1 about the withdrawal
		__withdrawalNotify(msg.sender, _to, _value);

		// emit an event
		emit WithdrawalInitiated(msg.sender, _to, _value);
	}

	/**
	 * @dev Notifies the L1 about the initiated withdrawal
	 *
	 * @dev Unsafe: doesn't verify the executor (msg.sender) permissions,
	 *      must be kept private at all times
	 *
	 * @param _from token sender in the child chain (in L2)
	 * @param _to token recipient in the root chain (in L1)
	 * @param _value amount of tokens withdrawn
	 */
	function __withdrawalNotify(address _from, address _to, uint256 _value) private {
		// send message to the root to unlock equal amount of tokens in the root chain
		// format: sender, recipient, amount
		_sendMessageToRoot(abi.encode(_from, _to, _value));

		// emit an event
		emit WithdrawalInitiated(_from, _to, _value);
	}

	/**
	 * @dev Restricted access function to rescue accidentally sent tokens,
	 *      the tokens are rescued via `transferFrom` function call on the
	 *      contract address specified and with the parameters specified:
	 *      `_contract.transferFrom(this, _to, _value)`
	 *
	 * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
	 *
	 * @param _contract smart contract address to execute `transfer` function on
	 * @param _to to address in `transferFrom(this, _to, _value)`
	 * @param _value value to transfer in `transferFrom(this, _to, _value)`;
	 *      this can also be a tokenId for ERC721 transfer
	 */
	function rescueToken(address _contract, address _to, uint256 _value) public {
		// verify the access permission
		require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

		// perform the transfer as requested, without any checks
		require(ERC20(_contract).transferFrom(address(this), _to, _value));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if a specific operation is permitted globally and/or
 *      if a particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable public functions
 *      of the smart contract (used by a wide audience).
 * @notice User roles are designed to control the access to restricted functions
 *      of the smart contract (used by a limited set of maintainers).
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @author Basil Gorin
 */
abstract contract AccessControl {
	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 *
	 * @dev We keep the mapping private to prevent direct writes to it from the inheriting
	 *      contracts, `getRole()` and `updateRole()` functions should be used instead
	 */
	mapping(address => uint256) private userRoles;

	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _assigned permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _assigned);

	/**
	 * @notice Creates an access control instance, setting the contract owner to have full privileges
	 *
	 * @param _owner smart contract owner having full privileges
	 */
	constructor(address _owner) {
		// grant owner full privileges
		__setRole(_owner, FULL_PRIVILEGES_MASK, FULL_PRIVILEGES_MASK);
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns (uint256) {
		// features are stored in 'this' address mapping of `userRoles`
		return getRole(address(this));
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Reads the permissions (role) for a given user from the `userRoles` mapping
	 *
	 * @dev Having a simple getter instead of making the mapping public
	 *      allows enforcing the encapsulation of the mapping and protects from
	 *      writing to it directly in the inheriting smart contracts
	 *
	 * @param operator address of a user to read permissions for,
	 *      or self address to read global features of the smart contract
	 */
	function getRole(address operator) public view returns(uint256) {
		// read the value from `userRoles` and return
		return userRoles[operator];
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for,
	 *       or self address to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		__setRole(operator, role, evaluateBy(msg.sender, getRole(operator), role));
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns (uint256) {
		// read operator's permissions
		uint256 p = getRole(operator);

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns (bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns (bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns (bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(getRole(operator), required);
	}

	/**
	 * @dev Sets the `assignedRole` role to the operator, logs both `requestedRole` and `actualRole`
	 *
	 * @dev Unsafe:
	 *      provides direct write access to `userRoles` mapping without any security checks,
	 *      doesn't verify the executor (msg.sender) permissions,
	 *      must be kept private at all times
	 *
	 * @param operator address of a user to alter permissions for,
	 *       or self address to alter global features of the smart contract
	 * @param requestedRole bitmask representing a set of permissions requested
	 *      to be enabled/disabled for a user specified, used only to be logged into event
	 * @param assignedRole bitmask representing a set of permissions to
	 *      enable/disable for a user specified, used to update the mapping and to be logged into event
	 */
	function __setRole(address operator, uint256 requestedRole, uint256 assignedRole) private {
		// assign the role to the operator
		userRoles[operator] = assignedRole;

		// fire an event
		emit RoleUpdated(msg.sender, operator, requestedRole, assignedRole);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) private pure returns (bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}