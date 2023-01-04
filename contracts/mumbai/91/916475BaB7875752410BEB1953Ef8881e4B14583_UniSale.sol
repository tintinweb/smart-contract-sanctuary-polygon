// SPDX-License-Identifier: MIT License

pragma solidity 0.8.17;

import "../../contracts/interfaces/IWhitelistConstraintModule.sol";
import "../../contracts/interfaces/ISecurityToken.sol";
import "../interfaces/ICurrency.sol";
import "../interfaces/ERC1820Client.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/NativeMetaTransaction.sol";

contract UniSale is NativeMetaTransaction, ReentrancyGuard, ERC1820Client {
	// tokenAddress => partition => SalesChannel
	mapping(address => mapping(bytes32 => SalesChannel)) private _channels;

	struct SalesChannel {
		// token will be force-transferred from this address. If 0, tokens will be minted.
		address issuer;
		// this whitelist will be checked before each purpose. If 0, no check is done.
		IWhitelistConstraintModule whitelist;
		// buyers array
		address[] buyers;
		// maximum amount of tokens that can be sold
		// could be different than token cap
		uint256 cap;
		// counts amount of tokens sold
		uint256 sold;
		// unix timestamp of time the sale will be closed and claim function can be called
		uint256 primaryMarketEndTimestamp;
		// if premintAddress is 0x0, tokens will be minted when distributed
		address premintAddress;
		// wether this partition is sold deferred
		bool useDeferredMinting;
		// used to keep track of distribution
		uint256 distributeCounter;
		// wether limits are used or not
		bool useLimit;
		// userAddress => limit
		mapping(address => uint256) limits;
		// rate: amount of the smallest unit of this currency necessary to buy 1 token
		// rate = 10^unit (where unit is the smallest possible unit of the currency)
		// i.e. 1,000000 USDC = 1 token --> rate = 10^6 (USDC has 6 decimals)
		// currencyAddress => rate
		mapping(address => uint256) rates;
		// userAddress => purchaseAmount
		mapping(address => uint256) purchases;
	}

	event TokenPurchased(
		address indexed buyer,
		address tokenAddress,
		uint256 value,
		address currencyToken,
		uint256 amount,
		bytes32 partition
	);

	event TokenClaim(address tokenAddress, bytes32 partition, address indexed buyer, uint256 value);

	event CurrencyRatesEdited(
		address tokenAddress,
		bytes32 partition,
		address currencyAddress,
		uint256 rate
	);

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function initialize() external initializer {
		_initializeEIP712("UniSale - Security Tokens Primary Market");
	}

	function addSalesChannel(
		address tokenAddress,
		address issuerWallet,
		address whitelistAddress,
		uint256 primaryMarketEndTimestamp,
		uint256 salesCap,
		bytes32 partition,
		address premintWallet,
		address currencyAddress,
		uint256 rate,
		bool useDeferredMinting,
		bool useLimit
	) public {
		require(issuerWallet != address(0), "issuerWallet zero");
		require(
			ERC1820Client.getInterfaceImplementer(tokenAddress, "ERC1400Token") == tokenAddress,
			"token is not ERC1400 compatible"
		);
		require(isContract(whitelistAddress), "whitelist is not a contract");
		require(block.timestamp < primaryMarketEndTimestamp, "primary market end in the past");
		require(rate > 0, "rate cannot be 0");

		ISecurityToken _securityToken = ISecurityToken(tokenAddress);
		require(_securityToken.hasRole(bytes32("SALE_ADMIN"), msgSender()), "!SALE_ADMIN");

		SalesChannel storage salesChannel = _channels[tokenAddress][partition];

		salesChannel.issuer = issuerWallet;
		salesChannel.whitelist = IWhitelistConstraintModule(whitelistAddress);
		salesChannel.primaryMarketEndTimestamp = primaryMarketEndTimestamp;
		salesChannel.cap = salesCap;
		salesChannel.premintAddress = premintWallet;
		salesChannel.useDeferredMinting = useDeferredMinting;
		salesChannel.useLimit = useLimit;

		editCurrencyRates(tokenAddress, partition, currencyAddress, rate);
	}

	function deleteSalesChannel(address tokenAddress, bytes32 partition)
		public
		onlySaleAdmin(tokenAddress)
	{
		delete _channels[tokenAddress][partition];
	}

	function purchaseTokenWithAllowance(
		address tokenAddress,
		bytes32 partition,
		address currencyAddress,
		uint256 amount
	) public nonReentrant {
		ICurrency currency = ICurrency(currencyAddress);

		// currency must be accepted
		require(
			_channels[tokenAddress][partition].rates[currencyAddress] > 0,
			"this stablecoin is not accepted"
		);

		// calculate currency amount needed based on rate
		uint256 currencyNeeded = _channels[tokenAddress][partition].rates[currencyAddress] * amount;

		// check allowance
		require(
			currency.allowance(msgSender(), address(this)) >= currencyNeeded,
			"stablecoin allowance too low"
		);

		// register purchase
		_addPurchase(tokenAddress, partition, msgSender(), amount);

		// send payment directly to issuer
		currency.transferFrom(
			msgSender(),
			_channels[tokenAddress][partition].issuer,
			currencyNeeded
		);

		emit TokenPurchased(
			msgSender(),
			tokenAddress,
			currencyNeeded,
			currencyAddress,
			amount,
			partition
		);
	}

	function purchaseWithAuthorization(
		address tokenAddress,
		bytes32 partition,
		address currencyAddress,
		uint256 amount,
		address userAddress,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) public nonReentrant {
		ICurrency currency = ICurrency(currencyAddress);

		// currency must be accepted
		require(
			_channels[tokenAddress][partition].rates[currencyAddress] > 0,
			"this stablecoin is not accepted"
		);

		// calculate currency needed based on rate and token amount
		uint256 currencyNeeded = _channels[tokenAddress][partition].rates[currencyAddress] * amount;

		// create the expected function signature
		bytes memory calculatedFunctionSignature = abi.encodeWithSignature(
			"transfer(address,uint256)",
			_channels[tokenAddress][partition].issuer,
			currencyNeeded
		);

		// check balance
		require(currency.balanceOf(userAddress) >= currencyNeeded, "stablecoin balance too low");

		// register purchase
		_addPurchase(tokenAddress, partition, userAddress, amount);

		// send payment directly to issuer
		currency.executeMetaTransaction(userAddress, calculatedFunctionSignature, sigR, sigS, sigV);

		emit TokenPurchased(
			userAddress,
			tokenAddress,
			currencyNeeded,
			currencyAddress,
			amount,
			partition
		);
	}

	function addFiatPurchase(
		address tokenAddress,
		bytes32 partition,
		address buyer,
		uint256 amount
	) public onlySaleAdmin(tokenAddress) {
		_addPurchase(tokenAddress, partition, buyer, amount);
	}

	function claimTokens(address tokenAddress, bytes32 partition) public nonReentrant {
		require(
			block.timestamp >= _channels[tokenAddress][partition].primaryMarketEndTimestamp,
			"primary market has not ended yet"
		);

		uint256 amountClaimable = _channels[tokenAddress][partition].purchases[msgSender()];

		require(amountClaimable > 0, "no tokens to claim");

		_channels[tokenAddress][partition].purchases[msgSender()] = 0;

		// ISSUE TOKENS
		_issueTokens(tokenAddress, partition, msgSender(), amountClaimable);

		emit TokenClaim(tokenAddress, partition, msgSender(), amountClaimable);
	}

	function distributeTokens(
		address tokenAddress,
		bytes32 partition,
		uint256 batchSize
	) public nonReentrant {
		require(
			block.timestamp >= _channels[tokenAddress][partition].primaryMarketEndTimestamp,
			"primary market has not ended yet"
		);

		uint256 end;

		uint256 dc = _channels[tokenAddress][partition].distributeCounter;

		uint256 length = _channels[tokenAddress][partition].buyers.length;

		if (dc < length) {
			end = dc + batchSize;
		} else {
			revert("done distributing");
		}

		if (end > length) {
			end = length;
		}

		ISecurityToken _securityToken = ISecurityToken(tokenAddress);

		if (_channels[tokenAddress][partition].premintAddress == address(0)) {
			for (; dc < end; dc++) {
				address investor = _channels[tokenAddress][partition].buyers[dc];

				// distribute tokens
				_securityToken.issueByPartition(
					partition,
					investor,
					_channels[tokenAddress][partition].purchases[investor],
					"0x"
				);
				_channels[tokenAddress][partition].purchases[investor] = 0;
			}
		} else {
			for (; dc < end; dc++) {
				address investor = _channels[tokenAddress][partition].buyers[dc];

				// distribute tokens
				_securityToken.operatorTransferByPartition(
					partition,
					_channels[tokenAddress][partition].premintAddress,
					investor,
					_channels[tokenAddress][partition].purchases[investor],
					"0x",
					"0x"
				);

				_channels[tokenAddress][partition].purchases[investor] = 0;
			}
		}

		_channels[tokenAddress][partition].distributeCounter = dc;
	}

	function cancelPurchase(
		address tokenAddress,
		bytes32 partition,
		address buyer,
		uint256 amount
	) public onlySaleAdmin(tokenAddress) {
		require(_channels[tokenAddress][partition].purchases[buyer] >= amount, "amount too high");

		// subtracting a specific amount makes it possible to cancel only some of a _buyers purchases
		_channels[tokenAddress][partition].purchases[buyer] -= amount;
	}

	function editPurchaseLimits(
		address tokenAddress,
		bytes32 partition,
		address buyer,
		uint256 amount
	) public onlySaleAdmin(tokenAddress) {
		require(buyer != address(0), "buyer is zero");

		_channels[tokenAddress][partition].limits[buyer] = amount;
	}

	function editCurrencyRates(
		address tokenAddress,
		bytes32 partition,
		address currencyAddress,
		uint256 rate
	) public onlySaleAdmin(tokenAddress) {
		require(rate > 0, "rate cannot be 0");

		_channels[tokenAddress][partition].rates[currencyAddress] = rate;

		emit CurrencyRatesEdited(tokenAddress, partition, currencyAddress, rate);
	}

	function _addPurchase(
		address tokenAddress,
		bytes32 partition,
		address buyer,
		uint256 amount
	) internal {
		require(buyer != address(0), "buyer is zero");

		// check primary market, if set
		if (_channels[tokenAddress][partition].primaryMarketEndTimestamp != 0) {
			require(
				block.timestamp < _channels[tokenAddress][partition].primaryMarketEndTimestamp,
				"primary market already ended"
			);
		}

		// check whitelist, if used
		if (address(_channels[tokenAddress][partition].whitelist) != address(0)) {
			require(
				_channels[tokenAddress][partition].whitelist.isWhitelisted(buyer),
				"buyer not whitelisted"
			);
		}

		// check cap, if set
		if (_channels[tokenAddress][partition].cap != 0) {
			require(
				_channels[tokenAddress][partition].sold + amount <
					_channels[tokenAddress][partition].cap,
				"would exceed sales cap"
			);
		}

		// check limits, if set
		if (_channels[tokenAddress][partition].useLimit) {
			require(
				_channels[tokenAddress][partition].limits[buyer] >= amount,
				"exceeds purchase limit for buyer"
			);
			// sub from _limits
			_channels[tokenAddress][partition].limits[buyer] -= amount;
		}

		// add to sold
		_channels[tokenAddress][partition].sold = _channels[tokenAddress][partition].sold + amount;

		// add buyer address to array
		_channels[tokenAddress][partition].buyers.push(buyer);

		if (!_channels[tokenAddress][partition].useDeferredMinting) {
			// Instant Minting, issue tokens
			_issueTokens(tokenAddress, partition, buyer, amount);
		} else {
			// Deferred Minting, register purchase
			_channels[tokenAddress][partition].purchases[buyer] += amount;
		}
	}

	function _issueTokens(
		address tokenAddress,
		bytes32 partition,
		address buyer,
		uint256 amount
	) internal {
		ISecurityToken securityToken = ISecurityToken(tokenAddress);

		if (_channels[tokenAddress][partition].premintAddress == address(0)) {
			securityToken.issueByPartition(partition, buyer, amount, "0x");
		} else {
			securityToken.operatorTransferByPartition(
				partition,
				_channels[tokenAddress][partition].premintAddress,
				buyer,
				amount,
				"0x",
				"0x"
			);
		}
	}

	function editPrimaryMarketEnd(
		address tokenAddress,
		bytes32 partition,
		uint256 newPrimaryMarketEndTimestamp
	) public onlySaleAdmin(tokenAddress) {
		require(block.timestamp < newPrimaryMarketEndTimestamp, "not in future");

		_channels[tokenAddress][partition].primaryMarketEndTimestamp = newPrimaryMarketEndTimestamp;
	}

	// read functions for private types

	function getWhitelistAddress(address tokenAddress, bytes32 partition)
		external
		view
		returns (address whitelistAddress)
	{
		return address(_channels[tokenAddress][partition].whitelist);
	}

	function getPurchase(
		address tokenAddress,
		bytes32 partition,
		address buyer
	) external view returns (uint256 amount) {
		return _channels[tokenAddress][partition].purchases[buyer];
	}

	function getLimit(
		address tokenAddress,
		bytes32 partition,
		address buyer
	) external view returns (uint256 limit) {
		return _channels[tokenAddress][partition].limits[buyer];
	}

	function getCurrencyRate(
		address tokenAddress,
		bytes32 partition,
		address currencyAddress
	) external view returns (uint256 rate) {
		return _channels[tokenAddress][partition].rates[currencyAddress];
	}

	function getPrimaryMarketEndTimestamp(address tokenAddress, bytes32 partition)
		external
		view
		returns (uint256 primaryMarketEndTimestamp)
	{
		return _channels[tokenAddress][partition].primaryMarketEndTimestamp;
	}

	function getBuyers(address tokenAddress, bytes32 partition)
		external
		view
		returns (address[] memory buyers)
	{
		return _channels[tokenAddress][partition].buyers;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlySaleAdmin(address tokenAddress) {
		ISecurityToken _securityToken = ISecurityToken(tokenAddress);
		require(_securityToken.hasRole(bytes32("SALE_ADMIN"), msgSender()), "!SALE_ADMIN");
		_;
	}

	function isContract(address account) internal view returns (bool) {
		// This method relies in extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}
}

// SPDX-License-Identifier: MIT License

pragma solidity 0.8.17;

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
contract ReentrancyGuard {
	bool private _entered;

	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly.
	 * Calling a `nonReentrant` function from another `nonReentrant`
	 * function is not supported. It is possible to prevent this from happening
	 * by making the `nonReentrant` function external, and make it call a
	 * `private` function that does the actual work.
	 */
	modifier nonReentrant() {
		// On the first call to nonReentrant, _entered will be false
		require(!_entered, "ReentrancyGuard: reentrant call");

		// Any calls to nonReentrant after this point will fail
		_entered = true;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_entered = false;
	}
}

// SPDX-License-Identifier: MIT License

pragma solidity 0.8.17;

import { EIP712Base } from "./EIP712Base.sol";
import "./ContextMixin.sol";

contract NativeMetaTransaction is EIP712Base, ContextMixin {
	bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));
	event MetaTransactionExecuted(
		address userAddress,
		address payable relayerAddress,
		bytes functionSignature
	);
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

	function executeMetaTransaction(
		address userAddress,
		bytes memory functionSignature,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) public payable returns (bytes memory) {
		MetaTransaction memory metaTx = MetaTransaction({
			nonce: nonces[userAddress],
			from: userAddress,
			functionSignature: functionSignature
		});

		require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");

		// increase nonce for user (to avoid re-use)
		nonces[userAddress] = nonces[userAddress] + 1;

		emit MetaTransactionExecuted(userAddress, msgSender(), functionSignature);

		// Append userAddress and relayer address at the end to extract it from calling context
		(bool success, bytes memory returnData) = address(this).call(
			abi.encodePacked(functionSignature, userAddress)
		);
		require(success, "Function call not successful");

		return returnData;
	}

	function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encode(
					META_TRANSACTION_TYPEHASH,
					metaTx.nonce,
					metaTx.from,
					keccak256(metaTx.functionSignature)
				)
			);
	}

	function getNonce(address user) public view returns (uint256 nonce) {
		nonce = nonces[user];
	}

	function verify(
		address signer,
		MetaTransaction memory metaTx,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) internal view returns (bool) {
		require(signer != address(0), "<: INVALID_SIGNER");
		return
			signer == ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
	}
}

// SPDX-License-Identifier: MIT License

pragma solidity 0.8.17;

contract Initializable {
	bool inited = false;

	modifier initializer() {
		require(!inited, "already inited");
		_;
		inited = true;
	}
}

contract EIP712Base is Initializable {
	struct EIP712Domain {
		string name;
		string version;
		address verifyingContract;
		bytes32 salt;
	}

	string public constant ERC712_VERSION = "1";

	bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
		keccak256(
			bytes(
				"EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
			)
		);
	bytes32 internal domainSeperator;

	// supposed to be called once while initializing.
	// one of the contractsa that inherits this contract follows proxy pattern
	// so it is not possible to do this in a constructor
	function _initializeEIP712(string memory name) internal {
		_setDomainSeperator(name);
	}

	function _setDomainSeperator(string memory name) internal {
		domainSeperator = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(ERC712_VERSION)),
				address(this),
				bytes32(getChainId())
			)
		);
	}

	function getDomainSeperator() public view returns (bytes32) {
		return domainSeperator;
	}

	function getChainId() public view returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}

	/**
	 * Accept message hash and returns hash message in EIP712 compatible form
	 * So that it can be used to recover signer from signature signed using EIP712 formatted data
	 * https://eips.ethereum.org/EIPS/eip-712
	 * "\\x19" makes the encoding deterministic
	 * "\\x01" is the version byte to make it compatible to EIP-191
	 */
	function toTypedMessageHash(bytes32 messageHash)
		internal
		view
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
			);
	}
}

// SPDX-License-Identifier: MIT License

pragma solidity 0.8.17;

contract ContextMixin {
	function msgSender() internal view returns (address payable sender) {
		if (msg.sender == address(this)) {
			bytes memory array = msg.data;
			uint256 index = msg.data.length;
			assembly {
				// Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
				sender := and(
					mload(add(array, index)),
					0xffffffffffffffffffffffffffffffffffffffff
				)
			}
		} else {
			sender = payable(msg.sender);
		}
		return sender;
	}
}

// SPDX-License-Identifier: MIT License

pragma solidity 0.8.17;

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
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

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
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

interface ICurrency is IERC20 {
	function executeMetaTransaction(
		address userAddress,
		bytes memory functionSignature,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT License

pragma solidity 0.8.17;

/**
 * @dev Taken from node_modules/erc1820
 * updated solidity version
 * commented out interfaceAddr & delegateManagement
 */
interface ERC1820Registry {
	function setInterfaceImplementer(
		address _addr,
		bytes32 _interfaceHash,
		address _implementer
	) external;

	function getInterfaceImplementer(address _addr, bytes32 _interfaceHash)
		external
		view
		returns (address);

	function setManager(address _addr, address _newManager) external;

	function getManager(address _addr) external view returns (address);
}

/// Base client to interact with the registry.
contract ERC1820Client {
	ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

	function setInterfaceImplementation(string memory _interfaceLabel, address _implementation)
		internal
	{
		bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
		ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
	}

	function getInterfaceImplementer(address _addr, string memory _interfaceLabel)
		internal
		view
		returns (address)
	{
		return
			ERC1820REGISTRY.getInterfaceImplementer(
				_addr,
				keccak256(abi.encodePacked(_interfaceLabel))
			);
	}
}

// SPDX-License-Identifier: MIT License

pragma solidity >=0.6.6;

import "./IConstraintModule.sol";

interface IWhitelistConstraintModule is IConstraintModule {
	function isWhitelisted(address account) external view returns (bool);

	function editWhitelist(address account, bool whitelisted) external;

	function bulkEditWhitelist(address[] calldata accounts, bool whitelisted)
		external;
}

// SPDX-License-Identifier: MIT License

pragma solidity >=0.6.6;

import "./IConstraintModule.sol";


/**
 * @author Simon Dosch
 * @title ISecurityToken
 * @dev Interface for using the Security Token
 * this interface is meant solely for usage with libraries like truffle or web3.js.
 * it is not used by any deployed contract
 */
interface ISecurityToken {
	function addPartitionProxy(bytes32 partition, address proxyAddress)
		external;

	function bulkIssueByPartition(
		bytes32 partition,
		address[] calldata tokenHolders,
		uint256[] calldata values,
		bytes calldata data
	) external;

	//******************/
	// Constrainable INTERFACE
	//******************/

	function getModulesByPartition()
		external
		view
		returns (IConstraintModule[] memory);

	function setModulesByPartition(
		bytes32 partition,
		IConstraintModule[] calldata newModules
	) external;

	//******************/
	// Administrable INTERFACE
	//******************/
	function addRole(bytes32 role, address account) external;

	function removeRole(bytes32 role, address account) external;

	function renounceRole(bytes32 role) external;

	function hasRole(bytes32 role, address account)
		external
		view
		returns (bool);

	event RoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);
	event RoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);
	event RoleRenounced(bytes32 indexed role, address indexed account);

	//******************/
	// GSNRecipient INTERFACE
	//******************/

	function acceptRelayedCall(
		address relay,
		address from,
		bytes calldata encodedFunction,
		uint256 transactionFee,
		uint256 gasPrice,
		uint256 gasLimit,
		uint256 nonce,
		bytes calldata approvalData,
		uint256 maxPossibleCharge
	) external view returns (uint256, bytes memory);

	function getHubAddr() external view returns (address);

	function relayHubVersion() external view returns (string memory);

	function preRelayedCall(bytes calldata context) external returns (bytes32);

	function postRelayedCall(
		bytes calldata context,
		bool success,
		uint256 actualCharge,
		bytes32 preRetVal
	) external;

	//******************/
	// IERC1400Raw INTERFACE
	//******************/

	function name() external view returns (string memory); // 1/13

	function symbol() external view returns (string memory); // 2/13

	function totalSupply() external view returns (uint256); // 3/13

	function balanceOf(address owner) external view returns (uint256); // 4/13

	function granularity() external view returns (uint256); // 5/13

	// deleted function controllers() external view returns (address[] memory); // 6/13
	// function authorizeOperator(address operator) external; // 7/13
	// function revokeOperator(address operator) external; // 8/13
	// function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

	// not necessary for ERC1400Partition
	// function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
	// function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

	// not necessary for ERC1400Partition
	// function redeem(uint256 value, bytes calldata data) external; // 12/13
	// function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13

	event TransferWithData(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);
	event Issued(
		address indexed operator,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);
	event Redeemed(
		address indexed operator,
		address indexed from,
		uint256 value,
		bytes data,
		bytes operatorData
	);
	event AuthorizedOperator(
		address indexed operator,
		address indexed tokenHolder
	);
	event RevokedOperator(
		address indexed operator,
		address indexed tokenHolder
	);

	//******************/
	// ERC1400Partition INTERFACE
	//******************/

	// ERC20 proxy compatibility
	function totalSupplyByPartition(bytes32 partition)
		external
		view
		returns (uint256);

	// Partition proxy contracts
	function partitionProxies() external view returns (address[] memory);

	// Token Information
	function balanceOfByPartition(bytes32 partition, address tokenHolder)
		external
		view
		returns (uint256); // 1/10

	function partitionsOf(address tokenHolder)
		external
		view
		returns (bytes32[] memory); // 2/10

	// Token Transfers
	function transferByPartition(
		bytes32 partition,
		address to,
		uint256 value,
		bytes calldata data
	) external returns (bytes32); // 3/10

	function operatorTransferByPartition(
		bytes32 partition,
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external returns (bytes32); // 4/10

	// Operators
	function controllersByPartition(bytes32 partition)
		external
		view
		returns (address[] memory); // 7/10

	function authorizeOperatorByPartition(bytes32 partition, address operator)
		external; // 8/10

	function revokeOperatorByPartition(bytes32 partition, address operator)
		external; // 9/10

	function isOperatorForPartition(
		bytes32 partition,
		address operator,
		address tokenHolder
	) external view returns (bool); // 10/10

	// Optional functions
	function totalPartitions() external view returns (bytes32[] memory);

	// Transfer Events
	event TransferByPartition(
		bytes32 indexed fromPartition,
		address operator,
		address indexed from,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	event ChangedPartition(
		bytes32 indexed fromPartition,
		bytes32 indexed toPartition,
		uint256 value
	);

	// Operator Events
	event AuthorizedOperatorByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed tokenHolder
	);
	event RevokedOperatorByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed tokenHolder
	);

	//******************/
	// ERC1400Capped INTERFACE
	//******************/

	// Document Management
	function getDocument(bytes32 documentName)
		external
		view
		returns (string memory, bytes32); // 1/9

	function setDocument(
		bytes32 documentName,
		string calldata uri,
		bytes32 documentHash
	) external; // 2/9

	event Document(
		bytes32 indexed documentName,
		string uri,
		bytes32 documentHash
	);

	// Controller Operation
	function isControllable() external view returns (bool); // 3/9

	// Token Issuance
	function isIssuable() external view returns (bool); // 4/9

	function issueByPartition(
		bytes32 partition,
		address tokenHolder,
		uint256 value,
		bytes calldata data
	) external; // 5/9

	event IssuedByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	// Token Redemption
	// function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data) external; // 6/9
	function operatorRedeemByPartition(
		bytes32 partition,
		address tokenHolder,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external; // 7/9

	event RedeemedByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed from,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	// Optional functions
	function renounceControl() external;

	function renounceIssuance() external;

	// Capped
	function cap() external view returns (uint256);

	function setCap(uint256 newCap) external;

	event CapSet(uint256 newCap);

	// GSN
	function setGSNAllowed(bool allow) external;

	function getGSNAllowed() external view returns (bool);
}

// SPDX-License-Identifier: MIT License

pragma solidity >=0.6.6;


/**
 * @author Simon Dosch
 * @title IConstraintModule
 * @dev ConstraintModule's interface
 */
interface IConstraintModule {
	// ConstraintModule should also implement an interface to the token they are referring to
	// to call functions like hasRole() from Administrable

	// string private _module_name;

	/**
	 * @dev Validates live transfer. Can modify state
	 * @param msg_sender Sender of this function call
	 * @param partition Partition the tokens are being transferred from
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer.
	 * @param operatorData Information attached to the transfer, by the operator.
	 * @return valid transfer is valid
	 * @return reason Why the transfer failed (intended for require statement)
	 */
	function executeTransfer(
		address msg_sender,
		bytes32 partition,
		address operator,
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external returns (bool valid, string memory reason);

	/**
	 * @dev Returns module name
	 * @return bytes32 name of the constraint module
	 */
	function getModuleName() external view returns (bytes32);
}