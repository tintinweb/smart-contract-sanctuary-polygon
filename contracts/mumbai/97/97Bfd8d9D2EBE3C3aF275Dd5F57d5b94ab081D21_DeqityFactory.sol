// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./TokenizedEquity.sol";

/** @title Deqity Factory V1
 *  @notice Allows user to deploy a contract to represent the equity of their organization.
 *  @author MaximilianFullStack
 */
contract DeqityFactory {
    address public adminFeeSetter;
    uint16 public adminFee;
    address[] public equityContracts;

    mapping(string => mapping(string => address)) public getEquity;

    /* === CONSTRUCTOR ===*/

    constructor(uint16 adminFee_) {
        adminFee = adminFee_;
        adminFeeSetter = msg.sender;
    }

    /* === RECEIVE FUNCTION === */

    receive() external payable {}

    /* === FALLBACK FUNCTION === */

    fallback() external {}

    /* === EXTERNAL FUNCTIONS === */

    /// @notice deploys new contract representing organization equity
    function createEquity(
        string memory name,
        string memory symbol,
        address[] memory shareHolders,
        uint256[] memory shareHolderShares
    ) external returns (address equity) {
        require(
            shareHolders.length == shareHolderShares.length,
            "Num of shareholders and coresponding shares mismatch"
        );
        require(
            shareHolders[0] != address(0),
            "Shareholder address cant be null"
        );
        require(shareHolderShares[0] > 0, "Shareholder cant have zero shares");
        require(
            keccak256(abi.encodePacked((name))) !=
                keccak256(abi.encodePacked((""))),
            "Organization name cannot be blank"
        );
        require(
            keccak256(abi.encodePacked((symbol))) !=
                keccak256(abi.encodePacked((""))),
            "Organization name cannot be blank"
        );
        require(
            getEquity[name][symbol] == address(0),
            "Contract already exists with name and symbol"
        );
        equity = address(
            new TokenizedEquity(
                name,
                symbol,
                adminFee,
                msg.sender,
                shareHolders,
                shareHolderShares
            )
        );
        equityContracts.push(equity);
        getEquity[name][symbol] = equity;
    }

    /// @notice sets fee for all depolyed contracts. Sale amounts are divied by admin fee. e.g. 200 = 0.5%
    function setAdminFee(uint16 adminFee_) external {
        require(
            msg.sender == adminFeeSetter,
            "Only fee setter can change admin fee"
        );
        require(adminFee_ != adminFee, "New fee is the same as previous");
        adminFee = adminFee_;
    }

    /// @notice sets the address than can change fee amount and the fees are transfered to.
    function setFeeSetter(address adminFeeSetter_) external {
        require(
            msg.sender == adminFeeSetter,
            "Only fee setter can change admin fee setter"
        );
        require(
            adminFeeSetter != adminFeeSetter_,
            "New setter is the same as old"
        );
        adminFeeSetter = adminFeeSetter_;
    }

    /// @notice transfers contract balance to the fee setter (doesnt matter who function caller is)
    function withdrawl() external {
        require(address(this).balance > 0, "No generated fees to withdraw");
        payable(adminFeeSetter).transfer(address(this).balance);
    }

    /* === VIEW FUNCTIONS ===*/

    function getEquityAddress(string memory name, string memory symbol)
        public
        view
        returns (address)
    {
        return getEquity[name][symbol];
    }

    function numOfEquityContracts() public view returns (uint256) {
        return equityContracts.length;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** @title Tokenized Equity V1
 *  @notice Allows user to tokenize the equity of their organization and sell it to investors all over the world.
 *  @author MaximilianFullStack
 */
contract TokenizedEquity is ERC20, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    enum SaleStatus {
        CLOSED,
        OPEN
    }
    SaleStatus status;

    address public immutable i_factory;
    uint16 public immutable i_adminFee;
    uint256 public totalShares;
    uint256 public dillutionSharePrice;
    bool public initilzied;

    address[] public initlalShareHolders;
    address[] public shareHolders;

    mapping(address => uint256) public shareHolderShares;
    mapping(address => uint256) public equity;
    mapping(address => uint256) public initialEquity;
    mapping(address => uint256) public peerToPeerSharePrice;
    mapping(address => uint256) public peerToPeerSharesForSale;

    /* === CONSTRUCTOR ===*/

    constructor(
        string memory name,
        string memory symbol,
        uint16 adminFee_,
        address initilizer,
        address[] memory shareHolders_,
        uint256[] memory shareHolderShares_
    ) ERC20(name, symbol) {
        i_factory = msg.sender;
        i_adminFee = adminFee_;
        initilzied = false;
        status = SaleStatus.CLOSED;
        initilizeEquity(shareHolders_, shareHolderShares_);
        transferOwnership(initilizer);
    }

    /* === RECIEVE FUNCTION === */

    receive() external payable {}

    /* === FALLBACK FUNCTION === */

    fallback() external {}

    /* === EXTERNAL FUNCTIONS ===*/

    /// @notice a dillution is a esentially a sale from all existing share holders at once. It maintains the pre-existing equity ratios
    ///   between the intial shareholders.
    function startDillutionSale(uint256 newShares, uint256 sharePrice_)
        external
        onlyOwner
        nonReentrant
    {
        require(initilzied == true, "Equity not initilized");

        require(status == SaleStatus.CLOSED, "Sale has already started");
        require(newShares > 0, "Zero new shares set for sale");
        require(sharePrice_ > 0, "Undefined share price set");

        ///updating status variables
        dillutionSharePrice = sharePrice_;
        totalShares = totalShares += newShares;
        status = SaleStatus.OPEN;
    }

    /// @notice allows buyers to mint equity tokens, effectivly equally dilluting all existing shareholders.
    function buyDillutionShares(uint256 quantity)
        external
        payable
        nonReentrant
    {
        require(status == SaleStatus.OPEN, "No active sale");
        require(
            totalSupply() < totalShares.add(quantity),
            "Cannot buy more shares than available"
        );
        require(
            initialEquity[msg.sender] == 0,
            "Intital Shareholders cannot buy dillution shares"
        );
        require(
            msg.value == (dillutionSharePrice.mul(quantity)).div(1 ether),
            "Input value doesnt match share price"
        );

        ///calculates fee from sale and transfers to factory
        uint256 fee = SafeMath.div(msg.value, i_adminFee);
        payable(i_factory).transfer(fee);

        ///minting tokens and adding minter to share holder array
        _mint(msg.sender, quantity);
        shareHolders.push(msg.sender);

        ///updates status variables
        update(false);

        ///ends sale if there is no shares left to sell
        if (totalSupply() >= totalShares) {
            endDillutionSale();
        }
    }

    /// @notice a peer to peer sale is a sale from a single shareholder.
    function startPeerToPeerSale(uint256 quantity, uint256 sharePrice_)
        external
        nonReentrant
    {
        require(initilzied == true, "Equity not initlilized");
        require(
            peerToPeerSharesForSale[msg.sender] == 0,
            "Seller already has sale started"
        );
        require(quantity > 0, "Zero value quantity input");
        require(sharePrice_ > 0, "Zero value share price input");
        require(
            balanceOf(msg.sender) >= quantity,
            "User does not have enough shares to sell"
        );

        ///updates peer to peer variables for seller address
        peerToPeerSharePrice[msg.sender] = sharePrice_;
        peerToPeerSharesForSale[msg.sender] = quantity;

        ///approves unlimited equity tokens to be moved by the contract. Trade off between ease of use and security.
        approve(
            address(this),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    /// @notice motifies a seller's existing sale
    function alterPeerToPeerSale(
        address seller,
        uint256 newQuantity,
        uint256 newSharePrice_
    ) external nonReentrant {
        require(initilzied == true, "Equity not initlilized");
        require(msg.sender == seller, "Only the seller can motify their sale");
        require(
            peerToPeerSharesForSale[msg.sender] > 0,
            "Seller doesnt have a sale"
        );
        require(
            balanceOf(msg.sender) >= newQuantity,
            "User does not have enough shares to sell"
        );

        if (newQuantity == 0) {
            peerToPeerSharesForSale[msg.sender] = newQuantity;
            endPeerToPeerSale(msg.sender);
        } else {
            peerToPeerSharePrice[msg.sender] = newSharePrice_;
            peerToPeerSharesForSale[msg.sender] = newQuantity;
        }
    }

    /// @notice allows buyer to purchase equity tokens from seller
    function buyPeerToPeerShares(address seller, uint256 quantity)
        external
        payable
        nonReentrant
    {
        require(initilzied == true, "Equity not initilzied");
        require(
            peerToPeerSharesForSale[seller] >= quantity,
            "Inputed seller doesnt have enough shares listed"
        );
        require(
            (peerToPeerSharePrice[seller].mul(quantity)).div(1 ether) ==
                msg.value,
            "Invaild msg value"
        );

        ///calculates fee from sale and transfers to factory
        uint256 fee = SafeMath.div(msg.value, i_adminFee);
        payable(i_factory).transfer(fee);

        ///pays seller and tranfers tokens to buyer
        payable(seller).transfer(SafeMath.sub(msg.value, fee));
        _transfer(seller, msg.sender, quantity);

        ///adds buyer to shareholder list
        shareHolders.push(msg.sender);

        ///updates status variables
        update(false);
        peerToPeerSharesForSale[seller] = peerToPeerSharesForSale[seller].sub(
            quantity
        );

        if (peerToPeerSharesForSale[seller] == 0) {
            endPeerToPeerSale(seller);
        }
    }

    /* === INTERNAL FUNCTIONS === */

    /// @notice updates the number of tokens shareholders own and their equity
    function update(bool inital) internal {
        for (uint256 i = 0; i < shareHolders.length; i++) {
            uint256 bal = balanceOf(shareHolders[i]);
            if (bal > 0) {
                shareHolderShares[shareHolders[i]] = bal;
                equity[shareHolders[i]] = (bal.mul(1 ether)).div(totalSupply());
                if (inital == true) {
                    initialEquity[shareHolders[i]] = (bal.mul(1 ether)).div(
                        totalSupply()
                    );
                }
            } else {
                delete shareHolders[i];
            }
        }
    }

    /// @notice mints tokens according to pre-existing equity
    function initilizeEquity(
        address[] memory shareholders_,
        uint256[] memory shareHolderShares_
    ) internal nonReentrant {
        require(totalSupply() == 0, "Equity already initilzied");
        require(initilzied != true, "Equity already initilized");

        uint256 totalShares_;

        ///mints tokens for each shareholder
        for (uint256 i = 0; i < shareholders_.length; i++) {
            _mint(shareholders_[i], shareHolderShares_[i]);
            totalShares_ += shareHolderShares_[i];
            shareHolders.push(shareholders_[i]);
            initlalShareHolders.push(shareholders_[i]);
        }

        ///updates status variables
        totalShares = totalShares_;
        update(true);
        initilzied = true;
    }

    /// @notice ends dillution sale and pays inital shareholders
    function endDillutionSale() internal {
        require(status == SaleStatus.OPEN, "No current sale");
        require(initilzied == true, "Equity not initilized");
        require(totalSupply() >= totalShares, "Still supply left to be sold");

        ///pays the initial shareholders according to there equity
        for (uint256 i = 0; i < initlalShareHolders.length; i++) {
            uint256 amount = (initialEquity[initlalShareHolders[i]]).mul(
                address(this).balance
            );
            uint256 pay = amount.div(1 ether);
            payable(shareHolders[i]).transfer(pay);
        }

        //closes sale and updates variables
        status = SaleStatus.CLOSED;
        update(true);

        ///updates inital holders for next dillution sale
        initlalShareHolders = shareHolders;
    }

    function endPeerToPeerSale(address seller) internal {
        require(initilzied == true, "Equity not initilzied");
        require(
            peerToPeerSharesForSale[seller] == 0,
            "User has no active sale"
        );

        delete peerToPeerSharesForSale[seller];
        delete peerToPeerSharePrice[seller];
    }

    /* === PUBLIC FUNCTIONS === */

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = msg.sender;
        _transfer(owner, to, amount);

        shareHolders.push(to);
        update(false);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        shareHolders.push(to);
        update(false);

        return true;
    }

    /* === VIEW FUNCTIONS === */

    function getContractStatus() public view returns (SaleStatus, bool) {
        return (status, initilzied);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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