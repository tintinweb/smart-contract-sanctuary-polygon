/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// File: contracts/EIP712Base.sol



pragma solidity ^0.8.7;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 internal domainSeperator;

    constructor(string memory name, string memory version) {
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
			id := 1 // set to Goerli for now, Mainnet later
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

// File: contracts/EIP712MetaTransaction.sol



pragma solidity ^0.8.7;


abstract contract EIP712MetaTransaction is EIP712Base {

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

    mapping(address => uint256) internal nonces;

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
    )
        public
        payable
        returns(bytes memory)
    {
        MetaTransaction memory metaTx = MetaTransaction(
            {
                nonce: nonces[userAddress],
                from: userAddress,
                functionSignature: functionSignature
            }
        );

        require(
            verify(
                userAddress,
                metaTx,
                sigR,
                sigS,
                sigV
            ), "Signer and signature do not match"
        );

	    nonces[userAddress] =
	    nonces[userAddress] + 1;

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(
                functionSignature,
                userAddress
            )
        );

        require(
            success,
            'Function call not successful'
        );

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        return returnData;
    }

    function hashMetaTransaction(
        MetaTransaction memory metaTx
    )
        internal
        pure
        returns (bytes32)
    {
		return keccak256(
		    abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
	}

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(
            toTypedMessageHash(
                hashMetaTransaction(metaTx)
            ),
            sigV,
            sigR,
            sigS
        );

        require(
            signer != address(0x0),
            'Invalid signature'
        );
		return signer == user;
	}

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function getNonce(
        address _user
    )
        external
        view
        returns(uint256 nonce)
    {
        nonce = nonces[_user];
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/PaymentGateway.sol

pragma solidity ^0.8.8;


//coldWallet -> Backend doesnt have access
//hotWallet -> Backend has access
//hotWallet of each account cannot have a balance greater than $ 500
//a clientId can have multiple w

contract PaymentGateway is EIP712MetaTransaction  {




     struct Account {
        uint256 accountId;
        string name;
        address beneficiary;
        bool active;
    }

     uint256 accountCounter = 0;
     mapping(uint256 => Account) public accounts;
     uint32 public constant BASE_FEE = 1000000;
     IERC20 public acceptedToken;
    uint32 public fee;
    address public feeOwner;

     event DeveloperRegistered(
        uint256 developerId,
        string name,
        address beneficiary
    );


      event PaymentProcess(
        uint256 orderId,
        uint256 accountId,
        uint256 amount,
        address beneficiary,
        address payer
    );

     constructor(IERC20 _acceptedToken) EIP712Base("PaymentGateway", "v1.0") {
        acceptedToken = _acceptedToken;
        feeOwner = msg.sender;
        fee = 5000;
        //paperKeyManager = IPaperKeyManager(0x43Ca8B5b235A0f607259C8fEACd15f9f06f91878);
        
    }

   

    function registerDeveloper(string calldata name, address beneficiary) public {

        Account storage account = accounts[accountCounter];
        account.accountId = accountCounter;
        account.name = name;
        account.beneficiary = beneficiary;

        accountCounter = accountCounter + 1;

        emit DeveloperRegistered(account.accountId,account.name,account.beneficiary);

    }

    function processPayment(uint256 orderId, uint256 accountId, uint256 amount) public {

        Account storage account = accounts[accountId];

        require(isActive(accountId), "DEVELOPER_NOT_FOUND");

         address beneficiary = account.beneficiary;
         address sender = msg.sender;
         uint256 saleFee = (amount * fee) / BASE_FEE;

         require(acceptedToken.transferFrom(sender,beneficiary,amount - saleFee),"TRANSFER_PAYMENT_FAILED" );
         require(acceptedToken.transferFrom(sender, feeOwner, saleFee),"TRANSFER_FEES_FAILED");
        
        emit PaymentProcess(orderId,account.accountId,amount,account.beneficiary,sender);
    }


    function isActive(uint256 developerId) public view returns (bool) {
        return accounts[developerId].active;
    }

}