/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBEP20 {
   
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

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
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);


    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);


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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }


    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IRouter {
    function getPrice(address token) external view returns (uint256);
}



interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract MisrtyBox is  Context {
    using SafeMath for uint256;


    event TransferAnyBSC20Token(
        address indexed sender,
        address indexed recipient,
        uint256 tokens
    );
     event WithdrawAmount(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );
    event UpdateMysteryBoxDetails(
        uint boxType,
        uint256 price
    );
    event PurchaseMysteryBoxByToken(
       address indexed buyer,
        address indexed tokenAddress,
         uint boxType,
        uint qty,
        uint256 amount
        );
        

    IRouter _router = IRouter(0xa75f75b0e85eb307DE30259D71D989C92c77061A);
    mapping(uint256 => uint256) public MysteryBoxDetails;
    
    address public MNT = 0x50F6cef584f651f4629581e8F49b6f3295e22C95; // Payment token address
    address public USDT = 0x9c9dA7F0Ff9d8A3Df4b2485891F0bB0d3BD6A818; // Payment token address
    address public BUSD = 0x7565c3873d27779FA9065Cc1D146B199aA509293; // Payment token address
    uint public discountOnMnt = 5; // 5% discount with MNT purchase
    
    // AggregatorV3Interface bnbToUsdPrice = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // mainnet
    AggregatorV3Interface bnbToUsdPrice = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // testnet

    //multi-signature-wallet
    address public multiSigWallet;
    modifier onlyMultiSigWallet() {
        require(msg.sender == multiSigWallet, "Unauthorized Access");
        _;
    }
    address minter;
    modifier OnlyMinter() {
        require(msg.sender == minter, "Minter : Only minter can call this");
        _;
    }

    constructor(address _multisigWallet) {
          //assign multi sig wallet
        multiSigWallet = _multisigWallet;
        minter = msg.sender;
        MysteryBoxDetails[1] = 0.01 ether;   //amount in USDT
        MysteryBoxDetails[2] = 0.02 ether;   //amount in USDT
        MysteryBoxDetails[3] = 0.04 ether;   //amount in USDT
        MysteryBoxDetails[4] = 0.05 ether;   //amount in USDT

  
    }

    function getBNBprice() view public returns(uint256){
        (, int256 answer,,,) = bnbToUsdPrice.latestRoundData();
        return uint256(answer);
    }


    function getPriceInUSD(address token) public view returns(uint256 price) {
        if(MNT == token){
            price = IRouter(_router).getPrice(token); // MNT in USD
        }else if(USDT == token || BUSD == token){
            price = 1 ether;
        }else if(token == address(0)){
            (, int256 answer,,,) = bnbToUsdPrice.latestRoundData();
            price = uint256(answer);
        }
        
    }

    function PaymentToken(address _tokenAddress) internal returns(bool){
        return (_tokenAddress == MNT || _tokenAddress == USDT || _tokenAddress == BUSD);
    }

    function purchaseMysteryBoxByToken(
        uint boxType,
        uint qty,
        address tokenAddress
    ) external {

    require(boxType > 0 && boxType < 5, "Invalid boxType");
    require(qty > 0,"Invalid qty");
   require(PaymentToken(tokenAddress), "Invalid PaymentToken");

    uint256 price = getPriceInUSD(tokenAddress);
     
    uint256 amount = MysteryBoxDetails[boxType] / price * qty;
    if(tokenAddress == MNT && discountOnMnt > 0){
        amount -= (amount * discountOnMnt) / 100; // Discount with MNT
    }
 amount = amount * 10 ** 18;
    require(IBEP20(tokenAddress).balanceOf(msg.sender) >= amount,"Insufficient balance");
    require(IBEP20(tokenAddress).allowance(msg.sender,address(this)) >= amount,"Insufficient allowance");
    IBEP20(tokenAddress).transferFrom(msg.sender, address(this), amount);
  emit PurchaseMysteryBoxByToken(msg.sender, tokenAddress, boxType, qty, amount);

}


function purchaseMysteryBoxByNativeToken(
    uint boxType,
    uint qty    
    ) external payable {
    require(boxType > 0 && boxType < 5,"Invalid boxType");
    require(qty > 0,"Invalid qty");
//    uint256 price = getPriceInUSD(address(0));
    uint256 price = 27795425246;//getPriceInUSD(address(0));

    uint256 amount = MysteryBoxDetails[boxType] / price * qty;
     amount = amount * 10**6;
    require(msg.value >= amount,"Insufficient amount to purchase");
    emit PurchaseMysteryBoxByToken(msg.sender, address(0), boxType, qty, amount);
}

function getpurchaseMysteryBoxByNativeToken(
    uint boxType,
    uint qty    
    ) public view returns (uint256,uint256) {
    require(boxType > 0 && boxType < 5,"Invalid boxType");
    require(qty > 0,"Invalid qty");
//    uint256 price = getPriceInUSD(address(0));
    uint256 price = 27795425246;//getPriceInUSD(address(0));

    uint256 amount = MysteryBoxDetails[boxType] / price * qty;
      amount = amount * 10**6;

     return (amount,MysteryBoxDetails[boxType]);
     }

function setDiscountOnMnt(uint256 _percent) onlyMultiSigWallet public {
    discountOnMnt = _percent;
}

function updateMysteryBoxDetails(
    uint boxType,
    uint256 price // price in USDT 
    ) external onlyMultiSigWallet {
        require(boxType > 0 && boxType < 5,"Invalid boxType");
        require(price > 0,"Invalid Price");
        MysteryBoxDetails[boxType] = price; 
  emit  UpdateMysteryBoxDetails(boxType, price);
}



/*
     @dev function to withdraw BNB
     @param recipient address
     @param amount uint256
    */
    function withdraw(
        address recipient,
        uint256 amount
    ) external onlyMultiSigWallet {
        sendValue(recipient, amount);
        emit WithdrawAmount(address(this), recipient, amount);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }


    /* 
     @dev function to transfer any BEP20 token
     @param tokenAddress token contract address
     @param tokens amount of tokens
     @return success boolean status
    */
    function transferAnyBSC20Token(
        address tokenAddress,
        address wallet,
        uint256 tokens
    ) public onlyMultiSigWallet returns (bool success) {
        success = IBEP20(tokenAddress).transfer(wallet, tokens);
        require(success, "BEP20 transfer failed");
        emit TransferAnyBSC20Token(address(this), wallet, tokens);
    }


  function getSignatureForWithdraw(
        address recipient,
        uint256 amount
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "withdraw(address,uint256)",
                recipient,
                amount
            );
    }

    function getSignatureForTransferAnyBSC20Token(
        address tokenAddress,
        address wallet,
        uint256 tokens
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "transferAnyBSC20Token(address,address,uint256)",
                tokenAddress,
                wallet,
                tokens
            );
    }
    

    function getSignatureForSetDiscountOnMnt(
        uint256 _percent
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "setDiscountOnMnt(uint256)",
                _percent
            );
    }

     function getSignatureForupdateMysteryBoxDetails(
        uint256 boxType,
    uint256 price
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "updateMysteryBoxDetails(uint256,uint256)",
                boxType,
                price
            );
    }
 
 


  
}