// SPDX-License-Identifier: UNLICENSE

import "./owned.sol";
import "./dao.sol";
import "./interfaces.sol";

pragma solidity 0.8.7;

contract TMPTOKENV2 is IERC20, Owned, DAO {
    constructor(address _owner) {
        balances[_owner] = INITIAL_SUPPLY;
        emit Transfer(ZERO, _owner, INITIAL_SUPPLY);
        owner = _owner;
        dao = 0xF1A5C6fEcfE63504085fAf9a87E3cDa8B08fC383;
        setfeesfree();
    }

    string public constant name = "TMPTOKEN";
    string public constant symbol = "TMP2";
    uint8 public constant decimals = 18;

    uint256 private constant INITIAL_SUPPLY = 1_000_000_000 * (10**decimals);

    uint256 private constant maxFee = 10;

    uint256 private _totalSupply = INITIAL_SUPPLY;
    uint256 private FeeTotalCollected;
    uint256 private FeeTotalCollectedBurned;

    address private constant ZERO = address(0);
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => bool) public isFeeFreeSender;
    mapping(address => bool) public isFeeFreeRecipient;
    mapping(address => bool) public frozenAccount;

    uint256 public totalFee = 2; // Total procent fee deductet from transaction

    uint256 public burnFees = 40; // fee taken and burned
    uint256 public charityFees = 20; // fee taken and added to the charity
    address public charityaddress = 0x2e62DbBb6905807c9b0f8983D34Ec0aA4297111a;
    uint256 public rewardsFees = 20; // fee taken and added to rewards
    address public rewardsaddress = 0x2e62DbBb6905807c9b0f8983D34Ec0aA4297111a;
    uint256 public systemFees = 0; // fee taken and added to system
    address public systemaddress = 0x2e62DbBb6905807c9b0f8983D34Ec0aA4297111a;
    uint256 public stakingFees = 20; // fee taken and added to staking pool
    address public stakingaddress = 0x2e62DbBb6905807c9b0f8983D34Ec0aA4297111a;

    uint256 public minTotalSupply =0; // min amount of tokens total supply

    /**
    * @dev Update charity address
    * @param _charityaddress new charity address
    */
    function updateCharityAddress( address _charityaddress ) external onlyDAO {
        charityaddress = _charityaddress;
        emit updateedCharityAddress( charityaddress );
    }

    /**
    * @dev Update rewards address
    * @param _rewardsaddress new charity address
    */
    function updateRewardsAddress( address _rewardsaddress ) external onlyDAO {
        rewardsaddress = _rewardsaddress;
        emit updateedRewardsAddress( rewardsaddress );
    }

    /**
    * @dev Update rewards address
    * @param _systemaddress new charity address
    */
    function updateSystemAddress( address _systemaddress ) external onlyDAO {
        systemaddress = _systemaddress;
        emit updateedSystemAddress( systemaddress );
    }

    /**
    * @dev Update staking address
    * @param _stakingaddress new charity address
    */
    function updateStakingAddress( address _stakingaddress ) external onlyDAO {
        stakingaddress = _stakingaddress;
        emit updateedStakingAddress( stakingaddress );
    }

    /**
    * @dev Updates fees
    * @param _totalFee total taken fee
    * @param _burnFees burn fees
    * @param _charityFees liquidity pool fees
    * @param _rewardsFees rewards fees
    */
    function updateFees( uint256 _totalFee, uint256 _burnFees, uint256 _charityFees, uint256 _rewardsFees, uint256 _systemFees, uint256 _stakingFees ) external onlyDAO {
       require( _totalFee <= maxFee, "VERIFY FEE: TOO BIG FEE" );
       require(  _verifyFees(_burnFees, _charityFees, _rewardsFees, _systemFees, _stakingFees), "VERIFY FEE: SUM DO NOT MATCH");

        totalFee = _totalFee;
        burnFees = _burnFees;
        charityFees = _charityFees;
        rewardsFees = _rewardsFees;
        systemFees = _systemFees;
        stakingFees = _stakingFees;

        emit FeesUpdated( totalFee, burnFees, charityFees, rewardsFees, systemFees, stakingFees );
    }

    /**
    * @dev verify fees
    * @param _burnFees liquidity pool fees
    * @param _charityFees charity fees
    * @param _rewardsFees rewards fees
    * @param _systemFees system fees
    * @param _stakingFees staking fees
    */
    function _verifyFees( uint256 _burnFees, uint256 _charityFees, uint256 _rewardsFees, uint256 _systemFees, uint256 _stakingFees) private pure returns (bool){
        uint256 _totalFees = _burnFees + _charityFees + _rewardsFees + _systemFees + _stakingFees;
        if(_totalFees == 100){
            return true;
        } else {
            return false;
        }
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
        return FeeTotalCollected;
    }
    /// Total fees collected burned
    function FeesCollectedBurned() external view returns (uint256) {
        return FeeTotalCollectedBurned;
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

    function _calcTransferFees( uint256 amount ) private view returns ( uint256 _FeesToTake, uint256 _toburn, uint256 _tocharity, uint256 _toreward, uint256 _tosystem, uint256 _tostaking )
      {
        _FeesToTake = amount * totalFee / 100;
        if((_totalSupply  - balances[ZERO]) > minTotalSupply){
            _toburn = _FeesToTake * burnFees / 100;
        } else {
            _toburn = 0;
        }

        _tocharity = _FeesToTake * charityFees / 100;
        _toreward =  _FeesToTake * rewardsFees / 100;
        _tosystem =  _FeesToTake * systemFees / 100;
        _tostaking =  _FeesToTake * stakingFees / 100;
        _FeesToTake = _toburn + _tocharity + _toreward + _tosystem + _tostaking;
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

        if (Amount > 0) {
            if (isFeeFreeSender[sender]){
              _feeFreeTransfer(sender, recipient, Amount);
            } else if(isFeeFreeRecipient[recipient]){
              _feeFreeTransfer(sender, recipient, Amount);
            } else {
                ( uint256 _FeesToTake, uint256 _toburn, uint256 _tocharity, uint256 _toreward, uint256 _tosystem, uint256 _tostaking ) = _calcTransferFees( Amount );

                uint256 _totransfer = Amount - _FeesToTake;
                uint256 _takefromsender = Amount - _toburn;
                FeeTotalCollected += _FeesToTake;
                balances[sender] -= _takefromsender;
                balances[recipient] += _totransfer;
                if(_toburn>0){
                    _burn(sender, _toburn);
                    FeeTotalCollectedBurned += _toburn;
                    emit Transfer(sender, ZERO, _toburn);
                }
                if(_tocharity>0){
                    balances[charityaddress] += _tocharity;
                    emit Transfer(sender, charityaddress, _tocharity);
                }
                if(_toreward>0){
                    balances[rewardsaddress] += _toreward;
                    emit Transfer(sender, rewardsaddress, _toreward);
                }
                if(_tosystem>0){
                    balances[systemaddress] += _tosystem;
                    emit Transfer(sender, systemaddress, _tosystem);
                }
                if(_tostaking>0){
                    balances[stakingaddress] += _tostaking;
                    emit Transfer(sender, stakingaddress, _tostaking);
                }
                emit Transfer(sender, recipient, _totransfer);
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
        isFeeFreeSender[charityaddress] = true;
        isFeeFreeSender[rewardsaddress] = true;
        isFeeFreeSender[systemaddress] = true;
        isFeeFreeSender[stakingaddress] = true;
        isFeeFreeRecipient[charityaddress] = true;
    }

    /**
    * @dev Emitted when fees are updated
    * @param totalFee burn fees
    * @param burnFees liquidity pool fees
    * @param charityFees charity fees
    * @param rewardsFees rewards fees
    * @param systemFees system fees
    * @param stakingFees staking fees
    */
    event FeesUpdated( uint256 totalFee, uint256 burnFees, uint256 charityFees, uint256 rewardsFees, uint256 systemFees, uint256 stakingFees );

    /**
    * @dev Emitted when staking is updated
    * @param stakingaddress burn fees
    */
    event updateedStakingAddress( address stakingaddress );

    /**
    * @dev Emitted when system is updated
    * @param systemaddress burn fees
    */
    event updateedSystemAddress( address systemaddress );

    /**
    * @dev Emitted when rewards is updated
    * @param rewardsaddress burn fees
    */
    event updateedRewardsAddress( address rewardsaddress );

    /**
    * @dev Emitted when charity is updated
    * @param charityaddress burn fees
    */
    event updateedCharityAddress( address charityaddress );

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