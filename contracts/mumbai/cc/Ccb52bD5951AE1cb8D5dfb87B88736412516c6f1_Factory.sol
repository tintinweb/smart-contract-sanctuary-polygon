//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Exchange.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {

    //a mapping with an ERC20 token address on the one hand, and an exchange address on another.
    mapping(address=>address) public tokenToExchange;

    //function to create an exchange.
    function createExchange(address _tokenAddress) public onlyOwner returns (address) {
        require(_tokenAddress != address(0), "address is invalid");
        require(tokenToExchange[_tokenAddress] == address(0), "exchange already deployed for this token");

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        return address(exchange);
    }

    //function to add an exchange only by the owner.
    function manuallyAddExchange(address _tokenAddress, address _exchangeAddress) public onlyOwner {
        require(_tokenAddress != address(0), "address is invalid");
        require (_exchangeAddress != address(0), "address is invalid");
        require(tokenToExchange[_tokenAddress] == address(0), "exchange already deployed for this token");

        tokenToExchange[_tokenAddress] = _exchangeAddress;
    }


    //interfaces don't allow retrieving state variables, which is why we're building this function - for other contracts to interact with it
    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Sacred.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFactory {
    function getExchange(address _tokenAddress) external returns (address);
}

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable;

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable;
}

contract Exchange is ERC20 {
    address public tokenAddress;
    address public factoryAddress;

    constructor (address _token) ERC20("Sacred-Dex-V1", "Sacrex-V1") {
        require(_token != address(0), "invalid token address");

        tokenAddress = _token;
    }


    //here you need to keep the reserve ratio constant - you don't want to mess with the reserve if the coin has already been deployed, b/c that would lead to arbitrage.
    //then, if your ratio is (token reserve / eth reserve) you multiply the result with the value of tokens with the ratio in order to get the amount of tokens that you have to deposit.
    function addLiquidity(uint256 _tokenAmount) public payable returns (uint256){
        IERC20Sacred tokenToShip = IERC20Sacred(tokenAddress);

        if (getReserve() == 0) {
            tokenToShip.transferFrom(msg.sender, address(this), _tokenAmount);


            //if the reserve is 0, then amount of LP tokens minted will be equal to the amount of eth sent.
            uint256 liquidity = address(this).balance;

            _mint(msg.sender, liquidity);

            return liquidity;
        }

        else {

            //getting the eth reserve but removing the amount sent, as this is already in the contract.
            uint256 ethReserve = address(this).balance - msg.value;

            //getting the token reserve:
            uint256 tokenReserve = getReserve();

            //any reason why the parenthesis should be in a different position - or be there at all?
            uint256 tokenAmount = msg.value * (tokenReserve / ethReserve);

            //the token amount specified by the user needs to be at least as much as the amount that was calculated based on how much eth was transferred.
            require(_tokenAmount >= tokenAmount, "not enough tokens for the transfer");

            //calling the transferFrom function:
            tokenToShip.transferFrom(msg.sender, address(this), tokenAmount);

            //minting the liquidity based on the formula from Uniswap that the LP tokens are total supply of LP tokens already in circulation * (provided eth / eth reserve)
            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);

            return liquidity;

        }

    }

    function getReserve() public view returns (uint256) {
        return IERC20Sacred(tokenAddress).balanceOf(address(this));
    }


    //low level function that calculates the amount received when swapping - uses the constant product formula
    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {

        //one of the two values is going to be address(this).balance
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

        //getting the input amount with a fee - by multiplying both the numerator and the denominator by a power of 10. The fee in this case is 1%, but it can be modified. A fee of 0.03% for example will be multiplying by a factor of 100 and the inputAmountWithFee would be multiplied by 997.
        uint256 inputAmountWithFee = inputAmount * 99;

        uint256 numerator = inputAmountWithFee * outputReserve;

        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;

        //original formula - when no fee is present:
        //        return (inputAmount * outputReserve) / (inputReserve + inputAmount);
    }

    //function that uses the getAmount function to calculate the amount of tokens received when swapping a certain
    //amount of eth
    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "amount needs to be above 0");

        //get reserve of the token, which is needed to calcualte the amount:
        uint256 tokenReserve = getReserve();

        //calling getAmount with the information available:
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    //the reverse of the function above:
    function getEthAmount(uint256 tokenSold) public view returns (uint256) {
        require(tokenSold > 0, "amount needs to be above 0");

        uint256 tokenReserve = getReserve();

        return getAmount(tokenSold, tokenReserve, address(this).balance);
    }

    //the function that allows swapping eth for tokens, using the functions above:
    function ethToToken(uint256 _minTokens, address _recipient) private {
        //getting the reserve:
        uint256 tokenReserve = getReserve();

        //calculating how many tokens we would be getting
        //notice that the value provided by the user is subtracted from the balance
        //that's because by the time this function is called, the balance of the contract
        //would have already included the eth that the user sent to the contract:
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve);

        //require that the _minTokens, which is calculated on the frontend and decided on by the user,
        //is lower or equal to the tokens bought, so that the user doesn't get screwed.
        require(tokensBought >= _minTokens, "slippage out of bounds");

        //transfer the tokens to the user if the require statement above checks out, using the
        //values we've retrieved.
        IERC20Sacred(tokenAddress).transfer(_recipient, tokensBought);
    }

    //the function that allows swapping eth for tokens, using the functions above, with a sacred message:
    function ethToTokenSacredOne(uint256 _minTokens, address _recipient, string memory _name, string memory _message) private {
        //getting the reserve:
        uint256 tokenReserve = getReserve();

        //calculating how many tokens we would be getting
        //notice that the value provided by the user is subtracted from the balance
        //that's because by the time this function is called, the balance of the contract
        //would have already included the eth that the user sent to the contract:
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve);

        //require that the _minTokens, which is calculated on the frontend and decided on by the user,
        //is lower or equal to the tokens bought, so that the user doesn't get screwed.
        require(tokensBought >= _minTokens, "slippage out of bounds");

        //transfer the tokens to the user if the require statement above checks out, using the
        //values we've retrieved.
        IERC20Sacred(tokenAddress).transferSacredOne(_recipient, tokensBought, _name, _message);
    }


    //function that uses ethToToken to transfer to msg.sender
    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    //function that uses ethToToken to transfer to msg.sender
    function ethToTokenSwapSacredOne(uint256 _minTokens, string memory _name, string memory _message) public payable {
        ethToTokenSacredOne(_minTokens, msg.sender, _name, _message);
    }

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) public payable {
        ethToToken(_minTokens, _recipient);
    }

    function ethToTokenTransferSacredOne(uint256 _minTokens, address _recipient, string memory _name, string memory _message) public payable {
        ethToTokenSacredOne(_minTokens, _recipient, _name, _message);
    }

    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {

        //getting the amount of eth that will be bought:
        uint256 ethBought = getAmount(
            _tokensSold,
            IERC20Sacred(tokenAddress).balanceOf(address(this)),
            address(this).balance);

        //require that the _minEth, which is calculated on the frontend and decided on by the user,is lower or equal to the eth bought, so that the user doesn't get screwed.
        require(ethBought >= _minEth, "slippage out of bounds");

        //transferring the tokens to the exchange:
        //do not need to have a require statement because transferFrom throws exception in case balance is insufficient.
        IERC20Sacred(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);

        //transferring eth to sender:
        (bool success,) = msg.sender.call{value : ethBought}("");

        //require that the transfer is successful:
        require(success, "Eth transfer failed");
    }

    function tokenToEthSwapSacredOne(uint256 _tokensSold, uint256 _minEth, string memory _name, string memory _message) public {

        //getting the amount of eth that will be bought:
        uint256 ethBought = getAmount(
            _tokensSold,
            IERC20Sacred(tokenAddress).balanceOf(address(this)),
            address(this).balance);

        //require that the _minEth, which is calculated on the frontend and decided on by the user,is lower or equal to the eth bought, so that the user doesn't get screwed.
        require(ethBought >= _minEth, "slippage out of bounds");

        //transferring the tokens to the exchange:
        //do not need to have a require statement because transferFrom throws exception in case balance is insufficient.
        IERC20Sacred(tokenAddress).transferFromSacredOne(msg.sender, address(this), _tokensSold, _name, _message);

        //transferring eth to sender:
        (bool success,) = msg.sender.call{value : ethBought}("");

        //require that the transfer is successful:
        require(success, "Eth transfer failed");
    }



    //takes the amount of tokens to be exchanged
    //using the checks-effects-interactions pattern to create the architecture:
    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "needs to be larger than 0");

        uint ethAmount = (address(this).balance * _amount) / totalSupply();
        uint tokenAmount = (getReserve() * _amount) / totalSupply();

        //burn the tokens:
        _burn(msg.sender, _amount);

        //transfer the eth to the person calling the function:
        payable(msg.sender).transfer(ethAmount);

        //transfer the ERC20 tokens to the person calling the amount:
        IERC20Sacred(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    //function that allows swapping between tokens by first converting the tokens from this exchange to eth
    function tokenToTokenSwap(
        uint256 _tokensSold,
        uint256 _minTokensBought,
        address _tokenAddress
    ) public {

        address exchangeAddress = IFactory(factoryAddress).getExchange(_tokenAddress);

        require(
        exchangeAddress != address(this) && exchangeAddress != address(0),
        "exchange address invalid"
    );

        //getting the amount of eth that can be bought with the token amount provided:
        uint256 ethBought = getAmount(
            _tokensSold,
            IERC20Sacred(tokenAddress).balanceOf(address(this)),
            address(this).balance);

        IExchange(_tokenAddress).ethToTokenTransfer{value: ethBought}(_minTokensBought, msg.sender);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Sacred {
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
   * @dev Emitted when the someone intends to write a message on the blockchain:
     */
    event SacredEvent(string SacredMessage);

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * Emits a {SacredEvent} event.
     */
    function transferSacredOne(
        address _to,
        uint _tokens,
        string memory _name,
        string memory _message
    ) external returns (bool);

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
     * Posts a sacred message as on the blockchain as an event, using 'name' and 'message' as variables
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
 * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Posts a sacred message as on the blockchain as an event, using 'name' and 'message' as variables
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * Emits a {SacredEvent} event.
     */
    function transferFromSacredOne(
        address _from,
        address _to,
        uint256 _amount,
        string memory _name,
        string memory _message
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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