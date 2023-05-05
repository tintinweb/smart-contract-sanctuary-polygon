//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IPoolV3.sol";
import "./IndexLPToken.sol";
import "./IDAOTokenFarm.sol";


contract IndexV3 is Ownable {

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);

    IERC20Metadata immutable public depositToken;
    IndexLPToken immutable public lpToken;

    uint public totalDeposited = 0;
    uint public totalWithdrawn = 0;

    // depositToken token balances
    mapping (address => uint) public deposits;
    mapping (address => uint) public withdrawals;

    // users that deposited depositToken tokens into their balances
    address[] public users;
    mapping (address => bool) usersMap;

    IDAOTokenFarm public daoTokenFarm;
    uint8 immutable feesPercDecimals = 4;


    struct PoolInfo {
        string name;
        address poolAddress;
        address lpTokenAddress;
        uint8 weight;
    }

    PoolInfo[] public pools;
    uint public totalWeights;


    /**
     * Contract initialization.
     */
    constructor(address _depositTokenAddress, address _lpTokenAddress) {
        depositToken = IERC20Metadata(_depositTokenAddress);
        lpToken = IndexLPToken(_lpTokenAddress);
    }


    function getPoolsInfo() public view returns (PoolInfo[] memory) {
        return pools;
    }


    function getUsers() public view returns (address[] memory) {
        return users;
    }

  
    function lpTokensValue (uint lpTokens) public view returns (uint) {
        // the value of 'lpTokens' (Index LP tokens) is the share of the value of the Index  
        return lpToken.totalSupply() > 0 ? this.totalValue() * lpTokens / lpToken.totalSupply() : 0;
    }


    function gainsPerc(address account) public view returns (uint) {
        // if the address has no deposits (e.g. LPs were transferred from original depositor)
        // then consider the entire LP value as gains.
        // This is to prevent tax avoidance by withdrawing the LPs to different addresses
        if (deposits[account] == 0) return 10 ** uint(feesPercDecimals); // 100% gains

        //  account for staked LPs
        uint stakedLP = address(daoTokenFarm) != address(0) ? daoTokenFarm.getStakedBalance(account, address(lpToken)) : 0;
        uint valueInPool = lpTokensValue(lpToken.balanceOf(account) + stakedLP);

        // check if accounts is in gain
        bool hasGains =  withdrawals[account] + valueInPool > deposits[account];

        // return the fees on the gains or 0 if there are no gains
        return hasGains ? 10 ** uint(feesPercDecimals) * ( withdrawals[account] + valueInPool - deposits[account] ) / deposits[account] : 0;
    }
   


    // Return the total value held of the Index
    function totalValue() public view returns(uint) {
        uint total;
        for (uint i=0; i<pools.length; i++) {
            PoolInfo memory pool = pools[i];
            if (pool.poolAddress != address(0x0)) {
                total += IPoolV3(pool.poolAddress).portfolioValue(address(this));
            }
        }

        return total;
    }


    // Return the value held in this Index for the account provided
    function portfolioValue(address _addr) public view returns(uint) {
        
        return lpToken.totalSupply() == 0 ? 0 : totalValue() * lpToken.balanceOf(_addr) / lpToken.totalSupply();
    }
    
    
    // Deposit the given 'amount' of deposit tokens (e.g USDC) into the MultiPool.
    // These funds get deposited into the pools in this MultiPool according to each pool's weight.
    // Users receive MultiPoolLP tokens proportionally to their share of the value currently held in the MultiPool

    function deposit(uint256 amount) external {

        if (amount == 0) return;

        // remember addresses that deposited tokens
        deposits[msg.sender] += amount;
        totalDeposited += amount;
        if (!usersMap[msg.sender]) {
            usersMap[msg.sender] = true;
            users.push(msg.sender);
        }

        // move deposit tokens in the MultiPool
        depositToken.transferFrom(msg.sender, address(this), amount);

        // the value in the pools before this deposit
        uint valueBefore = totalPoolsValue();

        // allocate the deposit to the pools
        uint remainingAmount = amount;
        for (uint i=0; i<pools.length; i++) {
            PoolInfo memory pool = pools[i];
            if (pool.poolAddress != address(0x0)) {
                uint allocation = (i < pools.length-1) ? amount * pool.weight / totalWeights : remainingAmount;
                remainingAmount -= allocation;
                uint lpReceived = allocateToPool(pool, allocation);
                require(lpReceived > 0, "Invalid LP amount received");
            }
        }

        // the value in the pools after this deposit
        uint valueAfter = totalPoolsValue();

        // calculate lptokens for this deposit based on the value added to all pools
        uint lpToMint = lpTokensForDeposit(valueAfter - valueBefore);
      
        // mint lp tokens to the user
        lpToken.mint(msg.sender, lpToMint);

        emit Deposited(msg.sender, amount);
    }


   function withdrawLP(uint256 lpAmount) external {
        uint amount = lpAmount == 0 ? lpToken.balanceOf(msg.sender) : lpAmount;
        if (amount == 0) return;
        
        require(amount <= lpToken.balanceOf(msg.sender), "LP balance exceeded");
  
        // calculate percentage of LP being withdrawn
        uint precision = 10 ** uint(lpToken.decimals());
        uint withdrawnPerc = precision * amount / lpToken.totalSupply();
        
        // then burn the LP for this withdrawal
        lpToken.burn(msg.sender, amount);

        bool isWithdrawingAll = amount == lpToken.totalSupply();
        uint depositTokenBalanceBefore = depositToken.balanceOf(address(this));

        // for each pool withdraw the % of LP
        for (uint i=0; i<pools.length; i++) {
            PoolInfo memory pool = pools[i];
            if (pool.lpTokenAddress != address(0x0)) {
                uint multipoolBalance = IERC20(pool.lpTokenAddress).balanceOf(address(this));
                uint withdrawAmount = isWithdrawingAll ? multipoolBalance : withdrawnPerc * multipoolBalance / precision;
                IPoolV3(pool.poolAddress).withdrawLP(withdrawAmount);
            }
        }

        uint amountWithdrawn = depositToken.balanceOf(address(this)) - depositTokenBalanceBefore;
        require (amountWithdrawn > 0, "Amount withdrawn is 0");

        // remember tokens withdrawn
        withdrawals[msg.sender] += amountWithdrawn;
        totalWithdrawn += amountWithdrawn;

        // transfer the amount of depoist tokens withdrawn to the user
        depositToken.transfer(msg.sender, amountWithdrawn);

        emit Withdrawn(msg.sender, amountWithdrawn);
    }


    /**
     * Returns the fees, in LP tokens, that an account would pay to withdraw 'lpTokenAmount' LP tokens
     */
    function feesForWithdraw(uint lpTokenAmount, address account) public view returns (uint) {

        if (lpTokenAmount == 0 || lpToken.totalSupply() == 0) return 0;

        // calculate percentage of LP being withdrawn
        uint lpToWithdraw = lpTokenAmount < lpToken.balanceOf(account) ? lpTokenAmount : lpToken.balanceOf(account);

        uint precision = 10 ** uint(lpToken.decimals());
        uint withdrawnPerc = precision * lpToWithdraw / lpToken.totalSupply();
        bool isWithdrawingAll = (lpToWithdraw >= lpToken.totalSupply());

        // sum up expected fees value (in stable asset) across all pools in the multipool
        uint feesValue;
        for (uint i=0; i<pools.length; i++) {
            PoolInfo memory pool = pools[i];
            if (pool.poolAddress != address(0x0) && pool.lpTokenAddress != address(0x0)) {

                // the LP balance of the index with a pool
                uint indexBalance = IERC20(pool.lpTokenAddress).balanceOf(address(this));
                // the amount to withdraw from the pool is the percentage of Pool LP held by the Index
                uint withdrawAmount = isWithdrawingAll ? indexBalance : withdrawnPerc * indexBalance / precision;
                uint feesLP = IPoolV3(pool.poolAddress).feesForWithdraw(withdrawAmount, address(this));

                feesValue += IPoolV3(pool.poolAddress).lpTokensValue(feesLP);
            }
        }

        uint lpValue = this.lpTokensValue(lpToWithdraw);

        // lpFees / lpToWithdraw == feesValue / lpValue
        // lpFees := lpToWithdraw * feesValue / lpValue 
        uint lpFees = lpToWithdraw * feesValue / lpValue;

        return lpFees;
    }




    //// ONLY OWNER FUNCTIONS ////
    function addPool(string memory _name, address _pool, address _lpToken, uint8 weight) external onlyOwner {
        PoolInfo memory pool = PoolInfo({
            name: _name,
            poolAddress: _pool,
            lpTokenAddress: _lpToken,
            weight: weight
        });

        pools.push(pool);
        totalWeights += pool.weight;
    }

    function removePool(uint index) external onlyOwner {
        PoolInfo memory pool = pools[index];
        totalWeights -= pool.weight;

        delete pools[index];
    }

    function setFarmAddress(address _farmAddress) public onlyOwner {
        daoTokenFarm = IDAOTokenFarm(_farmAddress);
    }

    //// INTERNAL FUNCTIONS ////

    // Return the value of all pools in the MultiPool
    function totalPoolsValue() public view returns(uint) {
        uint total;
        for (uint i=0; i<pools.length; i++) {
            PoolInfo memory pool = pools[i];
            if (pool.poolAddress != address(0x0)) {
                total += IPoolV3(pool.poolAddress).totalValue();
            }
        }

        return total;
    }

    // Returns the MultiPool LP tokens representing the % of the value of the 'amount' deposited
    // with respect to the total value of this MultiPool
    function lpTokensForDeposit(uint amount) internal view returns (uint) {
        
        uint depositLPTokens;
        if (lpToken.totalSupply() == 0) {
            // If first deposit => allocate the inital LP tokens amount to the user
            depositLPTokens = amount;
        } else {
            // if already have allocated LP tokens => calculate the additional LP tokens for this deposit
            // calculate portfolio % of the deposit (using 'precision' digits)
            uint precision = 10**uint(lpToken.decimals());
            uint depositPercentage = precision * amount / totalValue();

            // calculate the amount of LP tokens for the deposit so that they represent 
            // a % of the existing LP tokens equivalent to the % value of this deposit to the sum of all pools value.
            // 
            // X := P * T / (1 - P)  
            //      X: additinal LP toleks to allocate to the user to account for this deposit
            //      P: Percentage of pools value accounted by this deposit
            //      T: total LP tokens allocated before this deposit
    
            depositLPTokens = (depositPercentage * lpToken.totalSupply()) / ((1 * precision) - depositPercentage);
        }

        return depositLPTokens;
    }



    // Deposit 'amount' into 'pool' and returns the pool LP tokens received
    function allocateToPool(PoolInfo memory pool, uint amount) internal returns (uint) {
        IERC20 pooLP = IERC20(pool.lpTokenAddress);
        uint lpBalanceBefore = pooLP.balanceOf(address(this));

        // deposit into the pool
        depositToken.approve(pool.poolAddress, amount);
        IPoolV3(pool.poolAddress).deposit(amount);

        // return the LP tokens received
        return pooLP.balanceOf(address(this)) - lpBalanceBefore;
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
pragma solidity ^0.8.14;

interface IPoolV3 {

    // View functions

    function totalValue() external view returns(uint);
    function riskAssetValue() external view returns(uint);
    function stableAssetValue() external view returns(uint);
    function portfolioValue(address addr) external view returns (uint);
    function feesForWithdraw(uint lpToWithdraw, address account) external view returns (uint);
    function lpTokensValue (uint lpTokens) external view returns (uint);

    // Transactional functions
    function deposit(uint amount) external;
    function withdrawLP(uint amount) external;

    // Only Owner functions
    function setFeesPerc(uint feesPerc) external;
    function setSlippageThereshold(uint slippage) external;
    function setStrategy(address strategyAddress) external;
    function setUpkeepInterval(uint upkeepInterval) external;
    function collectFees(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MinterRole.sol";

/**
 * The LP Token of the Index.
 * New tokens get minted by the Pool when users deposit into the Index
 * and get burt when users withdraw from the Index.
 * Only the Index contract should be able to mint/burn these tokens.
 */

contract IndexLPToken is ERC20, MinterRole {

    uint8 immutable decs;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol) {
        decs = _decimals;
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(address to, uint256 value) public onlyMinter returns (bool) {
        _burn(to, value);
        return true;
    }

    function decimals() public view override returns (uint8) {
        return decs;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IDAOTokenFarm {

    function getStakedBalance(address account, address lpToken) external view returns (uint);
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
pragma solidity ^0.8.14;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0), "0x0 account");
        require(!has(role, account), "Account already has role");

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0), "0x0 account");
        require(has(role, account), "Account does not have role");

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "0x0 account");
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Non minter call");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}