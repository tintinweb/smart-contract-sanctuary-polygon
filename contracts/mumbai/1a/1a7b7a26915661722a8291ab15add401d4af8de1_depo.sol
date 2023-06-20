/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

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


pragma solidity ^0.8.6;


contract depo{
mapping(address=>uint) public depositAmount;

mapping(address=>uint)public _balances;

mapping(address=>uint)public withdrawAmount;
mapping(address=>bool)public toblock;
mapping(address=>uint) public istimestamp;

       
address public owner;
    constructor(address _token){
        owner=msg.sender;
token=IERC20(_token);
//  notax[] = true;
       
    }
    address public newOwner;
    IERC20 public token;
    uint lockedUntil=1 minutes;
    // address public newToken;
    // uint public balance;

    // constructor(address _token){
    //     token=ERC20Token(_token);
    // }


    //set token address only by the owner
    // function changeTokenAddress(address _addr)public{
    //     require(msg.sender==owner,"!owner");
    //     newToken=_addr;
    // }
    modifier onlyowner{
        require(msg.sender==owner,"!owner");
        _;

    }
   function transferOwnership(address _to) public onlyowner {
        require(msg.sender == owner);
        newOwner = _to;
        owner=newOwner;
    }



    function blockTheAddress(address _addr)public onlyowner{
        toblock[_addr]=true;
    }

    function ublockTheaddress(address _addr)public onlyowner{
        toblock[_addr]=false;
    }

   function ChangeTokenAddress(address _addr) public onlyowner  {
        token = IERC20(_addr);
    }
     function balanceOf(address account) private view  returns (uint) {
        return _balances[account];
    }

    function stake(uint _amount)external{
        require(msg.sender != owner);
         require(_amount>0,"Amount should be greater than 0 ");
         token.transferFrom( msg.sender, address(this), _amount);
      depositAmount[msg.sender]=_amount;

       
        // require(lockedUntil<=block.timestamp,"wait for the time");
    }

    function depositTokens(uint256 _amount) external {

        require(_amount>0,"Amount should be greater than 0 ");

        istimestamp[msg.sender]=block.timestamp;
       

      token.transferFrom( msg.sender, address(this), _amount);

      depositAmount[msg.sender]=_amount;

    //   _balances[address(this)]=_amount;
    //   transferFrom(address(this),_amount);
      

    }


    function getTokenBalance() public view returns(uint)
    {
     return token.balanceOf(address(this)) ; 
    }
// function norewardwithdraw(address _addr){
//     if()

// }

    function withdraw(address _addr,uint _amount)public{
        require(!toblock[msg.sender],"blocked");
       require(msg.sender !=owner,"only user");
       
  require(istimestamp[msg.sender] + 2 minutes <block.timestamp,"wait for time ");

    
        
// require(istimestamp[_addr]<=block.timestamp,"time limit error");
//          istimestamp[_addr]=block.timestamp+(lockedUntil*1);
          

         uint reward=50;
         uint given=_amount+reward;

         _balances[msg.sender]+=given;

        token.transfer(_addr,given);
    }
    function _stakewithdraw(address _addr,uint _amount)public{
        token.transfer(_addr,_amount);
    }
     function withdrawAll(address receiver) public onlyowner {
        //  uint tokens=getTokenBalance();
    //    require(owner==msg.sender, "you cant withdraw");

    // _balances[msg.sender]+=tokens;

    // _balances[address(this)]-=tokens;
//    uint local= getTokenBalance();

    token.transfer(receiver,getTokenBalance());
 }

}