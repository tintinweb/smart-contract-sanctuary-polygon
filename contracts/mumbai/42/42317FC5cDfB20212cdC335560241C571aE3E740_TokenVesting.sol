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
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting{
 
    struct BeneficiaryInfo{
        uint vestingId;
        uint duration;
        uint cliff;
        uint slicePeriod;
        uint startTime;
        mapping(uint=>mapping(IERC20=>uint)) particularTokenAmount;
        mapping(uint=>mapping(IERC20=>uint)) releasedTokenAmount;
    }
    
    mapping (address=>BeneficiaryInfo)public beneficiaries;

// Events
    event LockTokensEvent(address beneficiary, string  message);
    event ReleaseTokensEvent(address beneficiary, string message);

// Modifiers
    modifier cliffPeriodOver(address _beneficiary){
        _;
        require(block.timestamp>=beneficiaries[_beneficiary].cliff,"Wait Till Cliff period");
    }
    modifier isBeneficiary(address _beneficiary){
        _;
        require( msg.sender==_beneficiary,"Only Beneficiary can Lock and Release Tokens");
    }
  
// Locking Tokens
    function lockTokens(address _beneficiaryAddress,uint _tokensAmount,uint _cliff,uint _duration,uint _slicePeriod,IERC20 _token) isBeneficiary(_beneficiaryAddress) public {

        BeneficiaryInfo storage beneficiary=beneficiaries[_beneficiaryAddress];
        beneficiary.duration=_duration;
        beneficiary.cliff=_cliff;
        beneficiary.slicePeriod=_slicePeriod;
        beneficiary.startTime=block.timestamp;
        beneficiary.particularTokenAmount[beneficiary.vestingId][_token]=_tokensAmount;
        beneficiary.vestingId+=1;
        _token.transferFrom(msg.sender,address(this),_tokensAmount);
        emit LockTokensEvent(_beneficiaryAddress, "Tokens are Locked in smart contract ");     
}

// check tokens balance
    function checkReleasedTokens(IERC20 _token, uint _id)public view returns (uint){
        uint releasedTokens= beneficiaries[msg.sender].releasedTokenAmount[_id][_token];
        return releasedTokens;

}

// Calculate no. of eligible tokens to release
    function releasableTokens(address _beneficiary,IERC20 _token, uint _id) internal cliffPeriodOver(_beneficiary) view returns(uint) {
        uint timeSinceStart = block.timestamp - beneficiaries[_beneficiary].startTime;
        uint noOfPeriodsSinceStart = timeSinceStart/ beneficiaries[_beneficiary].slicePeriod;
        uint durationTime=beneficiaries[_beneficiary].duration;
        uint totalPeriods =durationTime / beneficiaries[_beneficiary].slicePeriod;
        uint releasedTokens=beneficiaries[_beneficiary].releasedTokenAmount[_id][_token];
        uint totalTokenAmount=beneficiaries[_beneficiary].particularTokenAmount[_id][_token];
        if (noOfPeriodsSinceStart >= totalPeriods ) {
            return totalTokenAmount-releasedTokens;
        } 
        else {
            uint tokensVestedInOnePeriod =totalTokenAmount/ totalPeriods;
            uint tokensToBeVested = tokensVestedInOnePeriod * noOfPeriodsSinceStart;
            tokensToBeVested=tokensToBeVested-releasedTokens;
            return tokensToBeVested;
        }
    }

// Release Tokens to beneficiary
    function releaseTokens(address _beneficiary,IERC20 _token, uint _id) isBeneficiary(_beneficiary) cliffPeriodOver(_beneficiary)public { 
       uint tokensClaimed=releasableTokens(_beneficiary, _token,_id);
       require(tokensClaimed<=beneficiaries[_beneficiary].particularTokenAmount[_id][_token],"Tokens Claiming are greater than tokens locked");
       require(tokensClaimed>0,"Cannot Claim Now");
        beneficiaries[_beneficiary].releasedTokenAmount[_id][_token]+=tokensClaimed;
       _token.transfer(_beneficiary,tokensClaimed);
       emit ReleaseTokensEvent(_beneficiary, "Tokens are Released in account of beneficiary ");
    }
}