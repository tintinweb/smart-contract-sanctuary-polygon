/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT

//Evolve coin is official token by Evolve, first sport federation of E2, expanding onto the metaverse. Please for more information visit , or you can reach us here https://discord.gg/bsGeU7rMK6
//go Shane! Go E2, The Metaverse!

pragma solidity ^ 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^ 0.8.0;


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
    function owner() public view virtual returns(address) {
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


pragma solidity ^ 0.8.0;

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
function totalSupply() external view returns(uint256);

/**
 * @dev Returns the amount of tokens owned by `account`.
 */
function balanceOf(address account) external view returns(uint256);

/**
 * @dev Moves `amount` tokens from the caller's account to `to`.
 *
 * Returns a boolean value indicating whether the operation succeeded.
 *
 * Emits a {Transfer} event.
 */
function transfer(address to, uint256 amount) external returns(bool);

/**
 * @dev Returns the remaining number of tokens that `spender` will be
 * allowed to spend on behalf of `owner` through {transferFrom}. This is
 * zero by default.
 *
 * This value changes when {approve} or {transferFrom} are called.
 */
function allowance(address owner, address spender) external view returns(uint256);

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
function approve(address spender, uint256 amount) external returns(bool);

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
) external returns(bool);
}


pragma solidity ^ 0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns(string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns(string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns(uint8);
}



pragma solidity ^ 0.8.0;

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
    function name() public view virtual override returns(string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns(string memory) {
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
    function decimals() public view virtual override returns(uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns(uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns(uint256) {
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
    function transfer(address to, uint256 amount) public virtual override returns(bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns(uint256) {
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
    function approve(address spender, uint256 amount) public virtual override returns(bool) {
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
    ) public virtual override returns(bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
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
    ) internal virtual { }

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
    ) internal virtual { }
}



pragma solidity ^ 0.8.0;

abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}


pragma solidity >= 0.7.0 < 0.9.0;


interface TokenInterface {
    function ownerOf(uint256 tokenId) external view returns(address);
}

interface LiquidityInterface {
    function transferForLiquidity() external payable;
}


contract EvolveCoin is ERC20, ERC20Burnable, Ownable {

    address public liquidityAddress = 0x3e3F1D84069A10cb7B6EEbC07eC83614fb4Ab45C;
    LiquidityInterface liquidityInstance = LiquidityInterface(liquidityAddress);

    uint256 public maxSupply = 20000000000 * (10 ** 18);
    uint256 public maxAirdroppable = 100000000 * (10 ** 18);
    uint256 public totalAirdropped = 0;
    uint256 public currentPrice = 1000000000 gwei;  //this means 1 Matic
    address[] public stakingAssets;
    address[] public creatorsList;
    mapping(address => uint256) public stakeAmount;
    mapping(address => uint256) public stakeTime;
    mapping(address => address[]) public stakeCreators;
    mapping(address => uint256) public stakePercentageToCreators;
    mapping(address => uint256) public howMuchStakedFromContract;

    struct tokenBond{
        address contractAddress;
        uint256 tokenId;
        uint256 whenStakeStarted;
    }

    tokenBond[] tokenBonds;


    constructor(
        string memory _name,
        string memory _symbol

    ) ERC20(_name, _symbol) {

    }

    function buyAtPrice(uint amount) public payable {

        require(msg.value >= currentPrice * amount / (10 ** 4));
        _mint(msg.sender, amount * (10 ** 14));

    }

    function setPrice(uint256 newPrice) public onlyOwner {

        uint256 thisPrice = newPrice;
        currentPrice = thisPrice;

    }

    //allows to airdrop Token till a certain maxAirdroppable
    function airdropToken(uint amount, address addressTo) public onlyOwner {
        uint256 amountConverted = amount * (10 ** 14);
        uint256 supply = totalSupply();
        require(amountConverted + supply <= maxSupply);
        require(amountConverted + totalAirdropped <= maxAirdroppable);

        totalAirdropped += amountConverted;
        _mint(addressTo, amountConverted);

    }

    function burnForAction(uint amount, address whoBurn) public {
        bool isListedAsset = false;
        for (uint i = 0; i < stakingAssets.length; i++) {
            if (stakingAssets[i] == msg.sender) {
                isListedAsset = true;
            }
        }
        require(isListedAsset == true);

        uint dividendi = stakeCreators[msg.sender].length;
        uint howMuch = ((amount * (10 ** 14) * stakePercentageToCreators[msg.sender]) / 100) / dividendi;

        for (uint i = 0; i < dividendi; i++) {

            _transfer(whoBurn, stakeCreators[msg.sender][i], howMuch);

        }

        _burn(whoBurn, amount * (10 ** 14) - (howMuch * dividendi));
        maxSupply -= amount * (10 ** 14) - (howMuch * dividendi);

    }

    function stakeAsset(address fromWhere, uint256 tokenId)public{

        uint256 supply = totalSupply();
        bool isListedAsset = false;
        for (uint i = 0; i < stakingAssets.length; i++) {
            if (stakingAssets[i] == fromWhere) {
                isListedAsset = true;
            }
        }
        require(isListedAsset == true);

        TokenInterface tokenInterface = TokenInterface(fromWhere);
        require(tokenInterface.ownerOf(tokenId) == msg.sender);

        uint inWhichPosition;
        bool bondExists = false;
        for (uint i = 0; i < tokenBonds.length; i++) {
            if (tokenBonds[i].contractAddress == fromWhere) {
                if (tokenBonds[i].tokenId == tokenId) {
                    inWhichPosition = i;
                    bondExists = true;
                }
            }
        }

        if (bondExists == false) {
            tokenBond memory thisBond = tokenBond(fromWhere, tokenId, block.timestamp);
            tokenBonds.push(thisBond);
        } else {

            require(block.timestamp - tokenBonds[inWhichPosition].whenStakeStarted > stakeTime[fromWhere]);
            tokenBonds[inWhichPosition].whenStakeStarted = block.timestamp;

        }

        require(stakeAmount[fromWhere] * (10 ** 14) + supply <= maxSupply);
        _mint(msg.sender, stakeAmount[fromWhere] * (10 ** 14));
        howMuchStakedFromContract[msg.sender] += stakeAmount[fromWhere];

    }

    function createAssetStakeDeal(address whatContract, uint256 _stakeAmount, uint256 _stakeTime, uint256 _percentageToCreators, address[] memory creatorsAddresses) public onlyOwner {


        bool isListedAsset = false;
        for (uint i = 0; i < stakingAssets.length; i++) {
            if (stakingAssets[i] == whatContract) {
                isListedAsset = true;
            }
        }
        require(isListedAsset == false);

        stakingAssets.push(whatContract);
        stakeAmount[whatContract] = _stakeAmount;
        stakeTime[whatContract] = _stakeTime;
        stakePercentageToCreators[whatContract] = _percentageToCreators;
        stakeCreators[whatContract] = creatorsAddresses;
        howMuchStakedFromContract[whatContract] = 0;


    }

    function modifyAssetStakeDeal(address whatContract, uint256 _stakeAmount, uint256 _stakeTime, uint256 _stakePercentage) public onlyOwner {

        stakeAmount[whatContract] = _stakeAmount;
        stakeTime[whatContract] = _stakeTime;
        stakePercentageToCreators[whatContract] = _stakePercentage;

    }

    function modifyAssetStakeCreators(address whatContract, address[] memory _creators) public onlyOwner{

        stakeCreators[whatContract] = _creators;

    }

    function getCurrentPrice() public view returns(uint256) {
        return currentPrice;

    }

    function getStakeContracts() public view returns(address[] memory){
        return stakingAssets;

    }

    function getMaxSupply() public view returns(uint256){
        return maxSupply;

    }

    function getHowMuchAirdropped() public view returns(uint256){
        return totalAirdropped;

    }

    function getTokenInvolved(address _contractAddress, uint whichPosition) public view returns(uint256) {

        uint256 whatId;
        uint counter = 0;
        for (uint i = 0; i < tokenBonds.length; i++) {
            if (tokenBonds[i].contractAddress == _contractAddress) {

                counter = counter + 1;
                if (counter == whichPosition) {
                    whatId = tokenBonds[i].tokenId;

                }

            }

        }

        return whatId;

    }

    function getTokenBond(uint256 _tokenId, address _contractAddress) public view returns(uint256){

        uint256 inWhichPosition;
        bool bondExists = false;
        for (uint i = 0; i < tokenBonds.length; i++) {
            if (tokenBonds[i].contractAddress == _contractAddress) {
                if (tokenBonds[i].tokenId == _tokenId) {
                    inWhichPosition = i;
                    bondExists = true;
                }
            }
        }

        require(bondExists == true);
        return tokenBonds[inWhichPosition].whenStakeStarted;

    }

    function isTokenStakable(uint256 _tokenId, address _contractAddress) public view returns(bool){

        uint256 inWhichPosition;
        bool bondExists = false;
        for (uint i = 0; i < tokenBonds.length; i++) {
            if (tokenBonds[i].contractAddress == _contractAddress) {
                if (tokenBonds[i].tokenId == _tokenId) {
                    inWhichPosition = i;
                    bondExists = true;
                }
            }
        }
        bool isAvaiable = false;
        if (bondExists == false) {
            isAvaiable = true;
        }
        if (block.timestamp - tokenBonds[inWhichPosition].whenStakeStarted > stakeTime[_contractAddress]) {
            isAvaiable = true;
        }

        return isAvaiable;

    }

    function withdraw() public payable onlyOwner {
        liquidityInstance.transferForLiquidity{value: (address(this).balance)}();
    }



}