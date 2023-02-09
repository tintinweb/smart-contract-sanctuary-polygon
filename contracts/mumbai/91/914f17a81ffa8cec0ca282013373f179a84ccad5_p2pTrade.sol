/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Ownable {
    error NotOwner(); 

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract ReentrancyGuard {
    error ReentrantCall();
    uint8 private constant _NOT_ENTERED = 1;
    uint8 private constant _ENTERED = 2;
    uint8 private _status = _NOT_ENTERED;

    constructor() {}

    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReentrantCall();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        assembly {
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        assembly {
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }
}

library p2pErrors {
    error CheckLimits(); // 0x60d0a98e
    error SpecifyLargerAmount(); // 0x3e3aefd5
    error SpecifySmallerAmount(); // 0x1647d0f6
    error OrderNotExist(); // 0x69a07471
    error OwnerCantBuyFromHimself(); // 0xba818fbd
    error RatioIsNotEnough(); // 0x4b8fcc33
    error UsdLockIsNotEnough(); // 0x93e11ca0
    error NotOrderOwner(); // 0xf6412b5a
    error NoFreeUsdToCancel(); // 0x47e13d73
    error NotSellerOrBuyer(); // 0xc8eb7947
    error DealClosed(); // 0xc9907ff5
    error CantOpenConflict(); // 0xddd9bcab
    error NotBuyer(); // 0x472e017e
    error NotSeller(); // 0x5ec82351
    error AlreadySigned(); // 0xb0bd6aca
    error NotConflict(); // 0x2f0b21e8
}

interface p2pStructs {
    struct OrderInfo {
        // All payment methods
        string[] methods;
        // assets[0] - What the provider sell
        // assets[1] - What the provider buy
        string[2] assets;
        // ratios[0] - ratio of Asset0 to Asset1
        // ratios[1] - ratio of Asset1 to USD
        uint256[2] ratios;
        // ratio = ratios[0] * ratios[1]
        uint256 ratio;
        // amounts[0] - Initial amount of Asset0
        // amounts[1] - The amount of Asset0 available for buy
        // (without subtracting the locked amount)
        // amounts[2] - The amount of Asset0 locked in deals
        uint256[3] amounts;
        // The amount of locked USD in the order
        uint256 usdLock;
        // limits[0] - Minimum Asset0 amount to buy
        // limits[1] - Maximum  Asset0 amount to buy (if 0 - unlimited)
        uint256[2] limits;
        // The owner of Order
        address orderOwner;
    }

    struct DealInfo {
        // ID of the Order
        uint256 orderId;
        // amounts[0] - Amount of Asset0
        // amounts[1] - Amount of Asset1
        uint256[2] amounts;
        // Collateral in USD for this deal
        uint256 amountUsd;
        // Amount of signatures (2 - deal closed)
        uint8 sign;
        // Has the buyer signed
        bool buyerSigned;
        // Has the seller signed
        bool sellerSigned;
        // Buyer address
        address buyer;
        // Seller address
        address seller;
        // Is the conflict open
        bool isConflict;
        // times[0] - timestamp open
        // times[1] - timestamp close
        uint256[2] times;
    }

    struct UserInfo {
        uint256[] openDeals;
        uint256[] conflictDeals;
    }
}

interface p2pEvents {
    event CreateOrder(uint256 indexed orderId);
    event CreateDeal(uint256 indexed dealId);
    event CancellOrder(uint256 indexed orderId);
    event SetConflict(uint256 indexed dealId);
    event UpdateOrderLimits(uint256 indexed orderId);
    event FastChangeOrder(uint256 indexed orderId);
    event PutSignBuyer(uint256 indexed dealId);
    event PutSignSeller(uint256 indexed dealId);
    event ConfirmDeal(uint256 indexed dealId);
    event DeleteOpenDeal(uint256 indexed dealId);
    event DeleteOrder(uint256 indexed orderId);
    event CloseConflict(uint256 indexed dealId);
    event ConfirmDealByOperator(uint256 indexed dealId, uint8 whoRight);
}

contract p2pTrade is Ownable, ReentrancyGuard, p2pEvents, p2pStructs {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    mapping(address => bool) private _isOperator;

    mapping(string => uint256[]) private ordersByMethod;
    mapping(address => uint256[]) private sellerInfo;

    mapping(address => UserInfo) private userInfo;

    mapping(uint256 => OrderInfo) private orderInfo;

    mapping(uint256 => DealInfo) private dealInfo;

    IERC20 public immutable USD;
    address public FeeRecipient;

    uint32 public fee = 1500;
    uint256 private constant MINIMUM_ASSET = 1;
    uint8 public immutable DECIMALS;
    uint32 private immutable RATIO_FACTOR;

    uint256 public nextOrder;
    uint256 public nextDeal;

    uint256 public timestampToConflict;
    uint256 public minimumUsdOrder;

    modifier onlyOperator() {
        require(_isOperator[msg.sender], "Not operator");
        _;
    }

    constructor(
        IERC20 _usd,
        address _owner,
        address _FeeRecipient,
        uint256 _minimumUsdOrder
    ) payable {
        transferOwnership(_owner);
        minimumUsdOrder = _minimumUsdOrder;
        FeeRecipient = _FeeRecipient;
        USD = _usd;
        DECIMALS = uint8(USD.decimals());
        RATIO_FACTOR = uint32(10**DECIMALS);
    }

    // view

    function isOperator(address account) external view returns (bool) {
        return _isOperator[account];
    }

    function getDealData(uint256 id) external view returns (DealInfo memory) {
        return dealInfo[id];
    }

    function getOrderData(uint256 id) external view returns (OrderInfo memory) {
        return orderInfo[id];
    }

    function getOrdersByMethod(string memory method)
        external
        view
        returns (uint256[] memory)
    {
        return ordersByMethod[method];
    }

    function getUserInfo(address account)
        external
        view
        returns (UserInfo memory)
    {
        return userInfo[account];
    }

    function getSellerInfo(address account)
        external
        view
        returns (uint256[] memory)
    {
        return sellerInfo[account];
    }

    function canConflict(uint256 dealId) public view returns (bool) {
        DealInfo storage deal = dealInfo[dealId];
        if (deal.times[0] == 0 || deal.times[1] > 0 || deal.isConflict) {
            return false;
        }
        if (deal.times[0].add(timestampToConflict) <= block.timestamp) {
            return true;
        }
        return false;
    }

    function getTransferAmounts(uint256 amount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 feeAmount = amount.mul(fee).div(100000);
        return (amount.sub(feeAmount), feeAmount);
    }

    // external

    function createOrder(
        string[] memory methods,
        string memory asset0,
        string memory asset1,
        uint256 ratio0,
        uint256 ratio1,
        uint256 amountAsset0,
        uint256 minToBuy,
        uint256 maxToBuy
    ) public nonReentrant {
        if (amountAsset0 < MINIMUM_ASSET)
            revert p2pErrors.SpecifyLargerAmount();

        if (
            (minToBuy > amountAsset0 || maxToBuy > amountAsset0) ||
            (maxToBuy > 0 && maxToBuy < minToBuy)
        ) revert p2pErrors.CheckLimits();

        uint256 ratio = ratio0.mul(ratio1).div(RATIO_FACTOR);
        if (ratio == 0) revert p2pErrors.RatioIsNotEnough();

        orderInfo[nextOrder] = OrderInfo(
            methods,
            [asset0, asset1],
            [ratio0, ratio1],
            ratio,
            [amountAsset0, amountAsset0, 0],
            ratio.mul(amountAsset0).div(RATIO_FACTOR),
            [minToBuy, maxToBuy],
            msg.sender
        );

        if (orderInfo[nextOrder].usdLock < minimumUsdOrder)
            revert p2pErrors.UsdLockIsNotEnough();
        USD.safeTransferFrom(
            msg.sender,
            address(this),
            orderInfo[nextOrder].usdLock
        );

        for (uint8 i = 0; i < methods.length; i++) {
            ordersByMethod[methods[i]].push(nextOrder);
        }
        sellerInfo[msg.sender].push(nextOrder);

        emit CreateOrder(nextOrder);

        nextOrder++;
    }

    function createDeal(uint256 orderId, uint256 amount0)
        external
        nonReentrant
    {
        OrderInfo storage order = orderInfo[orderId];
        if (order.orderOwner == address(0)) revert p2pErrors.OrderNotExist();

        if (msg.sender == order.orderOwner)
            revert p2pErrors.OwnerCantBuyFromHimself();

        if (
            (order.amounts[1].sub(order.amounts[2]) < amount0) ||
            (order.limits[1] > 0 && amount0 > order.limits[1])
        ) revert p2pErrors.SpecifySmallerAmount();

        dealInfo[nextDeal] = DealInfo(
            orderId,
            [amount0, order.ratios[0].mul(amount0).div(RATIO_FACTOR)],
            order.ratio.mul(amount0).div(RATIO_FACTOR),
            0,
            false,
            false,
            msg.sender,
            order.orderOwner,
            false,
            [block.timestamp, 0]
        );

        if (
            (amount0 < MINIMUM_ASSET && amount0 < order.limits[0]) ||
            (dealInfo[nextDeal].amounts[1] == 0 ||
                dealInfo[nextDeal].amountUsd == 0)
        ) revert p2pErrors.SpecifyLargerAmount();

        order.amounts[2] = order.amounts[2].add(amount0);
        userInfo[msg.sender].openDeals.push(nextDeal);
        userInfo[order.orderOwner].openDeals.push(nextDeal);

        emit CreateDeal(nextDeal);

        nextDeal++;
    }

    function cancellOrder(uint256 orderId) public {
        OrderInfo storage order = orderInfo[orderId];
        if (order.orderOwner != msg.sender) revert p2pErrors.NotOrderOwner();
        uint256 amountUsd = order
            .ratio
            .mul(order.amounts[1].sub(order.amounts[2]))
            .div(RATIO_FACTOR);
        if (amountUsd == 0) revert p2pErrors.NoFreeUsdToCancel();
        order.usdLock = order.usdLock.sub(amountUsd);
        order.amounts[1] = order.amounts[2];

        if (order.amounts[1] == 0) {
            deleteOrder(orderId);
        }

        USD.safeTransfer(order.orderOwner, amountUsd);

        emit CancellOrder(orderId);
    }

    function cancellAll() external nonReentrant {
        uint256[] memory info = sellerInfo[msg.sender];
        for (uint256 i = 0; i < info.length; i++) {
            cancellOrder(info[i]);
        }
    }

    function setConflict(uint256 dealId) external nonReentrant {
        DealInfo storage deal = dealInfo[dealId];
        if (deal.seller != msg.sender && deal.buyer != msg.sender)
            revert p2pErrors.NotSellerOrBuyer();
        if (deal.sign == 2) revert p2pErrors.DealClosed();
        if (!canConflict(dealId)) revert p2pErrors.CantOpenConflict();

        deal.isConflict = true;

        userInfo[deal.buyer].conflictDeals.push(dealId);

        userInfo[deal.seller].conflictDeals.push(dealId);

        emit SetConflict(dealId);
    }

    function updateOrderLimits(
        uint256 orderId,
        uint256 minToBuy,
        uint256 maxToBuy
    ) external {
        OrderInfo storage order = orderInfo[orderId];
        if (order.orderOwner != msg.sender) revert p2pErrors.NotOrderOwner();
        if (
            (minToBuy > order.amounts[0] || maxToBuy > order.amounts[0]) ||
            (maxToBuy > 0 && maxToBuy < minToBuy)
        ) revert p2pErrors.CheckLimits();

        order.limits = [minToBuy, maxToBuy];

        emit UpdateOrderLimits(orderId);
    }

    function fastChangeOrder(
        uint256 orderId,
        uint256 addedAmountAsset0,
        uint256 ratio0,
        uint256 ratio1,
        uint256 minToBuy,
        uint256 maxToBuy
    ) external nonReentrant {
        OrderInfo storage order = orderInfo[orderId];
        if (order.orderOwner != msg.sender) revert p2pErrors.NotOrderOwner();

        cancellOrder(orderId);
        createOrder(
            order.methods,
            order.assets[0],
            order.assets[1],
            ratio0,
            ratio1,
            order.amounts[1].sub(order.amounts[2]).add(addedAmountAsset0),
            minToBuy,
            maxToBuy
        );

        emit FastChangeOrder(orderId);
    }

    function putSignBuyer(uint256 dealId) external nonReentrant {
        DealInfo storage deal = dealInfo[dealId];
        if (deal.buyer != msg.sender) revert p2pErrors.NotBuyer();
        if (deal.sign == 2) revert p2pErrors.DealClosed();
        if (deal.buyerSigned) revert p2pErrors.AlreadySigned();
        deal.sign++;
        deal.buyerSigned = true;
        if (deal.sign == 2) {
            confirmDeal(dealId);
        }

        emit PutSignBuyer(dealId);
    }

    function putSignSeller(uint256 dealId) external nonReentrant {
        DealInfo storage deal = dealInfo[dealId];
        if (deal.seller != msg.sender) revert p2pErrors.NotSeller();
        if (deal.sign == 2) revert p2pErrors.DealClosed();
        if (deal.sellerSigned) revert p2pErrors.AlreadySigned();
        deal.sign++;
        deal.sellerSigned = true;
        if (deal.sign == 2) {
            confirmDeal(dealId);
        }

        emit PutSignSeller(dealId);
    }

    // private

    function confirmDeal(uint256 dealId) private {
        DealInfo storage deal = dealInfo[dealId];
        (uint256 tAmount, uint256 feeAmount) = getTransferAmounts(
            deal.amountUsd
        );

        deleteOpenDeal(dealId);

        USD.safeTransfer(FeeRecipient, feeAmount);
        USD.safeTransfer(deal.seller, tAmount);

        emit ConfirmDeal(dealId);
    }

    function deleteOpenDeal(uint256 dealId) private {
        DealInfo storage deal = dealInfo[dealId];
        deal.times[1] = block.timestamp;

        OrderInfo storage order = orderInfo[deal.orderId];
        order.amounts[2] = order.amounts[2].sub(deal.amounts[0]);
        order.usdLock = order.usdLock.sub(deal.amountUsd);
        order.amounts[1] = order.amounts[1].sub(deal.amounts[0]);

        if (order.amounts[1] == 0) {
            deleteOrder(deal.orderId);
        }

        UserInfo storage buyer = userInfo[deal.buyer];
        for (uint256 i = 0; i < buyer.openDeals.length; i++) {
            if (buyer.openDeals[i] == dealId) {
                buyer.openDeals[i] = buyer.openDeals[
                    buyer.openDeals.length - 1
                ];
                buyer.openDeals.pop();
                break;
            }
        }

        UserInfo storage seller = userInfo[deal.seller];
        for (uint256 i = 0; i < seller.openDeals.length; i++) {
            if (seller.openDeals[i] == dealId) {
                seller.openDeals[i] = seller.openDeals[
                    seller.openDeals.length - 1
                ];
                seller.openDeals.pop();
                break;
            }
        }

        if (deal.isConflict) {
            closeConflict(dealId);
        }

        emit DeleteOpenDeal(dealId);
    }

    function deleteOrder(uint256 orderId) private {
        OrderInfo storage order = orderInfo[orderId];

        for (uint8 i = 0; i < order.methods.length; i++) {
            for (
                uint256 y = 0;
                y < ordersByMethod[order.methods[i]].length;
                y++
            ) {
                if (ordersByMethod[order.methods[i]][y] == orderId) {
                    ordersByMethod[order.methods[i]][y] = ordersByMethod[
                        order.methods[i]
                    ][ordersByMethod[order.methods[i]].length - 1];
                    ordersByMethod[order.methods[i]].pop();
                    break;
                }
            }
        }

        for (uint256 i = 0; i < sellerInfo[order.orderOwner].length; i++) {
            if (sellerInfo[order.orderOwner][i] == orderId) {
                sellerInfo[order.orderOwner][i] = sellerInfo[order.orderOwner][
                    sellerInfo[order.orderOwner].length - 1
                ];
                sellerInfo[order.orderOwner].pop();
                break;
            }
        }

        emit DeleteOrder(orderId);
    }

    function closeConflict(uint256 dealId) private {
        DealInfo storage deal = dealInfo[dealId];
        deal.isConflict = false;

        UserInfo storage buyer = userInfo[deal.buyer];
        for (uint256 i = 0; i < buyer.conflictDeals.length; i++) {
            if (buyer.conflictDeals[i] == dealId) {
                buyer.conflictDeals[i] = buyer.conflictDeals[
                    buyer.conflictDeals.length - 1
                ];
                buyer.conflictDeals.pop();
                break;
            }
        }

        UserInfo storage seller = userInfo[deal.seller];
        for (uint256 i = 0; i < seller.conflictDeals.length; i++) {
            if (seller.conflictDeals[i] == dealId) {
                seller.conflictDeals[i] = seller.conflictDeals[
                    seller.conflictDeals.length - 1
                ];
                seller.conflictDeals.pop();
                break;
            }
        }
        emit CloseConflict(dealId);
    }

    // onlyOperator

    function confirmDealByOperator(uint256 dealId, uint8 whoRight)
        external
        onlyOperator
    {
        // 0 - buyer
        // 1 - seller
        require(whoRight == 0 || whoRight == 1);
        DealInfo storage deal = dealInfo[dealId];
        if (!deal.isConflict) revert p2pErrors.NotConflict();
        if (deal.sign == 2) revert p2pErrors.DealClosed();

        address account = whoRight == 0 ? deal.buyer : deal.seller;

        (uint256 tAmount, uint256 feeAmount) = getTransferAmounts(
            deal.amountUsd
        );

        deal.sign = 2;
        deleteOpenDeal(dealId);

        USD.safeTransfer(FeeRecipient, feeAmount);
        USD.safeTransfer(account, tAmount);

        emit ConfirmDealByOperator(dealId, whoRight);
    }

    // onlyOwner

    // _fee = 1505 = 1,505 %
    function updateFee(uint32 _fee) external onlyOwner {
        require(_fee <= 10000);
        fee = _fee;
    }

    function setIsOperator(address account, bool _is) external onlyOwner {
        _isOperator[account] = _is;
    }

    function updateTimestampToConflict(uint256 _minutes) external onlyOwner {
        require(_minutes <= 120);
        timestampToConflict = _minutes * 60;
    }

    function updateMinimumUsdOrder(uint256 newMinimumUsdOrder)
        external
        onlyOwner
    {
        minimumUsdOrder = newMinimumUsdOrder;
    }

    function updateFeeRecipient(address _FeeRecipient) external onlyOwner {
        FeeRecipient = _FeeRecipient;
    }

    function WithdrawWrongTokens(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        require(token != USD);
        token.safeTransfer(msg.sender, amount);
    }
}