/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity 0.8.19;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.19;

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

// File: contracts/PolyKick_ILO.sol


pragma solidity 0.8.19;



interface polyNFT {
    function mint(address) external;

    function balanceOf(address) external view returns (uint256);

    function tokenDetails(address)
        external
        view
        returns (
            uint256,
            uint256,
            string memory
        );

    function useNFT(address) external;
}

interface polyFactory {
    function polyKickDAO() external view returns (address);

    function owner() external view returns (address);

    function allowedCurrencies(IERC20 _token)
        external
        view
        returns (string memory, uint8);
}

contract PolyKick_ILO {
    using SafeMath for uint256;

    polyNFT public nftContract;
    polyFactory public factoryContract;

    address public constant burn = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    uint256 firstRun;

    IERC20 public token;
    uint8 public tokenDecimals;
    uint256 public tokenAmount;
    IERC20 public currency;
    uint8 public currencyDecimals;
    uint256 public Price;
    uint256 public firstPrice;
    uint256 public softCap;
    uint256 public duration;
    uint256 public preMaxAmount;
    uint256 public preMinAmount;
    uint256 public preMaxC;
    uint256 public preMinC;
    uint256 public maxAmount;
    uint256 public minAmount;
    uint256 public maxC;
    uint256 public minC;
    uint256 public salesCount;
    uint256 public buyersCount;

    address public seller;
    address public polyWallet;
    address public polyKickDAO;

    uint256 public sellerVault;
    uint256 public soldAmounts;
    uint256 public notSold;
    uint256 public tokensBurned;
    uint256 public raisedAmount;

    uint256 private pkPercentage;
    uint256 private toPolykick;
    uint256 private toExchange;

    bool public success = false;
    bool public fundsReturn = false;
    bool public allowMintNFT = false;
    bool public isInitiated = false;

    address[] public buyersList;

    struct buyerVault {
        uint256 tokenAmount;
        uint256 currencyPaid;
        uint256 txCount;
        bool isClaimed;
    }

    mapping(address => bool) public isWhitelisted;
    mapping(address => buyerVault) public buyer;
    mapping(address => bool) public isBuyer;
    mapping(address => bool) public isAdmin;


    event iloInitiated(bool status);
    event approveILO(string Result);
    event successfulILO(
        string Results,
        uint256 TokensSold,
        uint256 TokensRemaining,
        uint256 TokensBurned,
        uint256 RaisedAmount
    );
    event tokenSale(uint256 CurrencyAmount, uint256 TokenAmount);
    event tokenWithdraw(address indexed buyer, uint256 amount);
    event CurrencyReturned(address Buyer, uint256 Amount);
    event discountSet(uint256 Discount, bool Status);
    event whiteList(address Buyer, bool Status);

    /* @dev: Check if Admin */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Not Admin!");
        _;
    }
    /* @dev: Check if contract owner */
    modifier onlyOwner() {
        require(msg.sender == polyWallet, "Not Owner!");
        _;
    }

    /*
    @dev: prevent reentrancy when function is executed
*/
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(
        address _seller,
        address _polyKick,
        IERC20 _token,
        uint8 _tokenDecimals,
        uint256 _tokenAmount,
        IERC20 _currency,
        uint256 _price,
        uint256 _softCap,
        uint256 _duration,
        uint256 _pkPercentage,
        uint256 _toPolykick,
        uint256 _toExchange
    ) {
        factoryContract = polyFactory(msg.sender);
        seller = _seller;
        polyWallet = _polyKick;
        token = _token;
        tokenDecimals = _tokenDecimals;
        tokenAmount = _tokenAmount;
        currency = _currency;
        Price = _price;
        softCap = _softCap;
        duration = _duration;
        pkPercentage = _pkPercentage;
        toPolykick = _toPolykick;
        toExchange = _toExchange;
        _status = _NOT_ENTERED;
        notSold = _tokenAmount;
        isAdmin[polyWallet] = true;
    }

    function initiateILO(
        uint256 _firstRun,
        uint256 _firstPrice,
        uint256 _preMin,
        uint256 _preMax,
        uint256 _min,
        uint256 _max
    ) external onlyAdmin {
        require(!isInitiated, "ILO is initiated");
        polyKickDAO = factoryContract.polyKickDAO();
        setCurrencyDecimals();
        firstRun = _firstRun.mul(1 hours).add(block.timestamp);
        firstPrice = _firstPrice;
        preMinBuyMax(_preMin, _preMax, firstPrice, currencyDecimals);
        minBuyMax(_min, _max, Price, currencyDecimals);
        isInitiated = true;
        emit iloInitiated(isInitiated);
    }

    function addAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Address zero!");
        require(!isAdmin[_newAdmin], "Admin exist");
        isAdmin[_newAdmin] = true;
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(isAdmin[_admin], "Admin does not exist");
        isAdmin[_admin] = false;
    }

    function setPolyDAO(address _DAO) external onlyAdmin {
        require(_DAO != address(0), "Address 0");
        polyKickDAO = _DAO;
    }

    function setPolyNFT(address _polyNFT) external onlyAdmin {
        require(_polyNFT != address(0), "Address 0");
        nftContract = polyNFT(_polyNFT);
    }

    function setAllowMintNFT(bool _true_false) external onlyAdmin {
        allowMintNFT = _true_false;
    }

    function isActive() public view returns (bool) {
        require(isInitiated, "ILO is not initiated yet");
        if (duration < block.timestamp) {
            return false;
        } else {
            return true;
        }
    }

    function minBuyMax(
        uint256 minAmt,
        uint256 maxAmt,
        uint256 _price,
        uint8 _dcml
    ) internal {
        uint256 min = minAmt * 10**_dcml;
        uint256 max = maxAmt * 10**_dcml;
        minAmount = (min.div(_price)) * 10**tokenDecimals;
        maxAmount = (max.div(_price)) * 10**tokenDecimals;
        minC = minAmt;
        maxC = maxAmt;
    }

    function preMinBuyMax(
        uint256 minAmt,
        uint256 maxAmt,
        uint256 _price,
        uint8 _dcml
    ) internal {
        uint256 min = minAmt * 10**_dcml;
        uint256 max = maxAmt * 10**_dcml;
        preMinAmount = (min.div(_price)) * 10**tokenDecimals;
        preMaxAmount = (max.div(_price)) * 10**tokenDecimals;
        preMinC = minAmt;
        preMaxC = maxAmt;
    }

    function setCurrencyDecimals() internal {
        (, uint8 returnedDecimals) = factoryContract.allowedCurrencies(
            currency
        );
        currencyDecimals = returnedDecimals;
    }

    function getRaised() public view returns (uint256 _raised) {
        if (sellerVault != 0) {
            _raised = sellerVault.div(10**currencyDecimals);
        }
        return _raised;
    }

    function iloInfo()
        public
        view
        returns (
            uint256 tokensSold,
            uint256 tokensRemaining,
            uint256 burned,
            uint256 price,
            uint256 sales,
            uint256 participants,
            uint256 raised
        )
    {
        if (tokensBurned != 0) {
            burned = tokensBurned.div(10**tokenDecimals);
        } else {
            burned = 0;
        }
        raised = getRaised();
        if (raised == 0) {
            raised = raisedAmount.div(10**currencyDecimals);
        }
        return (
            soldAmounts.div(10**tokenDecimals),
            notSold.div(10**tokenDecimals),
            burned,
            Price,
            salesCount,
            buyersCount,
            raised
        );
    }

    function addToWhiteListBulk(address[] memory _allowed) external onlyAdmin {
        for (uint256 i = 0; i < _allowed.length; i++) {
            require(_allowed[i] != address(0x0), "Zero aadress!");
            isWhitelisted[_allowed[i]] = true;
        }
    }

    function addToWhiteList(address _allowed) external onlyAdmin {
        require(_allowed != address(0x0), "Zero aadress!");
        isWhitelisted[_allowed] = true;
        emit whiteList(_allowed, isWhitelisted[_allowed]);
    }

    function extendILO(uint256 _duration) external onlyAdmin {
        require(duration != 0, "ILO has ended");
        fundsReturn = true;
        duration = _duration.add(block.timestamp);
    }

    function isSoftCap() public view returns (bool) {
        if (soldAmounts < softCap) {
            return true;
        } else {
            return false;
        }
    }

    function checkFirstRun() public view returns (bool) {
        if (block.timestamp < firstRun) {
            return true;
        } else {
            return false;
        }
    }

    function allowedToBuy(address _buyer) public view returns (bool) {
        if (nftContract.balanceOf(_buyer) > 0) {
            (, uint256 _ILOs, ) = nftContract.tokenDetails(_buyer);
            require(_ILOs > 0, "Need Poly NFT");
            return true;
        } else {
            return false;
        }
    }

    function buyTokens(uint256 _amountToPay) external nonReentrant {
        require(
            isWhitelisted[msg.sender] == true,
            "You need to be whitelisted for this ILO"
        );
        require(isActive(), "ILO is not active!");
        if (checkFirstRun()) {
            require(
                allowedToBuy(msg.sender) == true,
                "firstRun: Not NFT Holder"
            );
        }
        uint256 amount = _amountToPay * 10**tokenDecimals;
        uint256 finalAmount;

        if (isSoftCap() && allowedToBuy(msg.sender)) {
            finalAmount = amount.div(firstPrice); //pricePerToken;
            require(
                buyer[msg.sender].tokenAmount.add(finalAmount) <= maxAmount,
                "Limit reached"
            );
            if (buyer[msg.sender].txCount == 0) {
                require(
                    finalAmount >= minAmount,
                    "Amount is under minimum allocation"
                );
                nftContract.useNFT(msg.sender); // remove 1 ILO participation from NFT holder
            }
            require(
                finalAmount <= maxAmount,
                "Amount is over maximum allocation"
            );
        } else if (isSoftCap()) {
            finalAmount = amount.div(firstPrice); //pricePerToken;
            require(
                buyer[msg.sender].tokenAmount.add(finalAmount) <= preMaxAmount,
                "Limit reached"
            );
            if (buyer[msg.sender].txCount == 0) {
                require(
                    finalAmount >= preMinAmount,
                    "Amount is under pre-minimum allocation"
                );
            }
            require(finalAmount <= preMaxAmount, "Above pre-maximum!");
        } else {
            finalAmount = amount.div(Price); //pricePerToken;
            require(
                buyer[msg.sender].tokenAmount.add(finalAmount) <= maxAmount,
                "Limit reached"
            );
            if (buyer[msg.sender].txCount == 0) {
                require(
                    finalAmount >= minAmount,
                    "Amount is under minimum allocation"
                );
            }
            require(
                finalAmount <= maxAmount,
                "Amount is over maximum allocation"
            );
        }

        emit tokenSale(_amountToPay, finalAmount);
        require(
            currency.allowance(msg.sender, address(this)) >= _amountToPay,
            "Check currency allowance"
        );
        require(
            currency.transferFrom(msg.sender, address(this), _amountToPay),
            "Check currency balance"
        );
        sellerVault += _amountToPay;
        buyer[msg.sender].tokenAmount += finalAmount;
        buyer[msg.sender].currencyPaid += _amountToPay;
        soldAmounts += finalAmount;
        notSold -= finalAmount;
        if (isBuyer[msg.sender] != true) {
            isBuyer[msg.sender] = true;
            buyersList.push(msg.sender);
            buyersCount++;
        }
        salesCount++;
        buyer[msg.sender].txCount++;
    }

    function iloApproval() external onlyAdmin {
        require(!isActive(), "ILO has not ended yet!");
        if (soldAmounts >= softCap) {
            duration = 0;
            success = true;
            tokensBurned = notSold;
            token.transfer(burn, notSold);
            emit successfulILO(
                "ILO Succeed",
                soldAmounts,
                notSold,
                tokensBurned,
                sellerVault
            );
        } else {
            duration = 0;
            success = false;
            fundsReturn = true;
            sellerVault = 0;
            emit approveILO("ILO Failed");
        }
    }

    function succeedILO() external onlyAdmin {
        uint256 tenPercent = softCap.mul(10).div(100);
        require(
            soldAmounts >= softCap.sub(tenPercent),
            "softCap is not reached"
        );
        duration = 0;
        success = true;
        tokensBurned = notSold;
        token.transfer(burn, notSold);
        emit successfulILO(
            "ILO Succeed",
            soldAmounts,
            notSold,
            tokensBurned,
            sellerVault
        );
    }

    function setMinMax(uint256 _minAmount, uint256 _maxAmount)
        external
        onlyAdmin
    {
        minBuyMax(_minAmount, _maxAmount, Price, currencyDecimals);
    }

    function withdrawTokens(address _buyer) public nonReentrant {
        require(isBuyer[_buyer] == true, "Not a Buyer");
        require(success == true, "ILO Failed");
        if (allowMintNFT == true) {
            nftContract.mint(_buyer);
        }
        uint256 buyerAmount = buyer[_buyer].tokenAmount;
        emit tokenWithdraw(_buyer, buyerAmount);
        token.transfer(_buyer, buyerAmount);
        buyer[_buyer].tokenAmount -= buyerAmount;
        isBuyer[_buyer] = false;
        buyer[_buyer].isClaimed = true;
    }

    function returnFunds(address _buyer) public nonReentrant {
        require(isBuyer[_buyer] == true, "Not a Buyer");
        require(
            success == false && fundsReturn == true,
            "ILO Succeed try withdrawTokens"
        );
        uint256 buyerAmount = buyer[_buyer].currencyPaid;
        emit CurrencyReturned(_buyer, buyerAmount);
        currency.transfer(_buyer, buyerAmount);
        buyer[_buyer].currencyPaid -= buyerAmount;
        buyer[_buyer].tokenAmount = 0;
        isBuyer[_buyer] = false;
        buyer[_buyer].isClaimed = true;
    }

    function airDrop(uint256 start, uint256 end) public nonReentrant {
        require(end <= buyersList.length, "end out of range");
        require(start <= end, "Invalid range");

        if (success == true) {
            for (uint256 i = start; i < end; i++) {
                address _buyer = buyersList[i];
                if (
                    isBuyer[_buyer] == true && buyer[_buyer].isClaimed == false
                ) {
                    withdrawTokens(_buyer);
                }
            }
        } else if (fundsReturn == true) {
            for (uint256 i = start; i < end; i++) {
                address _buyer = buyersList[i];
                if (
                    isBuyer[_buyer] == true && buyer[_buyer].isClaimed == false
                ) {
                    returnFunds(_buyer);
                }
            }
        }
    }

    function sellerWithdraw() external nonReentrant {
        require(msg.sender == seller, "Not official seller");
        require(!isActive(), "ILO is active!");
        if (success == true) {
            require(sellerVault != 0, "Seller claimed raised!");
            raisedAmount = sellerVault;
            uint256 polyKickAmount = sellerVault.mul(pkPercentage).div(100);
            uint256 totalPolykick = polyKickAmount.add(toPolykick);
            uint256 sellerAmount = sellerVault.sub(totalPolykick).sub(
                toExchange
            );
            if (toExchange > 0) {
                currency.transfer(polyWallet, toExchange);
            }
            currency.transfer(polyKickDAO, polyKickAmount);
            currency.transfer(polyKickDAO, toPolykick);
            currency.transfer(seller, sellerAmount);
        } else if (success == false) {
            token.transfer(seller, token.balanceOf(address(this)));
        }
        sellerVault = 0;
    }

    function emergencyRefund(uint256 _confirm) external onlyAdmin {
        require(success != true, "ILO is successful");
        require(isActive(), "ILO has ended use approveILO");
        require(_confirm == 369, "Wrong confirmation code");
        success = false;
        fundsReturn = true;
        sellerVault = 0;
        duration = 0;
        emit approveILO("ILO Failed");
    }

    function getBuyerTokenAmounts()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory tokenAmounts = new uint256[](buyersList.length);
        address[] memory buyerAddresses = new address[](buyersList.length);

        for (uint256 i = 0; i < buyersList.length; i++) {
            uint256 _tokenAmount = buyer[buyersList[i]].tokenAmount;
            tokenAmounts[i] = _tokenAmount / (10**tokenDecimals); // Remove 18 decimals
            buyerAddresses[i] = buyersList[i];
        }

        return (buyerAddresses, tokenAmounts);
    }

    function getUnclaimedBalances()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory tokenAmounts = new uint256[](buyersList.length);
        address[] memory buyerAddresses = new address[](buyersList.length);

        for (uint256 i = 0; i < buyersList.length; i++) {
            uint256 _tokenAmount = buyer[buyersList[i]].tokenAmount;
            if (_tokenAmount > 0) {
                tokenAmounts[i] = _tokenAmount / (10**tokenDecimals); // Remove 18 decimals
                buyerAddresses[i] = buyersList[i];
            }
        }

        return (buyerAddresses, tokenAmounts);
    }

    function getBuyerCurrencyAmounts()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory currencyAmounts = new uint256[](buyersList.length);
        address[] memory buyerAddresses = new address[](buyersList.length);

        for (uint256 i = 0; i < buyersList.length; i++) {
            uint256 _currencyAmount = buyer[buyersList[i]].currencyPaid;
            currencyAmounts[i] = _currencyAmount / (10**currencyDecimals); // Remove 6 decimals
            buyerAddresses[i] = buyersList[i];
        }

        return (buyerAddresses, currencyAmounts);
    }

    /*
   @dev: Withdraw any ERC20 token sent by mistake or extra currency amounts
*/
    function erc20Withdraw(IERC20 _token) external onlyOwner {
        uint256 amountAvailable;
        if (_token == currency) {
            amountAvailable = _token.balanceOf(address(this)).sub(sellerVault);
            require(amountAvailable > 0, "No extra tokens!");
            _token.transfer(polyWallet, amountAvailable);
        } else if (_token == token) {
            amountAvailable = _token.balanceOf(address(this)).sub(tokenAmount);
            require(amountAvailable > 0, "No extra tokens!");
            _token.transfer(polyWallet, amountAvailable);
        } else {
            amountAvailable = _token.balanceOf(address(this));
            _token.transfer(polyWallet, amountAvailable);
        }
    }

    /*
   @dev: people who send Matic by mistake to the contract can withdraw them
*/
    mapping(address => uint256) public balanceReceived;

    function wrongSend() public payable {
        assert(
            balanceReceived[msg.sender] + msg.value >=
                balanceReceived[msg.sender]
        );
        balanceReceived[msg.sender] += msg.value;
    }

    function withdrawWrongTransaction(address payable _to, uint256 _amount)
        public
    {
        require(_amount <= balanceReceived[msg.sender], "not enough funds.");
        assert(
            balanceReceived[msg.sender] >= balanceReceived[msg.sender] - _amount
        );
        balanceReceived[msg.sender] -= _amount;
        _to.transfer(_amount);
    }

    receive() external payable {
        wrongSend();
    }
}

                /*********************************************************
                    Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/