/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

abstract contract Context {
function _msgSender() internal view virtual returns (address) {
    return msg.sender;
}

}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}



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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
    }


interface TMEEBIT{
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


contract DoubleOrNothing is ERC721TokenReceiver {

    using SafeMath for uint256;
    uint public DexFeePercent = 4;
    uint256 internal nonce = 0;
    uint256 public minTry = 10 ether;
    uint256 public maxTry = 1000 ether;
    bool public marketPaused;
    address payable internal deployer;
    TMEEBIT private tmeebits;
    
    uint256 total_investors;
    uint256 total_contributed;
    uint256 total_withdrawn;
    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }
       struct History {
        uint256 tokenId;
        uint256 wasSuccess;
        address owner;
        uint256 price;
        PlayerDeposit[] deposits;
    }
    
   mapping (address => History) public txHistorys;  


    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        address onlySellTo;     // specify to sell only to a specific person
    }

       mapping (uint => Offer) public punksOfferedForSale;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint indexed punkIndex, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);
    event ERC721Received(address operator, address _from, uint256 tokenId);
    event Deposit(address indexed addr, uint256 amount);
 


    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    bool private reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */

    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;

    }


  
    // constructor()  {
    //       _transferOwnership(_msgSender());
    //     // tmeebits = TMEEBIT(_tmeebit);
    // }

    function pauseMarket(bool _paused) external onlyDeployer {
        marketPaused = _paused;
    }


    function tryChance()payable public{
        // require(address(this).balance > msg.value.mul(2),"try another time");
        uint256 rand = random();
        if(rand>0){
            _sendValue(msg.sender,msg.value.mul(2));
        }
        History storage txHistory = txHistorys[msg.sender];
         txHistory.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));
        //  txHistorys[msg.sender]=History(88,rand,msg.sender,msg.value);
        txHistory.tokenId = 33;
        txHistory.wasSuccess = rand;
        txHistory.owner= msg.sender;
        txHistory.price = msg.value;

        emit Deposit(msg.sender, msg.value);

    }



function random() public returns (uint256) {
      uint256 index = uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % 2;
      nonce ++;
     return index;

}








    function offerPunkForSale(uint punkIndex) public reentrancyGuard {

        require(marketPaused == false, 'Market Paused');
        require(tmeebits.ownerOf(punkIndex) == msg.sender, 'Only owner');
        require((tmeebits.getApproved(punkIndex) == address(this) || tmeebits.isApprovedForAll(msg.sender, address(this))), 'Not Approved');
        tmeebits.safeTransferFrom(msg.sender, address(this), punkIndex);
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, address(0));
        emit PunkOffered(punkIndex, address(0));
    }

    function punkNoLongerForSale(uint punkIndex) public reentrancyGuard{

        Offer memory offer = punksOfferedForSale[punkIndex];
        require(offer.isForSale == true, 'punk is not for sale');
        address seller = offer.seller;
        require(seller == msg.sender, 'Only Owner');
        tmeebits.safeTransferFrom(address(this), msg.sender, punkIndex);
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, address(0));
        emit PunkNoLongerForSale(punkIndex);
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4){
        _data;
        emit ERC721Received(_operator, _from, _tokenId);
        return 0x150b7a02;
    }

    function _sendValue(address _to, uint _value) internal {
        (bool success, ) = address(uint160(_to)).call{value: _value}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function _calculateShares(uint value) internal view returns (uint _sellerShare, uint _feeBOneShare, uint _feeBTwoShare, uint _feeBThreeShare, uint _feeBFourShare) {
        uint totalFeeValue = _fraction(DexFeePercent, 100, value); // fee: 6% of punk price
        _sellerShare = value - totalFeeValue; // 94% of punk price
        _feeBOneShare = _fraction(2 , 5, totalFeeValue); // 40% of fee
        _feeBTwoShare = _fraction(1 , 10, totalFeeValue); // 10% of Fee
        _feeBThreeShare  = _fraction(1, 3 , totalFeeValue); // 33.33% of Fee
        _feeBFourShare = _fraction(1, 6, totalFeeValue); // 16.66% of fee
        return ( _sellerShare,  _feeBOneShare,  _feeBTwoShare,  _feeBThreeShare,  _feeBFourShare);

    }

    function _fraction(uint devidend, uint divisor, uint value) internal pure returns(uint) {
        return (value.mul(devidend)).div(divisor);
    }

}