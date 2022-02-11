// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


import "./Dependencies/SafeMath.sol";
import "./Dependencies/SafeERC20.sol";
import "./Dependencies/IERC20.sol";
import "./Dependencies/ReentrancyGuard.sol";
import "./Dependencies/IERC721.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/EXORConsumerBase.sol";

contract BlindBox is Ownable, ReentrancyGuard, EXORConsumerBase{
    using SafeMath for uint;
    using SafeERC20 for IERC20;


    uint private saleIDCounter;

    bool private onlyInitOnce;

    //data source
    //test
    //0x898527f28d6abe526308a6d18157ed1249c5bf1e
    //0xA275CfbD3549D80AE9e2Fed25B97EEA84A45e93E
    //0x75bf996d1348773144E8BFe674243192BFe48B83

    //main net
    //0x21407CE76B98955F1155f8a92eC2B1adaa0CC993
    //0xE8f5c57a5a2C0b3706F4a895E2018BEa38a47A1f
    //0xe31f0B7272E2EF4161d5a0f76040Fc464be55E4c
    //0xa6c3aD36705E007D183177e091d44643D04a74E8
    function init(address newOwner,address _EXORAddress, address _feeToken, address _datasource)  public {

        require(!onlyInitOnce, "already initialized");
        onlyInitOnce = true;
        initEXORConsumerBase(_EXORAddress,_feeToken,_datasource);
        _transferOwnership(newOwner);

    }



    //2021.9.26 only support erc721
    struct BaseSale {
        //erc721 tokenId
        uint256[] tokenIds;

        //contract address
        address contractAddress;

        // the sale setter
        address seller;

        //trading
        uint trading;

        // address of token to pay
        address payTokenAddress;
        // price of token to pay
        uint price;
        // address of receiver
        address receiver;
        uint startTime;
        uint endTime;
        // whether the sale is available
        bool isAvailable;
    }

    struct BlindBoxSale {
        BaseSale base;
        // max number of token could be bought from an address
        uint purchaseLimitation;
    }

    //async purchase
    struct BlindOrder {

        uint saleID;

        uint amount;

        //exo req id
        bytes32 requestId;

        //exo random number
        uint256 randomness;
    }


    // whitelist to set sale
    mapping(address => bool) public whitelist;
    // Payment whitelist for the address of ERC20
    mapping(address => bool) private paymentWhitelist;
    // sale ID -> blindBox sale
    mapping(uint => BlindBoxSale) blindBoxSales;
    // sale ID -> mapping(address => how many tokens have bought)
    mapping(uint => mapping(address => uint)) blindBoxSaleIDToPurchaseRecord;

    //storage reqId for query caller's address and  BlindOrder
    mapping(bytes32 => address) requestIdAndAddress;

    //reqId -> order
    mapping(bytes32 => BlindOrder) consumerOrders;

    address public serverAddress;

    // sale ID -> server hash
    mapping(bytes32 => uint)  serverHashMap;

    event SetWhitelist(address _member, bool _isAdded);
    event PaymentWhitelistChange(address erc20Addr, bool jurisdiction);
    event SetBlindBoxSale(uint _saleID, address _blindBoxSaleSetter, address _payTokenAddress,
        uint _price, address _receiver, uint _purchaseLimitation, uint _startTime, uint _endTime);
    event UpdateBlindBoxSale(uint _saleID, address _operator, address _newPayTokenAddress,
        uint _newPrice, address _newReceiver, uint _newPurchaseLimitation, uint _newStartTime, uint _newEndTime);
    event CancelBlindBoxSale(uint _saleID, address _operator);
    event BlindBoxSaleExpired(uint _saleID, address _operator);
    //v2.0 add reqId attribute
    event Purchase(uint _saleID, address _buyer, uint _remainNftTotal, address _payTokenAddress, uint _totalPayment,bytes32 _reqId);
    event AddTokens(uint256[] _tokenIds,uint _saleID);


    //extends from EXORConsumerBase
    event RequestNonce(uint256 indexed nonce);

    event PurchaseSuccess(uint _saleID, address _buyer, uint _remainNftTotal, address _payTokenAddress, uint _totalPayment,
        bytes32 _requestId, uint256 _randomness,uint[] _tokenIds);

    event DataSourceChanged(address indexed datasource, bool indexed allowed);

    //align BlindBox's nftTotal by tokenId's size
    event AlignTotalsSuccess(uint _saleID,uint  nftTotal);

    //exo timer
    uint256 public timer;


    modifier onlyWhitelist() {
        require(whitelist[msg.sender],
            "the caller isn't in the whitelist");
        _;
    }

    modifier onlyPaymentWhitelist(address erc20Addr) {
        require(paymentWhitelist[erc20Addr],
            "the pay token address isn't in the whitelist");
        _;
    }

    function setWhitelist(address _member, bool _status) external onlyOwner {
        whitelist[_member] = _status;
        emit SetWhitelist(_member, _status);
    }
    /**
     * @dev Public function to set the payment whitelist only by the owner.
     * @param erc20Addr address address of erc20 for paying
     * @param jurisdiction bool in or out of the whitelist
     */
    function setPaymentWhitelist(address erc20Addr, bool jurisdiction) public onlyOwner {
        paymentWhitelist[erc20Addr] = jurisdiction;
        emit PaymentWhitelistChange(erc20Addr, jurisdiction);
    }

    // set blindBox sale by the member in whitelist
    // NOTE: set 0 duration if you don't want an endTime
    function setBlindBoxSale(

        address _payTokenAddress,
        uint _price,
        address _receiver,
        uint _purchaseLimitation,
        uint _startTime,
        uint _duration,
        address _contractAddress//add contract address
    ) external nonReentrant onlyWhitelist onlyPaymentWhitelist(_payTokenAddress) {
        // 1. check the validity of params
        _checkBlindBoxSaleParams(_price, _startTime, _purchaseLimitation);

        // 2.  build blindBox sale
        uint endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }

        BaseSale memory baseSale;
        baseSale.seller = msg.sender;
        baseSale.trading = 0;
        baseSale.payTokenAddress = _payTokenAddress;
        baseSale.price = _price;
        baseSale.receiver = _receiver;
        baseSale.startTime = _startTime;
        baseSale.endTime = endTime;
        baseSale.isAvailable = true;
        baseSale.contractAddress = _contractAddress;



        BlindBoxSale memory blindBoxSale = BlindBoxSale({
            base : baseSale,
            purchaseLimitation : _purchaseLimitation
            });

        // 3. store blindBox sale
        uint currentSaleID = saleIDCounter;
        saleIDCounter = saleIDCounter.add(1);
        blindBoxSales[currentSaleID] = blindBoxSale;
        emit SetBlindBoxSale(currentSaleID, blindBoxSale.base.seller,
            blindBoxSale.base.payTokenAddress, blindBoxSale.base.price, blindBoxSale.base.receiver, blindBoxSale.purchaseLimitation,
            blindBoxSale.base.startTime, blindBoxSale.base.endTime);
    }



    //admin add token to blindboxSale
    function addTokenIdToBlindBoxSale(uint _saleID,address _contractAddress, uint256[] memory _tokenIds) external onlyWhitelist{

        BlindBoxSale storage blindBoxSale = blindBoxSales[_saleID];

        require(blindBoxSale.base.startTime > now,
            "it's not allowed to update the blindBox sale after the start of it");

        require(blindBoxSale.base.seller == msg.sender,
            "the blindBox sale can only be updated by its setter");

        require(blindBoxSale.base.contractAddress==_contractAddress,
            "the contract and saleId doesn't match");


        IERC721 tokenAddressCached = IERC721(blindBoxSale.base.contractAddress);
        for(uint i = 0; i < _tokenIds.length; i++) {
            uint256  tokenId = _tokenIds[i];
            require(tokenAddressCached.ownerOf(tokenId) == blindBoxSale.base.seller,
                "unmatched ownership of target ERC721 token");
            blindBoxSale.base.tokenIds.push(tokenId);
        }

        emit AddTokens(_tokenIds,_saleID);
    }

    // update the blindBox sale before starting
    // NOTE: set 0 duration if you don't want an endTime
    function updateBlindBoxSale(
        uint _saleID,
        address _payTokenAddress,
        uint _price,
        address _receiver,
        uint _purchaseLimitation,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist onlyPaymentWhitelist(_payTokenAddress) {
        BlindBoxSale memory blindBoxSale = _getBlindBoxSaleByID(_saleID);
        // 1. make sure that the blindBox sale doesn't start
        require(blindBoxSale.base.startTime > now,
            "it's not allowed to update the blindBox sale after the start of it");
        require(blindBoxSale.base.isAvailable,
            "the blindBox sale has been cancelled");
        require(blindBoxSale.base.seller == msg.sender,
            "the blindBox sale can only be updated by its setter");

        // 2. check the validity of params to update
        _checkBlindBoxSaleParams( _price, _startTime, _purchaseLimitation);

        // 3. update blindBox sale
        uint endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }



        blindBoxSale.base.payTokenAddress = _payTokenAddress;
        blindBoxSale.base.price = _price;
        blindBoxSale.base.receiver = _receiver;
        blindBoxSale.base.startTime = _startTime;
        blindBoxSale.base.endTime = endTime;
        blindBoxSale.purchaseLimitation = _purchaseLimitation;
        blindBoxSales[_saleID] = blindBoxSale;
        emit UpdateBlindBoxSale(_saleID, blindBoxSale.base.seller,
            blindBoxSale.base.payTokenAddress, blindBoxSale.base.price, blindBoxSale.base.receiver, blindBoxSale.purchaseLimitation,
            blindBoxSale.base.startTime, blindBoxSale.base.endTime);
    }

    // cancel the blindBox sale
    function cancelBlindBoxSale(uint _saleID) external onlyWhitelist {
        BlindBoxSale memory blindBoxSale = _getBlindBoxSaleByID(_saleID);
        require(blindBoxSale.base.isAvailable,
            "the blindBox sale isn't available");
        require(blindBoxSale.base.seller == msg.sender,
            "the blindBox sale can only be cancelled by its setter");

        blindBoxSales[_saleID].base.isAvailable = false;
        emit CancelBlindBoxSale(_saleID, msg.sender);
    }

    uint256 oraclePrice;

    function setOraclePrice(uint256 _oraclePrice) public onlyOwner{
        oraclePrice = _oraclePrice;
    }
    //generate reqId and send req to ex oracle
    function sendOracleReq(uint amount) private returns (bytes32 requestId){

        //10 nft gas : 0.0005 special process 500000000000000
        uint256 price = oraclePrice * amount;

        //used order count change exor fee
        bytes32 reqId = requestRandomness(timer,price);//60000000000000000 is 0.06 exor token
        timer = timer + 1;
        emit RequestNonce(timer);
        return reqId;
    }

    /**
    * Enable or Disable a datasource
    */
    function changeDataSource(address _datasource, bool _boolean) external onlyOwner {
        datasources[_datasource] = _boolean;
        emit DataSourceChanged(_datasource, _boolean);
    }


    function setServerAddress(address targetAddress) public onlyOwner{
        serverAddress = targetAddress;
    }


    //step2 pay and purchase
    //新版本 function purchase() external nonReentrant
    // rush to purchase by anyone
    function purchase(uint _saleID, uint _amount,bytes32 hash,uint8 v, bytes32 r, bytes32 s) external nonReentrant {

        require(ecrecover(hash, v, r, s) == serverAddress,"verify server sign failed") ;

        require(serverHashMap[hash] != _saleID,"sign hash repeat") ;

        //msg.sender获取order对象
        BlindBoxSale memory blindBoxSale = _getBlindBoxSaleByID(_saleID);
        // check the validity
        require(_amount > 0,
            "amount should be > 0");
        require(blindBoxSale.base.isAvailable,
            "the blindBox sale isn't available");
        require(blindBoxSale.base.seller != msg.sender,
            "the setter can't make a purchase from its own blindBox sale");
        uint currentTime = now;
        require(currentTime >= blindBoxSale.base.startTime,
            "the blindBox sale doesn't start");

        // check whether the end time arrives
        if (blindBoxSale.base.endTime != 0 && blindBoxSale.base.endTime <= currentTime) {
            // the blindBox sale has been set an end time and expired
            blindBoxSales[_saleID].base.isAvailable = false;
            emit BlindBoxSaleExpired(_saleID, msg.sender);
            return;
        }

        //compute curent tokenIds sub current tranding
        uint remainingAmount = blindBoxSales[_saleID].base.tokenIds.length - blindBoxSales[_saleID].base.trading;

        // check  remain amount is enough
        require(_amount <= remainingAmount ,
            "insufficient amount of token for this trade");


        // check the purchase record of the buyer
        uint newPurchaseRecord = blindBoxSaleIDToPurchaseRecord[_saleID][msg.sender].add(_amount);
        require(newPurchaseRecord <= blindBoxSale.purchaseLimitation,
            "total amount to purchase exceeds the limitation of an address");



        // pay the receiver
        blindBoxSaleIDToPurchaseRecord[_saleID][msg.sender] = newPurchaseRecord;
        uint totalPayment = blindBoxSale.base.price.mul(_amount);
        IERC20(blindBoxSale.base.payTokenAddress).safeTransferFrom(msg.sender, blindBoxSale.base.receiver, totalPayment);


        //fronzen trading amount
        blindBoxSales[_saleID].base.trading = blindBoxSales[_saleID].base.trading + _amount;
        uint newRemainingAmount = blindBoxSales[_saleID].base.tokenIds.length - blindBoxSales[_saleID].base.trading;

        if ( newRemainingAmount == 0) {
            blindBoxSales[_saleID].base.isAvailable = false;
        }


        //pay erc20 success , create BlindOrder
        BlindOrder memory order;
        order.saleID = _saleID;
        order.amount = _amount;

        bytes32 reqId = sendOracleReq(_amount);
        order.requestId = reqId;

        //storage user's address and order
        consumerOrders[reqId] = order;
        //storage requestId and user's address for auth
        requestIdAndAddress[reqId] = msg.sender;

        serverHashMap[hash] = _saleID;
        emit Purchase(_saleID, msg.sender, newRemainingAmount, blindBoxSale.base.payTokenAddress, totalPayment,reqId);
    }



    //ex oracle's callback function,process lottery
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {

        address  userAddress = requestIdAndAddress[requestId];

        require(userAddress != address(0), "the target order  doesn't exist");

        BlindOrder storage order = consumerOrders[requestId];

        order.randomness = randomness;


        uint[] memory tokenIDsRecord = new uint[](order.amount);

        uint tokenSize = blindBoxSales[order.saleID].base.tokenIds.length;

        for (uint i = 0; i < order.amount; i++) {
            uint index = randomness % tokenSize;

            uint256 tokenId = blindBoxSales[order.saleID].base.tokenIds[index];

            // call other contract use tokenId and sender address
            IERC721(blindBoxSales[order.saleID].base.contractAddress).safeTransferFrom(
                blindBoxSales[order.saleID].base.seller,
                requestIdAndAddress[requestId],
                tokenId);

            //for event
            tokenIDsRecord[i] = tokenId;
            //array tail -> array[index]
            blindBoxSales[order.saleID].base.tokenIds[index] = blindBoxSales[order.saleID].base.tokenIds[tokenSize-1];
            tokenSize--;
            //array tail pop
            blindBoxSales[order.saleID].base.tokenIds.pop();
        }


        //sub trading value
        blindBoxSales[order.saleID].base.trading = blindBoxSales[order.saleID].base.trading - order.amount;

        uint remainNftTotal = blindBoxSales[order.saleID].base.tokenIds.length - blindBoxSales[order.saleID].base.trading;

        address payTokenAddress = blindBoxSales[order.saleID].base.payTokenAddress;

        uint totalPayment = blindBoxSales[order.saleID].base.price.mul(order.amount);

        uint rSaleId = order.saleID;
        // remove consumerOrders and requestIdAndAddress
        delete requestIdAndAddress[requestId];
        delete consumerOrders[requestId];


        emit PurchaseSuccess(rSaleId,userAddress,remainNftTotal,payTokenAddress,totalPayment,requestId, randomness,tokenIDsRecord);


    }

    //special process for proxy
    function setKeyHash() external onlyOwner {

        _keyHash = 0;
    }


    // read method
    function getBlindBoxSaleTokenRemaining(uint _saleID) public view returns (uint){
        // check whether the blindBox sale ID exists
        BlindBoxSale memory blindBoxSale = _getBlindBoxSaleByID(_saleID);
        return blindBoxSale.base.tokenIds.length - blindBoxSale.base.trading;
    }

    function getBlindBoxSalePurchaseRecord(uint _saleID, address _buyer) public view returns (uint){
        // check whether the blindBox sale ID exists
        _getBlindBoxSaleByID(_saleID);
        return blindBoxSaleIDToPurchaseRecord[_saleID][_buyer];
    }

    function getBlindBoxSale(uint _saleID) public view returns (BlindBoxSale memory){
        return _getBlindBoxSaleByID(_saleID);
    }


    /**
     * @dev Public function to query whether the target erc20 address is in the payment whitelist.
     * @param erc20Addr address target address of erc20 to query about
     */
    function getPaymentWhitelist(address erc20Addr) public view returns (bool){
        return paymentWhitelist[erc20Addr];
    }

    function _getBlindBoxSaleByID(uint _saleID) internal view returns (BlindBoxSale memory blindBoxSale){
        blindBoxSale = blindBoxSales[_saleID];
        require(blindBoxSale.base.seller != address(0),
            "the target blindBox sale doesn't exist");
    }

    function _checkBlindBoxSaleParams(
        uint _price,
        uint _startTime,
        uint _purchaseLimitation
    ) internal {


        require(_price > 0,
            "the price or the initial price must be > 0");

        require(_startTime >= now,
            "startTime must be >= now");

        require(_purchaseLimitation > 0,
            "purchaseLimitation must be > 0");

    }





}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.10;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
interface IEXOR {
    function randomnessRequest(
        uint256 _consumerSeed,
        uint256 _feePaid,
        address _feeToken
    ) external;
}

contract EXORRequestIDBase {

    //special process for proxy
    bytes32 public _keyHash;

    function makeVRFInputSeed(
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns ( uint256 ) {

        return uint256(keccak256(abi.encode(_userSeed, _requester, _nonce)));
    }

    function makeRequestId(
        uint256 _vRFInputSeed
    ) internal view returns (bytes32) {

        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

abstract contract EXORConsumerBase is EXORRequestIDBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ================================================== STATE VARIABLES ================================================== */
    // @notice requesting times of this consumer
    uint256 private nonces;
    // @notice reward address
    address public feeToken;
    // @notice EXORandomness address
    address private EXORAddress;
    // @notice appointed data source map
    mapping(address => bool) public datasources;

    bool private onlyInitEXOROnce;


    /* ================================================== CONSTRUCTOR ================================================== */

    function initEXORConsumerBase (
        address  _EXORAddress,
        address _feeToken,
        address _datasource
    ) public {
        require(!onlyInitEXOROnce, "exorBase already initialized");
        onlyInitEXOROnce = true;

        EXORAddress = _EXORAddress;
        feeToken = _feeToken;
        datasources[_datasource] = true;


    }

    /* ================================================== MUTATIVE FUNCTIONS ================================================== */
    // @notice developer needs to overwrites this function, and the total gas used is limited less than 200K
    //         it will be emitted when a bot put a random number to this consumer
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal virtual;

    // @notice developer needs to call this function in his own logic contract, to ask for a random number with a unique request id
    // @param _seed seed number generated from logic contract
    // @param _fee reward number given for this single request
    function requestRandomness(
        uint256 _seed,
        uint256 _fee
    )
    internal
    returns (
        bytes32 requestId
    )
    {
        IERC20(feeToken).safeApprove(EXORAddress, 0);
        IERC20(feeToken).safeApprove(EXORAddress, _fee);

        IEXOR(EXORAddress).randomnessRequest(_seed, _fee, feeToken);

        uint256 vRFSeed  = makeVRFInputSeed(_seed, address(this), nonces);
        nonces = nonces.add(1);
        return makeRequestId(vRFSeed);
    }

    // @notice only EXORandomness contract can call this function
    // @param requestId a specific request id
    // @param randomness a random number
    function rawFulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) external {
        require(msg.sender == EXORAddress, "Only EXORandomness can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
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
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.10;

import "./EXORConsumerBase.sol";
import "./Ownable.sol";


contract EXORandomConsumer is EXORConsumerBase {

    event RequestNonce(uint256 indexed nonce);
    event DemoRandom(bytes32 indexed requestId, uint256 indexed randomness);
    event DataSourceChanged(address indexed datasource, bool indexed allowed);


    /**
    * Constructor inherits EXORConsumerBase
    *
    * Network: OEC Testnet
    * _EXORAddress: 0x20506127Af03E02cabB67020962e8152087DfF3f
    * _feeToken: 0xc474786670dda7763ec2733df674dd3fa1ddc819 (an erc20 token address)
    * _datasource: 0x898527f28d6abe526308a6d18157ed1249c5bf1e
    */
 /*   constructor(address _EXORAddress, address _feeToken, address _datasource) EXORConsumerBase(_EXORAddress, _feeToken, _datasource) public {


    }*/

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit DemoRandom(requestId, randomness);

        //根据reqId取order
        //讲随机数存入order
    }

    /**
     * Requests randomness to EXORandomness
     */
    function requestRandomness(uint256 timer) external {
        requestRandomness(timer, 100);

        timer = timer + 1;
        emit RequestNonce(timer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Dependencies/Ownable.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/SafeERC20.sol";
import "./Dependencies/IERC20.sol";
import "./Dependencies/IERC721.sol";
import "./Dependencies/ReentrancyGuard.sol";

contract Sales721 is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // set the saleIDCounter initial value to 1
    uint private saleIDCounter = 1;
    bool private onlyInitOnce;

    struct BaseSale {
        // the sale setter
        address seller;
        // addresses of token to sell
        address[] tokenAddresses;
        // tokenIDs of token to sell
        uint[] tokenIDs;
        // address of token to pay
        address payTokenAddress;
        // price of token to pay
        uint price;
        // address of receiver
        address receiver;
        uint startTime;
        uint endTime;
        // whether the sale is available
        bool isAvailable;
    }

    struct FlashSale {
        BaseSale base;
        // max number of token could be bought from an address
        uint purchaseLimitation;
    }

    struct Auction {
        BaseSale base;
        // the minimum increment in a bid
        uint minBidIncrement;
        // the highest price so far
        uint highestBidPrice;
        // the highest bidder so far
        address highestBidder;
    }

    // whitelist to set sale
    mapping(address => bool) public whitelist;
    // sale ID -> flash sale
    mapping(uint => FlashSale) flashSales;
    // sale ID -> mapping(address => how many tokens have bought)
    mapping(uint => mapping(address => uint)) flashSaleIDToPurchaseRecord;
    // sale ID -> auction
    mapping(uint => Auction) auctions;
    // filter to check repetition
    mapping(address => mapping(uint => bool)) repetitionFilter;

    address public testServerAddress;

    address public serverAddress;
    // sale ID -> server hash
    mapping(bytes32 => uint)  serverHashMap;

    // whitelist to set sale
    mapping(uint => bool) public flashSaleOnProd;

    event SetWhitelist(address _member, bool _isAdded);
    event SetFlashSale(uint _saleID, address _flashSaleSetter, address[] _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress,
        uint _price, address _receiver, uint _purchaseLimitation, uint _startTime, uint _endTime);
    event UpdateFlashSale(uint _saleID, address _operator, address[] _newTokenAddresses, uint[] _newTokenIDs, address _newPayTokenAddress,
        uint _newPrice, address _newReceiver, uint _newPurchaseLimitation, uint _newStartTime, uint _newEndTime);
    event CancelFlashSale(uint _saleID, address _operator);
    event FlashSaleExpired(uint _saleID, address _operator);
    event Purchase(uint _saleID, address _buyer, address[] _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress, uint _totalPayment);
    event SetAuction(uint _saleID, address _auctionSetter, address[] _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress,
        uint _initialPrice, address _receiver, uint _minBidIncrement, uint _startTime, uint _endTime);
    event UpdateAuction(uint _saleID, address _operator, address[] _newTokenAddresses, uint[] _newTokenIDs, address _newPayTokenAddress,
        uint _newInitialPrice, address _newReceiver, uint _newMinBidIncrement, uint _newStartTime, uint _newEndTime);
    event RefundToPreviousBidder(uint _saleID, address _previousBidder, address _payTokenAddress, uint _refundAmount);
    event CancelAuction(uint _saleID, address _operator);
    event NewBidderTransfer(uint _saleID, address _newBidder, address _payTokenAddress, uint _bidPrice);
    event SettleAuction(uint _saleID, address _operator, address _receiver, address _highestBidder, address[] _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress, uint _highestBidPrice);
    event MainCoin(uint totalPayment);
    modifier onlyWhitelist() {
        require(whitelist[msg.sender],
            "the caller isn't in the whitelist");
        _;
    }

    function init(address _newOwner) public {
        require(!onlyInitOnce, "already initialized");

        _transferOwnership(_newOwner);
        onlyInitOnce = true;
    }

    function setWhitelist(address _member, bool _status) external onlyOwner {
        whitelist[_member] = _status;
        emit SetWhitelist(_member, _status);
    }

    // set auction by the member in whitelist
    function setAuction(
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        address _payTokenAddress,
        uint _initialPrice,
        address _receiver,
        uint _minBidIncrement,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist {
        // 1. check the validity of params
        _checkAuctionParams(msg.sender, _tokenAddresses, _tokenIDs, _initialPrice, _minBidIncrement, _startTime, _duration);

        // 2. build auction
        Auction memory auction = Auction({
        base : BaseSale({
        seller : msg.sender,
        tokenAddresses : _tokenAddresses,
        tokenIDs : _tokenIDs,
        payTokenAddress : _payTokenAddress,
        price : _initialPrice,
        receiver : _receiver,
        startTime : _startTime,
        endTime : _startTime.add(_duration),
        isAvailable : true
        }),
        minBidIncrement : _minBidIncrement,
        highestBidPrice : 0,
        highestBidder : address(0)
        });

        // 3. store auction
        uint currentSaleID = saleIDCounter;
        saleIDCounter = saleIDCounter.add(1);
        auctions[currentSaleID] = auction;
        emit SetAuction(currentSaleID, auction.base.seller, auction.base.tokenAddresses, auction.base.tokenIDs,
            auction.base.payTokenAddress, auction.base.price, auction.base.receiver, auction.minBidIncrement,
            auction.base.startTime, auction.base.endTime);
    }

    // update auction by the member in whitelist
    function updateAuction(
        uint _saleID,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        address _payTokenAddress,
        uint _initialPrice,
        address _receiver,
        uint _minBidIncrement,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        // 1. make sure that the auction doesn't start
        require(auction.base.startTime > now,
            "it's not allowed to update the auction after the start of it");
        require(auction.base.isAvailable,
            "the auction has been cancelled");
        require(auction.base.seller == msg.sender,
            "the auction can only be updated by its setter");

        // 2. check the validity of params to update
        _checkAuctionParams(msg.sender, _tokenAddresses, _tokenIDs, _initialPrice, _minBidIncrement, _startTime, _duration);

        // 3. update the auction
        auction.base.tokenAddresses = _tokenAddresses;
        auction.base.tokenIDs = _tokenIDs;
        auction.base.payTokenAddress = _payTokenAddress;
        auction.base.price = _initialPrice;
        auction.base.receiver = _receiver;
        auction.base.startTime = _startTime;
        auction.base.endTime = _startTime.add(_duration);
        auction.minBidIncrement = _minBidIncrement;
        auctions[_saleID] = auction;
        emit UpdateAuction(_saleID, auction.base.seller, auction.base.tokenAddresses, auction.base.tokenIDs,
            auction.base.payTokenAddress, auction.base.price, auction.base.receiver, auction.minBidIncrement,
            auction.base.startTime, auction.base.endTime);
    }

    // cancel the auction
    function cancelAuction(uint _saleID) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        require(auction.base.isAvailable,
            "the auction isn't available");
        require(auction.base.seller == msg.sender,
            "the auction can only be cancelled by its setter");

        if (auction.highestBidPrice != 0) {
            // some bid has paid for this auction
            IERC20(auction.base.payTokenAddress).safeTransfer(auction.highestBidder, auction.highestBidPrice);
            emit RefundToPreviousBidder(_saleID, auction.highestBidder, auction.base.payTokenAddress, auction.highestBidPrice);
        }

        auctions[_saleID].base.isAvailable = false;
        emit CancelAuction(_saleID, msg.sender);
    }

    // bid for the target auction
    function bid(uint _saleID, uint _bidPrice) external nonReentrant {
        Auction memory auction = _getAuctionByID(_saleID);
        // check the validity of the target auction
        require(auction.base.isAvailable,
            "the auction isn't available");
        require(auction.base.seller != msg.sender,
            "the setter can't bid for its own auction");
        uint currentTime = now;
        require(currentTime >= auction.base.startTime,
            "the auction doesn't start");
        require(currentTime < auction.base.endTime,
            "the auction has expired");

        IERC20 payToken = IERC20(auction.base.payTokenAddress);
        // check bid price in auction
        if (auction.highestBidPrice != 0) {
            // not first bid
            require(_bidPrice.sub(auction.highestBidPrice) >= auction.minBidIncrement,
                "the bid price must be larger than the sum of current highest one and minimum bid increment");
            // refund to the previous highest bidder from this contract
            payToken.safeTransfer(auction.highestBidder, auction.highestBidPrice);
            emit RefundToPreviousBidder(_saleID, auction.highestBidder, auction.base.payTokenAddress, auction.highestBidPrice);
        } else {
            // first bid
            require(_bidPrice == auction.base.price,
                "first bid must follow the initial price set in the auction");
        }

        // update storage auctions
        auctions[_saleID].highestBidPrice = _bidPrice;
        auctions[_saleID].highestBidder = msg.sender;

        // transfer the bid price into this contract
        payToken.safeApprove(address(this), 0);
        payToken.safeApprove(address(this), _bidPrice);
        payToken.safeTransferFrom(msg.sender, address(this), _bidPrice);
        emit NewBidderTransfer(_saleID, msg.sender, auction.base.payTokenAddress, _bidPrice);
    }

    // settle the auction by the member in whitelist
    function settleAuction(uint _saleID) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        // check the validity of the target auction
        require(auction.base.isAvailable,
            "only the available auction can be settled");
        require(auction.base.endTime <= now,
            "the auction can only be settled after its end time");

        if (auction.highestBidPrice != 0) {
            // the auction has been bidden
            // transfer pay token to the receiver from this contract
            IERC20(auction.base.payTokenAddress).safeTransfer(auction.base.receiver, auction.highestBidPrice);
            // transfer erc721s to the bidder who keeps the highest price
            for (uint i = 0; i < auction.base.tokenAddresses.length; i++) {
                IERC721(auction.base.tokenAddresses[i]).safeTransferFrom(auction.base.seller, auction.highestBidder, auction.base.tokenIDs[i]);
            }
        }

        // close the auction
        auctions[_saleID].base.isAvailable = false;
        emit SettleAuction(_saleID, msg.sender, auction.base.receiver, auction.highestBidder, auction.base.tokenAddresses,
            auction.base.tokenIDs, auction.base.payTokenAddress, auction.highestBidPrice);

    }


    event AddTokens(uint256[] _tokenIds,uint _saleID);

    function addTokenIdToSale(uint _saleID,address[] memory _tokenAddresses, uint256[] memory _tokenIDs) external onlyWhitelist{

        uint standardLen = _tokenAddresses.length;
        require(standardLen > 0,
            "length of tokenAddresses must be > 0");
        require(standardLen == _tokenIDs.length,
            "length of tokenIDs is wrong");

        require(flashSales[_saleID].base.startTime > now,
            "it's not allowed to update the  sale after the start of it");

        require(flashSales[_saleID].base.seller == msg.sender,
            "the  sale can only be updated by its setter");



        for(uint i = 0; i < _tokenIDs.length; i++) {
            uint256  tokenId = _tokenIDs[i];
            address  tokenAddresses = _tokenAddresses[i];

            IERC721 tokenAddressCached = IERC721(tokenAddresses);
            require(tokenAddressCached.ownerOf(tokenId) == flashSales[_saleID].base.seller,
                "unmatched ownership of target ERC721 token");

            flashSales[_saleID].base.tokenIDs.push(tokenId);
            flashSales[_saleID].base.tokenAddresses.push(tokenAddresses);
        }

        emit AddTokens(_tokenIDs,_saleID);
    }

    // set flash sale by the member in whitelist
    // NOTE: set 0 duration if you don't want an endTime
    function setFlashSale(
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        address _payTokenAddress,
        uint _price,
        address _receiver,
        uint _purchaseLimitation,
        uint _startTime,
        uint _duration,
        bool prod
    ) external nonReentrant onlyWhitelist {
        // 1. check the validity of params
        _checkFlashSaleParams(msg.sender, _tokenAddresses, _tokenIDs, _price, _startTime, _purchaseLimitation);

        // 2.  build flash sale
        uint endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }

        FlashSale memory flashSale = FlashSale({
        base : BaseSale({
        seller : msg.sender,
        tokenAddresses : _tokenAddresses,
        tokenIDs : _tokenIDs,
        payTokenAddress : _payTokenAddress,
        price : _price,
        receiver : _receiver,
        startTime : _startTime,
        endTime : endTime,
        isAvailable : true
        }),
        purchaseLimitation : _purchaseLimitation
        });

        // 3. store flash sale
        uint currentSaleID = saleIDCounter;
        saleIDCounter = saleIDCounter.add(1);
        flashSales[currentSaleID] = flashSale;

        //if true then prod env else test env
        flashSaleOnProd[currentSaleID] = prod;

        emit SetFlashSale(currentSaleID, flashSale.base.seller, flashSale.base.tokenAddresses, flashSale.base.tokenIDs,
            flashSale.base.payTokenAddress, flashSale.base.price, flashSale.base.receiver, flashSale.purchaseLimitation,
            flashSale.base.startTime, flashSale.base.endTime);
    }

    // update the flash sale before starting
    // NOTE: set 0 duration if you don't want an endTime
    function updateFlashSale(
        uint _saleID,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        address _payTokenAddress,
        uint _price,
        address _receiver,
        uint _purchaseLimitation,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist {
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        // 1. make sure that the flash sale doesn't start
        require(flashSale.base.startTime > now,
            "it's not allowed to update the flash sale after the start of it");
        require(flashSale.base.isAvailable,
            "the flash sale has been cancelled");
        require(flashSale.base.seller == msg.sender,
            "the flash sale can only be updated by its setter");

        // 2. check the validity of params to update
        _checkFlashSaleParams(msg.sender, _tokenAddresses, _tokenIDs, _price, _startTime, _purchaseLimitation);

        // 3. update flash sale
        uint endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }

        flashSale.base.tokenAddresses = _tokenAddresses;
        flashSale.base.tokenIDs = _tokenIDs;
        flashSale.base.payTokenAddress = _payTokenAddress;
        flashSale.base.price = _price;
        flashSale.base.receiver = _receiver;
        flashSale.base.startTime = _startTime;
        flashSale.base.endTime = endTime;
        flashSale.purchaseLimitation = _purchaseLimitation;
        flashSales[_saleID] = flashSale;
        emit UpdateFlashSale(_saleID, flashSale.base.seller, flashSale.base.tokenAddresses, flashSale.base.tokenIDs,
            flashSale.base.payTokenAddress, flashSale.base.price, flashSale.base.receiver, flashSale.purchaseLimitation,
            flashSale.base.startTime, flashSale.base.endTime);
    }

    // cancel the flash sale
    function cancelFlashSale(uint _saleID) external onlyWhitelist {
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        require(flashSale.base.isAvailable,
            "the flash sale isn't available");
        require(flashSale.base.seller == msg.sender,
            "the flash sale can only be cancelled by its setter");

        flashSales[_saleID].base.isAvailable = false;
        emit CancelFlashSale(_saleID, msg.sender);
    }



    function setServerAddress(address targetAddress) public onlyOwner{
        serverAddress = targetAddress;
    }


    function setTestServerAddress(address targetAddress) public onlyOwner{
        testServerAddress = targetAddress;
    }


    function setFlashSaleEnv(uint _saleID,bool isProd) public nonReentrant onlyOwner{
        flashSaleOnProd[_saleID] = isProd;
    }

    // rush to purchase by anyone
    function purchase(uint _saleID, uint _amount,bytes32 hash,uint8 v, bytes32 r, bytes32 s) external payable nonReentrant {


        if(flashSaleOnProd[_saleID]==true){
            require(ecrecover(hash, v, r, s) == serverAddress,"verify prod server sign failed") ;
        }else{
            require(ecrecover(hash, v, r, s) == testServerAddress,"verify test server sign failed") ;
        }
        // we have set saleIDCounter initial value to 1 to prevent when _saleID = 0 from can not being purchased
        require(serverHashMap[hash] != _saleID,"sign hash repeat") ;


        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        // check the validity
        require(_amount > 0,
            "amount should be > 0");
        require(flashSale.base.isAvailable,
            "the flash sale isn't available");
        require(flashSale.base.seller != msg.sender,
            "the setter can't make a purchase from its own flash sale");
        uint currentTime = now;
        require(currentTime >= flashSale.base.startTime,
            "the flash sale doesn't start");
        // check whether the end time arrives
        if (flashSale.base.endTime != 0 && flashSale.base.endTime <= currentTime) {
            // the flash sale has been set an end time and expired
            flashSales[_saleID].base.isAvailable = false;
            emit FlashSaleExpired(_saleID, msg.sender);
            return;
        }
        // check the purchase record of the buyer
        uint newPurchaseRecord = flashSaleIDToPurchaseRecord[_saleID][msg.sender].add(_amount);
        require(newPurchaseRecord <= flashSale.purchaseLimitation,
            "total amount to purchase exceeds the limitation of an address");
        // check whether the amount of token rest in flash sale is sufficient for this trade
        require(_amount <= flashSale.base.tokenIDs.length,
            "insufficient amount of token for this trade");

        // pay the receiver
        flashSaleIDToPurchaseRecord[_saleID][msg.sender] = newPurchaseRecord;
        uint totalPayment = flashSale.base.price.mul(_amount);
        //IERC20(flashSale.base.payTokenAddress).safeTransferFrom(msg.sender, flashSale.base.receiver, totalPayment);

        if(flashSale.base.payTokenAddress!= address(0)){
            IERC20(flashSale.base.payTokenAddress).safeTransferFrom(msg.sender, flashSale.base.receiver, totalPayment);
        }else{
            require(msg.value >= totalPayment, "amount should be > totalPayment");
            emit MainCoin(totalPayment);
            payable(flashSale.base.receiver).transfer(totalPayment);
        }


        // transfer erc721 tokens to buyer
        address[] memory tokenAddressesRecord = new address[](_amount);
        uint[] memory tokenIDsRecord = new uint[](_amount);
        uint targetIndex = flashSale.base.tokenIDs.length - 1;
        for (uint i = 0; i < _amount; i++) {
            IERC721(flashSale.base.tokenAddresses[targetIndex]).safeTransferFrom(flashSale.base.seller, msg.sender, flashSale.base.tokenIDs[targetIndex]);
            tokenAddressesRecord[i] = flashSale.base.tokenAddresses[targetIndex];
            tokenIDsRecord[i] = flashSale.base.tokenIDs[targetIndex];
            targetIndex--;
            flashSales[_saleID].base.tokenAddresses.pop();
            flashSales[_saleID].base.tokenIDs.pop();
        }

        if (flashSales[_saleID].base.tokenAddresses.length == 0) {
            flashSales[_saleID].base.isAvailable = false;
        }

        serverHashMap[hash] = _saleID;
        emit Purchase(_saleID, msg.sender, tokenAddressesRecord, tokenIDsRecord, flashSale.base.payTokenAddress, totalPayment);
    }

    function getFlashSaleTokenRemaining(uint _saleID) public view returns (uint){
        // check whether the flash sale ID exists
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        return flashSale.base.tokenIDs.length;
    }

    function getFlashSalePurchaseRecord(uint _saleID, address _buyer) public view returns (uint){
        // check whether the flash sale ID exists
        _getFlashSaleByID(_saleID);
        return flashSaleIDToPurchaseRecord[_saleID][_buyer];
    }


    function getAuction(uint _saleID) public view returns (Auction memory){
        return _getAuctionByID(_saleID);
    }

    function getFlashSale(uint _saleID) public view returns (FlashSale memory){
        return _getFlashSaleByID(_saleID);
    }

    function getCurrentSaleID() external view returns (uint256) {
        return saleIDCounter;
    }

    function _getAuctionByID(uint _saleID) internal view returns (Auction memory auction){
        auction = auctions[_saleID];
        require(auction.base.seller != address(0),
            "the target auction doesn't exist");
    }

    function _getFlashSaleByID(uint _saleID) internal view returns (FlashSale memory flashSale){
        flashSale = flashSales[_saleID];
        require(flashSale.base.seller != address(0),
            "the target flash sale doesn't exist");
    }

    function _checkAuctionParams(
        address _baseSaleSetter,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        uint _initialPrice,
        uint _minBidIncrement,
        uint _startTime,
        uint _duration
    ) internal {
        _checkBaseSaleParams(_baseSaleSetter, _tokenAddresses, _tokenIDs, _initialPrice, _startTime);
        require(_minBidIncrement > 0,
            "minBidIncrement must be > 0");
        require(_duration > 0,
            "duration must be > 0");
    }

    function _checkFlashSaleParams(
        address _baseSaleSetter,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        uint _price,
        uint _startTime,
        uint _purchaseLimitation
    ) internal {
        uint standardLen = _checkBaseSaleParams(_baseSaleSetter, _tokenAddresses, _tokenIDs, _price, _startTime);
        require(_purchaseLimitation > 0,
            "purchaseLimitation must be > 0");
        require(_purchaseLimitation <= standardLen,
            "purchaseLimitation must be <= the length of tokenAddresses");
    }

    function _checkBaseSaleParams(
        address _baseSaleSetter,
        address[] memory _tokenAddresses,
        uint[] memory _tokenIDs,
        uint _price,
        uint _startTime
    ) internal returns (uint standardLen){
        standardLen = _tokenAddresses.length;
        require(standardLen > 0,
            "length of tokenAddresses must be > 0");
        require(standardLen == _tokenIDs.length,
            "length of tokenIDs is wrong");
        // check whether the sale setter has the target tokens && approval
        IERC721 tokenAddressCached;
        uint tokenIDCached;
        for (uint i = 0; i < standardLen; i++) {
            tokenAddressCached = IERC721(_tokenAddresses[i]);
            tokenIDCached = _tokenIDs[i];
            // check repetition
            require(!repetitionFilter[address(tokenAddressCached)][tokenIDCached],
                "repetitive ERC721 tokens");
            repetitionFilter[address(tokenAddressCached)][tokenIDCached] = true;
            require(tokenAddressCached.ownerOf(tokenIDCached) == _baseSaleSetter,
                "unmatched ownership of target ERC721 token");
            require(
                tokenAddressCached.getApproved(tokenIDCached) == address(this) ||
                tokenAddressCached.isApprovedForAll(_baseSaleSetter, address(this)),
                "the contract hasn't been approved for ERC721 transferring");
        }

        require(_price > 0,
            "the price or the initial price must be > 0");
        require(_startTime >= now,
            "startTime must be >= now");

        // clear filter
        for (uint i = 0; i < standardLen; i++) {
            repetitionFilter[_tokenAddresses[i]][_tokenIDs[i]] = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Dependencies/Ownable.sol";
import "./Dependencies/ReentrancyGuard.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/SafeERC20.sol";
import "./Dependencies/IERC20.sol";
import "./Dependencies/IERC1155.sol";

contract FlashSales1155 is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint private _saleIdCounter;
    bool private _onlyInitOnce;

    struct FlashSale {
        // The sale setter
        address seller;
        // Address of ERC1155 token to sell
        address tokenAddress;
        // Id of ERC1155 token to sell
        uint id;
        // Remaining amount of ERC1155 token in this sale
        uint remainingAmount;
        // ERC20 address of token for payment
        address payTokenAddress;
        // Price of token to pay
        uint price;
        // Address of receiver
        address receiver;
        // Max number of ERC1155 token could be bought from an address
        uint purchaseLimitation;
        uint startTime;
        uint endTime;
        // Whether the sale is available
        bool isAvailable;
    }

    // Payment whitelist for the address of ERC20
    mapping(address => bool) private _paymentWhitelist;

    // Whitelist to set sale
    mapping(address => bool) private _whitelist;

    // Mapping from sale id to FlashSale info
    mapping(uint => FlashSale) private _flashSales;

    // Mapping from sale ID to mapping(address => how many tokens have bought)
    mapping(uint => mapping(address => uint)) _flashSaleIdToPurchaseRecord;

    event PaymentWhitelistChange(address erc20Addr, bool jurisdiction);
    event SetWhitelist(address memberAddr, bool jurisdiction);
    event SetFlashSale(uint saleId, address flashSaleSetter, address tokenAddress, uint id, uint remainingAmount,
        address payTokenAddress, uint price, address receiver, uint purchaseLimitation, uint startTime,
        uint endTime);
    event UpdateFlashSale(uint saleId, address operator, address newTokenAddress, uint newId, uint newRemainingAmount,
        address newPayTokenAddress, uint newPrice, address newReceiver, uint newPurchaseLimitation, uint newStartTime,
        uint newEndTime);
    event CancelFlashSale(uint saleId, address operator);
    event FlashSaleExpired(uint saleId, address operator);
    event Purchase(uint saleId, address buyer, address tokenAddress, uint id, uint amount, address payTokenAddress,
        uint totalPayment);


    modifier onlyWhitelist() {
        require(_whitelist[msg.sender],
            "the caller isn't in the whitelist");
        _;
    }

    modifier onlyPaymentWhitelist(address erc20Addr) {
        require(_paymentWhitelist[erc20Addr],
            "the pay token address isn't in the whitelist");
        _;
    }

    function init(address _newOwner) public {
        require(!_onlyInitOnce, "already initialized");

        _transferOwnership(_newOwner);
        _onlyInitOnce = true;
    }

    /**
     * @dev External function to set flash sale by the member in whitelist.
     * @param tokenAddress address Address of ERC1155 token contract
     * @param id uint Id of ERC1155 token to sell
     * @param amount uint Amount of target ERC1155 token to sell
     * @param payTokenAddress address ERC20 address of token for payment
     * @param price uint Price of each ERC1155 token
     * @param receiver address Address of the receiver to gain the payment
     * @param purchaseLimitation uint Max number of ERC1155 token could be bought from an address
     * @param startTime uint Timestamp of the beginning of flash sale activity
     * @param duration uint The duration of this flash sale activity
     */
    function setFlashSale(
        address tokenAddress,
        uint id,
        uint amount,
        address payTokenAddress,
        uint price,
        address receiver,
        uint purchaseLimitation,
        uint startTime,
        uint duration
    )
    external
    nonReentrant
    onlyWhitelist
    onlyPaymentWhitelist(payTokenAddress)
    {
        // 1. check the validity of params
        _checkFlashSaleParams(msg.sender, tokenAddress, id, amount, price, purchaseLimitation, startTime);

        // 2.  build flash sale
        uint endTime;
        if (duration != 0) {
            endTime = startTime.add(duration);
        }

        FlashSale memory flashSale = FlashSale({
        seller : msg.sender,
        tokenAddress : tokenAddress,
        id : id,
        remainingAmount : amount,
        payTokenAddress : payTokenAddress,
        price : price,
        receiver : receiver,
        purchaseLimitation : purchaseLimitation,
        startTime : startTime,
        endTime : endTime,
        isAvailable : true
        });

        // 3. store flash sale
        uint currentSaleId = _saleIdCounter;
        _saleIdCounter = _saleIdCounter.add(1);
        _flashSales[currentSaleId] = flashSale;
        emit SetFlashSale(currentSaleId, flashSale.seller, flashSale.tokenAddress, flashSale.id,
            flashSale.remainingAmount, flashSale.payTokenAddress, flashSale.price, flashSale.receiver,
            flashSale.purchaseLimitation, flashSale.startTime, flashSale.endTime);
    }

    /**
     * @dev External function to update the existing flash sale by its setter in whitelist.
     * @param saleId uint The target id of flash sale to update
     * @param newTokenAddress address New Address of ERC1155 token contract
     * @param newId uint New id of ERC1155 token to sell
     * @param newAmount uint New amount of target ERC1155 token to sell
     * @param newPayTokenAddress address New ERC20 address of token for payment
     * @param newPrice uint New price of each ERC1155 token
     * @param newReceiver address New address of the receiver to gain the payment
     * @param newPurchaseLimitation uint New max number of ERC1155 token could be bought from an address
     * @param newStartTime uint New timestamp of the beginning of flash sale activity
     * @param newDuration uint New duration of this flash sale activity
     */
    function updateFlashSale(
        uint saleId,
        address newTokenAddress,
        uint newId,
        uint newAmount,
        address newPayTokenAddress,
        uint newPrice,
        address newReceiver,
        uint newPurchaseLimitation,
        uint newStartTime,
        uint newDuration
    )
    external
    nonReentrant
    onlyWhitelist
    onlyPaymentWhitelist(newPayTokenAddress)
    {
        FlashSale memory flashSale = getFlashSale(saleId);
        // 1. make sure that the flash sale doesn't start
        require(
            flashSale.startTime > now,
            "it's not allowed to update the flash sale after the start of it"
        );
        require(
            flashSale.isAvailable,
            "the flash sale has been cancelled"
        );
        require(
            flashSale.seller == msg.sender,
            "the flash sale can only be updated by its setter"
        );

        // 2. check the validity of params to update
        _checkFlashSaleParams(msg.sender, newTokenAddress, newId, newAmount, newPrice, newPurchaseLimitation,
            newStartTime);

        // 3. update flash sale
        uint endTime;
        if (newDuration != 0) {
            endTime = newStartTime.add(newDuration);
        }

        flashSale.tokenAddress = newTokenAddress;
        flashSale.id = newId;
        flashSale.remainingAmount = newAmount;
        flashSale.payTokenAddress = newPayTokenAddress;
        flashSale.price = newPrice;
        flashSale.receiver = newReceiver;
        flashSale.purchaseLimitation = newPurchaseLimitation;
        flashSale.startTime = newStartTime;
        flashSale.endTime = endTime;
        _flashSales[saleId] = flashSale;
        emit  UpdateFlashSale(saleId, flashSale.seller, flashSale.tokenAddress, flashSale.id, flashSale.remainingAmount,
            flashSale.payTokenAddress, flashSale.price, flashSale.receiver, flashSale.purchaseLimitation,
            flashSale.startTime, flashSale.endTime);
    }

    /**
     * @dev External function to cancel the existing flash sale by its setter in whitelist.
     * @param saleId uint The target id of flash sale to be cancelled
     */
    function cancelFlashSale(uint saleId) external onlyWhitelist {
        FlashSale memory flashSale = getFlashSale(saleId);
        require(
            flashSale.isAvailable,
            "the flash sale isn't available"
        );
        require(
            flashSale.seller == msg.sender,
            "the flash sale can only be cancelled by its setter"
        );

        _flashSales[saleId].isAvailable = false;
        emit CancelFlashSale(saleId, msg.sender);
    }

    /**
      * @dev External function to purchase ERC1155 from the target sale by anyone.
      * @param saleId uint The target id of flash sale to purchase
      * @param amount uint The amount of target ERC1155 to purchase
      */
    function purchase(uint saleId, uint amount) external nonReentrant {
        FlashSale memory flashSale = getFlashSale(saleId);
        // 1. check the validity
        require(
            amount > 0,
            "amount should be > 0"
        );
        require(
            flashSale.isAvailable,
            "the flash sale isn't available"
        );
        require(
            flashSale.seller != msg.sender,
            "the setter can't make a purchase from its own flash sale"
        );
        uint currentTime = now;
        require(
            currentTime >= flashSale.startTime,
            "the flash sale doesn't start"
        );
        // 2. check whether the end time arrives
        if (flashSale.endTime != 0 && flashSale.endTime <= currentTime) {
            // the flash sale has been set an end time and expired
            _flashSales[saleId].isAvailable = false;
            emit FlashSaleExpired(saleId, msg.sender);
            return;
        }

        // 3. check whether the amount of token rest in flash sale is sufficient for this trade
        require(amount <= flashSale.remainingAmount,
            "insufficient amount of token for this trade");
        // 4. check the purchase record of the buyer
        uint newPurchaseRecord = _flashSaleIdToPurchaseRecord[saleId][msg.sender].add(amount);
        require(newPurchaseRecord <= flashSale.purchaseLimitation,
            "total amount to purchase exceeds the limitation of an address");

        // 5. pay the receiver
        _flashSaleIdToPurchaseRecord[saleId][msg.sender] = newPurchaseRecord;
        uint totalPayment = flashSale.price.mul(amount);
        IERC20(flashSale.payTokenAddress).safeTransferFrom(msg.sender, flashSale.receiver, totalPayment);

        // 6. transfer ERC1155 tokens to buyer
        uint newRemainingAmount = flashSale.remainingAmount.sub(amount);
        _flashSales[saleId].remainingAmount = newRemainingAmount;
        if (newRemainingAmount == 0) {
            _flashSales[saleId].isAvailable = false;
        }

        IERC1155(flashSale.tokenAddress).safeTransferFrom(flashSale.seller, msg.sender, flashSale.id, amount, "");
        emit Purchase(saleId, msg.sender, flashSale.tokenAddress, flashSale.id, amount, flashSale.payTokenAddress,
            totalPayment);
    }

    /**
     * @dev Public function to set the whitelist of setting flash sale only by the owner.
     * @param memberAddr address Address of member to be added or removed
     * @param jurisdiction bool In or out of the whitelist
     */
    function setWhitelist(address memberAddr, bool jurisdiction) external onlyOwner {
        _whitelist[memberAddr] = jurisdiction;
        emit SetWhitelist(memberAddr, jurisdiction);
    }

    /**
     * @dev Public function to set the payment whitelist only by the owner.
     * @param erc20Addr address Address of erc20 for paying
     * @param jurisdiction bool In or out of the whitelist
     */
    function setPaymentWhitelist(address erc20Addr, bool jurisdiction) public onlyOwner {
        _paymentWhitelist[erc20Addr] = jurisdiction;
        emit PaymentWhitelistChange(erc20Addr, jurisdiction);
    }

    /**
     * @dev Public function to query whether the target erc20 address is in the payment whitelist.
     * @param erc20Addr address Target address of erc20 to query about
     */
    function getPaymentWhitelist(address erc20Addr) public view returns (bool){
        return _paymentWhitelist[erc20Addr];
    }

    /**
     * @dev Public function to query whether the target member address is in the whitelist.
     * @param memberAddr address Target address of member to query about
     */
    function getWhitelist(address memberAddr) public view returns (bool){
        return _whitelist[memberAddr];
    }

    /**
     * @dev Public function to query the flash sale by sale Id.
     * @param saleId uint Target sale Id of flash sale to query about
     */
    function getFlashSale(uint saleId) public view returns (FlashSale memory flashSale){
        flashSale = _flashSales[saleId];
        require(flashSale.seller != address(0), "the target flash sale doesn't exist");
    }

    function getCurrentSaleId() public view returns (uint256) {
        return _saleIdCounter;
    }

    /**
     * @dev Public function to query the purchase record of the amount that an address has bought.
     * @param saleId uint Target sale Id of flash sale to query about
     * @param buyer address Target address to query the record with
     */
    function getFlashSalePurchaseRecord(uint saleId, address buyer) public view returns (uint){
        // check whether the flash sale Id exists
        getFlashSale(saleId);
        return _flashSaleIdToPurchaseRecord[saleId][buyer];
    }


    function _checkFlashSaleParams(
        address saleSetter,
        address tokenAddress,
        uint id,
        uint amount,
        uint price,
        uint purchaseLimitation,
        uint startTime
    )
    private
    view
    {
        // check whether the sale setter has the target tokens && approval
        IERC1155 tokenAddressCached = IERC1155(tokenAddress);
        require(
            tokenAddressCached.balanceOf(saleSetter, id) >= amount,
            "insufficient amount of ERC1155"
        );
        require(
            tokenAddressCached.isApprovedForAll(saleSetter, address(this)),
            "the contract hasn't been approved for ERC1155 transferring"
        );
        require(amount > 0, "the amount must be > 0");
        require(price > 0, "the price must be > 0");
        require(startTime >= now, "startTime must be >= now");
        require(purchaseLimitation > 0, "purchaseLimitation must be > 0");
        require(purchaseLimitation <= amount, "purchaseLimitation must be <= amount");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Dependencies/IERC1155.sol";
import "./Dependencies/IERC1155MetadataURI.sol";
import "./Dependencies/IERC1155Receiver.sol";
import "./Dependencies/Context.sol";
import "./Dependencies/IERC165.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/Address.sol";
import "./Dependencies/StringLibrary.sol";
import "./Dependencies/Ownable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `_interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `_interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


contract HasContractURI is ERC165 {
    string private _contractURI;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    constructor(string memory contractURI) public {
        _contractURI = contractURI;
        _registerInterface(_INTERFACE_ID_CONTRACT_URI);
    }

    /**
     * @dev Internal function to set the contract URI
     * @param contractURI string URI prefix to assign
     */
    function _setContractURI(string memory contractURI) internal {
        _contractURI = contractURI;
    }

    function getContractURI() public view returns (string memory){
        return _contractURI;
    }
}


abstract contract HasCopyright is ERC165 {

    struct Copyright {
        address author;
        uint256 feeRateNumerator;
    }

    uint private constant _feeRateDenominator = 10000;

    event SetCopyright(
        uint256 id,
        address creator,
        address author,
        uint256 feeRateNumerator,
        uint256 feeRateDenominator
    );

    /*
     * bytes4(keccak256('getCopyright(uint256)')) == 0x6f4eaff1
     */
    bytes4 private constant _INTERFACE_ID_COPYRIGHT = 0x6f4eaff1;

    // Mapping from id to copyright
    mapping(uint256 => Copyright) internal _copyrights;

    constructor() public {
        _registerInterface(_INTERFACE_ID_COPYRIGHT);
    }

    function _setCopyright(uint256 id, address creator, Copyright[] memory copyrightInfos) internal {
        uint256 copyrightLen = copyrightInfos.length;
        require(copyrightLen <= 1,
            "the length of copyrights must be <= 1");
        if (copyrightLen == 1) {
            require(copyrightInfos[0].author != address(0),
                "the author in copyright can't be zero"
            );
            require(copyrightInfos[0].feeRateNumerator <= _feeRateDenominator,
                "the feeRate in copyright must be <= 1"
            );

            _copyrights[id] = copyrightInfos[0];
            emit SetCopyright(id, creator, copyrightInfos[0].author, copyrightInfos[0].feeRateNumerator, _feeRateDenominator);
        }
    }

    function getFeeRateDenominator() public pure returns (uint256){
        return _feeRateDenominator;
    }

    function getCopyright(uint256 id) public view virtual returns (Copyright memory);
}


contract ERC1155Base is Context, IERC1155MetadataURI, HasCopyright, HasContractURI {
    using SafeMath for uint256;
    using Address for address;
    using StringLibrary for string;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token URI prefix
    string private _tokenURIPrefix;

    // Mapping from id to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from id to token uri
    mapping(uint256 => string) private _uris;

    // Mapping from id to token supply
    mapping(uint256 => uint256) private _tokenSupply;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    constructor (
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory tokenURIPrefix
    )
    HasContractURI(contractURI)
    public {
        _name = name;
        _symbol = symbol;
        _tokenURIPrefix = tokenURIPrefix;

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 id) external view virtual override returns (string memory) {
        _requireTokenExisted(id);
        return _tokenURIPrefix.append(_uris[id]);
    }

    function getTokenSupply(uint256 id) external view returns (uint256){
        _requireTokenExisted(id);
        return _tokenSupply[id];
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
    public
    view
    virtual
    override
    returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
    public
    virtual
    override
    {
        require(to != address(0), "transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
    public
    virtual
    override
    {
        require(ids.length == amounts.length, "ids and amounts length mismatch");
        require(to != address(0), "transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function getName() external view returns (string memory){
        return _name;
    }

    function getSymbol() external view returns (string memory){
        return _symbol;
    }

    function getTokenURIPrefix() external view returns (string memory){
        return _tokenURIPrefix;
    }

    function getCopyright(uint256 id) public view override returns (Copyright memory){
        _requireTokenExisted(id);
        return _copyrights[id];
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(uint256 id, address account, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _tokenSupply[id] = amount;
        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
    internal
    virtual
    {}

    /**
     * @dev Internal function to set the token URI for a given token.
     * @param id uint256 ID of the token to set its URI
     * @param tokenURI string URI to assign
     */
    function _setTokenURI(uint256 id, string memory tokenURI) internal {
        _uris[id] = tokenURI;
        emit URI(tokenURI, id);
    }

    /**
     * @dev Internal function to set the token URI prefix.
     * @param tokenURIPrefix string URI prefix to assign
     */
    function _setTokenURIPrefix(string memory tokenURIPrefix) internal {
        _tokenURIPrefix = tokenURIPrefix;
    }

    function _requireTokenExisted(uint256 id) private view {
        require(_tokenSupply[id] != 0, "target token doesn't exist");
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
    private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
    private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


contract MintableERC1155 is Ownable, ERC1155Base {
    using SafeMath for uint256;

    uint256 private _idCounter;

    constructor (
        string memory name,
        string memory symbol,
        address newOwner,
        string memory contractURI,
        string memory tokenURIPrefix
    )
    public
    ERC1155Base(name, symbol, contractURI, tokenURIPrefix)
    {
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
        transferOwnership(newOwner);
    }

    function mint(
        address receiver,
        uint256 amount,
        string memory tokenURI,
        bytes memory data,
        Copyright[] memory copyrightInfos
    ) external {
        require(amount > 0, "amount to mint must be > 0");
        // 1. get id with auto-increment
        uint256 currentId = _idCounter;
        _idCounter = _idCounter.add(1);

        // 2. mint
        _mint(currentId, receiver, amount, data);

        // 3. set tokenURI
        _setTokenURI(currentId, tokenURI);

        // 4. set copyright
        _setCopyright(currentId, msg.sender, copyrightInfos);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) external onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
    external
    returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
    external
    returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./UintLibrary.sol";

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library UintLibrary {
    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Dependencies/Ownable.sol";

contract OKCaller is Ownable {

    address public erc721Address;
    //0x1b78fbf0433bdd22d7e7f30dc6ac54de33df3729 bsc测试网的mint721
    constructor ( address nftAddress ) public {

        erc721Address = nftAddress;

    }

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    mapping(uint => bytes32) public blackListMap;

    address public serverAddress;

    function setServerAddress(address targetAddress) public onlyOwner{
        serverAddress = targetAddress;
    }

    function proxy(address dest, HowToCall howToCall, bytes memory calldataValue,uint salesId,bytes32 hash,uint8 v, bytes32 r, bytes32 s)
    public

    {
        require(ecrecover(hash, v, r, s) == serverAddress,"verify server sign failed") ;
        require(blackListMap[salesId] != hash,"hash is already in use") ;

        if (howToCall == HowToCall.Call) {
            dest.call(calldataValue);
        } else if (howToCall == HowToCall.DelegateCall) {
            dest.delegatecall(calldataValue);
        }

        blackListMap[salesId] = hash;
    }

}