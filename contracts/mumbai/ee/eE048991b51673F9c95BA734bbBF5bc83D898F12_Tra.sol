// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Tra is Ownable {

    enum ActionStatus {
        INPROGRESS,
        SUCCESS,
        FAILURE,
        CANCELED
    }

    struct Shipment {
        address sender;
        address recipient;
        uint start_time;
        string item1;
        uint256 quantity1;
        uint256 price1;
        string item2;
        uint256 quantity2;
        uint256 price2;
        bool receiver_sign;
        ActionStatus action_status;
    }

    struct Condition {
        uint end_time;
        string destination;
        uint256 token_amount;
    }

    event Log(string text);

    uint256 public shipment_id;
    uint256 public purchase_id;
    uint256 public invoice_id;
    IERC20 usdc;
    mapping(address => uint256) public balances;
    mapping(uint256 => Shipment) public shipments;
    mapping(uint256 => Condition) public conditions;
    mapping(uint256 => uint256) public purchase_list;
    mapping(uint256 => uint256) public invoice_list;
    mapping(address => uint256) public shipment_list;
    mapping(address => uint256) public success_shipment_list;

    constructor() {
        shipment_id = 0;
        purchase_id = 0;
        invoice_id = 0;
        usdc = IERC20(0x0FA8781a83E46826621b3BC094Ea2A0212e71B23);
    }

    function sendToken(address from, address to, uint256 token_amount) private {
        balances[from] = usdc.balanceOf(from);
        require(balances[from] >= token_amount, "You do not have enough tokens.");
        require(usdc.transferFrom(from, to, token_amount));
        emit Log("Payment sent.");
    }

    function getBalance(address supplier) public view returns (uint256) {
        return balances[supplier];
    }

    function recoverToken(uint purchase_cid) public onlyOwner {
        balances[shipments[purchase_cid].sender] -= conditions[purchase_cid].token_amount;
        balances[shipments[purchase_cid].recipient] += conditions[purchase_cid].token_amount;

        require(usdc.transfer(shipments[purchase_cid].recipient, conditions[purchase_cid].token_amount));
    }

    function setContractParameters(uint256 purchase_cid, uint end_time, string memory destination, uint256 token_amount) public onlyOwner {
        conditions[purchase_cid] = Condition(end_time, destination, token_amount);
    }
    
    function createContract(address recipient, string memory item1, uint256 quantity1, uint256 price1, string memory item2, uint256 quantity2, uint256 price2) public {
        shipments[++shipment_id] = Shipment(msg.sender, recipient, block.timestamp, item1, quantity1, price1, item2, quantity2, price2, false, ActionStatus.INPROGRESS);
        shipment_list[msg.sender] ++;
    }
    
    function purchaseOrder(uint256 shipment_cid) public {
        uint256 token_amount = 0;
        require(shipments[shipment_cid].recipient == msg.sender, "This account is not buyer.");
        token_amount = shipments[shipment_cid].price1 * shipments[shipment_cid].quantity1 + shipments[shipment_cid].price2 * shipments[shipment_cid].quantity2;  
        sendToken(msg.sender, address(this), token_amount);
        shipments[shipment_cid].receiver_sign = true;
        purchase_list[++purchase_id] = shipment_cid;
    }
    
    function issueInvoice(uint256 purchase_cid) public {
        uint256 token_amount = 0;
        uint256 shipment_cid = purchase_list[purchase_cid];
        if(shipments[shipment_cid].sender != msg.sender){
            emit Log("This shipment is not yours.");
            shipments[shipment_cid].action_status = ActionStatus.FAILURE;
        } 
        else if(shipments[shipment_cid].receiver_sign == false) {
            emit Log("The receiver did not sign.");
        } else {
            token_amount = shipments[shipment_cid].price1 * shipments[shipment_cid].quantity1 + shipments[shipment_cid].price2 * shipments[shipment_cid].quantity2;  
            require(usdc.transfer(msg.sender, token_amount));
            shipments[shipment_cid].action_status = ActionStatus.SUCCESS;
            success_shipment_list[shipments[shipment_cid].sender] ++;
            invoice_list[++invoice_id] = shipment_cid;
        }

    }

    function deleteShipment(uint256 purchase_cid) public onlyOwner {
        shipments[purchase_cid].action_status = ActionStatus.CANCELED;
        shipment_list[shipments[purchase_cid].sender] --;
    }
    
    function checkShipment(uint256 purchase_cid) public view returns (Shipment memory) {
        return shipments[purchase_cid];
    }
    
    function checkSuccess(address recipient) public view returns (uint256) {
        return success_shipment_list[recipient];
    }
    
    function calculateReputation(address recipient) public view returns (uint256)  {
        if(shipment_list[recipient] > 0){
            return (uint256) (success_shipment_list[recipient] * 100 / shipment_list[recipient]);
        } else {
            return 0;
        }
    }
}