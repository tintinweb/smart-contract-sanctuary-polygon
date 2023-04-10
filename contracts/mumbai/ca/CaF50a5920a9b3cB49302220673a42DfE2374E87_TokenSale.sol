/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;


interface IERC20 {
    // //
    //  * @dev Emitted when `value` tokens are moved from one account (`from`) to
    //  * another (`to`).
    //  *
    //  * Note that `value` may be zero.
    //  *//
    event Transfer(address indexed from, address indexed to, uint256 value);

    // /
    //  * @dev Emitted when the allowance of a spender for an owner is set by
    //  * a call to {approve}. value is the new allowance.
    //  */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // /
    //  * @dev Returns the amount of tokens in existence.
    //  */
    function totalSupply() external view returns (uint256);

    // /
    //  * @dev Returns the amount of tokens owned by account.
    //  */
    function balanceOf(address account) external view returns (uint256);

    // /
    //  * @dev Moves `amount` tokens from the caller's account to `to`.
    //  *
    //  * Returns a boolean value indicating whether the operation succeeded.
    //  *
    //  * Emits a {Transfer} event.
    //  */
    function transfer(address to, uint256 amount) external returns (bool);

    // /
    //  * @dev Returns the remaining number of tokens that spender will be
    //  * allowed to spend on behalf of owner through {transferFrom}. This is
    //  * zero by default.
    //  *
    //  * This value changes when {approve} or {transferFrom} are called.
    //  */
    function allowance(address owner, address spender) external view returns (uint256);

    // /
    //  * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    //  *
    //  * Returns a boolean value indicating whether the operation succeeded.
    //  *
    //  * IMPORTANT: Beware that changing an allowance with this method brings the risk
    //  * that someone may use both the old and the new allowance by unfortunate
    //  * transaction ordering. One possible solution to mitigate this race
    //  * condition is to first reduce the spender's allowance to 0 and set the
    //  * desired value afterwards:
    //  * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    //  *
    //  * Emits an {Approval} event.
    //  */
    function approve(address spender, uint256 amount) external returns (bool);

    // /
    //  * @dev Moves amount tokens from from to to using the
    //  * allowance mechanism. amount is then deducted from the caller's
    //  * allowance.
    //  *
    //  * Returns a boolean value indicating whether the operation succeeded.
    //  *
    //  * Emits a {Transfer} event.
    //  */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}




contract TokenSale {
    
    struct User {
        uint256 levelIncome;
        uint256 referralIncome;
        address referrer;
        bool tokensReceived;
        uint256 nextWithdrawnTime;
        uint256[10] levelCount;
    }

   uint256[] usdDistribution =[5 ether,2 ether,2 ether,0.5 ether,0.5 ether];
   uint256[] levelIncome = [500 ether,300 ether,300 ether,300 ether,200 ether,200 ether,200 ether,100 ether,100 ether,100 ether];

    uint256 private levelsIncome = 500 ether;
    bool public isWithdrawEnabled = false;
    address public owner;

    mapping(address => User) public users;
    IERC20 public token;

    uint256 public price = 20 ether;
    uint256 tokenToBeSent = 10000 ether;
    uint256 withdrawTime = 30 days;
    IERC20 public  paymentToken;

    constructor(
        uint256 _price,
       
        IERC20 _token,
        IERC20 _paymentToken
    ) {
        price = _price;
        
        token = _token;
        owner = msg.sender;
        paymentToken=_paymentToken;
        users[msg.sender].referrer = address(0);
    }

    function setToken(IERC20 newToken) external {
        require(msg.sender == owner, "You are not an owner");
        token = newToken;
    }

    function setPrice(uint256 newPrice) external {
        require(msg.sender == owner, "You are not an owner");
        price = newPrice;
    }

    function enableWithdraw() external {
        require(msg.sender == owner, "You are not an owner");
        isWithdrawEnabled = true;
    }

    function buyToken(address _referrer) external  {
        require(msg.sender != _referrer, "caller cannot be referrer");
        require(_referrer != address(0), "referrer cannot be zero address");
        require(users[_referrer].tokensReceived==true || _referrer==owner, "Referrer should buy tokens first");
       

        require(paymentToken.transferFrom(msg.sender, address(this), price),"Error while Buying");       

        token.transfer(_referrer, levelsIncome);
        users[_referrer].referralIncome =users[_referrer].referralIncome+usdDistribution[0];
           
        require(paymentToken.transfer(_referrer,usdDistribution[0]),"Error while Buying");
        address ref = _referrer;
        for (uint256 i = 0; i < 10; i++) {

            if (ref == address(0)) break;
           
            users[ref].levelIncome = users[ref].levelIncome + levelIncome[i];
            users[msg.sender].levelCount[i]++;
            if(i<4){
                paymentToken.transfer(ref,usdDistribution[i+1]);
            }
            ref = users[ref].referrer;
             
        }
        token.transfer(msg.sender, tokenToBeSent);
        users[msg.sender].tokensReceived=true;
        // if (msg.value > getAmountToBePaid()) {
        //     payable(msg.sender).transfer(msg.value - getAmountToBePaid());
        // }
    }

    

    function withdrawLevelIncome() external {
        require(
            token.balanceOf(address(this)) >= users[msg.sender].levelIncome,
            "Contract don't have sufficient tokens"
        );
        require(
            block.timestamp >= users[msg.sender].nextWithdrawnTime,
            "Withraw can be done after 30 days"
        );
        require(isWithdrawEnabled, "Withdrawing token is not allowed by owner");
        if (users[msg.sender].levelIncome > 0) {
            token.transfer(msg.sender, users[msg.sender].levelIncome / 10);
            users[msg.sender].levelIncome =
                users[msg.sender].levelIncome -
                users[msg.sender].levelIncome /
                10;
            users[msg.sender].nextWithdrawnTime =
                block.timestamp +
                withdrawTime;
        }
    }

    function withdrawDumpedtokens(IERC20 _token) external {
        require(msg.sender == owner, "You are not an owner");
        require(
            _token.balanceOf(address(this)) > 0,
            "No token balance available"
        );
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

  function WithdrawBNB(address receiver) external  {
      require(msg.sender == owner, "You are not an owner");
    payable(receiver).transfer(address(this).balance);
  }

    function setWithdrawTime(uint256 newTime) external payable {
        require(msg.sender == owner, "You are not an owner");
        withdrawTime = newTime;
    }

    function setPaymentToken(IERC20 _paymentToken)external {
        require(msg.sender == owner, "You are not an owner");
        paymentToken=_paymentToken;
    }

}