/**
 *Submitted for verification at polygonscan.com on 2023-04-07
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
    function mint(address _to) external;
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

    IERC20 public token;
    uint8 public tokenDecimals;
    uint256 public tokenAmount;
    IERC20 public currency;
    uint8 public currencyDecimals;
    uint256 public price;
    uint256 public discount;
    uint256 public target;
    uint256 public duration;
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

    uint256 private pkPercentage;
    uint256 private toPolykick;
    uint256 private toExchange;

    bool public success = false;
    bool public fundsReturn = false;
    bool public isDiscount = false;
    bool public allowMintNFT = false;
    bool public isInitiated = false;

    bool public adminApproval;

    struct buyerVault {
        uint256 tokenAmount;
        uint256 currencyPaid;
    }

    mapping(address => bool) public isWhitelisted;
    mapping(address => buyerVault) public buyer;
    mapping(address => bool) public isBuyer;
    mapping(address => bool) public isAdmin;

    event approveILO(string Result);
    event tokenSale(uint256 CurrencyAmount, uint256 TokenAmount);
    event tokenWithdraw(address Buyer, uint256 Amount);
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
    /* @dev: Check if contract owner and admin */
    modifier onlyOwnerAndAdmin() {
        require(
            msg.sender == polyWallet && adminApproval,
            "Only after approval by owner and admin"
        );
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
        uint256 _target,
        uint256 _duration,
        uint256 _pkPercentage,
        uint256 _toPolykick,
        uint256 _toExchange
    ) {
        factoryContract = polyFactory(msg.sender);
        seller = _seller;
        polyWallet = _polyKick;
        //polyKickDAO = _polyKick;
        token = _token;
        tokenDecimals = _tokenDecimals;
        tokenAmount = _tokenAmount;
        currency = _currency;
        price = _price;
        target = _target;
        duration = _duration;
        pkPercentage = _pkPercentage;
        toPolykick = _toPolykick;
        toExchange = _toExchange;
        //minBuyMax(100, 10000, _price, 6); //minAmount = tokenAmount.mul(1).div(1000);
        maxAmount = tokenAmount.mul(1).div(100);
        _status = _NOT_ENTERED;
        notSold = _tokenAmount;
        discount = price.mul(80).div(100); //20% discount price
        isAdmin[polyWallet] = true;
    }

    function initiateILO() public {
        require(!isInitiated, "ILO is initiated");
        polyKickDAO = factoryContract.polyKickDAO();
        setCurrencyDecimals();
        minBuyMax(100, 13000, price, currencyDecimals);
        isInitiated = true;
    }

    function setAdminApproval() external onlyAdmin {
        require(
            msg.sender != polyWallet,
            "This is the owner you need another admin"
        );
        adminApproval = true;
    }

    function addAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Address zero!");
        require(!isAdmin[_newAdmin], "Admin exist");
        isAdmin[_newAdmin] = true;

        // Reset the admin approval after the function call
        adminApproval = false;
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(isAdmin[_admin], "Admin does not exist");
        isAdmin[_admin] = false;

        // Reset the admin approval after the function call
        adminApproval = false;
    }

    function setPolyDAO(address _DAO) external onlyAdmin {
        require(_DAO != address(0), "Address 0");
        polyKickDAO = _DAO;

        // Reset the admin approval after the function call
        adminApproval = false;
    }

    function setPolyNFT(address _polyNFT) external onlyAdmin {
        nftContract = polyNFT(_polyNFT);

        // Reset the admin approval after the function call
        adminApproval = false;
    }

    function setAllowMintNFT(bool _true_false) external onlyAdmin {
        allowMintNFT = _true_false;

        // Reset the admin approval after the function call
        adminApproval = false;
    }

    function isActive() public view returns (bool) {
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

    function setCurrencyDecimals() internal {
        (, uint8 returnedDecimals) = factoryContract.allowedCurrencies(currency);
        currencyDecimals = returnedDecimals;
    }

    function iloInfo()
        public
        view
        returns (
            uint256 tokensSold,
            uint256 tokensRemaining,
            uint256 Price,
            uint256 Sales,
            uint256 Buyers,
            uint256 USDcollected
        )
    {
        return (
            soldAmounts,
            notSold,
            price,
            salesCount,
            buyersCount,
            sellerVault
        );
    }

    function setDiscount(uint256 _discount, bool _isDiscount)
        external
        onlyOwner
    {
        require(_discount < 99 && _discount > 0, "discount error");
        uint256 dis = 100 - _discount;
        discount = price.mul(dis).div(100);
        isDiscount = _isDiscount;
        emit discountSet(discount, _isDiscount);
    }

    function addToWhiteListBulk(address[] memory _allowed) external onlyAdmin {
        if (!isInitiated) {
            initiateILO();
        }
        for (uint256 i = 0; i < _allowed.length; i++) {
            require(_allowed[i] != address(0x0), "Zero aadress!");
            isWhitelisted[_allowed[i]] = true;
        }
    }

    function addToWhiteList(address _allowed) external onlyAdmin {
        if (!isInitiated) {
            initiateILO();
        }
        require(_allowed != address(0x0), "Zero aadress!");
        isWhitelisted[_allowed] = true;
        emit whiteList(_allowed, isWhitelisted[_allowed]);
    }

    function extendILO(uint256 _duration) external onlyAdmin {
        require(duration != 0, "ILO has ended");
        fundsReturn = true;
        duration = _duration.add(block.timestamp);
    }

    function buyTokens(uint256 _amountToPay) external nonReentrant {
        require(
            isWhitelisted[msg.sender] == true,
            "You need to be whitelisted for this ILO"
        );
        require(isActive(), "ILO Ended!");

        uint256 amount = _amountToPay * 10**tokenDecimals;
        uint256 finalAmount;
        if (isDiscount == true) {
            finalAmount = amount.div(discount); //pricePerToken;
        } else {
            finalAmount = amount.div(price); //pricePerToken;
        }
        require(
            buyer[msg.sender].tokenAmount.add(finalAmount) <= maxAmount,
            "Limit reached"
        );
        require(finalAmount >= minAmount, "Amount is under minimum allocation");
        require(finalAmount <= maxAmount, "Amount is over maximum allocation");
        emit tokenSale(_amountToPay, finalAmount);
        //The transfer requires approval from currency smart contract
        currency.transferFrom(msg.sender, address(this), _amountToPay);
        sellerVault += _amountToPay;
        buyer[msg.sender].tokenAmount += finalAmount;
        buyer[msg.sender].currencyPaid += _amountToPay;
        soldAmounts += finalAmount;
        notSold -= finalAmount;
        if (isBuyer[msg.sender] != true) {
            isBuyer[msg.sender] = true;
            buyersCount++;
        }
        salesCount++;
    }

    function iloApproval() external onlyAdmin {
        require(!isActive(), "ILO has not ended yet!");
        if (soldAmounts >= target) {
            duration = 0;
            success = true;
            token.transfer(burn, notSold);
            emit approveILO("ILO Succeed");
        } else {
            duration = 0;
            success = false;
            fundsReturn = true;
            sellerVault = 0;
            emit approveILO("ILO Failed");
        }
    }

    function succeedILO() external onlyAdmin {
        uint256 fivePercent = target.mul(5).div(100);
        require(
            soldAmounts >= target.sub(fivePercent),
            "Target is not reached"
        );
        duration = 0;
        success = true;
        token.transfer(burn, notSold);
        emit approveILO("ILO Succeed");
    }

    function setMinMax(uint256 _minAmount, uint256 _maxAmount)
        external
        onlyAdmin
    {
        minBuyMax(_minAmount, _maxAmount, price, currencyDecimals);
    }

    function withdrawTokens() external nonReentrant {
        require(isBuyer[msg.sender] == true, "Not a Buyer");
        require(success == true, "ILO Failed");
        if (allowMintNFT == true) {
            nftContract.mint(msg.sender);
        }
        uint256 buyerAmount = buyer[msg.sender].tokenAmount;
        emit tokenWithdraw(msg.sender, buyerAmount);
        token.transfer(msg.sender, buyerAmount);
        soldAmounts -= buyerAmount;
        buyer[msg.sender].tokenAmount -= buyerAmount;
        isBuyer[msg.sender] = false;
    }

    function returnFunds() external nonReentrant {
        //require(block.timestamp > duration, "ILO has not ended yet!");
        require(isBuyer[msg.sender] == true, "Not a Buyer");
        require(
            success == false && fundsReturn == true,
            "ILO Succeed try withdrawTokens"
        );
        uint256 buyerAmount = buyer[msg.sender].currencyPaid;
        emit CurrencyReturned(msg.sender, buyerAmount);
        currency.transfer(msg.sender, buyerAmount);
        buyer[msg.sender].currencyPaid -= buyerAmount;
        isBuyer[msg.sender] = false;
    }

    function sellerWithdraw() external nonReentrant {
        require(msg.sender == seller, "Not official seller");
        require(block.timestamp > duration, "ILO has not ended yet!");
        if (success == true) {
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
    }

    function emergencyRefund(uint256 _confirm) external onlyAdmin {
        require(success != true, "ILO is successful");
        require(isActive(), "ILO has ended use approveILO");
        require(_confirm == 369, "Wrong confirmation code");
        success = false;
        fundsReturn = true;
        sellerVault = 0;
        emit approveILO("ILO Failed");
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

// File: contracts/polyFactoryFinal.sol


pragma solidity 0.8.19;



contract PolyKick_Factory {
    PolyKick_ILO private pkILO;

    uint256 public projectsAllowed;
    uint256 public projectsCount;
    address public owner;
    address public polyKickDAO = 0xE1be41e3AD6945e36d58a3b8B18181a21497d497;
    uint256 private pID;
    uint256 private toPolykick;
    uint256 private toExchange;
    uint256 public countILO;

    event projectAdded(
        uint256 ProjectID,
        string ProjectName,
        IERC20 ProjectToken,
        address ProjectOwner
    );
    event ILOCreated(address pkILO);
    event ChangeOwner(address NewOwner);

    struct allowedProjects {
        uint256 projectID;
        string projectName;
        address projectOwner;
        IERC20 projectToken;
        uint8 tokenDecimals;
        IERC20 currency;
        address ILO;
        uint256 rounds;
        uint256 totalAmounts;
        uint256 polyKickPercentage;
        bool projectStatus;
        bool isTarget;
    }

    struct Currencies {
        string name;
        uint8 decimals;
    }
    mapping(IERC20 => Currencies) public allowedCurrencies;
    mapping(IERC20 => bool) public isCurrency;
    mapping(IERC20 => bool) public isProject;
    mapping(IERC20 => allowedProjects) public projectsByID;

    mapping(address => bool) public isAdmin;

    /* @dev: Check if contract owner */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner!");
        _;
    }

    /* @dev: Check if contract owner */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Not Admin!");
        _;
    }

    constructor() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        pID = 0;
    }

    /*
    @dev: Change the contract owner
*/
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0x0), "Zero Address");
        emit ChangeOwner(_newOwner);
        owner = _newOwner;
    }

    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0x0), "zero address");
        isAdmin[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        require(_admin != address(0x0), "zero address");
        isAdmin[_admin] = false;
    }

    function addCurrency(
        string memory _name,
        IERC20 _currency,
        uint8 _decimal
    ) external onlyAdmin {
        //can also fix incase of wrong data
        allowedCurrencies[_currency].name = _name;
        allowedCurrencies[_currency].decimals = _decimal;
        isCurrency[_currency] = true;
    }

    function addProject(
        string memory _name,
        IERC20 _token,
        uint8 _tokenDecimals,
        address _projectOwner,
        uint256 _polyKickPercentage,
        IERC20 _currency,
        uint256 _toPolykick,
        uint256 _toExchange
    ) external onlyAdmin returns (uint256) {
        require(isProject[_token] != true, "Project already exist!");
        require(isCurrency[_currency] == true, "Not a currency");
        require(_polyKickPercentage <= 24, "Max is 24 %");
        pID++;
        uint8 dcml = allowedCurrencies[_currency].decimals;
        toPolykick = _toPolykick * 10**dcml;
        toExchange = _toExchange * 10**dcml;
        projectsByID[_token].projectID = pID;
        projectsByID[_token].projectName = _name;
        projectsByID[_token].projectOwner = _projectOwner;
        projectsByID[_token].projectToken = _token;
        projectsByID[_token].tokenDecimals = _tokenDecimals;
        projectsByID[_token].currency = _currency;
        projectsByID[_token].projectStatus = true;
        isProject[_token] = true;
        projectsByID[_token].polyKickPercentage = _polyKickPercentage;
        projectsAllowed++;
        emit projectAdded(pID, _name, _token, _projectOwner);
        return (pID);
    }

    function projectNewRound(IERC20 _token, IERC20 _currency)
        external
        onlyAdmin
    {
        projectsByID[_token].projectStatus = true;
        projectsByID[_token].currency = _currency;
        toPolykick = 0;
        toExchange = 0;
    }

    function targetTo(
        uint256 _target,
        uint256 _price,
        IERC20 _token
    ) internal {
        uint8 tDcml = projectsByID[_token].tokenDecimals;
        uint256 trg = _target / 10**tDcml;
        uint256 trPrice = trg * _price;
        uint256 payTo = (toPolykick + toExchange);
        require(trPrice > payTo * 2, "Target does not cover payments");
        projectsByID[_token].isTarget = true;
    }

    function startILO(
        IERC20 _token,
        uint256 _tokenAmount,
        uint256 _price,
        uint8 _priceDecimals,
        uint256 _target,
        uint256 _days
    ) external onlyAdmin {
        IERC20 _currency = projectsByID[_token].currency;
        require(isProject[_token] == true, "Project is not allowed!");
        require(
            projectsByID[_token].projectStatus == true,
            "ILO was initiated"
        );
        require(
            _token.balanceOf(msg.sender) >= _tokenAmount,
            "Not enough tokens"
        );
        require(
            _priceDecimals <= allowedCurrencies[_currency].decimals,
            "Decimal err"
        );
        projectsByID[_token].projectStatus = false;
        uint256 _pkP = projectsByID[_token].polyKickPercentage;
        uint256 price = _price *
            10**(allowedCurrencies[_currency].decimals - _priceDecimals);
        uint8 _tokenDecimals = projectsByID[_token].tokenDecimals;
        uint256 _duration = (_days * 1 days) + block.timestamp;
        targetTo(_target, price, _token);
        require(projectsByID[_token].isTarget == true, "is target!");
        pkILO = new PolyKick_ILO(
            projectsByID[_token].projectOwner,
            owner,
            _token,
            _tokenDecimals,
            _tokenAmount,
            _currency,
            price,
            _target,
            _duration,
            _pkP,
            toPolykick,
            toExchange
        );
        emit ILOCreated(address(pkILO));
        _token.transferFrom(msg.sender, address(pkILO), _tokenAmount);
        projectsCount++;
        registerILO(_token, _tokenAmount);
    }

    function registerILO(IERC20 _token, uint256 _tokenAmount) internal {
        projectsByID[_token].rounds++;
        projectsByID[_token].totalAmounts += _tokenAmount;
        projectsByID[_token].ILO = address(pkILO);
    }
}

                /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/