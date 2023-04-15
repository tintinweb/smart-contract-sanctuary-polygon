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

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract vesting{

    IERC20 public token;
    struct beneficiarydata{
        address addressOfToken;
        uint noOfTokens;
        uint cliff;
        uint startTime;
        uint duration;
        uint slicePeriod;
        bool locked;
    }

    mapping (address => beneficiarydata[]) public beneficiaryDetails;
    mapping (address => mapping(uint => uint)) public releasedTokens;//keeps track of amount of tokens by beneficiary at particular period
    mapping (address => mapping(address => bool)) public whitelist;

    event tokensLocked(address beneficiary,address Tokenaddress,uint tokens);
    event tokensWithdrawn(address beneficiary,address Tokenaddress,uint tokens);


    function whitelistTokens(address _tokenaddress) external {
        whitelist[msg.sender][_tokenaddress] = true;
    }

    function checkBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }

    function lockTokens(address _tokenaddress,uint _noOfTokens,uint _cliff,uint _duration,uint _sliceperiod) external{
        require(whitelist[msg.sender][_tokenaddress],"Token not allowed");
        require(_noOfTokens>0,"Invalid amount of tokens");
        require(_cliff<_duration,"Cliff cannot be above Duration");
        token = IERC20(_tokenaddress);

        beneficiarydata memory person = beneficiarydata({
            addressOfToken:_tokenaddress,
            noOfTokens:_noOfTokens,
            cliff:_cliff,
            startTime: block.timestamp + _cliff,
            duration:_duration,
            slicePeriod:_sliceperiod,
            locked:true
        });

        beneficiaryDetails[msg.sender].push(person);
        token.transferFrom(msg.sender,address(this),_noOfTokens);
        emit tokensLocked(msg.sender,_tokenaddress,_noOfTokens);
    }
   
    function withdrawTokens(uint8 index) external {
        require(block.timestamp>beneficiaryDetails[msg.sender][index].startTime,"No tokens unlocked");
        require(releasedTokens[msg.sender][index]<beneficiaryDetails[msg.sender][index].noOfTokens,"Tokens already withdrawn");
        token = IERC20(beneficiaryDetails[msg.sender][index].addressOfToken);
        uint tokensLeft=unlockTokens(index);
        require(tokensLeft!=0);
        releasedTokens[msg.sender][index]+=tokensLeft;
        token.transfer(msg.sender,tokensLeft);
        address Tokenaddress = beneficiaryDetails[msg.sender][index].addressOfToken;
        emit tokensWithdrawn(msg.sender,Tokenaddress,releasedTokens[msg.sender][index]);
    }
    
    function unlockTokens(uint8 ind) public view returns(uint) {

        uint totalNoOfPeriods = beneficiaryDetails[msg.sender][ind].duration/beneficiaryDetails[msg.sender][ind].slicePeriod;
        uint tokensPerPeriod = (beneficiaryDetails[msg.sender][ind].noOfTokens)/(totalNoOfPeriods);
        uint timePeriodSinceStart = block.timestamp - beneficiaryDetails[msg.sender][ind].startTime;
        uint noOfPeriodsTillNow = timePeriodSinceStart/(beneficiaryDetails[msg.sender][ind].slicePeriod);
        uint noOfTokensTillNow = (noOfPeriodsTillNow * tokensPerPeriod) - releasedTokens[msg.sender][ind] ;

        if(noOfPeriodsTillNow >= totalNoOfPeriods){ //Exceeded the duration
            return (beneficiaryDetails[msg.sender][ind].noOfTokens) - releasedTokens[msg.sender][ind];
        }

        return noOfTokensTillNow ;
    }
    function getTime() public view returns(uint){
        return block.timestamp;
    }
    

 }