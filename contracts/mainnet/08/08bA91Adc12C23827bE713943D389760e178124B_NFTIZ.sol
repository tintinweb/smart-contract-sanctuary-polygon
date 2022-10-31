// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTIZ is Ownable {
    struct Offer {
        address token;
        address owner;
        uint256 budget;
        uint256 balance;
        uint256 total;
        uint256 quantity;
        uint256 vesting;
        uint256 closedAfter;
        bool recover;
    }

    struct WalletProfit {
        uint256 balance;
        uint256 total;
        uint256 quantity;
    }

    /* Project Fee - [ERC20 TOKEN]: amount */
    mapping(address => uint256) internal projectFee;
    /* Offers - [UNIQUE OFFER_ID]: { ...offerData } */
    mapping(string => Offer) public offers;
    /* Profit - [UNIQUE OFFER_ID]: { [wallet]: amount } */
    mapping(string => mapping(address => WalletProfit)) public profit;
    /* Signer Wallet */
    address internal _signer;

    /* Events */
    event CreateOffer(string indexed offerId, uint256 budget);
    event CloseOffer(string indexed offerId, uint256 percent, uint256 date);

    event AddBudget(string indexed offerId, uint256 amount, uint256 budget);
    event WithdrawBudget(string indexed offerId, uint256 amount, address wallet);

    event AddProfit(string indexed offerId, address wallet, uint256 amount, uint256 fee);
    event WithdrawProfit(string indexed offerId, address wallet, uint256 amount);

    /* Modifiers */
    modifier onlyOwnerOrSigner {
        require(owner() == _msgSender() || signer() == _msgSender(), "Caller is not the owner or signer");
        _;
    }

    modifier preCheckWithdrawProfit(string memory _offerId) {
        if (offers[_offerId].vesting != 0) {
            uint256 endVestingDate = offers[_offerId].closedAfter + offers[_offerId].vesting;

            require(offers[_offerId].closedAfter != 0, "Offer must be closed");
            require(block.timestamp >= endVestingDate, "Vesting hasn't ended");
        }

        _;
    }

    function signer() public view returns(address) {
        return _signer;
    }

    function setSigner(address _newSigner) public onlyOwner {
        _signer = _newSigner;
    }

    function _getERC20Tokens(address _token, uint256 _amount) internal {
        IERC20 tkn = IERC20(_token);
        tkn.transferFrom(_msgSender(), address(this), _amount);
    }

    function _withdrawERC20Tokens(address _wallet, address _token, uint256 _amount) internal {
        IERC20 tkn = IERC20(_token);
        tkn.transfer(_wallet, _amount);
    }

    function createOffer(string memory _offerId, address _token, uint256 _amount, uint256 _vesting, bool _recover) public {
        require(_amount > 0, "You need to specify a budget for the offer");
        require(offers[_offerId].owner == address(0), "Offer with this ID already exists");

        Offer memory newOffer = Offer({
            token: _token,
            owner: _msgSender(),
            budget: _amount,
            balance: _amount,
            vesting: _vesting,
            recover: _recover,
            total: 0,
            quantity: 0,
            closedAfter: 0
        });

        _getERC20Tokens(_token, _amount);
        offers[_offerId] = newOffer;

        emit CreateOffer(_offerId, _amount);
    }

    function addBudget(string memory _offerId, uint256 _amount) public {
        require(offers[_offerId].closedAfter == 0, "Offer is closed");

        _getERC20Tokens(offers[_offerId].token, _amount);

        offers[_offerId].budget += _amount;
        offers[_offerId].balance += _amount;

        emit AddBudget(_offerId, _amount, offers[_offerId].budget);
    }

    function _withdrawOfferBudget(string memory _offerId, uint256 _amount, address _wallet) internal {
        require(offers[_offerId].closedAfter != 0, "Offer is not closed");
        require(block.timestamp > offers[_offerId].closedAfter, "Blocking period has not ended");
        require(offers[_offerId].balance >= _amount, "Insufficient funds");

        _withdrawERC20Tokens(_wallet, offers[_offerId].token, _amount);

        offers[_offerId].balance -= _amount;

        emit WithdrawBudget(_offerId, _amount, _wallet);
    }

    function withdrawBudget(string memory _offerId, uint256 _amount, address _wallet) public {
        require(offers[_offerId].owner == _msgSender(), "Only the owner of the offer can withdraw");

        _withdrawOfferBudget(_offerId, _amount, _wallet);
    }

    function recoverBudget(string memory _offerId, uint256 _amount, address _wallet) public onlyOwner {
        require(offers[_offerId].recover, "Recovery is inactive for this offer");

        _withdrawOfferBudget(_offerId, _amount, _wallet);
    }

    function closeOffer(string memory _offerId, uint256 _percent, uint256 _date, address _wallet) public onlyOwnerOrSigner {
        require(offers[_offerId].closedAfter == 0, "Offer is already closed");
        require(_percent >= 0 && _percent <= 100, "Wrong percentage");
        require(_date != 0, "Date is required");

        uint256 newBalance = _percent * offers[_offerId].balance / 100;
        address destination = offers[_offerId].owner;

        if (_wallet != address(0)) destination = _wallet;

        _withdrawERC20Tokens(destination, offers[_offerId].token, offers[_offerId].balance - newBalance);

        offers[_offerId].balance = newBalance;
        offers[_offerId].closedAfter = _date;

        emit CloseOffer(_offerId, _percent, _date);
    }

    function getFee(address _token) public view returns(uint256) {
        return projectFee[_token];
    }

    function withdrawFee(address _wallet, address _token, uint256 _amount) public onlyOwner {
        require(projectFee[_token] >= _amount, "Insufficient funds to withdraw");

        _withdrawERC20Tokens(_wallet, _token, _amount);

        projectFee[_token] -= _amount;
    }

    function addProfit(string memory _offerId, address _wallet, uint256 _amount, uint256 _fee) public onlyOwnerOrSigner {
        require(_wallet != address(0), "Incorrect wallet");
        require(_fee >= 0 && _fee <= 100, "Wrong Fee");
        require(offers[_offerId].balance >= _amount, "Offer balance exhausted");

        offers[_offerId].balance -= _amount;

        uint256 feeAmount = _fee * _amount / 100;
        uint256 value = _amount - feeAmount;

        profit[_offerId][_wallet].balance += value;
        projectFee[offers[_offerId].token] += feeAmount;
        
        /* Accounting */
        profit[_offerId][_wallet].quantity += 1;
        profit[_offerId][_wallet].total += value;

        offers[_offerId].quantity += 1;
        offers[_offerId].total += value;
        
        /* NFTIZ Accounting */
        profit[_offerId][address(0)].quantity += 1;
        profit[_offerId][address(0)].total += feeAmount;

        emit AddProfit(_offerId, _wallet, _amount, _fee);
    }

    function _withdrawOfferProfit(string memory _offerId, address _from, address _to, uint256 _amount) internal {
        require(profit[_offerId][_from].balance >= _amount, "Insufficient funds to withdraw");

        _withdrawERC20Tokens(_to, offers[_offerId].token, _amount);

        profit[_offerId][_from].balance -= _amount;

        emit WithdrawProfit(_offerId, _from, _amount);
    }

    function withdrawProfit(string memory _offerId, uint256 _amount) public preCheckWithdrawProfit(_offerId) {
        _withdrawOfferProfit(_offerId, _msgSender(), _msgSender(), _amount);
    }

    function recoverProfit(string memory _offerId, address _from, address _to, uint256 _amount) public onlyOwner preCheckWithdrawProfit(_offerId) {
        _withdrawOfferProfit(_offerId, _from, _to, _amount);
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