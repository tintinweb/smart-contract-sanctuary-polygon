// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOpenStay.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract OpenStay is Ownable, IOpenStay {

    using Counters for Counters.Counter;
    Counters.Counter private _idCounter;

    uint256 constant MAX_BPS = 10_000;

    uint256 public platformTax = 500;

    uint256 private _adminBalance;

    mapping(uint256 => bool) private _rentalIds;
    mapping(uint256 => RentalProperties) private _rentals;
    mapping(uint256 => PaymentSettings) private _paymentSettings;
    mapping(uint256 => Booking[]) private _rentalBookings;
    mapping(uint256 => address) private _rentalProvider;
    mapping(address => uint256) public balanceOf;

    IERC20 public paymentToken;

    constructor(IERC20 _paymentToken) {
        paymentToken = _paymentToken;
    }

    function addRental(
        RentalProperties memory rentalProperties,
        PaymentSettings memory paymentSettings
    ) external {
        require(validatePaymentSettings(paymentSettings), "[addRental]: invalid payment settings");

        uint256 id = _idCounter.current();
        _idCounter.increment();

        rentalProperties.id = id;

        _rentalIds[id] = true;
        _rentals[id] = rentalProperties;
        _paymentSettings[id] = paymentSettings;
        _rentalProvider[id] = msg.sender;

        emit RentalCreated(id, msg.sender, rentalProperties, paymentSettings);
    }

    function bookRental(uint256 rentalId, uint256 bookFrom, uint256 amountOfNights) external
    {
        require(_rentalIds[rentalId], "[bookRental]: invalid rentalId specified");
        require(checkAvailability(rentalId, bookFrom, amountOfNights), "[bookRental]: date is not available");

        _payForRental(rentalId, amountOfNights);
        _rentalBookings[rentalId].push(Booking(bookFrom, amountOfNights, msg.sender, rentalId));

        emit RentalBooked(rentalId, bookFrom, amountOfNights, msg.sender);
    }

    function editFeatures(address initiator, uint256 rentalId, string[] memory features) external onlyOwner {
        require(_rentalIds[rentalId], "[editFeatures]: invalid rental id");
        require(_rentalProvider[rentalId] == initiator, "[editFeatures]: unauthorized");
        require(features.length > 0, "[editFeatures]: features are empty");

        _rentals[rentalId].features = features;

        emit UpdateRentalProperties(rentalId, _rentals[rentalId]);
    }

    function editMaxGuests(address initiator, uint256 rentalId, uint8 maxGuests) external onlyOwner {
        require(_rentalIds[rentalId], "[editMaxGuests]: invalid rental id");
        require(_rentalProvider[rentalId] == initiator, "[editMaxGuests]: unauthorized");
        require(maxGuests > 0, "[editMaxGuests]: max guests cannot be zero");

        _rentals[rentalId].maxGuests = maxGuests;

        emit UpdateRentalProperties(rentalId, _rentals[rentalId]);
    }

    function editPricePerNight(address initiator, uint256 rentalId, uint256 price) external onlyOwner {
        require(_rentalIds[rentalId], "[editPricePerNight]: invalid rental id");
        require(_rentalProvider[rentalId] == initiator, "[editPricePerNight]: unauthorized");
        require(price > 0, "[editPricePerNight]: price cannot be zero");

        _rentals[rentalId].pricePerNight = price;

        emit UpdateRentalProperties(rentalId, _rentals[rentalId]);
    }

    function editVisibility(address initiator, uint256 rentalId, bool isHidden) external onlyOwner {
        require(_rentalIds[rentalId], "[editVisibility]: invalid rental id");
        require(_rentalProvider[rentalId] == initiator, "[editVisibility]: unauthorized");

        _rentals[rentalId].isHidden = isHidden;

        emit UpdateRentalProperties(rentalId, _rentals[rentalId]);
    }

    function updatePaymentSettings(address initiator, uint256 rentalId, PaymentSettings memory paymentSettings) external onlyOwner {
        require(_rentalIds[rentalId], "[updatePaymentSettings]: invalid rental id");
        require(_rentalProvider[rentalId] == initiator, "[updatePaymentSettings]: unauthorized");
        require(validatePaymentSettings(paymentSettings), "[updatePaymentSettings]: invalid payment settings");

        _paymentSettings[rentalId] = paymentSettings;

        emit UpdateRentalPaymentSettings(rentalId, _paymentSettings[rentalId]);
    }

    function _payForRental(uint256 rentalId, uint256 amountOfNights) private {
        PaymentSettings memory paymentSettings = _paymentSettings[rentalId];
        address sender = msg.sender;
        uint256 price = _rentals[rentalId].pricePerNight * amountOfNights;
        uint256 priceAfterTax = price - price * platformTax / MAX_BPS;

        paymentToken.transferFrom(sender, address(this), price);

        _adminBalance += price * platformTax / MAX_BPS;

        for (uint8 i = 0; i < paymentSettings.receivers.length; i++) {
            balanceOf[paymentSettings.receivers[i]] += priceAfterTax * paymentSettings.shares[i] / MAX_BPS;
        }
    }

    function withdrawToWallet(address from, address to, uint256 value) external onlyOwner {
        require(balanceOf[from] >= value, '[withdrawToWallet]: insufficient balance');
        paymentToken.transfer(to, value);
        balanceOf[from] -= value;
        emit Withdraw(from, to, value);
    }

    function adminWithdraw() external onlyOwner {
        paymentToken.transfer(owner(), _adminBalance);
    }

    function getAdminBalance() external view onlyOwner returns(uint256)  {
        return _adminBalance;
    }

    function validatePaymentSettings(PaymentSettings memory paymentSettings) internal pure returns(bool) {
        if (paymentSettings.shares.length != paymentSettings.receivers.length
            || paymentSettings.shares.length != paymentSettings.names.length
            || paymentSettings.shares.length != paymentSettings.roles.length
        ) return false;

        uint256 total;

        for (uint8 i = 0; i < paymentSettings.shares.length; i++) {
            total += paymentSettings.shares[i];
        }

        return total == MAX_BPS;
    }

    function checkAvailability(uint256 rentalId, uint256 startFrom, uint256 amountOfNights) internal view returns(bool) {
        Booking[] memory bookings = _rentalBookings[rentalId];
        uint256 endTimestamp = startFrom + (amountOfNights * 1 days + 1 days);
        for (uint256 i = 0; i < bookings.length; i++) {
            uint256 bookingEndTimestamp = bookings[i].fromTimestamp + (bookings[i].nights * 1 days + 1 days);
            if ((startFrom >= bookings[i].fromTimestamp && startFrom <= bookingEndTimestamp) ||
            (endTimestamp >= bookings[i].fromTimestamp && endTimestamp <= bookingEndTimestamp) ||
            (bookings[i].fromTimestamp >= startFrom && bookings[i].fromTimestamp <= endTimestamp) ||
                (bookingEndTimestamp >= startFrom && bookingEndTimestamp <= endTimestamp)) {
                return false;
            }
        }
        return true;
    }

    function updatePlatformComission(uint256 taxShare) external onlyOwner {
        platformTax = taxShare;
    }

    function getRentals() external view returns (RentalProperties[] memory) {
        RentalProperties[] memory rentals = new RentalProperties[](_idCounter.current());

        for (uint256 i = 0; i < _idCounter.current(); i++) {
            rentals[i] = _rentals[i];
        }

        return rentals;
    }

    function getRental(uint256 rentalId) external view returns (RentalProperties memory) {
        return _rentals[rentalId];
    }

    function getPaymentSettings(uint256 rentalId) external view returns(PaymentSettings memory) {
        return _paymentSettings[rentalId];
    }

    function getRentalBookings(uint256 rentalId)
    external
    view
    returns (Booking[] memory)
    {
        return _rentalBookings[rentalId];
    }

    function getRentPrice(uint256 rentalId, uint256 amountOfNights) external view returns(uint256) {
        return _rentals[rentalId].pricePerNight * amountOfNights;
    }

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

interface IOpenStay {
  struct RentalProperties {
    string host;
    string name;
    string lng;
    string lat;
    uint256 pricePerNight;
    string[] imgs;
    bool isVerified;
    bool isHidden;
    uint8 bedsCount;
    uint8 bathroomsCount;
    uint8 maxGuests;
    string description;
    string[] features;
    string createdAt;
    string updatedAt;
    uint256 id;
  }

  struct PaymentSettings {
    address[] receivers;
    uint256[] shares;
    string[] roles;
    string[] names;
  }

  struct Booking {
    uint256 fromTimestamp;
    uint256 nights;
    address bookerAddress;
    uint256 rentalId;
  }

  event RentalCreated(
    uint256 rentalId,
    address rentalProvider,
    RentalProperties rentalProperties,
    PaymentSettings paymentSettings
  );
  event RentalBooked(
    uint256 rentalId,
    uint256 fromTimestamp,
    uint256 nights,
    address booker
  );
  event UpdateRentalProperties(
    uint256 rentalId,
    RentalProperties rentalProperties
  );
  event UpdateRentalPaymentSettings(
    uint256 rentalId,
    PaymentSettings paymentSettings
  );
  event Withdraw(address from, address to, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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