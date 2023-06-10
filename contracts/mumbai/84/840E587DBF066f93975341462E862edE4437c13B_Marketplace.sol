// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MarketplaceEscrow.sol";
import "./UserRegistry.sol";
import "./OfferContract.sol";
import "./OrderContract.sol";

contract Marketplace {
    address private escrowContract;
    address private offerContract;
    address private orderContract;

    ERC20 public tokenContract;
    
    

    event PlatformFeeCollected(address indexed payer, uint256 amount);

    constructor(
        address _escrowContract,
        address _offerContract,
        address _orderContract
    ) {
        require(
            _escrowContract != address(0),
            "Invalid escrow contract address"
        );
        require(_offerContract != address(0), "Invalid offer contract address");
        require(_orderContract != address(0), "Invalid offer contract address");

        escrowContract = _escrowContract;
        offerContract = _offerContract;
        orderContract = _orderContract;
    }

    /************************************/ 
    /* Deal Contract functions         */ 
    /************************************/  
    function createDeal(
        address _buyer,
        address _seller,
        uint256 _amount,
        address token,
        uint256 order,
        uint256 offer
    ) external {
        require(_seller != address(0), "Invalid seller address");
        require(_amount > 0, "Invalid deal amount");

        address buyer = _buyer;

        MarketplaceEscrow(escrowContract).createDeal(
            buyer,
            _seller,
            _amount,
            token,
            order,
            offer
        );
    }

    function completeDeal(uint256 _dealId) external {
        MarketplaceEscrow(escrowContract).completeDeal(_dealId);
    }

    function cancelDeal(uint256 _dealId) external {
        MarketplaceEscrow(escrowContract).cancelDeal(_dealId);
    }

    function getDeal(uint256 _dealId) external view returns(MarketplaceEscrow.Deal memory) {
        return MarketplaceEscrow(escrowContract).getDeal(_dealId);
    }

    /************************************/ 
    /* Order Contract functions         */ 
    /************************************/  
    function createOrder(
        string memory _purity,
        uint256 _volume,
        uint256 _density,
        uint256 _pressure,
        uint256 _temperature,
        uint256 _price,
        string memory _longitude,
        string memory _latitude,
        uint256 _co2footprint
    ) external {
        OrderContract(orderContract).createOrder(
            _purity,
            _volume,
            _density,
            _pressure,
            _temperature,
            _price,
            _longitude,
            _latitude,
            _co2footprint
        );
    }

    function getOrderCount() external view returns (uint256) {
        return OrderContract(orderContract).getOrderCount();
    }


    function getOrder(uint256 index) external view returns (OrderContract.Order memory) {
        return OrderContract(orderContract).getOrder(index);
    }

    /************************************/ 
    /* Offer Contract functions         */ 
    /************************************/  
 function createOffer(
         string memory _purity,
        uint256 _density,
        uint256 _volume,
        uint256 _pressure,
        uint256 _temperature,
        uint256 _price,
        string memory _longitude,
        string memory _latitude,
        uint256 _co2footprint
    ) external {
        OfferContract(offerContract).createOffer(
            _purity,
            _volume,
            _density,
            _pressure,
            _temperature,
            _price,
            _longitude,
            _latitude,
            _co2footprint
        );
    }

    function getOfferCount() public view returns (uint256) {
        return OfferContract(offerContract).getOfferCount();
    }

    function getOffer(uint256 index) public view returns (OfferContract.Offer memory) {
        return OfferContract(offerContract).getOffer(index);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MarketplaceEscrow {
    enum DealStatus {
        Pending,
        Completed,
        Canceled
    }

    struct Deal {
        DealStatus status;
        address buyer;
        address seller;
        uint256 amount;
        address token;
        uint256 offer;
        uint256 order;
        uint256 created;
    }

    mapping(uint256 => Deal) public deals;
    uint256 public dealCount;

    ERC20 public tokenContract;

    event DealCreated(
        uint256 dealId,
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        address indexed token
    );
    event DealCompleted(uint256 dealId);
    event DealCanceled(uint256 dealId);

    constructor(address _tokenContract) {
        tokenContract = ERC20(_tokenContract);
        dealCount = 0;
    }

    function createDeal(
        address _buyer,
        address _seller,
        uint256 _amount,
        address token,
        uint256 order,
        uint256 offer
    ) external returns (uint256) {
        require(_buyer != address(0), "Invalid buyer address");
        require(_seller != address(0), "Invalid seller address");
        require(_amount > 0, "Invalid deal amount");

        uint256 newDealId = dealCount;
        

        deals[newDealId] = Deal(
            DealStatus.Pending,
            _buyer,
            _seller,
            _amount,
            token,
            order,
            offer,
            block.timestamp
        );
        dealCount++;

        emit DealCreated(newDealId, _buyer, _seller, _amount, token);
    
        return newDealId;
    }

    function completeDeal(uint256 _dealId) external {
        require(
            deals[_dealId].status == DealStatus.Pending,
            "Deal is not pending"
        );

        Deal storage deal = deals[_dealId];
        deal.status = DealStatus.Completed;

        // ERC20(deal.token).transferFrom(deal.buyer, deal.seller, deal.amount);

        emit DealCompleted(_dealId);
    }

    function cancelDeal(uint256 _dealId) external {
        require(
            deals[_dealId].status == DealStatus.Pending,
            "Deal is not pending"
        );

        Deal storage deal = deals[_dealId];
        deal.status = DealStatus.Canceled;

        emit DealCanceled(_dealId);
    }

    function getDeal(uint256 _dealId) external view returns(Deal memory) {
        // require(_dealId > 0, "Deal id must be greater than 0");
        return deals[_dealId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OfferContract {
    struct Offer {
        uint256 id;
        string purity;
        uint256 volume;
        uint256 density;
        uint256 pressure;
        uint256 temperature;
        uint256 price;
        string longitude;
        string latitude;
        uint256 co2footprint;
    }

    Offer[] public offers;
    uint256 private offerCount = 0;

      event OfferCreated(
        uint256 id,
        address indexed sender,
        string indexed quality,
        uint256 indexed density
    );

    function createOffer(
        string memory _purity,
        uint256 _density,
        uint256 _volume,
        uint256 _pressure,
        uint256 _temperature,
        uint256 _price,
        string memory _longitude,
        string memory _latitude,
        uint256 _co2footprint
    ) public {
        require(msg.sender != address(0)," Invalid sender address!");
        Offer memory newOffer = Offer(
            offerCount,
            _purity,
            _volume,
            _density,
            _pressure,
            _temperature,
            _price,
            _longitude,
            _latitude,
            _co2footprint
        );

        offers.push(newOffer);
        offerCount++;

        emit OfferCreated(newOffer.id, msg.sender, _purity, _density);
    }

    function getOfferCount() public view returns (uint256) {
        return offerCount;
    }

    function getOffer(uint256 index) public view returns (Offer memory) {
        require(index < offers.length, "Index out of range");
        return offers[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrderContract {
    struct Order {
        uint256 id;
        string purity;
        uint256 volume;
        uint256 density;
        uint256 pressure;
        uint256 temperature;
        uint256 price;
        string longitude;
        string latitude;
        uint256 co2footprint;
    }

    Order[] public orders;
    uint256 private orderCount = 0;

    event OrderCreated(
        uint256 id,
        address indexed sender,
        string indexed purity,
        uint256 indexed density
    );

    function createOrder(
        string memory _purity,
        uint256 _volume,
        uint256 _density,
        uint256 _pressure,
        uint256 _temperature,
        uint256 _price,
        string memory _longitude,
        string memory _latitude,
        uint256 _co2footprint
    ) public {
        require(msg.sender != address(0), "Invalid sender address!");
        Order memory newOrder = Order(
            orderCount,
            _purity,
            _volume,
            _density,
            _pressure,
            _temperature,
            _price,
            _longitude,
            _latitude,
            _co2footprint
        );

        orders.push(newOrder);
        orderCount++;

        emit OrderCreated(newOrder.id, msg.sender, _purity, _density);
    }

    function getOrderCount() public view returns (uint256) {
       return orderCount;     
    }

    function getOrder(uint256 index) public view returns (Order memory) {
        require(index < orders.length, "Index out of range");
        return orders[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserRegistry {
    struct User {
        uint256 volumePerMonth;
        bool registered;
    }

    mapping(address => User) public users;

    event UserRegistered(address indexed user);
    event VolumeUpdated(address indexed user, uint256 volumePerMonth);

    constructor() {}

    function registerUser(address _user) external {
        require(_user != address(0), "Invalid user address");

        users[_user] = User(0, true);

        emit UserRegistered(_user);
    }

    function addVolume(address _user, uint256 _volume) external {
        require(_user != address(0), "Invalid user address");
        require(users[_user].registered, "Address is not registered");
        require(_volume > 0, "Volume per month must be greater than zero");

        users[_user].volumePerMonth += _volume;

        emit VolumeUpdated(_user, _volume);
    }

    function getUserFeePercentage(
        address _user
    ) external view returns (uint256) {
        require(_user != address(0), "Invalid user address");
        require(users[_user].registered, "Address is not registered");

        uint256 volume = users[_user].volumePerMonth;

        if (volume < 100000) {
            return 300; // 3% represented as 300 (3 * 100)
        } else if (volume < 1000000) {
            return 150; // 1.5% represented as 150 (1.5 * 100)
        } else if (volume < 5000000) {
            return 90; // 0.9% represented as 90 (0.9 * 100)
        } else {
            // Default fee percentage if volume exceeds 5,000,000 USD is 0.35%
            return 35;
        }
    }

    function getUserInfo(address _user) external view returns (User memory) {
        require(_user != address(0), "Invalid user address!");
        return users[_user];
    }
}