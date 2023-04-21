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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract vestingContract{

    struct beneficiaryData{
        mapping (uint => uint256) amountWithdrawnTillNow;
        mapping (uint => bool) allowedToVest;
    }

    struct vestingData{
        address provider;
        address tokenAddress;
        uint256 startDate;
        uint256 tokenPerSlicePeriod;
        uint slicePeriod;
        uint releasedToken;
        uint256 expiryDate;
    }

    mapping(address => beneficiaryData) private beneficiaries;
    vestingData[] public vestingSchedule;
    uint public vestingCurrentId;

    event withdrawn(address indexed _receiver, uint indexed _amount, string indexed _statement);
    event lockedVesting(address indexed _provider, uint indexed _slicePeriod ,uint indexed _expiryOfVesting);
    event lockedTokenAmount(address _tokenAddress, uint indexed _amountPerSlicePeriod, uint indexed _totalAmountVested);

    constructor(){
        vestingCurrentId = 0;
    }

    modifier checkAccesibility(uint _vestingId){
        require(_vestingId < vestingCurrentId, "Please enter valid vestingId");
        require( block.timestamp >= vestingSchedule[_vestingId].startDate , "vesting not even started yet");
        _;
    }

    function lockVestingTokens(address _tokenAddress, address _provider, address[] memory _receivers, uint _cliff, uint _amountOfTokenPerSlicePeriod, uint _slicePeriodOfVesting ,uint _expiryOfVesting) public returns(bool success){
        
        uint _vestingId = vestingCurrentId;
        vestingCurrentId++;
        
        uint totalAmountOfToken = _amountOfTokenPerSlicePeriod * (_expiryOfVesting/_slicePeriodOfVesting) * (_receivers.length);
        IERC20(_tokenAddress).transferFrom(_provider, address(this), totalAmountOfToken);
        
        for(uint i=0; i<_receivers.length; i++){
            beneficiaries[_receivers[i]].allowedToVest[_vestingId] = true;
        }

        vestingData memory tempVestingSchedule = vestingData(_provider, _tokenAddress, block.timestamp + _cliff, _amountOfTokenPerSlicePeriod, _slicePeriodOfVesting, 0, block.timestamp + _cliff +_expiryOfVesting);
        vestingSchedule.push(tempVestingSchedule);
        
        emit lockedVesting(_provider, _slicePeriodOfVesting ,_expiryOfVesting);
        emit lockedTokenAmount(_tokenAddress, _amountOfTokenPerSlicePeriod, totalAmountOfToken);
        return true;
    }

    function amountWithdrawnTillNow(uint _vestingId) public view checkAccesibility(_vestingId) returns(uint){
        require( beneficiaries[msg.sender].allowedToVest[_vestingId] , "Only beneficiary is allowed");
        return beneficiaries[msg.sender].amountWithdrawnTillNow[_vestingId];
    }

    function numberOfSlicePeriodTillNow(uint _vestingId) private view returns(uint){
        uint currentTime;
        (block.timestamp <= vestingSchedule[_vestingId].expiryDate) ? currentTime = block.timestamp : currentTime = vestingSchedule[_vestingId].expiryDate;
        uint SlicePeriods = (currentTime - vestingSchedule[_vestingId].startDate) / vestingSchedule[_vestingId].slicePeriod;
        return SlicePeriods;
    }

    function releaseToken(uint _vestingId) public  checkAccesibility(_vestingId) returns(vestingData memory){
        require( beneficiaries[msg.sender].allowedToVest[_vestingId] , "Only beneficiary is allowed to release tokens");
        vestingSchedule[_vestingId].releasedToken = numberOfSlicePeriodTillNow(_vestingId) * vestingSchedule[_vestingId].tokenPerSlicePeriod;
        return (vestingSchedule[_vestingId]);
    }

    function viewVestingSchedule(uint _vestingId) public view returns(vestingData memory){
        return vestingSchedule[_vestingId];
    }

    function checkWithdrawableAmount(uint256 _vestingId) external view checkAccesibility(_vestingId) returns(uint){
        require( beneficiaries[msg.sender].allowedToVest[_vestingId] , "Only beneficiary is allowed");
        uint realeasedToken = numberOfSlicePeriodTillNow(_vestingId) * vestingSchedule[_vestingId].tokenPerSlicePeriod;
        uint withdrawableAmount =  realeasedToken - beneficiaries[msg.sender].amountWithdrawnTillNow[_vestingId];
        return withdrawableAmount;
    }

    function withdraw(uint _withdrawalAmount, uint256 _vestingId) external checkAccesibility(_vestingId) returns(bool success){
        require( beneficiaries[msg.sender].allowedToVest[_vestingId] , "Only beneficiary is allowed");
        vestingSchedule[_vestingId].releasedToken = numberOfSlicePeriodTillNow(_vestingId) * vestingSchedule[_vestingId].tokenPerSlicePeriod;
        
        uint amountRemainToWithdraw = vestingSchedule[_vestingId].releasedToken - beneficiaries[msg.sender].amountWithdrawnTillNow[_vestingId];
        require( block.timestamp < vestingSchedule[_vestingId].expiryDate || amountRemainToWithdraw > 0, "your vesting conrtact is over");
        require( !(block.timestamp < vestingSchedule[_vestingId].expiryDate && amountRemainToWithdraw == 0), "vesting tokens are not yet realeased");
        
        uint withdrawableAmount = vestingSchedule[_vestingId].releasedToken - beneficiaries[msg.sender].amountWithdrawnTillNow[_vestingId];
        require(withdrawableAmount >= _withdrawalAmount, "you don't have access to withdraw this much amount!, you can check withdrawable amount");

        beneficiaries[msg.sender].amountWithdrawnTillNow[_vestingId] += _withdrawalAmount;
        IERC20(vestingSchedule[_vestingId].tokenAddress).transfer(msg.sender, _withdrawalAmount);
        emit withdrawn(msg.sender, _withdrawalAmount, "withdrawn");
        return true;
    }
}