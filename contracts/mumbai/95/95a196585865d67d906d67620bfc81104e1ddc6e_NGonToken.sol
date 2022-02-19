/**
 *Submitted for verification at polygonscan.com on 2022-02-18
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: NGonToken.sol



/*
 AN   NN    NN        GGGGGG    OOOOOO   NN    NN           w:  https://ngon.tech
      NNN   NN       GG    GG  OO    OO  NNN   NN           tw: @ngondomforreal
      NNNN  NN  ---- GG        OO    OO  NNNN  NN           fb: ngonproject
      NN  NNNN  ---- GG  GGGG  OO    OO  NN  NNNN           
      NN   NNN       GG    GG  OO    OO  NN   NNN
      NN    NN        GGGGGG    OOOOOO   NN    NN  PROJECT
*/
//Current Projects
// w:retrogameslibrary.co.uk  - - - - tw:@retrogamlib
// w:avttpt.ngon.tech


pragma solidity >=0.8.0 <0.9.0;





 
contract NGonToken is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public devWallet;
    address public managementWallet;
    bool public isPaused;

    uint8 private _decimals;

    uint8 private dFee;    
    uint8 private mFee;
    uint8 private lFee;

    uint public holdRequirementForLottoEligibility;
    uint8 private txNumForDraw = 10;

    mapping (address => bool) isExemptFromFees;
    mapping (address => bool) isTeamWallet;

    address[] private eligibleForLotto; //Only tax paying users are eligible for the lottery draw. Dev/Admin/Exchange wallets are excluded

    uint private maxSupply;
    uint8 private txCounter;
    bool public lotteryEnabled;

    constructor (
        string memory _setName,
        string memory _setSymbol,
        uint _supply,
        uint8 _setDecimals,
        uint8 _devFee,
        uint8 _managementFee,
        uint8 _lFee) {
        _name = _setName;
        _symbol = _setSymbol;
        _decimals = _setDecimals;
        maxSupply = _supply * 10**_decimals;
        managementWallet = owner();
        devWallet = owner();
        isExemptFromFees[owner()] = true;
        isExemptFromFees[address(this)] = true;        
        setFees(_devFee, _managementFee, _lFee);
        
        _mint(owner(), maxSupply);
    }

//onlyOwner() funcs
//Standard set fees function - Capped - 10 == 1% to allow for percentages to decimal places
    function setFees(uint8 _dFee, uint8 _mFee, uint8 _lFee) public onlyOwner {
        require((_dFee + _mFee + _lFee) <= 50, "Fees cannot exceed 5%");
        dFee = _dFee;
        mFee = _mFee;
        lFee = _lFee;
    }

//Initialised to 1000
    function setLottoRequirementAmount(uint _amountInNgon) public onlyOwner {
        require(_amountInNgon >= 1, "Must be an Token holder to be eligible - can't be zero");
        holdRequirementForLottoEligibility = _amountInNgon * 10**_decimals;
    }

//Initialised to 10
    function settxNumForDraw(uint8 _number) public onlyOwner {
        txNumForDraw = _number;
        if (_number <= txCounter) {
            txCounter = 0;
        }
    }

/* Sets new Wallet addresses for Dev and management fund. 
Checks to make sure wallets aren't already exempt from fees and limits before setting*/
    function setDevWallet(address _address) public onlyOwner {
        require (devWallet != _address, "This address is already the Dev Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        } 
        
        devWallet = _address;
    }

    function setManagementWallet(address _address) public onlyOwner {
        require (managementWallet != _address, "This address is already the management Wallet");

        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        } 
        
        managementWallet = _address;
    }

//Enables/disables the Lottery
    function setLotteryEnabled(bool _bool) public onlyOwner {
        require(holdRequirementForLottoEligibility >= 1, "Set token hold requirements before enabling lottery");
        require(lotteryEnabled != _bool, "Lottery already matches that state");
        lotteryEnabled = _bool;
    }

//Resets Dev/Management wallets to owner address
    function resetWalletsToOwner() public onlyOwner {
        if (devWallet != owner()) {
            isExemptFromFees[devWallet] = false;
            devWallet = owner();
        }
        if (managementWallet != owner()) {
            isExemptFromFees[managementWallet] = false;
            managementWallet = owner();
        }
    }

//Pauses contract, prevents transactions
    function setPause(bool _bool) public onlyOwner {
        require(isPaused != _bool, "isPaused already matches that state");
        isPaused = _bool;
    }
//Adds team wallet with fee exemption
    function addTeamWallet(address _address) public onlyOwner {
        require(!isTeamWallet[_address], "Address already registered as a Team Wallet");
        if (!isExemptFromFees[_address]) {
        isExemptFromFees[_address] = true;
        }

        isTeamWallet[_address] = true;
    }

    function removeTeamWallet(address _address) public onlyOwner {
        require(isTeamWallet[_address], "Address already not currently registered as a Team Wallet");
        removeFeeExemption(_address);
        isTeamWallet[_address] = false;
    }

    function setExemptFromFees(address _address) public onlyOwner {
        require(!isExemptFromFees[_address], "Address is already exempt");
            
        isExemptFromFees[_address] = true;
    }

    function removeFeeExemption(address _address) public onlyOwner {
        require(_address != owner(), "Owner cannot be removed");
        require(_address != devWallet, "DevWallet cannot be removed");
        require(_address != managementWallet, "management Wallet cannot be removed");
        
        isExemptFromFees[_address] = false; 
    }

//
//In event tokens need reissuing - capped to maxSupply
    function reissueMint(address _address, uint256 amount) public onlyOwner {
        require(totalSupply() < maxSupply, "Maximum tokens already exist");
        require(totalSupply() + amount <= maxSupply, "You can't mint more than the Max Supply");
        _mint(_address, amount);
    }

// Private/Int funcs
//Gets the tax amounts for each normal transaction
    function getTaxAmount(uint _amount) private view returns (uint, uint, uint, uint){
        uint _dFee = (_amount * dFee) / 1000;
        uint _mFee = (_amount * mFee) / 1000;
        uint _lFee = (_amount * lFee) / 1000;
        uint _tAmount = _amount - (_dFee + _mFee + _lFee);
        return (_tAmount, _dFee, _mFee, _lFee);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");


        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

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

    
// transfer function to account for fees
    function _transferNormal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!isPaused, "Transfers are paused, check official announcements for info");
        
            (uint _tAmount, uint _dFee, uint _mFee, uint _lFee) = getTaxAmount(amount);

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += _tAmount;
            _balances[devWallet] += _dFee;
            _balances[managementWallet] += _mFee;
            _balances[address(this)] += _lFee;

            emit Transfer(sender, recipient, _tAmount);
            emit Transfer(sender, devWallet, _dFee);
            emit Transfer(sender, managementWallet, _mFee);
            emit Transfer(sender, address(this), _lFee);

            if (!isExemptFromFees[sender] && _balances[sender] < holdRequirementForLottoEligibility) {           
                for (uint i = 0; i < eligibleForLotto.length; i++) {
                    if (eligibleForLotto[i] == sender) {
                        eligibleForLotto[i] = eligibleForLotto[eligibleForLotto.length - 1];
                        eligibleForLotto.pop();
                            break;
                    }
                }
            }

            if (!isExemptFromFees[recipient] && _balances[recipient] >= holdRequirementForLottoEligibility) { 
                bool exists;
                for (uint i = 0; i < eligibleForLotto.length; i++) {
                    if (eligibleForLotto[i] == recipient){
                        exists = true;
                        break;
                    }  
                }

                if (!exists) {
                    eligibleForLotto.push(recipient);
                }
              
            }

            if (lotteryEnabled) {
                txCounter++;
                if (txCounter == txNumForDraw) {
                    uint randAdditive = _balances[address(this)];
                    uint modulus = eligibleForLotto.length * 2;
                    uint rand = uint(keccak256(abi.encodePacked(block.timestamp + _tAmount + randAdditive)));
                    uint lottoResult = rand % modulus;

                    if (lottoResult > eligibleForLotto.length) { //Lotto rollover occurs if result does not match an eligible wallet
                        txCounter = 0; //Reset the txCounter for the next lotto draw
                    } else { //distribute jackpot to winner and reset the txCounter
                    address winner = eligibleForLotto[lottoResult]; 
                    emit Transfer(address(this), winner, _balances[address(this)]);
                    _balances[winner] += _balances[address(this)];
                    _balances[address(this)] = 0;
                                  
                    txCounter = 0;
                    }
                }
            }
        
    }

//Added transfer function for sending to wallets with no max hold limits (Owner,Dev,Management,Team etc)
    function _transferNoFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!isPaused, "Transfers are paused, check official announcements for info");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

//Check to see if the recipient is exempt from fees and if their balance makes them eligible for the lottery draw
        if (!isExemptFromFees[recipient] && _balances[recipient] >= holdRequirementForLottoEligibility) { 
            bool exists;    
            for (uint i = 0; i < eligibleForLotto.length; i++) {
                if (eligibleForLotto[i] == recipient){
                    exists = true;
                        break;
                    }
            }
//Adds to list of eligible addresses if not previously listed 
            if (exists == false) {
                eligibleForLotto.push(recipient);
            }
                
        }

        emit Transfer(sender, recipient, amount);

    }

// Means of retrieval in case of tokens being sent to contract in error
    function withdrawToOwner(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        
        require(balance > 0, "Contract has no balance");
        require(token.transfer(owner(), balance), "Transfer failed");
    }

// Public funcs
// Allows burning of tokens
    function _burnTokens(uint amount) public {
        require(balanceOf(_msgSender()) >= amount, "You don't have enough to burn that amount");
        _burn(_msgSender(), amount);
    }

// Standard ERC20 funcs
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

// Adapted transfer call to cater for fee exemptions
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!isPaused, "Transfers are paused, check official announcements for info");
        require(amount > 0, "Amount must be greater than zero");
            if (isExemptFromFees[_msgSender()] || isExemptFromFees[recipient]) {
                _transferNoFees(_msgSender(), recipient, amount);
            } else {
                _transferNormal(_msgSender(), recipient, amount);
            }

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!isPaused, "Transfers are paused, check official announcements for info");
        require(amount > 0, "Amount must be greater than zero");

        if (isExemptFromFees[sender] || isExemptFromFees[recipient]) {
                _transferNoFees(sender, recipient, amount);
            } else {
                _transferNormal(sender, recipient, amount);
            }

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

      return true;
      
    }
//

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

// Public Views

    function checkIfFeeExempt(address _address) public view returns (bool) {
        bool a;
        if (isExemptFromFees[_address]) {
            a = true;
        }
        return a;
    }

    function amIEligibleForLotto() public view returns (bool) {
        bool _bool;
        for (uint i = 0; i < eligibleForLotto.length; i++) {
            if (eligibleForLotto[i] == _msgSender()) {
            _bool = true;
            break;
            }
        }
            return _bool;

    }

//Check if wallet is eligible for lottery
    function checkWalletLottoEligibility(address _address) public view returns(bool) {
        bool _bool;
        for (uint i = 0; i < eligibleForLotto.length; i++) {
            if (eligibleForLotto[i] == _address) {
            _bool = true;
            break;
            }
        }
        
        return _bool;

    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function lottoBalance() public view returns (uint256) {
        return this.balanceOf(address(this));
    }

    function fees() public view returns (uint8) {
        uint8 _fees = (dFee + lFee) + mFee;
        return (_fees);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    receive() external payable {}
}