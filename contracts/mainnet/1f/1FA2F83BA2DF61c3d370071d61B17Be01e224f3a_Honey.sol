// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

///@notice The standard ERC20 contract, with the exception of _balances being internal as opposed to private
import "./ERC20.sol";
import "./interfaces/IHexagonMarketplace.sol";


contract Honey is ERC20, Ownable, Pausable {

    // The constant used to calculate percentages, allows percentages to have 1 decimal place (ie 15.5%)
    uint constant BASIS_POINTS = 1000;

    // Variables related to fees and restrictions
    mapping(address => bool) excludedFromTransferRestrictions;
    mapping(address => bool) excludedFromTax;
    mapping(address => bool) taxableRecipient;

    mapping(address => uint) maxInitialPurchasePerWallet;

    struct collectionOwner {
        address collectionAddress;
        uint tokensSold;
    }
   
    ///@notice mapping that keeps tract of collection owners, offering them less sales tax for selling tokens recieved from royalties
    mapping(address => collectionOwner) collectionOwners;

    //collection owners pay 2.5% sales tax on royalties sold
    uint constant collectionOwnersSalesTax = 25;

    //Addresses that can update the collection owners parameters, so it can be done on request by the owners by a trusted wallet
    mapping(address => bool) verifiedAddresses;

    // Windows of time at the start of launch, during which this token has special trading restrictions
    uint specialTimePeriod;
    uint hourAfterLaunch;

    ///@notice this is the sales tax, initially set to 15% (150 / BASIS_POINTS = 0.15);
    uint public salesTax = 150;
    uint constant maxSalesTax = 150;

    IHexagonMarketplace hexagonMarketplace;

    address public distributionContract;
    
    constructor() ERC20("HONEY", "HNY") {

        _mint(msg.sender, 1000000 ether);
        
        // ///@notice get the sushiswap router on polygon
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

        // // Create a uniswap pair for this new token
        address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        // Allow the deployer and liquidity pool to trade tokens freely in the first 6 days
        excludedFromTransferRestrictions[msg.sender] = true;
        excludedFromTransferRestrictions[uniswapV2Pair] = true;
        excludedFromTransferRestrictions[0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506] = true;

        // Set deployer and this address as free from tax as free from tax, other addresses will be added to this exclusion whitelist
        excludedFromTax[msg.sender] = true;
        excludedFromTax[address(this)] = true;

        // Sets the liquidity pairing to be taxable on selling of tokens, more liquidity pools could be added
        taxableRecipient[uniswapV2Pair] = true;
       
    }

    /**
    *@dev Override ERC20 transfer function to prevent trading when paused
    */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
     

    /**
    *@dev Override ERC20 transferFrom function to prevent trading when paused
    */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused  returns (bool) {
        _spendAllowance(sender, _msgSender(), amount);
        _transfer(sender, recipient, amount);

        return true;
    }

    /**
    * @dev Transfer is adjusted to charge a sales tax when selling to set liquidity pools, this tax is sent to this address, with a portion being sold to the liquidity
    * pool for matic. These funds can be claimed ans set to the set protocal wallets
    *  There is some additonal logic adding limitations to sales, purchases and a different sales tax for the first 6 days this protocol is public, with additional 
    *  restrictions for the first hour. There restrictions aim to help smooth over the initial laucnh and prevent whales and bots from having an advantage 
    */
    function _transfer(address sender, address recipient, uint256 amount) internal override {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount should be greater than zero");

        _beforeTokenTransfer(sender, recipient, amount);

        uint feePercent = salesTax;

        // ///@notice check to see there is a sales tax applied by checking if the reciever is a liquidity pool, and if the sender is not excluded from paying taxes 
        bool toTax = (taxableRecipient[recipient] && !excludedFromTax[sender]);
       

        ///@notice check if the current time is within the time period that requires addtional logic
        if(block.timestamp < specialTimePeriod) {

            ///@notice if a liquidity pool in not invloved in any way, and the wallets involved with sending aren't exempt from the transfer restricitons
            ///then this shouldn't be allowed, and honey can be transfered to owher wallets at this time
            bool allowed = (taxableRecipient[recipient] || taxableRecipient[sender] || taxableRecipient[msg.sender] || excludedFromTransferRestrictions[recipient] ||
                excludedFromTransferRestrictions[sender] || excludedFromTransferRestrictions[msg.sender]); 

            ///@notice tokens are being traded to other wallets during the restricted time period
            require(allowed, "Can't trade to other wallets at the moment");
            

            ///@notice check to see if the sender or opperator is a taxable reciepient (liquidity pool), if so then someone is attempting to buy, which has some 
            ///restricitons at this time
            if(taxableRecipient[sender] || taxableRecipient[msg.sender]) {

                ///@notice tokens are being purchased so check if there are purchasing more than they are allowed
                uint maxPurchase = 100 ether;

                ///@notice additonal restrictions are applied for the first hour this protocal is live
                if(block.timestamp < hourAfterLaunch) {
                    maxPurchase = 20 ether;
                }

                //Check if purchased above allowed amount
                require(maxInitialPurchasePerWallet[recipient] + amount <= maxPurchase, "Max purchase Exceeded for this time");

                //Update purchases
                maxInitialPurchasePerWallet[recipient] += amount;


            } else if(toTax) {

                ///@notice this is a taxable sale, and during this tiome period the sales tax starts at 45% and decreases over time at a rate of 5% per day
                /// until it reaches the final sales tax of 15% (numbers are multiplied by 10 to allow an additional decimal point of expression)
                //TODO: double check this math
                feePercent = (((specialTimePeriod - block.timestamp) * 300) / 6 days) + feePercent;


            } 
            
        }
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[sender] = senderBalance  - (amount);
        }

        if(toTax) {

            uint tax;

            if(collectionOwners[sender].collectionAddress != address(0)) {

                ///@notice this address is tied to a collection on the hexagon marketplace, so they recieve a lower tax on royalties earned
                collectionOwner memory _collectionOwner = collectionOwners[sender];

                uint royaltiesEarned = hexagonMarketplace.getRoyaltiesGenerated(_collectionOwner.collectionAddress, 0);

                if(_collectionOwner.tokensSold + amount <= royaltiesEarned) {

                    // update the number of tokens sold using this tax
                    collectionOwners[sender].tokensSold += amount;

                    tax = (amount * collectionOwnersSalesTax) / BASIS_POINTS;

                } else {

                    ///@notice This address is trying to sell more tokens than earned from royalties on the collection, so give reduced tax on remaining royalties
                    uint amountWithReducedTax = royaltiesEarned - _collectionOwner.tokensSold;

                    uint toBetaxedInFull = amount - amountWithReducedTax;

                    // Tax in full the amount sold over whats earned in royalties
                    tax = (toBetaxedInFull * feePercent) / BASIS_POINTS;

                    // Tax up to the royalties earned with the reduced tax
                    tax += (amountWithReducedTax * collectionOwnersSalesTax) / BASIS_POINTS;

                    // update the number of tokens sold using this tax
                    collectionOwners[sender].tokensSold = royaltiesEarned;

                }


            } else {

                ///@notice this transaction will be taxed, so a potion of the tax will go to this contract, and another portion will be sold to the
                /// liquidity pool for matic 
                tax = ((amount * feePercent) / BASIS_POINTS);


            }

            amount -= tax;

            ///@notice set the total tax to the balance of this contract, some (or all) of the tax will be solid to matic
            _balances[distributionContract] += tax;

            emit Transfer(sender, distributionContract, tax);

            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);


        } else {

            ///@notice no sales tax required, add balance normally
            _balances[recipient] = _balances[recipient] + (amount);

            emit Transfer(sender, recipient, amount);

        }

        _afterTokenTransfer(sender, recipient, amount);
            
    }

    /**
    * @dev gets the sales tax of the token when sold to a liquidity pool, returns based on BASIS_POINTS (1000)
    */
    function getSalesTax() external view returns (uint) {

        if(block.timestamp < specialTimePeriod) {
            return  (((specialTimePeriod - block.timestamp) * 300) / 6 days) + salesTax;
        } else {
            return salesTax;
        }

    }

    /**
    * @dev This allows the contract to revieve matic by selling honey to the liquidity pool
    */
    receive() external payable {}

    /**
    * @dev Sets the sales tax
    * Requires the caller to be the owner of the contract
    */
    function SetSalesTax(uint _salesTax) external onlyOwner {

        require(_salesTax <= maxSalesTax, "tax can't be above max tax");

        salesTax = _salesTax;

    }

    /**
    * @dev Sets an address to be able to transfer the token to other wallets
    * Requires the caller to be the owner of the contract
    */
    function ExcludeFromTransferRestrictions(address _address, bool _value) external onlyOwner {

        excludedFromTransferRestrictions[_address] = _value;

    }

    /**
    * @dev Sets an address to excluded from the sales tax
    * Requires the caller to be the owner of the contract
    */
    function ExcludeFromTax(address _address, bool _value) external onlyOwner {

        excludedFromTax[_address] = _value;

    }

    /**
    * @dev Sets an address to be taxable if tokens are sent to it (ie liquidity pools)
    * Requires the caller to be the owner of the contract
    */
    function setTaxableRecipient(address _address, bool _value) external onlyOwner {

        taxableRecipient[_address] = _value;

    }

    /**
    * @dev Sets the hexagon marketplace interface, which is used to check royalties collected on the marketplace
    * Requires the sender to the owner of the collection
    */
    function setHexagonMarketplace(address _hexagonAddress) external onlyOwner {

        require(_hexagonAddress != address(0), "Zero Address");

        hexagonMarketplace = IHexagonMarketplace(_hexagonAddress);

    }

    function setDistributionContract(address _distributioncontract) external onlyOwner {

        require(_distributioncontract != address(0), "Zero Address");

        distributionContract = _distributioncontract;

    }

    /**
    * @dev Adds an address that owns a collection traded on the hexagonMarketplace, so the address is charged a lower tax percent for the royalties earned,
    * or updates the payment address of a collection, removing the data for the pervious owner
    * Requires the sender to be a verified address
    */
    function updateWhitelistedCollection(address _collectionAddress, address _walletAddress, address _previousAddress) external {

        require(verifiedAddresses[msg.sender], "Needs to be called by a verified address");

        if(_previousAddress == address(0)) {

            collectionOwners[_walletAddress] = collectionOwner(_collectionAddress, 0);
            
        } else {

            collectionOwner memory previousCollectionOwner = collectionOwners[_previousAddress];

            require(previousCollectionOwner.collectionAddress != address(0), "Collection does not exist");

            collectionOwners[_walletAddress] = previousCollectionOwner;

            delete collectionOwners[_previousAddress];

        }

    }

    /**
    * @dev updates the addresses that are able to call the updateWhitelistedCollection function
    * Requires the caller to be the owner of the collection
    */
    function updateVerifiedAddresses(address _address, bool _value) external onlyOwner {

        require(_address != address(0), "Zero Address");

        verifiedAddresses[_address] = _value;
    }

    /**
    * @dev sets a time window with special restrictions
    * this can only be set once, and will be done on launch, called by the owners
    */
    function startTimePeriod() external onlyOwner {

        require(specialTimePeriod == 0, "Can only call once");

        // Setting the 6 day time period which has special restrictions to start on deployment
        specialTimePeriod = block.timestamp + (6 days);

        // Setting this to be a day and an hour after deployment, but planning to open things up 24 hours after deployment giving 1 hour of extra restrictions
        // on purchaseshelp things run smoothly
        hourAfterLaunch = block.timestamp + (1 hours);

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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

    ///@notice _balances set to internal
    mapping(address => uint256) internal _balances;

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
interface IHexagonMarketplace {

    function getRoyaltiesGenerated(address _collectionAddress, uint _currencyType) external view returns(uint);

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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