/**
 *Submitted for verification at polygonscan.com on 2022-09-11
*/

// SPDX-License-Identifier: MIT
// pragma solidity >=0.4.21 <8.10.0; 
// Win 50 for 1 Matic Or Earn upto 70%

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/Win50Matic.sol


// pragma solidity >=0.4.21 <8.10.0; 
// Win 50 for 1 Matic Or Earn upto 70%
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;



contract Win50Matic  is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint;
    uint private ctFeediv;
    uint private ctFeemul;
    uint256 private minSpinAmount =  1000000000000000000;  
    uint256 private maxSpinAmount =  4000000000000000000;
    uint private numFunders; 
    uint private numBoo; 
    mapping (uint => address) private funders;
    mapping (address => uint256) private fundersbal;
    Jellyy private jellyy;
    address private jadd;
    uint private slotnumber = 1;
    uint256 private totalwithdraws;
    uint private totalbuyer=0;
    uint256 private totalplayvalue=0;

    constructor(address _jellyy,uint _boo,uint _fun,uint _ctFeediv,uint _ctFeemul) {
        funders[1] = msg.sender;
        funders[2] = _jellyy;
        funders[3] = _jellyy;
        jadd = _jellyy;
        numBoo = _boo; 
        numFunders = _fun; 
        ctFeediv = _ctFeediv; 
        ctFeemul = _ctFeemul; 
        jellyy = Jellyy(_jellyy); 
    }

    modifier nonContract() {
        require(tx.origin == msg.sender, "Contract not allowed");
        _;
    }

    event withdrawEvent(address _to,uint256 toPay);

      function SetContractF(uint _ctFeediv,uint _ctFeemul) external onlyOwner nonContract {
        ctFeediv = _ctFeediv;
        ctFeemul = _ctFeemul;
    }

      function SetMinSpinAmount(uint256 _minSpinAmount,uint256 _maxSpinAmount) external onlyOwner nonContract {
        minSpinAmount = _minSpinAmount;
        maxSpinAmount = _maxSpinAmount;
    }

    
    function SetF(uint256 _n,uint256 _m,uint256 _k) external onlyOwner nonContract {
        fundersbal[funders[1]] = _n;
        fundersbal[funders[2]] = _m;
        fundersbal[funders[3]] = _k;
    }

    function SetNB(uint _numBoo) external onlyOwner nonContract {
            numBoo = _numBoo;
    }


     function getUpperDeck() external view nonContract  returns (uint,uint256,uint256,uint){
            return (totalbuyer,
                    totalwithdraws,
                    totalplayvalue,                    
                    slotnumber);
    }

     function getSlot() external view nonContract returns (uint){
            return slotnumber;
    }

     function getCTBal() external view nonContract returns (uint256){
            return address(this).balance;
    }

     function getMinSpinAmount() external view nonContract returns (uint256){
            return minSpinAmount;
    }

   function getBal(address _usrAddress) external view returns (uint256){
            return fundersbal[_usrAddress];
    }

    function getUserBlock() external view nonContract returns (uint){
            return block.number;
    }

     function getBou() external view nonContract returns (uint){
            return numFunders;
    }

     function Bet() external payable nonContract nonReentrant {
        require(msg.sender != address(0), "msg sender is the zero address");
        require(msg.value >= minSpinAmount && msg.value <= maxSpinAmount, "amount must be with limit");
        
        uint qty = msg.value.div(minSpinAmount);
        totalplayvalue = totalplayvalue.add(msg.value);

        uint i=0;
        for(; i < qty;i++) {
            totalbuyer++;
            funders[++numFunders] = msg.sender;
        }
        

        while (numBoo <= numFunders) {
        
         (uint[] memory t,uint256 bus )=  jellyy.callbot(numBoo,minSpinAmount);
            
            for (i = 0; i < t.length; i++) {
                
                if (t[i] != 0 && funders[t[i]] != address(0)) {

                    fundersbal[funders[t[i]]] = fundersbal[funders[t[i]]].add(bus);
                }
            }
            
             if (numBoo >= ctFeemul) {

                uint256 mini27 = 320000000000000000; 
                uint256 mini47 = 520000000000000000;
                uint256 mini92 = 920000000000000000;
                for (i = ctFeediv; i <= ctFeemul; i++) {

                 if(i % 2 != 0) { fundersbal[funders[i]] = fundersbal[funders[i]].add(mini47); } 
                 else { fundersbal[funders[i]] = fundersbal[funders[i]].add(mini27); }

                }

                fundersbal[funders[1]] = fundersbal[funders[1]].sub(mini92);


                qty = numFunders - numBoo; numBoo = 3; numFunders = 3;
                slotnumber++;
                 uint j=0;
                for(; j < qty;j++) {
                    funders[++numFunders] = msg.sender;
                  }

             }

            numBoo++;
        }
       


    }


     function BetAgain(uint256 _reqamt) external payable nonContract nonReentrant {
        require(msg.sender != address(0), "msg sender is the zero address");
        require(_reqamt > 0 , "req amt is zero");
        require(_reqamt >= minSpinAmount && _reqamt <= maxSpinAmount, "Min 1 Max 4 Matic");
        
        uint256 _amount = fundersbal[msg.sender];
        require(_amount > 0, "insufficient user balance");
        require(_reqamt <= _amount, "user balance low");
        fundersbal[msg.sender] = fundersbal[msg.sender].sub(_reqamt);

        uint qty = _reqamt.div(minSpinAmount);
        totalplayvalue = totalplayvalue.add(_reqamt);

        uint i=0;
        for(; i < qty;i++) {
            totalbuyer++;
            funders[++numFunders] = msg.sender;
        }
        

        while (numBoo <= numFunders) {
        
         (uint[] memory t,uint256 bus )=  jellyy.callbot(numBoo,minSpinAmount);
            
            for (i = 0; i < t.length; i++) {
                
                if (t[i] != 0 && funders[t[i]] != address(0)) {

                    fundersbal[funders[t[i]]] = fundersbal[funders[t[i]]].add(bus);
                }
            }
            
             if (numBoo >= ctFeemul) {

                uint256 mini27 = 320000000000000000; 
                uint256 mini47 = 520000000000000000;
                uint256 mini92 = 920000000000000000;
                for (i = ctFeediv; i <= ctFeemul; i++) {

                 if(i % 2 != 0) { fundersbal[funders[i]] = fundersbal[funders[i]].add(mini47); } 
                 else { fundersbal[funders[i]] = fundersbal[funders[i]].add(mini27); }

                }

                fundersbal[funders[1]] = fundersbal[funders[1]].sub(mini92);


                qty = numFunders - numBoo; numBoo = 3; numFunders = 3;
                slotnumber++;
                 uint j=0;
                for(; j < qty;j++) {
                    funders[++numFunders] = msg.sender;
                  }

             }

            numBoo++;
        }
    }

      function Withdraw(uint256 _reqamt) external payable nonContract nonReentrant {
        require(msg.sender != address(0), "msg sender is the zero address");
        require(_reqamt > 0 , "req amt is zero");
        uint256 _amount = fundersbal[msg.sender];
        require(_amount > 0, "insufficient user balance");
        require(_reqamt <= _amount, "user balance low");
        fundersbal[msg.sender] = fundersbal[msg.sender].sub(_reqamt);
        uint256 currentBalance = address(this).balance;
        require(currentBalance >= _reqamt, "insufficient contract balance");

        totalwithdraws = totalwithdraws.add(_reqamt);
        (bool success, ) = payable(msg.sender).call{value: _reqamt}("");
        require(success);

        emit withdrawEvent(msg.sender,_reqamt);
    }


}

contract Jellyy {

    function callbot(uint booked,uint256 mini) public pure returns (uint[] memory,uint256) {

      uint[] memory cars ;
        if (booked >= 0) {}
      return (cars,mini);
   }  

}