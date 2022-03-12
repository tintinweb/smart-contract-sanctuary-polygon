/**
 *Submitted for verification at polygonscan.com on 2022-03-11
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/SCATERC20.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

abstract contract ERC20 is IERC20 {

  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) internal _allowances;

  uint256 internal _totalSupply;

  string internal _name;

  string internal _symbol;
    
  uint8 internal _decimals;

  constructor (string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender]
          .sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]
          .sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      _beforeTokenTransfer(sender, recipient, amount);

      _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address( this ), account_, amount_);
        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address( 0 ), account_, amount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal virtual { }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IERC2612Permit {

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct =
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = ecrecover(_hash, v, r, s);
        require(signer != address(0) && signer == owner, "Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

contract VaultOwned is Ownable {
    
  address public _vault;
  bool public vaultIsLocked = false;

  function setVault( address vault_ ) external onlyOwner() returns ( bool ) {
    require( !vaultIsLocked, "The Vault cannot be changed!" );
    _vault = vault_;

    return true;
  }

  function lockVault() external onlyOwner() {
    require( !vaultIsLocked, "The Vault cannot be changed!" );
    vaultIsLocked = true;
  }

  function vault() public view returns (address) {
    return _vault;
  }

  modifier onlyVault() {
    require( _vault == msg.sender, "VaultOwned: caller is not the Vault" );
    _;
  }

}

contract SCATERC20Token is ERC20Permit, VaultOwned {

    using SafeMath for uint256;

    // If one of these addresses transfers into a taxed destination
    // trigger anti-bot.
    mapping(address => bool) public antiBotTriggererMap;

    // Dual directionally exempt an address from tax.
    mapping(address => bool) public exemptTaxMap;

    // Tax an address recieving or sending SCAT,
    mapping(address => bool) public taxFromMap;
    mapping(address => bool) public taxToMap;

    // Max transfer tax rate: 25.00%.
    uint256 public constant MAXIMUM_TRANSFER_TAX_RATE = 2500;

    // Transfer tax rate in basis points. (default 8.00%)
    uint256 public transferTaxRate = 800;
    // Tax rate the unix time a buyback occurs.
    uint256 public constant peakAntiBotTaxRate = 9000;

    // The last unixtimestamp a buyback occured.
    uint256 public lastAntiBotTrigger = 0;
    // How long the extra tax linearly decends for in seconds.
    uint256 public antiBotCoolDown = 6 minutes;//6;
    // The share the SCAT stakers get of the anti-bot tax.
    // This is in addition to their 8%.
    uint256 public stakingShareOfAntiBotTax = 0;

    // Staking address for rewards, defaults to burning tokens, but will be set to
    // the real staking address momentarily after this contracts deploy step.
    address public stakingAddress = 0x000000000000000000000000000000000000dEaD;

    // Treasury address.
    address public treasuryAddress = 0x000000000000000000000000000000000000dEaD;

    address public constant houseWallet = 0x4E5D385E44DCD0b7adf5fBe03A6BB867A8A90E7B;

    event TransferFeeChanged( uint256 txnFee );
    event StakingShareOfAntiBotTaxChanged( uint256 newShare );
    event UpdateFeeMaps( address indexed _contract, bool fromTaxed, bool toTaxed );
    event UpdateExemptMaps( address indexed _contract, bool indexed exempt );
    event UpdateAntiBotRoleMap( address indexed _address, bool hasRole );
    event SetStakingAddress( address stakingAddress );
    event SetTreasuryAddress( address treasuryAddress );
    event OperatorTransferred( address indexed previousOperator, address indexed newOperator );
    event StartAntiBot( uint256 indexed unitTime );
    event SetSCATRouter( address router );

    // The operator can only update the transfer tax rate
    address public operator;

    modifier onlyOperator() {
        require( operator == msg.sender, "!operator");
        _;
    }

    modifier onlyOperatorOrTreasury() {
        require( treasuryAddress == msg.sender || operator == msg.sender, "!treasury && !operator");
        _;
    }

    constructor( address _addLiquidityHelper ) ERC20("SnowCat", "SCAT", 9) {
      require( _addLiquidityHelper != address(0), "addLiquidityHelper address can't be address(0)" );
      exemptTaxMap[_addLiquidityHelper] = true;

      operator = msg.sender;
    }

    function mint(address account_, uint256 amount_) external onlyVault() {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
     
    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }

    /// @dev overrides transfer function to meet tokenomics of SCAT
    function _transfer( address sender, address recipient, uint256 amount ) internal virtual override {
        bool isAntiBotOn = block.timestamp >= lastAntiBotTrigger && block.timestamp <= lastAntiBotTrigger + antiBotCoolDown;

        bool taxableTransfer = taxFromMap[ sender ] || taxToMap[ recipient ] ||
                              (isAntiBotOn && taxFromMap[ recipient ]) || (isAntiBotOn && taxToMap[ sender ]);

        if ( !taxableTransfer ||
            recipient == stakingAddress ||
            exemptTaxMap[sender] ||
            exemptTaxMap[recipient] ||
            transferTaxRate == 0
            ) {
            // Allows us to a
            if ( taxableTransfer && antiBotTriggererMap[ sender ] ) {
              antiBotTriggererMap[ sender ] = false;
              lastAntiBotTrigger = block.timestamp;
            }
            super._transfer( sender, recipient, amount );
        } else {
            uint256 totalTaxRate = transferTaxRate;

            if ( isAntiBotOn ) {
              totalTaxRate = peakAntiBotTaxRate.sub(
                  block.timestamp.sub( lastAntiBotTrigger )
                    .mul( peakAntiBotTaxRate.sub( transferTaxRate ) )
                      .div( antiBotCoolDown )
                );

                // Probably not necessary, but defensive programming.
                totalTaxRate = totalTaxRate < transferTaxRate ? transferTaxRate : totalTaxRate;
            }

            // default tax is 8.00% of every taxed transfer
            uint256 totalTaxAmount = amount.mul( totalTaxRate ).div( 10000 );

            // default 92.00% of transfer sent to recipient
            uint256 sendAmount = amount.sub( totalTaxAmount );

            assert( amount == sendAmount.add( totalTaxAmount ) );

            if ( totalTaxRate > transferTaxRate ) {
              uint256 baseTaxAmount = amount.mul( transferTaxRate ).div( 10000 );

              uint256 stakingShareTaxAmount = totalTaxAmount.sub( baseTaxAmount ).mul( stakingShareOfAntiBotTax ).div( 10000 );

              uint256 totalStakingReward = baseTaxAmount.add( stakingShareTaxAmount );

              if ( totalStakingReward > 0 )
                super._transfer( sender, stakingAddress, totalStakingReward );

              uint256 founderTaxReward = totalTaxAmount.sub( totalStakingReward );

              if ( founderTaxReward > 0 )
                super._transfer( sender, houseWallet, founderTaxReward );
            } else
              super._transfer( sender, stakingAddress, totalTaxAmount );

            super._transfer( sender, recipient, sendAmount );
            amount = sendAmount;
        }
    }

    /**
     * @dev Start the anti-bot tax rate with linear descent
     * Can only be called by the current operator or tresury.
     */    
    function startAntiBot() external onlyOperatorOrTreasury {
      lastAntiBotTrigger = block.timestamp;

      emit StartAntiBot( lastAntiBotTrigger );
    }

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateStakingShareOfAntiBotTax( uint256 _newStakingShareOfAntiBotTax ) external onlyOperator {
        require( _newStakingShareOfAntiBotTax  <= 10000,
            "!valid" );
        stakingShareOfAntiBotTax = _newStakingShareOfAntiBotTax;

        emit StakingShareOfAntiBotTaxChanged( stakingShareOfAntiBotTax );
    }

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate( uint256 _transferTaxRate ) external onlyOperator {
        require( _transferTaxRate  <= MAXIMUM_TRANSFER_TAX_RATE,
            "!valid" );
        transferTaxRate = _transferTaxRate;

        emit TransferFeeChanged( transferTaxRate );
    }

    /**
     * @dev Update the excludeFromMap
     * Can only be called by the current operator.
     */
    function updateFeeMaps( address _contract, bool fromTaxed, bool toTaxed ) external onlyOperator {
        taxFromMap[_contract] = fromTaxed;
        taxToMap[_contract] = toTaxed;

        emit UpdateFeeMaps( _contract, fromTaxed, toTaxed );
    }

      /**
     * @dev Update the excludeFromMap
     * Can only be called by the current operator.
     */
    function updatExemptMaps( address _contract, bool exempt ) external onlyOperator {
        exemptTaxMap[_contract] = exempt;

        emit UpdateExemptMaps( _contract, exempt );
    }

    /**
     * @dev Update the excludeFromMap
     * Can only be called by the current operator.
     */
    function updateAntiBotRoleMap( address _address, bool hasRole ) external onlyOperator {
        antiBotTriggererMap[_address] = hasRole;

        emit UpdateAntiBotRoleMap( _address, hasRole );
    }

    /**
     * @dev Update the SCAT staking address.
     * Can only be called by the current operator.
     */
    function updateSCATStakingAddress( address _stakingAddress ) external onlyOperator {
        require( _stakingAddress != address(0) && _stakingAddress != 0x000000000000000000000000000000000000dEaD, "!!0");
        require( stakingAddress == 0x000000000000000000000000000000000000dEaD, "!unset");

        stakingAddress = _stakingAddress;

        emit SetStakingAddress( stakingAddress );
    }
    
    /**
     * @dev Update the SCAT staking address.
     * Can only be called by the current operator.
     */
    function updateSCATTreasuryAddress( address _treasuryAddress ) external onlyOperator {
        require( _treasuryAddress != address(0) && _treasuryAddress != 0x000000000000000000000000000000000000dEaD, "!!0");
        require( treasuryAddress == 0x000000000000000000000000000000000000dEaD, "!unset");

        treasuryAddress = _treasuryAddress;

        exemptTaxMap[treasuryAddress] = true;

        emit SetTreasuryAddress( treasuryAddress );
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator( address newOperator ) external onlyOperator {
        require( newOperator != address(0), "!!0" );

        emit OperatorTransferred( operator, newOperator );

        operator = newOperator;
    }
}