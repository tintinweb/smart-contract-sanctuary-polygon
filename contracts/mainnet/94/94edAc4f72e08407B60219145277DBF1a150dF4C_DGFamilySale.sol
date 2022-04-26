// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "../biconomy/EIP712MetaTransaction.sol";

/**
 * DGFamily Collection: Sale Contract
 * https://drops.unxd.com/dgfamily
 *
 * The contract will conduct fixed price sale for a selected NFT
 */
contract DGFamilySale is Ownable, EIP712MetaTransaction, Pausable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	// Maps wallet address to purchase quantity
	mapping(address => uint256) private purchaseList;

	mapping(address => bool) private earlyAccessList;
	// Max number of NFT per wallet can purchase
	uint256 public maxPurchaseLimit;
	uint256 public totalNfts;
	uint256 public nftSold;
	uint256 public nftFixedPrice;
	uint256 public startingTimeInUnixTimestamp;
	uint256 public closingTimeInUnixTimestamp;
	address public tokenContract;
	address public nftContract;

	uint256 private constant TIME_INCREMENTER = 15 minutes;
	uint256 private platformFeePercentage;
	address private platformWallet;

	address private fundManager;

	bool private finalizeCalled = false;
	bool private fundsWithdrawn = false;
	bool public earlyAccessOpen = false;

	/***************************************
	 *   EVENTS
	 ***************************************/
	/**
	 * @notice Emits when a new order is submitted
     * @param quantity the number of nft requested for purchase
     * @param wallet the wallet address of the buyer
     */
	event NftOrderPlaced(uint256 indexed quantity, address indexed wallet);
	/**
	 * @notice Emits when auction has been finalized
     * @param totalFunds The total funds raised in the auction
     * @param _fundManager Address of the fund manager calling finalize
     */
	event Finalized(uint256 indexed totalFunds, address indexed _fundManager);
	/**
	 * @notice Emits after updating fund manager address
     * @param newFundManager Address of the new fund manager
     */
	event FundManagerChanged(address indexed newFundManager);
	/**
	 * @notice Emits after updating platform wallet address
     * @param newPlatformWallet Address of the new platform wallet
     */
	event PlatformWalletChanged(address indexed newPlatformWallet);
	/**
	 * @notice Emits after updating platform fee percentage
     * @param newFeePercentage the new fee percetnage.e.g: 10
     */
	event PlatformFeePercentageChanged(uint256 indexed newFeePercentage);
	/**
	 * @notice Emits after updating starting time
     * @param newTime the new starting time
     */
	event StartingTimeInUnixTimestampUpdated(uint256 indexed newTime);
	/**
	 * @notice Emits after updating Closing time
     * @param newTime the new Closing time
     */
	event ClosingTimeInUnixTimestampUpdated(uint256 indexed newTime);
	/**
	 * @notice Emits after updating the fixed prie
     * @param newPrice the new fixed price
     */
	event NftFixedPriceChanged(uint256 indexed newPrice);

	/**
	 * @notice Emits after adding addresses to early access list
     * @param count the number of addresses added
     */
	event AddedEarlyAccessList(uint256 indexed count);

	/**
	 * @notice Emits after adding addresses to early access list
     * @param count the number of addresses added
     */
	event RemovedEarlyAccessList(uint256 indexed count);
	/***************************************
	 *   MODIFIERS
	 ***************************************/
	/// Validates time of function call
	modifier isSaleOpen() {
		require(
			block.timestamp <= closingTimeInUnixTimestamp,
			"SALE_IS_CLOSED"
		);

		if (!earlyAccessOpen) {
			require(
				block.timestamp >= startingTimeInUnixTimestamp,
				"SALE_HAS_NOT_STARTED"
			);
		} else {
			require(
				earlyAccessList[msgSender()],
				"ONLY_WHITELISTED_WALLET_CAN_ACCESS"
			);
		}

		_;
	}

	/// Validates function call occurs after sale close
	modifier saleHasClosed() {
		require(
			block.timestamp > closingTimeInUnixTimestamp,
			"Sale is ongoing"
		);
		_;
	}
	/// Validates function called by fund manager
	modifier onlyFundManager() {
		require(msgSender() == fundManager, "ONLY_FUND_MANAGER_CAN_ACCESS");
		_;
	}

	/**
	 * @notice Initializes constructor
     * @param _nftContract Deployed Nft contract address
     * @param _tokenContract Deployed wETH contract address
     * @param _platformFeePercentage platform will set
     * @param _platformWallet platform fee collection address
     * @param _fundManager Fund manager's address
     * @param _nftFixedPrice Price of each NFT
     * @param _maxLimitPerWallet The max quantity every wallet can purchase
     * @param _total The total number of NFTs that can be sold
     * @param _startingTimeInUnixTimestamp Starting time for the auction
     * @param _closingTimeInUnixTimestamp Closing time for the auction
     */
	constructor(
		address _nftContract,
		address _tokenContract,
		address _fundManager,
		uint256 _nftFixedPrice,
		uint256 _maxLimitPerWallet,
		uint256 _total,
		uint256 _platformFeePercentage,
		address _platformWallet,
		uint256 _startingTimeInUnixTimestamp,
		uint256 _closingTimeInUnixTimestamp
	) EIP712MetaTransaction("NftSales", "1") {
		require(_nftContract != address(0), "ADDRESS_CAN_NOT_BE_ZERO");
		require(_tokenContract != address(0), "ADDRESS_CAN_NOT_BE_ZERO");
		require(_fundManager != address(0), "ADDRESS_CAN_NOT_BE_ZERO");
		require(_nftFixedPrice > 0, "NFT_PRICE_CAN_NOT_BE_ZERO");
		require(_maxLimitPerWallet > 0, "MAX_PURCHASE_LIMIT_CAN_NOT_BE_ZERO");
		require(_total > 0, "TOTAL_NFT_CAN_NOT_BE_ZERO");
		require(
			_startingTimeInUnixTimestamp < _closingTimeInUnixTimestamp,
			"CLOSING_TIME_MUST_BE_GREATER"
		);

		fundManager = _fundManager;
		maxPurchaseLimit = _maxLimitPerWallet;
		nftFixedPrice = _nftFixedPrice;
		totalNfts = _total;
		startingTimeInUnixTimestamp = _startingTimeInUnixTimestamp;
		closingTimeInUnixTimestamp = _closingTimeInUnixTimestamp;
		nftContract = _nftContract;
		tokenContract = _tokenContract;
		platformFeePercentage = _platformFeePercentage;
		platformWallet = _platformWallet;
	}

	/** @dev Overridden function to make sure contract can never loses an owner

     */
	function renounceOwnership() public view override onlyOwner {
		revert("CAN_NOT_RENOUNCE_OWNERSHIP");
	}

	/** @notice Purchase NFT from Sale
     * @dev Will need to provide sufficient ERC20 approval to this contract before
     * calling this function. Provides 'NftOrderPlaced' event.
     * @param quantity Number of NFT to be purchased
     */

	function purchaseNft(uint256 quantity) external whenNotPaused isSaleOpen {
		uint256 totalPrice = quantity.mul(nftFixedPrice);

		require(
			purchaseList[msgSender()].add(quantity) <= maxPurchaseLimit,
			"BUYER_HAS_REACHED_PURCHASE_LIMIT"
		);
		require(
			quantity == 1,
			"YOU_CAN_ONLY_BUY_ONE_AT_A_TIME"
		);
		require(
			nftSold.add(quantity) <= totalNfts,
			"SUFFICIENT_NFT_NOT_AVAILABLE"
		);
		require(
			IERC20(tokenContract).balanceOf(msgSender()) >= totalPrice,
			"SUFFICIENT_BALANCE_NOT_PRESENT"
		);

		require(
			IERC20(tokenContract).allowance(msgSender(), address(this)) >=
			totalPrice,
			"SUFFICIENT_ALLOWANCE_NOT_MADE"
		);
		checkClosingTime();
		purchaseList[msgSender()] = purchaseList[msgSender()].add(quantity);
		nftSold = nftSold.add(quantity);

		// Transfer WETH to sales contract
		SafeERC20.safeTransferFrom(
			IERC20(tokenContract),
			msgSender(),
			address(this),
			totalPrice
		);

		emit NftOrderPlaced(quantity, msgSender());
	}

	/**
	 * @notice To be called by Fund Manager after sale is over to claim funds
     * @dev a "Finalized" event will be emitted
     */

	function finalize() external onlyFundManager saleHasClosed {
		require(!finalizeCalled, "FINALIZE_HAS_ALREADY_BEEN_CALLED");
		finalizeCalled = true;

		//Release Funds
		uint256 totalFunds = totalFundsRaised();
		uint256 platformFee = (totalFunds.mul(platformFeePercentage)).div(100);
		if (totalFunds > 0) {
			if (platformFee > 0) {
				SafeERC20.safeTransfer(
					IERC20(tokenContract),
					platformWallet,
					platformFee
				);
			}
			SafeERC20.safeTransfer(
				IERC20(tokenContract),
				fundManager,
				totalFunds.sub(platformFee)
			);
		}

		emit Finalized(totalFunds, fundManager);
	}

	/**
	 * @notice Owner can change closing time
     * @dev emits "closingTimeInUnixTimestampUpdated" event
     * @param _newTime New closing time
     */
	function setClosingTimeInUnixTimestamp(uint256 _newTime)
	external
	onlyOwner
	{
		require(
			block.timestamp < closingTimeInUnixTimestamp,
			"SALE_ALREADY_CLOSED"
		);
		require(
			_newTime > startingTimeInUnixTimestamp,
			"CLOSING_TIME_MUST_BE_GREATER"
		);
		closingTimeInUnixTimestamp = _newTime;
		emit ClosingTimeInUnixTimestampUpdated(closingTimeInUnixTimestamp);
	}

	/**
	 * @notice Owner can change starting time
     * @dev emits "startingTimeInUnixTimestampUpdated" event
     * @param _newTime New starting time
     */
	function setStartingTimeInUnixTimestamp(uint256 _newTime)
	external
	onlyOwner
	{
		require(
			_newTime < closingTimeInUnixTimestamp,
			"STARTING_TIME_MUST_BE_LESS"
		);
		startingTimeInUnixTimestamp = _newTime;
		emit StartingTimeInUnixTimestampUpdated(startingTimeInUnixTimestamp);
	}

	/**
	 * @notice Owner can change fund manager wallet
     * @dev emits "FundManagerChanged" event
     * @param _newManager New fund manager wallet address
     */
	function setFundManager(address _newManager) external onlyOwner {
		require(_newManager != address(0), "ADDRESS_CAN_NOT_BE_ZERO");
		fundManager = _newManager;

		emit FundManagerChanged(fundManager);
	}

	/**
	 * @notice Owner can change price for NFT
     * @dev emits "NftFixedPriceChanged" event
     * @param _newPrice New price incrementer percentage value
     */
	function setNftFixedPrice(uint256 _newPrice) external onlyOwner {
		require(_newPrice > 0, "NFT_PRICE_CAN_NOT_BE_ZERO");
		nftFixedPrice = _newPrice;

		emit NftFixedPriceChanged(nftFixedPrice);
	}

	/**
	 * @notice Owner can change platform wallet
     * @dev emits "PlatformWalletChanged" event
     * @param _newWallet New platform wallet address
     */
	function setPlatformWallet(address _newWallet) external onlyOwner {
		require(_newWallet != address(0), "ADDRESS_CAN_NOT_BE_ZERO");
		platformWallet = _newWallet;

		emit PlatformWalletChanged(fundManager);
	}

	/**
	 * @notice Owner can change bid incrementer percentage
     * @dev emits "PlatformFeePercentageChanged" event
     * @param _newFeePercentage New fee percentage value
     */
	function setPlatformFee(uint256 _newFeePercentage) external onlyOwner {
		platformFeePercentage = _newFeePercentage;

		emit PlatformFeePercentageChanged(platformFeePercentage);
	}

	/**
	 * @notice Owner can change max purchase limit per wallet
     * @param _newLimit The new purchase limit
     */
	function setNftMaxLimit(uint256 _newLimit) external onlyOwner {
		require(
			_newLimit > maxPurchaseLimit,
			"NEW_LIMIT_MUST_BE_GREATER_THAN_PREVIOUS"
		);
		maxPurchaseLimit = _newLimit;
	}

	/**
	 * @notice Owner can add wallets to early access list
     * @dev emits "AddedEarlyAccessList" event
     * @param _walletList List of wallets to be whitelisted for early access
     */
	function addEarlyAccessWallet(address[] calldata _walletList)
	external
	onlyOwner
	{
		for (uint256 i = 0; i < _walletList.length; i = i.add(1)) {
			earlyAccessList[_walletList[i]] = true;
		}

		emit AddedEarlyAccessList(_walletList.length);
	}

	/**
	 * @notice Owner can remove wallets from early access list
     * @dev emits "RemovedEarlyAccessList" event
     * @param _walletList List of wallets to be removed from list
     */
	function removeEarlyAccessWallet(address[] calldata _walletList)
	external
	onlyOwner
	{
		for (uint256 i = 0; i < _walletList.length; i = i.add(1)) {
			earlyAccessList[_walletList[i]] = false;
		}

		emit RemovedEarlyAccessList(_walletList.length);
	}

	/**
	 * @notice Owner can toggle & pause contract
     * @dev emits relevant Pausable events
     */
	function toggleEarlyAccess() external onlyOwner {
		earlyAccessOpen = earlyAccessOpen ? false : true;
	}

	/**
	 * @notice Owner can toggle & pause contract
     * @dev emits relevant Pausable events
     */
	function toggleContractState() external onlyOwner {
		if (!paused()) {
			_pause();
		} else {
			require(!fundsWithdrawn, "SALE_CAN_NOT_BE_UNPAUSED");
			_unpause();
		}
	}

	/**
	 * @notice EMERGENCY FEATURE: To be used by contract owner to withdraw funds.
     * @dev The contract will be in paused state and further bids won't be accepted
     */
	function withdrawFunds() external onlyOwner whenPaused {
		fundsWithdrawn = true;
		uint256 totalFunds = totalFundsRaised();
		uint256 platformFee = (totalFunds.mul(platformFeePercentage)).div(100);
		if (totalFunds > 0) {
			if (platformFee > 0) {
				SafeERC20.safeTransfer(
					IERC20(tokenContract),
					platformWallet,
					platformFee
				);
			}
			SafeERC20.safeTransfer(
				IERC20(tokenContract),
				fundManager,
				totalFunds.sub(platformFee)
			);
		}
	}

	/**
	 * @notice Get total funds raised from sales at a certain time
     * @return Fund amount
     */
	function getFundsRaised() external view onlyOwner returns (uint256) {
		return totalFundsRaised();
	}

	/**
	 * @notice Get the quantity purchased by an address
     * @param _buyer Address of the buyer
     * @return the number of nfts requested for purchase
     */
	function getPurchasedAmount(address _buyer)
	external
	view
	returns (uint256)
	{
		return purchaseList[_buyer];
	}

	/**
	 * @notice Getter for total funds raised
     * @return Total fund raised in the auction
     */
	function totalFundsRaised() private view returns (uint256) {
		return (IERC20(tokenContract).balanceOf(address(this)));
	}

	///  @dev Checks whether closing time needs to be increased under condition
	function checkClosingTime() private {
		if ((block.timestamp.add(15 minutes)) >= closingTimeInUnixTimestamp) {
			closingTimeInUnixTimestamp = closingTimeInUnixTimestamp.add(
				15 minutes
			);
		}
	}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./EIP712Base.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

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

    constructor(string memory name, string memory version)
        EIP712Base(name, version)
    {}

    function convertBytesToBytes4(bytes memory inBytes)
        internal
        pure
        returns (bytes4 outBytes4)
    {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(
            destinationFunctionSig != msg.sig,
            "functionSignature can not be of executeMetaTransaction method"
        );
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, string(returnData));
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
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

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        address signer = ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns (address sender) {
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
            sender = msg.sender;
        }
        return sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainID())
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns (bytes32) {
        return domainSeparator;
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
                abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}