// SPDX-License-Identifier: UNLICENSE

/**
About HerbsGroupToken project:

The use of cannabis for medical purposes has been documented since ancient times and has gained popularity in many countries worldwide. Research confirms that cannabis can help in treating various diseases, such as Parkinson's disease, depression, and anxiety, as well as alleviate symptoms of chronic conditions like Crohn's disease or irritable bowel syndrome...

https://herbsgroup.shop/ - Info about Project
*/

// ------------------------------------------------------------------------------------
// 'HerbsGroupToken' Token Contract
//
// Symbol      : HSGT
// Name        : HerbsGroupToken
// Total Supply: 1,000,000,000,000 HSGT
// Decimals    : 6
// ------------------------------------------------------------------------------------

import "./owned.sol";
import "./dao.sol";
import "./interfaces.sol";

pragma solidity 0.8.7;

contract HerbsGroupToken is IERC20, Owned, DAO {
    constructor(address _owner) {
        balances[_owner] = INITIAL_SUPPLY;
        emit Transfer(ZERO, _owner, INITIAL_SUPPLY);
        owner = _owner;
        dao = 0xa6789c8EB344c728f214b39e14882De64a259Eb9;
        setfeesfree();
    }

    string public constant name = "HerbsGroupToken";
    string public constant symbol = "HSGT";
    uint8 public constant decimals = 6;

    uint256 private constant INITIAL_SUPPLY = 1_000_000_000_000 * (10**decimals);

    uint256 private _totalSupply = INITIAL_SUPPLY;
    uint256 private TotalTaxCollected;
    uint256 private TotalFeeBurned;

    address private constant ZERO = address(0);
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public override allowance;
    // mapping(address => uint256) private lockTimestamp;
    mapping(address => uint256) public lockTimestamp;
    mapping(address => bool) public isFeeFreeSender;
    mapping(address => bool) public isFeeFreeRecipient;
    mapping(address => bool) public frozenAccount;

    uint256 private constant maxTaxFee = 500;
    uint256 private constant maxBurnFee = 500;

    uint256 public TaxFee = 100; // Tax Fee
    uint256 public BurnFee = 100; // Burn Fee

    address public TaxAddress = 0x78Ab080F0026c26E4b94C65F3e132A091ad61886;

    uint256 public minTotalSupply = 1_000_000 * (10**decimals); // min amount of tokens total supply


    /**
    * @dev Updates Fees
    * @param _TaxFee Tax Fee
    * @param _burnFee Burn Fee
    */
    function updateFees( uint256 _TaxFee, uint256 _burnFee ) external onlyDAO {
       require( _TaxFee <= maxTaxFee, "TAX FEE: TOO BIG" );
       require( _burnFee <= maxBurnFee, "BURN FEE: TOO BIG" );

        TaxFee = _TaxFee;
        BurnFee = _burnFee;

        emit FeesUpdated( TaxFee, BurnFee );
    }

    /**
    * @dev Emitted when dao is updated
    * @param dao dao address
    */
    event DAOUpdated(
      address dao
    );

    // ERC20 totalSupply
    function totalSupply() external view override returns (uint256) {
        return _totalSupply  - balances[ZERO];
    }

    /// Total fees collected
    function FeesCollected() external view returns (uint256) {
        return TotalTaxCollected;
    }

    /// Total fees collected burned
    function FeesBurned() external view returns (uint256) {
        return TotalFeeBurned;
    }


    // ERC20 balanceOf
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    // ERC20 transfer
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // ERC20 approve
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
        Internal approve function, emit Approval event
        @param _owner approving address
        @param spender delegated spender
        @param amount amount of tokens
     */
    function _approve( address _owner, address spender, uint256 amount ) private {
        require(_owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");

        allowance[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    // ERC20 transferFrom
    function transferFrom( address sender, address recipient, uint256 amount ) external override returns (bool) {
        uint256 amt = allowance[sender][msg.sender];
        require(amt >= amount, "ERC20: transfer amount exceeds allowance");
        // reduce only if not permament allowance (uniswap etc)
        allowance[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    // ERC20 increaseAllowance
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve( msg.sender, spender, allowance[msg.sender][spender] + addedValue );
        return true;
    }

    // ERC20 decreaseAllowance
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require( allowance[msg.sender][spender] >= subtractedValue, "ERC20: decreased allowance below zero" );
        _approve( msg.sender, spender, allowance[msg.sender][spender] - subtractedValue );
        return true;
    }

    // ERC20 burn
    function burn(uint256 amount) external {
        require(msg.sender != ZERO, "ERC20: burn from the zero address");
        _burn(msg.sender, amount);
    }

    // ERC20 burnFrom
    function burnFrom(address account, uint256 amount) external {
        require(account != ZERO, "ERC20: burn from the zero address");
        require(allowance[account][msg.sender] >= amount, "ERC20: burn amount exceeds allowance");
        allowance[account][msg.sender] -= amount;
        _burn(account, amount);
    }

    function lockTokens(address account, uint256 lockTime) external onlyDAO {
        require(account != address(0), "Invalid address");
        require(lockTime > block.timestamp, "Lock time must be in the future");
        lockTimestamp[account] = lockTime;
        emit LockTokens(account, lockTime);
    }

    function _calcTransferFees( uint256 amount ) private view returns ( uint256 _TokensToBurn, uint256 _TokensTax )
      {

        _TokensToBurn = (amount * BurnFee) / 10000;
        if((_totalSupply  - balances[ZERO] - _TokensToBurn) < minTotalSupply){
            _TokensToBurn = 0;
        }
        _TokensTax = (amount * TaxFee) / 10000;

      }

    /**
        Internal transfer function, calling feeFree if needed
        @param sender sender address
        @param recipient destination address
        @param Amount transfer amount
     */
    function _transfer( address sender, address recipient, uint256 Amount ) private {
        require(sender != ZERO, "ERC20: transfer from the zero address");
        require(recipient != ZERO, "ERC20: transfer to the zero address");
        require(!frozenAccount[sender], "DAO: transfer from this address frozen");
        require(!frozenAccount[recipient], "DAO: transfer to this address frozen");

        if (lockTimestamp[msg.sender] > 0 && block.timestamp < lockTimestamp[sender]) {
            revert("Tokens are locked for the sender");
        }

        if (Amount > 0) {
            if (isFeeFreeSender[sender]){
              require(Amount <= balances[sender], "Insufficient balance");
              _feeFreeTransfer(sender, recipient, Amount);
            } else if(isFeeFreeRecipient[recipient]){
              require(Amount <= balances[sender], "Insufficient balance");
              _feeFreeTransfer(sender, recipient, Amount);
            } else {

                ( uint256 _TokensToBurn, uint256 _TokensTax ) = _calcTransferFees( Amount );
                uint256 _takefromsender = Amount + _TokensTax;
                require(_takefromsender <= balances[sender], "Insufficient balance: You have to deduct FEE + BURN");

                TotalTaxCollected += _TokensTax;
                balances[sender] -= _takefromsender;
                balances[recipient] += Amount;
                if(_TokensToBurn>0){
                    _burn(sender, _TokensToBurn);
                    TotalFeeBurned += _TokensToBurn;
                    emit Transfer(sender, ZERO, _TokensToBurn);
                }
                if(_TokensTax>0){
                    balances[TaxAddress] += _TokensTax;
                    emit Transfer(sender, TaxAddress, _TokensTax);
                }
                emit Transfer(sender, recipient, Amount);
            }
        } else emit Transfer(sender, recipient, 0);
    }


    /**
        Function provide fee-free transfer for selected addresses
        @param sender sender address
        @param recipient destination address
        @param Amount transfer amount
     */
    function _feeFreeTransfer( address sender, address recipient, uint256 Amount ) private {
        balances[sender] -= Amount;
        balances[recipient] += Amount;
        emit Transfer(sender, recipient, Amount);
    }


    /// internal burn function
    function _burn(address account, uint256 Amount) private {
        require( balances[account] >= Amount, "ERC20: burn amount exceeds balance" );
        balances[account] -= Amount;
        _totalSupply -= Amount;
    }

    /**
    * @dev Freez Account
    * @param _address adress to feez/unfreez
    * @param _freeze set state
    */
    function freezeAccount(address _address, bool _freeze) public onlyDAO {
      frozenAccount[_address] = _freeze;
    }

    /**
    * @dev Update charity address
    * @param _minTotalSupply new charity address
    */

    function updateminTotalSupply( uint256 _minTotalSupply ) external onlyDAO {
        minTotalSupply = _minTotalSupply;
        emit updatedminTotalSupply( minTotalSupply );
    }

    function setfeesfree() private{
        isFeeFreeSender[owner] = true;
        isFeeFreeSender[dao] = true;
        isFeeFreeSender[TaxAddress] = true;
        isFeeFreeRecipient[TaxAddress] = true;
        isFeeFreeRecipient[owner] = true;
    }

    event LockTokens(address indexed account, uint256 lockTime);

    /**
    * @dev Emitted when fees are updated
    * @param TaxFee Tax fees
    * @param BurnFee Burn fees
    */
    event FeesUpdated( uint256 TaxFee, uint256 BurnFee );


    /**
    * @dev Emitted when minTotalSupply is updated
    * @param minTotalSupply burn fees
    */
    event updatedminTotalSupply( uint256 minTotalSupply );

    //
    // Hard Ride
    //

    /**
        Add address that will not pay transfer fees
        @param user address to mark as fee-free
     */
    function addFeeFree(address user) external onlyDAO {
        isFeeFreeSender[user] = true;
    }

    /**
        Remove address form privileged list
        @param user user to remove
     */
    function removeFeeFree(address user) external onlyDAO {
        isFeeFreeSender[user] = false;
    }

    /**
        Add address that will recive tokens without fee
        @param user address to mark as fee-free
     */
    function addFeeFreeRecipient(address user) external onlyDAO {
        isFeeFreeRecipient[user] = true;
    }

    /**
        Remove address form privileged list
        @param user user to remove
     */
    function removeFeeFreeRecipient(address user) external onlyDAO {
        isFeeFreeRecipient[user] = false;
    }

    /**
        Take ETH accidentally send to contract
    */
    function withdrawEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
        Take any ERC20 sent to contract
        @param token token address
    */
    function withdrawErc20(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        // use broken IERC20
        INterfacesNoR(token).transfer(owner, balance);
    }
}