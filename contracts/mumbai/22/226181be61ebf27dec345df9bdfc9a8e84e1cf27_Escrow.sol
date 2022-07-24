/**
 *Submitted for verification at polygonscan.com on 2022-07-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        require(_allowances[_msgSender()][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


/**
 * @title Escrow
 * @author Crodian
 * 
 * This contract is designed to create secure transactions between buyers and sellers by having
 * an Escrow service. Sellers can post an order online, where buyers can deposit
 * funds to the contract. When the package or service has been received by the buyer
 * and is satisfactory, the funds will be automatically released to the seller after time.
 * In case the product or service bought was not up to expectations, the buyer can 
 * file a dispute, which prevents the funds from being released until both buyer and 
 * seller can come to an agreement to get a full refund, discount or proceed as normal
 * after receiving customer service from the seller.
 */
contract Escrow {
    event LogInt(uint256 outputInt);
    event LogString(string outputString);
    event LogStringAddress(string outputString, address outputAddress);
    event LogStringUint(string outputString, uint outputInt);
    event LogStringBool(string outputString, bool outputBool);

    struct EscrowOrder {
        // Set to know the trade has already been created.
        bool valid;
        // Set so we know the order is being handled.
        bool processing;
        // The unique ID of the order.
        uint256 orderId;
        // Amount locked in the Escrow contract.
        uint256 fundsLocked;
        // Total gas used in all Escrow transactions.
        uint256 totalGasFeesSpent;
        // Address of the user who made the order.
        address buyerAddress;
        // Address of the seller's wallet.
        address sellerAddress;
        // Addresses of all channel affiliates.
        address[] channelAffiliates;
        // Address of the referral affiliate.
        address referralAffiliate;
        // Address of ERC20 token. (Optional, else Ethereum is used)
        address tokenAddress;
    }

    struct DepositData {
        // Set to know the deposit is open.
        bool valid;
        // The address of the owner of the deposit.
        address investorAddress;
        // Store when the deposit has been made.
        uint256 timeStamp;
        // The amount of funds locked in the contract by the deposit.
        uint256 funds;
        // Index lookup for reference.
        uint256 index;
        // Unique id for this deposit
        uint256 uid;
    }

    struct TokenData {
        // Set to know if the token is initialized.
        bool valid;
        // Cached ERC20 token.
        ERC20 token;
    }

    // The owner of the contract.
    address private owner;
    // The arbitrator of the contract.
    address private arbitrator;
    // The wallets of the moderators.
    address[] private moderatorAddresses;

    // Unique incremental id for every deposit.
    uint256 private uniqueId;

    /// @dev Keeps track whether the contract is running.
    /// If paused, most actions are blocked.
    bool public paused = false;

    // Prevents functions to be open to reentrancy attacks.
    bool private lock = false;

    // Mapping of all deposits made, awaiting to be attached to an order.
    mapping (address => DepositData) private deposits;
    address[] private depositAddressList;

    // Mapping of active trades. Key is a hash of the trade data.
    mapping (uint256 => EscrowOrder) private escrowOrders;
    uint256[] private escrowOrderList;

    // Token cache.
    mapping (address => TokenData) private tokens;

    /// Modifier to allow actions only executed by the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Escrow: Not owner");
        _;
    }

    /// Modifier to allow actions only executed by the arbitrator.
    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Escrow: Not arbitrator");
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier notPaused() {
        require(!paused, "Escrow: Contract paused");
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier isPaused {
        require(paused, "Escrow: Constract not paused");
        _;
    }
    
    /// Initialize the contract.
    constructor() {
        owner = msg.sender;
        arbitrator = msg.sender;
        moderatorAddresses.push(owner);
    }

    /// @dev Called by the owner of the contract, used only when a bug or exploit is detected and needs to get fixed.
    function pause() external onlyOwner notPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the owner, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyOwner isPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }

    /// @dev Transfer contract ownership.
    /// @param newOwner new address.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Escrow: Address invalid");

        // Assign new ownership.
        owner = newOwner;
    }
    
    /// @dev Transfer contract arbitrator.
    /// @param newArbitrator new address.
    function transferArbitrator(address newArbitrator) public onlyOwner {
        require(newArbitrator != address(0), "Escrow: Address invalid");

        // Assign new ownership.
        arbitrator = newArbitrator;
    }

    /// @dev Add moderator.
    /// @param moderatorAddress new address.
    function addModerator(address moderatorAddress) public onlyOwner {
        require(moderatorAddress != address(0), "Escrow: Address invalid");
        uint moderatorCount = moderatorAddresses.length;

        for (uint i = 0; i < moderatorCount; i++) {
            require(moderatorAddresses[i] != moderatorAddress);
        }

        // Swap default owner for the new moderator.
        if (owner != address(0) &&
            moderatorAddresses.length >= 1) {
            removeModerator(owner);
        }

        // Add the new moderator.
        moderatorAddresses.push(moderatorAddress);
    }

    /// @dev Remove a moderator.
    /// @param moderatorAddress Address to remove.
    function removeModerator(address moderatorAddress) public onlyOwner {
        require(moderatorAddress != address(0) &&
                moderatorAddresses.length >= 1, 
                "Escrow: Address invalid");

        // Find and remove the moderator.
        for (uint i = 0; i < moderatorAddresses.length; i++) {
            if (moderatorAddresses[i] == moderatorAddress) {
                moderatorAddresses[i] = moderatorAddresses[moderatorAddresses.length - 1];
                moderatorAddresses.pop();
                break;
            }
        }
    }

    /// Receive deposit from a buyer.
    receive() external payable notPaused {
        // Buyer already has an open deposit, top up the existing deposit.
        if (deposits[msg.sender].valid) {
            deposits[msg.sender].funds += msg.value;

        } else {
            // Save a new deposit for this sender.
            deposits[msg.sender] = DepositData({
                valid: true, 
                investorAddress: msg.sender, 
                funds: msg.value,
                timeStamp: block.timestamp,
                index: depositAddressList.length,
                uid: uniqueId});
            
            // Save the sender to the deposit list to get a lookup to iterate through the deposit mapping.
            depositAddressList.push(msg.sender);
            uniqueId++;
        }
    }

    /// @dev Refund a deposit made to the contract.
    /// Used in case of the seller not sending out the order, 
    /// or the seller/product is no longer available on the platform.
    /// @param buyer The address of the deposit.
    function refundDeposit(address buyer, address token) public onlyOwner returns (bool) {
        // Check if a deposit has been made.
        require(!lock, "Refund is locked");
        
        // Prevent reentrancy attacks.
        lock = true;

        // Store the funds.
        uint256 funds = deposits[buyer].funds;
        // Use an ERC20 token or use Ethereum.
        bool useToken = token != address(0);
        bool success;

        if (useToken) {
            // Send the tokens back to the user.
            ERC20 cachedToken = getToken(token);
            success = cachedToken.transfer(buyer, funds);
        } else {
            if (deposits[buyer].valid &&
                deposits[buyer].funds > 0) {
                // Send the ETH back to the user.
                (success, ) = buyer.call{value: funds}("");
                
                if (success) {
                    // Remove the deposit data.
                    deposits[buyer].valid = false;
                    delete deposits[buyer];
                    uint256 index = deposits[buyer].index;
                    address replacementAdress = depositAddressList[depositAddressList.length-1];
                    deposits[replacementAdress].index = index;
                    depositAddressList[index] = depositAddressList[depositAddressList.length-1];
                    depositAddressList.pop();
                }
            }
        }

        // Remove reentrancy lock.
        lock = false;
        return success;
    }

    /// Create a new order from a deposit.
    function createOrder(
        uint256 orderId, 
        address buyerAddress,
        address sellerAddress,
        uint256 price,
        uint256 deposit,
        address tokenAddress,
        address referralAffiliate,
        address[] memory channelAffiliates
        ) public onlyOwner notPaused {
        
        require(!lock &&
                !escrowOrders[orderId].valid && // Check if the order already exists.
                deposit >= price, "Invalid order"); // Check if there are enough funds.

        // Use an ERC20 token or use Ethereum.
        bool useToken = tokenAddress != address(0);
        uint256 index = 0;

        if (!useToken) {
            index = deposits[buyerAddress].index;

            require(deposits[buyerAddress].valid && // Check if there is an active deposit from this buyer.
                    index < depositAddressList.length); // Check if the stored index is not out of bounds.
        }

        // Prevent reentrancy attacks.
        lock = true;

        // Generate new Escrow Order data object.
        escrowOrders[orderId] = EscrowOrder(
            {
                valid: true,
                processing: false,
                orderId: orderId,
                fundsLocked: price,
                totalGasFeesSpent: 0,
                buyerAddress: buyerAddress,
                sellerAddress: sellerAddress,
                channelAffiliates: channelAffiliates,
                referralAffiliate: referralAffiliate,
                tokenAddress: tokenAddress
            });

        // Save the orderId to the escrowOrder list to get a lookup to iterate through the order mapping.
        escrowOrderList.push(orderId);
        
        // Token contract.
        ERC20 token;
        
        if (useToken) {
            token = getToken(tokenAddress);
        }

        // Give back change to buyer.
        uint256 change = deposit - price;

        if (change > 0) {
            bool success = false;
            if (useToken) {
                success = token.transfer(buyerAddress, change);
            } else {
                (success, ) = buyerAddress.call{value: change}("");
            }
            if (!success) {
                
            }
        }

        // Cleanup the deposit.
        if (!useToken) {
            deposits[buyerAddress].valid = false;
            delete deposits[buyerAddress];
            depositAddressList[index] = depositAddressList[depositAddressList.length-1];
            depositAddressList.pop();
        }

        // Remove reentrancy lock.
        lock = false;
    }

    /// Complete an order and transfer the funds to the seller.
    /// Affiliate and moderator cuts are only taken from the funds that the seller receives.
    /// @param orderId The unique id of the order to complete.
    /// @param splitPercentage Defines how much goes to the buyer and seller, e.g. 75 will give 75% to the seller, and 25% to the buyer.
    /// @return Has the order been completed successfully.
    function completeOrder(
        uint256 orderId, 
        uint256 splitPercentage) public onlyOwner notPaused returns (bool) {
        EscrowOrder storage order = escrowOrders[orderId];

        require(!lock &&
                splitPercentage >= 0 && splitPercentage <= 100 && 
                order.valid &&
                !order.processing, "Invalid order");

        // Prevent reentrancy attacks.
        lock = true;

        // Mark this order as currently being processed.
        order.processing = true;
        // Calculate the total sellers cut percentage from the funds.
        uint256 sellerCut = order.fundsLocked * splitPercentage / 100;
        // The remaining funds are for the buyer, in case of dispute handling and refunds.
        uint256 buyerCut = order.fundsLocked - sellerCut;

        // Cached index value.
        uint256 i;
        // Success check.
        bool success;
        // Use an ERC20 token or use Ethereum.
        bool useToken = order.tokenAddress != address(0);

        // Token contract.
        ERC20 token;
        if (useToken) {
            token = getToken(order.tokenAddress);
        }

        if (sellerCut > 0) {
            // Calculate 3.5% fee from the seller's cut.
            uint256 fee = order.fundsLocked * 35 / 1000;
            // Referral affiliate cut 1%
            uint256 referralCut = sellerCut / 100;
            // Channel affiliate cut 0.5%
            uint256 channelCut = sellerCut * 5 / 1000;
            // Moderator cut of whats left of the fee.
            uint256 moderatorCut = fee - channelCut - referralCut;
            // Save the amount not able to be transferred to the affiliates.
            uint256 affiliateLeftOver = 0;

            if (order.referralAffiliate != address(0)) {
                success = false;
                if (useToken) {
                    success = token.transfer(order.referralAffiliate, referralCut);
                } else {
                    (success, ) = order.referralAffiliate.call{value: referralCut}("");
                }
                if (!success) {
                    // Invalid affiliate address.
                    affiliateLeftOver += referralCut;
                    emit LogStringUint("[completeOrder] Send referral failed, new left over", affiliateLeftOver);
                }
            } else {
                // No referral affiliate present.
                affiliateLeftOver += referralCut;
                emit LogStringUint("[completeOrder] No referral set, new left over", affiliateLeftOver);
            }

            if (order.channelAffiliates.length > 0) {
                uint256 channelCutSingle = channelCut / order.channelAffiliates.length;

                for (i = 0; i < order.channelAffiliates.length; i++) {
                    address affiliateAddress = order.channelAffiliates[i];

                    success = false;
                    if (useToken) {
                        success = token.transfer(affiliateAddress, channelCutSingle);
                    } else {
                        (success, ) = affiliateAddress.call{value: channelCutSingle}("");
                    }
                    if (!success) {
                        // Invalid affiliate address.
                        affiliateLeftOver += channelCutSingle;
                        emit LogStringUint("[completeOrder] Send affiliate failed, new left over", affiliateLeftOver);
                    }
                }
            } else {
                // No channel affiliate present.
                affiliateLeftOver += channelCut;
            }

            // Add any failed affiliate transactions to the moderator.
            moderatorCut += affiliateLeftOver;

            if (moderatorAddresses.length > 0) {
                // Calculate how much should go to each moderator address.
                uint256 moderatorCutSingle = moderatorCut / moderatorAddresses.length;

                for (i = 0; i < moderatorAddresses.length; i++) {
                    address moderatorAddress = moderatorAddresses[i];
                    success = false;
                    if (useToken) {
                        success = token.transfer(moderatorAddress, moderatorCutSingle);
                    } else {
                        (success, ) = moderatorAddress.call{value: moderatorCutSingle}("");
                    }
                    if (!success) {
                        emit LogStringAddress("[completeOrder] Failed to send moderator cut to", moderatorAddress);
                    }
                }
            }
            
            // Send funds to seller.
            sellerCut -= fee;
            address sellerAddress = order.sellerAddress;
            
            success = false;
            if (sellerCut > 0) {
                if (useToken) {
                    success = token.transfer(sellerAddress, sellerCut);
                } else {
                    (success, ) = sellerAddress.call{value: sellerCut}("");
                }
            }
            if (!success) {
                emit LogStringAddress("[completeOrder] Failed to send seller cut", sellerAddress);
            }
        }

        if (buyerCut > 0) {
            // Send funds back to the buyer.
            address buyerAddress = order.buyerAddress;
            success = false;
            if (useToken) {
                success = token.transfer(buyerAddress, buyerCut);
            } else {
                (success, ) = buyerAddress.call{value: buyerCut}("");
            }
            if (!success) {
                emit LogStringAddress("[completeOrder] Failed to send buyer cut to", buyerAddress);
            }
        }

        // Order completed, remove the order data entry.
        delete escrowOrders[orderId];

        // Remove reentrancy lock.
        lock = false;

        // Executed successfully.
        return true;
    }

    /// Returns all currently open deposits waiting for an order to be assigned to.
    /// Only the contract owner can see who made deposits and how much.
    /// @return Address list and amount of funds locked in the deposit.
    function getDeposits() public view onlyOwner returns (address[] memory, uint256[] memory, uint256[] memory) {
        // Create a list of the data to retrieve.
        address[] memory addrs = new address[](depositAddressList.length);
        uint256[] memory funds = new uint256[](depositAddressList.length);
        uint256[] memory uids = new uint256[](depositAddressList.length);
        
        for (uint i = 0; i < depositAddressList.length; i++) {
            DepositData storage deposit = deposits[depositAddressList[i]];
            addrs[i] = deposit.investorAddress;
            funds[i] = deposit.funds;
            uids[i] = deposit.uid;
        }
        
        return (addrs, funds, uids);
    }

    function getOrders() public view onlyOwner returns 
        (bool[] memory, // processing
        uint256[] memory, // orderId
        uint256[] memory, // fundsLocked
        uint256[] memory, // totalGasFeesSpent
        address[] memory, // buyerAddress
        address[] memory, // sellerAddress
        address[] memory // tokenAddress
        ) {
        // Create a list of the data to retrieve.
        bool[] memory processings = new bool[](escrowOrderList.length);
        uint256[] memory orderIds = new uint256[](escrowOrderList.length);
        uint256[] memory fundsLocked = new uint256[](escrowOrderList.length);
        uint256[] memory totalGasFeesSpent = new uint256[](escrowOrderList.length);
        address[] memory buyerAddress = new address[](escrowOrderList.length);
        address[] memory sellerAddress = new address[](escrowOrderList.length);
        address[] memory tokenAddress = new address[](escrowOrderList.length);
        
        for (uint i = 0; i < escrowOrderList.length; i++) {
            EscrowOrder storage order = escrowOrders[escrowOrderList[i]];
            if (order.valid) {
                processings[i] = order.processing;
                orderIds[i] = order.orderId;
                fundsLocked[i] = order.fundsLocked;
                totalGasFeesSpent[i] = order.totalGasFeesSpent;
                buyerAddress[i] = order.buyerAddress;
                sellerAddress[i] = order.sellerAddress;
                tokenAddress[i] = order.tokenAddress;
            }
        }
        
        return (processings, orderIds, fundsLocked, totalGasFeesSpent, buyerAddress, sellerAddress, tokenAddress);
    }

    function getTimeStamp() public view onlyOwner returns (uint256) {
        require(!lock);
        return block.timestamp;
    }

    function getPaused() public view onlyOwner returns (bool) {
        require(!lock);
        return paused;
    }

    function getModerators() public view onlyOwner returns (address[] memory) {
        return moderatorAddresses;
    }

    function getTokenBalance(address tokenAddress) public onlyOwner returns (uint256) {
        bool useToken = tokenAddress != address(0);

        if (useToken) {
            ERC20 token = getToken(tokenAddress);
            return token.balanceOf(address(this));
        }

        return 0;
    }
    
    /// Retrieves cached token to avoid having to create it for every transaction
    /// @param tokenAddress Address of existing ERC20token.
    /// @return Cached token.
    function getToken(address tokenAddress) private returns (ERC20) {
        TokenData storage tokenData = tokens[tokenAddress];

        if (!tokenData.valid) {
            tokens[tokenAddress] = TokenData({
                valid: true,
                token: ERC20(tokenAddress)
            });
            tokenData = tokens[tokenAddress];
        }

        ERC20 token = tokenData.token;
        return (token);
    }
}