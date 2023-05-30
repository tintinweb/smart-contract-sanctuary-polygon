// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
pragma solidity 0.8.18;

interface IConsumer {
    function init(uint256 _stonkslyRequestId, string[] calldata args) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IConsumer.sol";

interface IStonksly {
    enum RequestType {
        PURCHASE,
        SALE
    }

    enum RequestStatus {
        NONE,
        PENDING,
        COMPLETED,
        REFUNDED
    }

    struct Request {
        RequestType requestType;
        RequestStatus status;
        address account;
        address sToken;
        uint256 amount;
        uint256 id;
    }

    function createSToken(
        string memory _name,
        string memory _symbol,
        string memory _assetSymbol
    ) external;

    function initPurchase(address _sToken) external payable;

    function finalizePurchase(uint256 _requestId, uint256 _assetPrice) external;

    function undoPurchase(uint256 _requestId) external;

    function initSale(address _sToken, uint256 _amount) external;

    function finalizeSale(uint256 _requestId, uint256 _assetPrice) external;

    function undoSale(uint256 _requestId) external;

    function emergencyRefund(uint256 _requestId) external;

    function setPurchaseConsumer(IConsumer _purchaseConsumer) external;

    function setSaleConsumer(IConsumer _saleConsumer) external;

    function withdrawFees() external;

    function addLiquidity() external payable;

    function removeLiquidity(uint256 _amount) external;

    function getPurchaseConsumer() external view returns (address);

    function getSaleConsumer() external view returns (address);

    function getCollectedFees() external view returns (uint256);

    function isPurchasable(address _sToken) external view returns (bool);

    function getRequest(uint256 _id) external view returns (Request memory);

    function getLiquidity(address _provider) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SToken is ERC20, Ownable {
    string private s_assetSymbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _assetSymbol
    ) ERC20(_name, _symbol) {
        s_assetSymbol = _assetSymbol;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    function getAssetSymbol() external view returns (string memory) {
        return s_assetSymbol;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import "./SToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STokenManager is Ownable {
    struct STokenWithData {
        address sToken;
        string symbol;
        string assetSymbol;
    }

    address[] s_sTokens;

    event STokenCreated(
        address token,
        string name,
        string symbol,
        string assetSymbol
    );

    function deploySToken(
        string memory _name,
        string memory _symbol,
        string memory _assetSymbol
    ) external onlyOwner returns (address) {
        SToken sToken = new SToken(_name, _symbol, _assetSymbol);
        sToken.transferOwnership(msg.sender);

        address sTokenAddress = address(sToken);
        s_sTokens.push(sTokenAddress);

        emit STokenCreated(sTokenAddress, _name, _symbol, _assetSymbol);

        return sTokenAddress;
    }

    function getSTokens() external view returns (STokenWithData[] memory) {
        address[] memory sTokens = s_sTokens;
        STokenWithData[] memory sTokensWithData = new STokenWithData[](
            sTokens.length
        );
        for (uint i = 0; i < sTokens.length; i++) {
            SToken sToken = SToken(sTokens[i]);
            sTokensWithData[i] = STokenWithData(
                address(sToken),
                sToken.symbol(),
                sToken.getAssetSymbol()
            );
        }
        return sTokensWithData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IConsumer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./STokenManager.sol";
import "./IStonksly.sol";

error Stonksly__NotAllowedCall(address who);
error Stonksly__TransferFailed(address account, uint256 amount);
error Stonksly_RequestIsNotPending(uint256 id);
error Stonksly_ConsumerAlreadySet();
error Stonksly__NotEnoughtLiquidityProvided();
error Stonksly__STokenNotRegistered(address sToken);
error Stonksly__RequestNotExists(uint256 requestId);
error Stonksly__NotTheRequestOwner(address who, address requestOwner);
error Stonksly__InvestmentRequired();

contract Stonksly is IStonksly, Ownable {
    address immutable s_stonkslyWallet;
    AggregatorV3Interface immutable s_priceFeed;
    STokenManager immutable s_sTokenManager;

    IConsumer private s_purchaseConsumer;
    IConsumer private s_saleConsumer;

    uint256 private s_collectedFees;
    uint256 private s_idCounter;

    address[] private s_sTokensAddresses;
    mapping(address => bool) private s_sTokens;
    mapping(uint256 => Request) private s_requests;
    mapping(address => uint256) private s_liquidityProviders;

    event RequestCreated(
        uint256 id,
        RequestType requestType,
        address accout,
        address sToken,
        uint256 payment
    );

    event RequestCompleted(
        uint256 id,
        RequestType requestType,
        address account,
        address sToken,
        uint256 sTokenAmount,
        uint256 maticAmount
    );

    event RequestRefunded(uint256 id);

    event LiquidityProvided(address who, uint256 amount);
    event LiquidityRemoved(address who, uint256 amount);

    event FeesCollected(uint256 amount);

    constructor(
        address _stonkslyWallet,
        AggregatorV3Interface _priceFeed,
        STokenManager _sTokenManager
    ) {
        s_stonkslyWallet = _stonkslyWallet;
        s_priceFeed = _priceFeed;
        s_sTokenManager = _sTokenManager;
    }

    function createSToken(
        string memory _name,
        string memory _symbol,
        string memory _assetSymbol
    ) external onlyOwner {
        address sToken = s_sTokenManager.deploySToken(
            _name,
            _symbol,
            _assetSymbol
        );
        s_sTokens[sToken] = true;
    }

    function initPurchase(address _sToken) external payable {
        if (msg.value == 0) {
            revert Stonksly__InvestmentRequired();
        }
        checkIfSTokenRegistered(_sToken);
        uint256 id = s_idCounter++;
        Request memory request = Request(
            RequestType.PURCHASE,
            RequestStatus.PENDING,
            msg.sender,
            _sToken,
            msg.value,
            id
        );
        s_requests[id] = request;

        string memory assetSymbol = SToken(_sToken).getAssetSymbol();
        string[] memory args = new string[](1);
        args[0] = assetSymbol;

        s_purchaseConsumer.init(id, args);

        emit RequestCreated(
            id,
            RequestType.PURCHASE,
            msg.sender,
            _sToken,
            msg.value
        );
    }

    //sprawdzić czy purchase request
    function finalizePurchase(
        uint256 _requestId,
        uint256 _assetPrice
    ) external {
        checkIfAllowed(address(s_purchaseConsumer));
        Request memory request = s_requests[_requestId];

        checkIfPending(request);

        request.status = RequestStatus.COMPLETED;
        s_requests[_requestId] = request;
        (, int price, , , ) = s_priceFeed.latestRoundData();

        // MATIC/USD -> 8 decimals, 18 decimals
        uint256 normalizedMaticPrice = uint256(price) * 1e10;

        //0,1% fee
        uint256 afterCharge = ((request.amount * 999) / 1000);
        s_collectedFees += request.amount - afterCharge;

        uint256 valueInUsd = (afterCharge * normalizedMaticPrice) / 1e18;
        uint256 valueInCents = valueInUsd * 100;

        uint256 normalizedAssetPrice = _assetPrice * 1e18;
        uint256 amount = (valueInCents * 1e18) / normalizedAssetPrice;

        SToken(request.sToken).mint(request.account, amount);

        emit RequestCompleted(
            _requestId,
            RequestType.PURCHASE,
            request.account,
            request.sToken,
            amount,
            request.amount
        );
    }

    function undoPurchase(uint256 _requestId) external {
        checkIfAllowed(address(s_purchaseConsumer));
        Request memory request = s_requests[_requestId];

        checkIfPending(request);

        request.status = RequestStatus.REFUNDED;
        s_requests[_requestId] = request;

        sendMatic(request.account, request.amount);

        emit RequestRefunded(_requestId);
    }

    //_sToken needs to be approved first
    function initSale(address _sToken, uint256 _amount) external {
        if (_amount == 0) {
            revert Stonksly__InvestmentRequired();
        }
        checkIfSTokenRegistered(_sToken);
        uint256 id = s_idCounter++;
        Request memory request = Request(
            RequestType.SALE,
            RequestStatus.PENDING,
            msg.sender,
            _sToken,
            _amount,
            id
        );
        s_requests[id] = request;

        SToken(_sToken).transferFrom(msg.sender, address(this), _amount);

        string memory assetSymbol = SToken(_sToken).getAssetSymbol();
        string[] memory args = new string[](1);
        args[0] = assetSymbol;

        s_saleConsumer.init(id, args);

        emit RequestCreated(id, RequestType.SALE, msg.sender, _sToken, _amount);
    }

    function finalizeSale(uint256 _requestId, uint256 _assetPrice) external {
        checkIfAllowed(address(s_saleConsumer));
        Request memory request = s_requests[_requestId];

        checkIfPending(request);

        request.status = RequestStatus.COMPLETED;
        s_requests[_requestId] = request;
        (, int price, , , ) = s_priceFeed.latestRoundData();

        uint256 normalizedMaticPriceInUsd = uint256(price) * 1e10;
        uint256 maticPriceInCents = normalizedMaticPriceInUsd * 100;
        uint normalizedAssetPrice = _assetPrice * 1e18;

        uint256 sTokensValueInCents = (normalizedAssetPrice * request.amount) /
            1e18; // 100000000000000000000

        uint256 maticAmount = (sTokensValueInCents * 1e18) / maticPriceInCents;

        // //0,1% fee
        uint256 maticToWithdraw = (maticAmount * 999) / 1000;
        s_collectedFees += maticAmount - maticToWithdraw;

        SToken(request.sToken).burn(address(this), request.amount);
        sendMatic(request.account, maticToWithdraw);

        emit RequestCompleted(
            _requestId,
            RequestType.SALE,
            request.account,
            request.sToken,
            request.amount,
            maticToWithdraw
        );
    }

    function undoSale(uint256 _requestId) external {
        checkIfAllowed(address(s_saleConsumer));
        Request memory request = s_requests[_requestId];

        checkIfPending(request);

        request.status = RequestStatus.REFUNDED;
        s_requests[_requestId] = request;

        sendSToken(request.sToken, request.account, request.amount);

        emit RequestRefunded(_requestId);
    }

    function emergencyRefund(uint256 _requestId) external {
        Request memory request = s_requests[_requestId];
        if (request.account != msg.sender) {
            revert Stonksly__NotTheRequestOwner(msg.sender, request.account);
        }
        checkIfPending(request);

        request.status = RequestStatus.REFUNDED;
        s_requests[_requestId] = request;

        if (request.requestType == RequestType.PURCHASE) {
            sendMatic(request.account, request.amount);
        } else {
            sendSToken(request.sToken, request.account, request.amount);
        }
        emit RequestRefunded(_requestId);
    }

    function setPurchaseConsumer(IConsumer _purchaseConsumer) external {
        if (address(s_purchaseConsumer) != address(0)) {
            revert Stonksly_ConsumerAlreadySet();
        }
        s_purchaseConsumer = _purchaseConsumer;
    }

    function setSaleConsumer(IConsumer _saleConsumer) external {
        if (address(s_saleConsumer) != address(0)) {
            revert Stonksly_ConsumerAlreadySet();
        }
        s_saleConsumer = _saleConsumer;
    }

    function withdrawFees() external {
        uint256 toWithdraw = s_collectedFees;
        s_collectedFees = 0;
        sendMatic(s_stonkslyWallet, toWithdraw);
        emit FeesCollected(toWithdraw);
    }

    // To provide additional MATIC liquidity - can be rewarded in future
    function addLiquidity() public payable {
        s_liquidityProviders[msg.sender] += msg.value;
        emit LiquidityProvided(msg.sender, msg.value);
    }

    function removeLiquidity(uint256 _amount) external {
        if (s_liquidityProviders[msg.sender] < _amount) {
            revert Stonksly__NotEnoughtLiquidityProvided();
        }
        s_liquidityProviders[msg.sender] -= _amount;
        sendMatic(msg.sender, _amount);

        emit LiquidityRemoved(msg.sender, _amount);
    }

    function sendMatic(address _receiver, uint256 _amount) private {
        (bool success, ) = _receiver.call{value: _amount}("");
        if (!success) {
            revert Stonksly__TransferFailed(_receiver, _amount);
        }
    }

    function sendSToken(
        address _sToken,
        address _receiver,
        uint256 _amount
    ) private {
        bool success = SToken(_sToken).transfer(_receiver, _amount);
        if (!success) {
            revert Stonksly__TransferFailed(_receiver, _amount);
        }
    }

    function getPurchaseConsumer() external view override returns (address) {
        return address(s_purchaseConsumer);
    }

    function getSaleConsumer() external view override returns (address) {
        return address(s_saleConsumer);
    }

    function getCollectedFees() external view override returns (uint256) {
        return s_collectedFees;
    }

    function isPurchasable(
        address _sToken
    ) external view override returns (bool) {
        return s_sTokens[_sToken];
    }

    function getRequest(
        uint256 _id
    ) external view override returns (Request memory) {
        return s_requests[_id];
    }

    function getLiquidity(
        address _provider
    ) external view override returns (uint256) {
        return s_liquidityProviders[_provider];
    }

    receive() external payable {
        addLiquidity();
    }

    function checkIfAllowed(address _who) private view {
        if (msg.sender != address(_who)) {
            revert Stonksly__NotAllowedCall(msg.sender);
        }
    }

    function checkIfSTokenRegistered(address _sToken) private view {
        if (!s_sTokens[_sToken]) {
            revert Stonksly__STokenNotRegistered(_sToken);
        }
    }

    function checkIfPending(Request memory _request) private pure {
        if (_request.status != RequestStatus.PENDING) {
            revert Stonksly_RequestIsNotPending(_request.id);
        }
    }
}