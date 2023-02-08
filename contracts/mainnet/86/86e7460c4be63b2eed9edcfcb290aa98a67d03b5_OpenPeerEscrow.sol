/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// File: contracts/libs/ERC2771Context.sol



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
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

// File: contracts/OpenPeerEscrow.sol


pragma solidity ^0.8.17;



contract OpenPeerEscrow is ERC2771Context {
    address public arbitrator;
    address payable public feeRecipient;
    address payable public immutable seller;
    address payable public immutable buyer;
    address public immutable token;
    uint256 public immutable amount;
    uint256 public immutable fee;
    uint32 public immutable sellerWaitingTime;
    uint32 public sellerCanCancelAfter;

    bool public dispute;

    /// @notice Settings
    /// @param _seller Seller address
    /// @param _buyer Buyer address
    /// @param _token Token address or 0x0000000000000000000000000000000000000000 for native token
    /// @param _fee OP fee (bps) ex: 30 == 0.3%
    /// @param _arbitrator Address of the arbitrator (currently OP staff)
    /// @param _feeRecipient Address to receive the fees
    /// @param _sellerWaitingTime Number of seconds where the seller can cancel the order if the buyer did not pay
    /// @param _trustedForwarder Forwarder address
    constructor(
        address payable _seller,
        address payable _buyer,
        address _token,
        uint256 _amount,
        uint256 _fee,
        address _arbitrator,
        address payable _feeRecipient,
        uint32 _sellerWaitingTime,
        address _trustedForwarder
    ) ERC2771Context(_trustedForwarder) {
        require(_amount > 0, "Invalid amount");
        require(_buyer != _seller, "Seller and buyer must be different");
        require(_seller != address(0), "Invalid seller");
        require(_buyer != address(0), "Invalid buyer");

        seller = _seller;
        token = _token;
        buyer = _buyer;
        amount = _amount;
        fee = (amount * _fee / 10_000);
        arbitrator = _arbitrator;
        feeRecipient = _feeRecipient;
        sellerWaitingTime = _sellerWaitingTime;
        sellerCanCancelAfter = uint32(block.timestamp) + sellerWaitingTime;
    }

    // Events
    event Released();
    event CancelledByBuyer();
    event SellerCancelDisabled();
    event CancelledBySeller();
    event DisputeOpened();
    event DisputeResolved();

    modifier onlySeller() {
        require(_msgSender() == seller, "Must be seller");
        _;
    }

    modifier onlyArbitrator() {
        require(_msgSender() == arbitrator, "Must be arbitrator");
        _;
    }

    modifier onlyBuyer() {
        require(_msgSender() == buyer, "Must be buyer");
        _;
    }

    /// @notice Release ether or token in escrow to the buyer.
    /// @return bool
    function release() external onlySeller returns (bool) {
        transferEscrowAndFees(buyer, amount, fee);
        emit Released();
        return true;
    }

    /// @notice Transfer the value of an escrow
    /// @param _to Recipient address
    /// @param _amount Amount to be transfered
    /// @param _fee Fee to be transfered
    function transferEscrowAndFees(address payable _to, uint256 _amount, uint256 _fee) private {
        withdraw(_to, _amount);
        if (_fee > 0) {
            withdraw(feeRecipient, _fee);
        }
    }

    /// @notice Cancel the escrow as a buyer with 0 fees
    /// @return bool
    function buyerCancel() external onlyBuyer returns (bool) {
        transferEscrowAndFees(seller, amount + fee, 0);
        emit CancelledByBuyer();
        return true;
    }

    /// @notice Cancel the escrow as a seller
    /// @return bool
    function sellerCancel() external onlySeller returns (bool) {
        if (sellerCanCancelAfter <= 1 || sellerCanCancelAfter > block.timestamp) {
            return false;
        }

        transferEscrowAndFees(seller, amount + fee, 0);
        emit CancelledBySeller();
        return true;
    }

    /// @notice Disable the seller from cancelling
    /// @return bool
    function markAsPaid() external onlyBuyer returns (bool) {
        sellerCanCancelAfter = 1;
        emit SellerCancelDisabled();
        return true;
    }

    /// @notice Withdraw values in the contract
    /// @param _to Address to withdraw fees in to
    /// @param _amount Amount to withdraw
    function withdraw(address payable _to, uint256 _amount) private  {
        if (token == address(0)) {
            (bool sent,) = _to.call{value: _amount}("");
            require(sent, "Failed to send MATIC");
        } else {
            require(IERC20(token).transfer(_to, _amount), "Failed to send tokens");
        }
    }

    /// @notice Allow seller or buyer to open a dispute
    function openDispute() external {
        require(_msgSender() == seller || _msgSender() == buyer, "Must be seller or buyer");

        if (token == address(0)) {
            require(address(this).balance > 0, "No funds to dispute");
        } else {
            require(IERC20(token).balanceOf(address(this)) > 0, "No funds to dispute");
        }

        dispute = true;
        emit DisputeOpened();
    }

    /// @notice Allow arbitrator to resolve a dispute
    /// @param _winner Address to receive the escrowed values - fees
    function resolveDispute(address payable _winner) external onlyArbitrator {
        require(dispute, "Dispute is not open");
        require(_winner == seller || _winner == buyer, "Winner must be seller or buyer");

        emit DisputeResolved();
        transferEscrowAndFees(_winner, amount, fee);
    }

    /// @notice Version recipient
    function versionRecipient() external pure returns (string memory) {
        return "1.0";
  	}

    receive() external payable {}
}