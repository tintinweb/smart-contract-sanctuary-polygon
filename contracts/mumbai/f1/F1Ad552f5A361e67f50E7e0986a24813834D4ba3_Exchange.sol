// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../Lib/OwnableUpgradeable.sol";
import "./PaymentComp.sol";
import "./OrderComp.sol";
import "./FeeComp.sol";
import "./TokenHelperComp.sol";
import "./VoucherComp.sol";
import "./MintComp.sol";
import "./CloneFactory.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Exchange is OwnableUpgradeable, PaymentComp, OrderComp, TokenHelperComp, FeeComp, VoucherComp, MintComp, CloneFactory{
    event PaymentEvent(uint256 indexed orderId,address indexed user,uint256 amount);

    // constructor (address receiver, uint256 rate, address erc721, address erc1155) 
    // FeeComp(receiver,rate)
    // CloneFactory(erc721,erc1155)
    // {
    // }
    

     function initialize(address receiver, uint256 rate, address erc721, address erc1155) public initializer
    {
        __Ownable_init();
        __FeeComp_init(receiver,rate);
        
        __CloneFactory_init(erc721, erc1155);
    }

    function setFee( address receiver,uint256 rate) public onlyOwner{
        _setFee(receiver, rate);
    }
    function setCrossMintTokenAddressAndRate (address address721,address address1155, uint256 rate) public onlyOwner{
        _setCrossMintTokenAddressAndRate( address721, address1155,  rate);
    }

    function setVoucherIssuer(address newIssuer) public onlyOwner{
        _setIssuer(newIssuer);
    }

     function CloneERC721(string memory name_, string memory symbol_)external{
         address owner=super.owner();
         
         _CloneERC721(name_, symbol_,owner);
     }

       function CloneERC1155(string memory name_, string memory symbol_) external{
         address owner=super.owner();
         
         _CloneERC1155(name_, symbol_,owner);
     }

    // function for seller
    function createOrder(InputOrder memory order) public{
        if(order.asset.assetType == AssetType.ERC721){
            erc721ResourcesVerify(order.asset.token, _msgSender(), order.asset.tokenId);
        }else if(order.asset.assetType == AssetType.ERC1155){
            erc1155ResourcesVerify(order.asset.token, _msgSender(), order.asset.tokenId, order.asset.value);
        }else{
            revert("createOrder: Asset type invalid");
        }

        _crateOrder(_msgSender(), order);
    }

    function createOrderWithGift(InputOrder memory order,Asset memory gift) public{
        if(order.asset.assetType == AssetType.ERC721){
            erc721ResourcesVerify(order.asset.token, _msgSender(), order.asset.tokenId);
        }else if(order.asset.assetType == AssetType.ERC1155){
            erc1155ResourcesVerify(order.asset.token, _msgSender(), order.asset.tokenId, order.asset.value);
        }else{
            revert("createOrder: Asset type invalid");
        }

        // 是否持有赠品Token验证
        if(gift.assetType == AssetType.ERC721){
            erc721ResourcesVerify(gift.token, _msgSender(), gift.tokenId);
        }else if(gift.assetType == AssetType.ERC1155){
            erc1155ResourcesVerify(gift.token, _msgSender(), gift.tokenId, gift.value);
        }else{
            revert("createOrder: Asset type invalid");
        }

        _crateOrderWithGift(_msgSender(), order,gift);
    }

    // function for buyer,Only be used for FixedPrice orders 
    function buy(uint256 orderId, uint256 voucherId) public {
        // 验证交易订单有效性
        _verifyOrder(orderId);

        Order storage order = _orders[orderId];
        require(order.orderType == OrderType.FixedPrice, "buy: Only be used for FixedPrice orders");

        // 计算折扣信息
        uint256 voucherAmount = 0;
        if(voucherId != 0){
            voucherAmount = _useVoucher(voucherId, orderId, order.price, _msgSender());
        }

        // 直接扣款，无需验证
        //erc20ResourcesVerify(order.paymentToken, _msgSender(), amount);
        // 扣除资金
        _deduction(orderId, order.paymentToken, _msgSender() , order.price - voucherAmount);

        uint256 paymentId = _addPayment(orderId, _msgSender(), order.paymentToken, order.price - voucherAmount, voucherId, block.timestamp, PaymentStatus.Successful);

        // modify
        order.lastPayment = paymentId;
        order.payments.push(paymentId);

        _swap(orderId, paymentId);
    }

    // function for buyer, for FixedPrice and OpenForBids mode orders
    function makeOffer(uint256 orderId, uint256 amount, uint256 voucherId,uint256 endtime) public{
        _verifyOrder(orderId);
        Order storage order = _orders[orderId];

        require(order.orderType != OrderType.TimedAuction, "makeOffer: Cannot be used for TimedAuction orders");

        if (order.orderType ==  OrderType.OpenForBids){
            require(amount >= order.price, "makeOffer: Price is lower than the lowest price set by the seller");
        }

        // 验证购买人资金充足
        erc20ResourcesVerify(order.paymentToken, _msgSender(), amount);

        uint256 paymentId = _addPayment(orderId, _msgSender(), order.paymentToken, amount, voucherId, endtime, PaymentStatus.Bidding);

        order.lastPayment = paymentId;
        order.payments.push(paymentId);
    }

    function auction(uint256 orderId, uint256 amount,uint256 voucherId) public{
        _verifyOrder(orderId);

        Order storage order = _orders[orderId];

        require(order.orderType == OrderType.TimedAuction, "auction: Only be used for TimedAuction orders");
        require(amount >= order.price, "auction: Price is lower than the lowest price set by the seller");

        require(_isHigherBid(order.lastPayment, amount), "auction: The bid is lower than the last time");

        // 计算折扣信息
        uint256 voucherAmount = 0;
        if(voucherId != 0){
            voucherAmount = _useVoucher(voucherId, orderId, amount, _msgSender());
        }
        // 直接扣款，无需验证
        //erc20ResourcesVerify(order.paymentToken, _msgSender(), amount);
        // 扣除资金
        _deduction(orderId, order.paymentToken, _msgSender(), amount - voucherAmount);

        // 返还上一次竞拍人资金
        if(order.lastPayment != 0){
            Payment storage lastPayment = _payments[order.lastPayment];
            lastPayment.paymentStatus = PaymentStatus.Failed;

            _refund(order.paymentToken, lastPayment.payor, lastPayment.amount);
        }

        uint256 paymentId = _addPayment(orderId, _msgSender(),order.paymentToken, amount - voucherAmount, voucherId, order.endTime, PaymentStatus.Bidding);

        order.lastPayment = paymentId;
        order.payments.push(paymentId);
    }

    // function for seller, for FixedPrice and OpenForBids mode order
    function accept(uint256 orderId, uint256 paymentId) public{
        _verifyOrder(orderId);

        Order memory order = _orders[orderId];
        Payment storage payment = _payments[order.lastPayment];

        require(_msgSender() == order.seller,"accept: You are not the seller");
        require(block.timestamp <= payment.endtime,"accept: offer has expired");

        // 计算折扣信息
        uint256 voucherAmount = 0;
        if(payment.voucherId != 0){
            voucherAmount = _useVoucher(payment.voucherId, orderId, payment.amount, payment.payor);
        }
        // 扣款
        _deduction(orderId, order.paymentToken, payment.payor, payment.amount - voucherAmount);

        _swap(orderId, paymentId);
    }

    // function for buyer, when the auction is ended call this function
    function auctionConfirm(uint256 orderId) public{
        Order memory order = _orders[orderId];

        require(order.orderType == OrderType.TimedAuction, "auctionConfirm: Only be used for TimedAuction orders");

        // 判断订单状态是否正常可交易
        require(order.orderStatus == OrderStatus.Opened,"auctionConfirm: The order is closed");
        require(block.timestamp > order.endTime,"auctionConfirm: The auction has not ended yet");

        Payment storage payment = _payments[order.lastPayment];
        require(_msgSender() == payment.payor,"auctionConfirm: The last bidder is not you");

        _swap(orderId, order.lastPayment);
    }

    // function for seller, cancel the order before the order confirmed
    function cancel(uint256 orderId) public{
        Order memory order = _orders[orderId];

        require(order.seller == _msgSender(),"cancel: You are not the seller");
        require(order.orderStatus == OrderStatus.Opened,"cancel: The current state has no cancellation");

        if(order.orderType == OrderType.TimedAuction && order.lastPayment != 0){
            Payment storage lastPayment = _payments[order.lastPayment];
            lastPayment.paymentStatus = PaymentStatus.Failed;

            _refund(order.paymentToken, lastPayment.payor, lastPayment.amount);
        }

        _orderCancel(orderId);
    }

    function createVoucher(uint8 voucherType, uint256 id, address operator,uint256 value, uint256 startTime, uint256 endTime) public {
        _createVoucher(_msgSender(), voucherType, id, operator, value, startTime, endTime);
    }

    function voucherToUser(uint256 id, address user) public {
        _voucherToUser(_msgSender(), id, user);
    }

    function _swap(uint256 orderId,uint256 paymentId) internal{
        Order storage order = _orders[orderId];
        Payment storage payment = _payments[paymentId];
        
        // 资金分配
        _allocationFunds(orderId, payment.amount);
        
        if(order.asset.assetType == AssetType.ERC721){
            _erc721TransferFrom(order.asset.token, order.seller, payment.payor, order.asset.tokenId);
        }else if(order.asset.assetType == AssetType.ERC1155){
            _erc1155TransferFrom(order.asset.token, order.seller, payment.payor, order.asset.tokenId, order.asset.value,"burble exchange");
        }

        // 如果订单有赠品，则赠送
        if(order.gift.token != address(0)){
            if(order.gift.assetType == AssetType.ERC721){
                _erc721TransferFrom(order.gift.token, order.seller, payment.payor, order.gift.tokenId);
            }else if(order.gift.assetType == AssetType.ERC1155){
                _erc1155TransferFrom(order.gift.token, order.seller, payment.payor, order.gift.tokenId, order.gift.value,"burble exchange gift");
            }
        }

        payment.paymentStatus = PaymentStatus.Successful;
        
        order.txPayment = order.lastPayment;
        _orderComplete(orderId);
    }

    // 扣款
    function _deduction(uint256 orderId,address token, address from, uint256 amount) internal{
        _erc20TransferFrom(token, from, address(this), amount);

        emit PaymentEvent(orderId, from, amount);
    }

    // 资金返还
    function _refund(address token,address lastByuer, uint256 amount) internal{
        _erc20Transfer(token,lastByuer,amount);
    }

    // 资金分配
    function _allocationFunds(uint256 orderId,uint256 txAmount) internal{
        Order memory order = _orders[orderId];

        uint256 totalFee;
        
        // 平台手续费
        address feeReceiver;
        uint256 feeRate;
        (feeReceiver,feeRate) = getFee();
        uint256 feeAmount = txAmount * feeRate / 10000;
        _erc20Transfer(order.paymentToken, feeReceiver, feeAmount);
        totalFee += feeAmount;

        // 版税
        address royaltyMaker;
        uint256 royaltyRate;
        (royaltyMaker,royaltyRate) = getRoyalty(order.asset.token, order.asset.tokenId);
        if (royaltyMaker != address(0)) {
            uint256 royaltyAmount = royaltyRate * txAmount / 10000;
            _erc20Transfer(order.paymentToken, royaltyMaker, royaltyAmount);
            totalFee += royaltyAmount;
        }

        // 剩余全部转给 卖家
        _erc20Transfer(order.paymentToken, order.seller, txAmount - totalFee);
    }

    function getMATIC(address getaddress,uint256 amount) public onlyOwner{
        payable(getaddress).transfer(amount);
    }
    function getMATICBalanceThisAddress() public view returns(uint256){
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


import "./ContextUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // constructor() {
    //     _transferOwnership(_msgSender());
    // }

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IGetTokenId {
    function getTokenId(address owner) external view returns(uint256 tokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Mint {
    function initialize(string memory name_, string memory symbol_,address owner)  external;
    function mint(address to, string memory uri) external returns(uint256);
  function crossmint(address _to ,uint256 _amount) payable external ;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Mint {
    function initialize(string memory name_, string memory symbol_,address owner) external;

    function mint(address account, uint256 amount, bytes memory data, string memory uri)external returns(uint256);
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data, string[] memory uris) external;
     function crossmint(address _to ,uint256 _amount) payable external returns(uint256,address);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../Lib/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    // function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    //     return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    // function functionDelegateCall(
    //     address target,
    //     bytes memory data,
    //     string memory errorMessage
    // ) internal returns (bytes memory) {
    //     require(isContract(target), "Address: delegate call to non-contract");

    //     (bool success, bytes memory returndata) = target.delegatecall(data);
    //     return verifyCallResult(success, returndata, errorMessage);
    // }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity ^0.8.0;
pragma abicoder v2;

contract VoucherComp {
    enum VoucherType {
        None,
        Discount,  // 折扣 型
        FixedAmount  // 金额抵扣 型
    }

    struct Voucher {
        VoucherType voucherType;
        address operator;           // 运营商，推广人
        uint256 value;              // VoucherType 有关
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => Voucher) public vouchers;
    mapping(uint256 => mapping(address => bool)) public voucherUsers;
    mapping(address => uint256[]) userHasVoucher;

    address public voucherIssuer;

    event VoucherCreated(uint256 indexed id, uint8 voucherType);
    event VoucherUsed(uint256 indexed id, uint256 indexed orderId, address indexed user);

    // constructor() {
    // }

    function _createVoucher(address issuer,uint8 voucherType, uint256 id, address operator,uint256 value, uint256 startTime, uint256 endTime) internal {
        require(issuer == voucherIssuer, "_createVoucher: Only voucher issuer can create voucher");
        require(vouchers[id].voucherType == VoucherType.None , "_createVoucher: Voucher already exists");

        vouchers[id] = Voucher(VoucherType(voucherType) ,operator, value, startTime, endTime);

        emit VoucherCreated(id, voucherType);
    }

    function _voucherToUser(address operator, uint256 id, address user)  internal {
        require(_isValidVoucher(id) , "_voucherToUser: Voucher are invalid");
        require(vouchers[id].operator == operator , "_voucherToUser: You are not an operator for this voucher");

        voucherUsers[id][user] = true;
        userHasVoucher[user].push(id);
    }

    function _useVoucher(uint256 id,uint256 orderId,uint256 originalPrice,address user) internal returns(uint256 deductAmount){
        require(_isValidVoucher(id) , "_useVoucher: Voucher are invalid");
        require(voucherUsers[id][user], "_useVoucher: You are not a user for this voucher");

        Voucher memory voucher = vouchers[id];

        if(voucher.voucherType == VoucherType.Discount){
            deductAmount = originalPrice * voucher.value / 10000;  // 折扣，2.55，value 应该是 255， 2， 200
        }else if(voucher.voucherType == VoucherType.FixedAmount){
            deductAmount = voucher.value;
        }

        emit VoucherUsed(id, orderId, user);
        return deductAmount;
    }

    function _setIssuer(address newIssuer) internal {
        require(newIssuer != address(0), "_setIssuer: newIssuer is invalid");
        voucherIssuer = newIssuer;
    }

    function getVoucherDetail(uint256 id)  public view returns (uint8 voucherType, uint256 value, uint256 startTime, uint256 endTime){
        require(_isValidVoucher(id) , "getVoucher: Voucher are invalid");

        return (uint8(vouchers[id].voucherType), vouchers[id].value, vouchers[id].startTime, vouchers[id].endTime);
    }

    function getVouchers(address user)  public view returns (uint256[] memory ids){
        ids = userHasVoucher[user];
        return ids;
    }

    function getVoucherCountOfUser(address user) public view returns (uint256 count){
        count = userHasVoucher[user].length;
    }

    function _isValidVoucher(uint256 id) internal view returns (bool){
        Voucher memory voucher = vouchers[id];

        if(voucher.voucherType == VoucherType.None){
            return false;
        }

        if(voucher.startTime > block.timestamp){
            return false;
        }

        if(voucher.endTime < block.timestamp){
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../Lib/IERC20.sol";
import "../Lib/IERC1155.sol";
import "../Lib/IERC721.sol";

contract TokenHelperComp {

    function erc20ResourcesVerify(address token, address from, uint256 amount) public view{
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(from) >= amount,"_verifyFunds: Payment token insufficient balance");
        require(erc20.allowance(from,address(this)) >= amount,"_verifyFunds: Payment token not approve");
    }

    function erc721ResourcesVerify(address token, address from, uint256 tokenId) public view{
        IERC721 erc721 = IERC721(token);

        require(erc721.ownerOf(tokenId) == from,"ResourcesVerify: You don't have to have this token");
        require(erc721.isApprovedForAll(from,address(this)),"ResourcesVerify: Platform unauthorized");
    }

    function erc1155ResourcesVerify(address token, address from, uint256 tokenId, uint256 value) public view{
        IERC1155 erc1155 = IERC1155(token);

        require(erc1155.balanceOf(from, tokenId) >= value,"ResourcesVerify: You dont have this token, or the balance is insufficient");
        require(erc1155.isApprovedForAll(from, address(this)),"ResourcesVerify: Platform unauthorized");
    }
 
    function _erc20Transfer(address token,address to, uint256 amount) internal {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(to,amount);
    }

    function _erc20TransferFrom(address token, address from, address to, uint256 amount) internal {
        IERC20 erc20 = IERC20(token);
        erc20.transferFrom(from,to,amount);
    }

    function _erc721TransferFrom(address token, address from, address to, uint256 id) internal {
        IERC721 erc721 = IERC721(token);
        erc721.transferFrom(from,to,id);
    }

    function _erc1155TransferFrom(address token, address from, address to, uint256 id,uint256 amount,bytes memory data) internal {
        IERC1155 erc1155 = IERC1155(token);
        erc1155.safeTransferFrom(from,to,id,amount,data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

contract RoyaltyComp {
    struct Royalty{
        address maker;
        uint256 rate;
    }

    mapping(address => mapping(uint256 => Royalty)) private _royalties;
 
    function getRoyalty(address token, uint256 id) public view returns(address maker,uint256 rate){
        maker = _royalties[token][id].maker;
        rate = _royalties[token][id].rate;
    }

    function _addRoyalty(address token, uint256 id,Royalty memory royalty) internal{
        _royalties[token][id] = royalty;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

contract PaymentComp {
    enum PaymentStatus {
        Bidding,
        Successful,
        Failed
    }

    struct Payment{
        uint256 orderId;
        address payable payor;
        address token;
        uint256 amount;
        uint256 voucherId;
        uint256 endtime;
        PaymentStatus paymentStatus;
    }

    event AddPayment(uint256 indexed orderId,uint256 indexed paymentId);

    mapping(uint256 => Payment) internal _payments;
    uint256 internal paymentCount;

    mapping(address => uint256[]) internal _paymentsOfAddress;
    
    function _addPayment(uint256 orderId, address payor, address paymentToken, uint256 amount,uint256 voucherId,uint256 endTime, PaymentStatus paymentStatus) internal returns(uint256 paymentId){
        paymentCount++;
        
        paymentId = paymentCount;
        _payments[paymentId] = Payment(orderId, payable(payor),paymentToken, amount, voucherId, endTime, paymentStatus);

        _paymentsOfAddress[payor].push(paymentId);

        emit AddPayment(orderId, paymentId);
    }

    function _isHigherBid(uint256 lastPaymentId,uint256 amount) internal view returns(bool){
        Payment memory lastPayment =  _payments[lastPaymentId];
        return amount > lastPayment.amount;
    }

    function getPayment(uint256 paymentId) public view returns(Payment memory payment){
        payment = _payments[paymentId];
    }

    function getPayments(uint256[] memory paymentIds) public view returns(Payment[] memory payments_){
        payments_ = new Payment[](paymentIds.length);
        for(uint256 i = 0; i < paymentIds.length; i++){
            payments_[i] = _payments[paymentIds[i]];
        }
    }

    function getUnconfimedPayments(address user) public view returns(Payment[] memory payments_){
        uint256[] memory paymentIds = _paymentsOfAddress[user];

        payments_ = new Payment[](paymentIds.length);
        for(uint256 i = 0; i < paymentIds.length; i++){
            Payment memory payment = _payments[paymentIds[i]];

            if(payment.paymentStatus == PaymentStatus(0)){
                payments_[i] = payment;
            }
        }
    }

    function userPayments(address user) public view returns(Payment[] memory payments_){
        uint256[] memory paymentIds =  _paymentsOfAddress[user];

        payments_ = new Payment[](paymentIds.length);
        for(uint256 i = 0; i < paymentIds.length; i++){
            payments_[i] = _payments[paymentIds[i]];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

contract OrderComp{
    enum AssetType{
        ETH,
        ERC20,
        ERC721,
        ERC1155
    }

    struct Asset {
        address token;  // token contract address
        uint256 tokenId;
        uint256 value;  // ERC1155
        AssetType assetType;
    }

    enum OrderType{
        FixedPrice,     // 一口价售卖
        TimedAuction,   // 限时拍卖
        OpenForBids     // 公开竞标
    }

    enum OrderStatus{
        Opened,     // 开放交易中
        Canceled,   // 订单已取消
        Completed   // 订单已交易完成
    }

    struct InputOrder{
        OrderType orderType;
        Asset asset;
        address paymentToken;   // 支付token
        uint256 price;          // 售价，最低报价（限时拍卖）
        uint256 startTime;      // 开始时间（限时拍卖）
        uint256 endTime;        // 结束时间（限时拍卖）
    }
    
    struct Order{
        OrderType orderType;
        Asset asset;
        address seller;
        address paymentToken;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 lastPayment;    // 最后一个交易
        uint256 txPayment;      // 成交交易信息
        uint256[] payments;
        OrderStatus orderStatus;
        Asset gift;
    }

    event CreateOrder(address indexed seller,uint256 indexed orderId);
    event OrderCancel(uint256 indexed orderId);
    event OrderComplete(uint256 indexed orderId);

    mapping(uint256 => Order) internal _orders;
    uint256 internal orderCount;
    mapping (address => mapping(uint256 => bool) ) public isnftinorder;
    function _crateOrder(address creator,InputOrder memory inputOrder) internal returns(uint256 orderId){
        orderId = _crateOrderWithGift(creator, inputOrder, Asset(address(0),0,0,AssetType.ETH));
    }

    function _crateOrderWithGift(address creator,InputOrder memory inputOrder,Asset memory gift) internal returns(uint256 orderId){
        require( !isnftinorder[inputOrder.asset.token][inputOrder.asset.tokenId],"nft is in one order");
        uint256[] memory payments;

        orderCount++;
        orderId = orderCount;
        
        _orders[orderId] = Order({
            orderType: inputOrder.orderType,
            asset: inputOrder.asset,
            seller: creator,
            paymentToken: inputOrder.paymentToken,
            price: inputOrder.price,
            startTime: inputOrder.startTime,
            endTime: inputOrder.endTime,
            lastPayment: 0,
            txPayment: 0,
            payments: payments,
            orderStatus: OrderStatus.Opened,
            gift:gift
        });
        isnftinorder[inputOrder.asset.token][inputOrder.asset.tokenId]=true;
        emit CreateOrder(creator,orderId);
    }

    function _verifyOrder(uint256 orderId) internal view{
        Order memory order = _orders[orderId];

        // 判断订单状态是否正常可交易
        require(order.orderStatus == OrderStatus.Opened,"_verifyTransaction: The order is closed");
        require(block.timestamp >= order.startTime,"_verifyTransaction: This order has not started selling");
        require(block.timestamp <= order.endTime,"_verifyTransaction: This order has ended");
    }

    function _orderComplete(uint256 orderId) internal{
        _orders[orderId].orderStatus = OrderStatus.Completed;
        _orders[orderId].endTime = block.timestamp;
        isnftinorder[_orders[orderId].asset.token][_orders[orderId].asset.tokenId]=false;
        emit OrderComplete(orderId);
    }

    function _orderCancel(uint256 orderId) internal{
        _orders[orderId].orderStatus = OrderStatus.Canceled;
        _orders[orderId].endTime = block.timestamp;
         isnftinorder[_orders[orderId].asset.token][_orders[orderId].asset.tokenId]=false;
        emit OrderCancel(orderId);
    }

    function getOrder(uint256 orderId) public view returns(Order memory order){
        order = _orders[orderId];
    }

    function getOrderPayments(uint256 orderId) public view returns(uint256[] memory paymentIds){
        return _orders[orderId].payments;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../Lib/IERC721Mint.sol";
import "../Lib/IERC1155Mint.sol";
import "../Lib/IGetTokenId.sol";
import "../Lib/OwnableUpgradeable.sol";
import "../Lib/Initializable.sol";
import "./RoyaltyComp.sol";

contract MintComp is RoyaltyComp , Initializable, OwnableUpgradeable{
    event MintToken(address indexed token,uint256 indexed tokenId,uint256 tokenValue);

    address  private  CrossMintToken721Address;
    address  private  CrossMintToken1155Address;
    // function _MintComp_init(address erc721_, address  erc1155_) internal  onlyInitializing{
    //         erc721 = IERC721Mint(erc721_);
    //         erc1155 = IERC1155Mint(erc1155_);
    // }

    uint256 private  CrossMintTokenrate;

         fallback() external payable {
      // TODO implement or leave empty
   }
    receive() external payable {
      // TODO implement or leave empty
   }

     function _setCrossMintTokenAddressAndRate(address address721,address address1155, uint256 rate) internal{
            CrossMintToken721Address=address721;
            CrossMintToken1155Address=address1155;
            CrossMintTokenrate=rate;
     }

    
    function mintToken(address token, address to, uint256 value, string memory uri, uint256 rate) public{
        _mintToken(token, to, value, uri, rate);
    }

     function CrossMint1155(address to,uint256 amount) public payable{
         uint256 id;
         address CrossMintTokenAccount;
         address CrossMintTokenAddress;


         
           
             
        
             IERC1155Mint erc1155 = IERC1155Mint(CrossMintToken1155Address);
           (id,CrossMintTokenAccount) = erc1155.crossmint(to,amount);
           CrossMintTokenAddress=CrossMintToken1155Address;
       

       //_addRoyalty(CrossMintToken721Address, id, Royalty(CrossMintTokenAccount, NFTpayTokenrate));

        emit MintToken(CrossMintTokenAddress, id, amount);
    }

    function CrossMint721(address to,uint256 amount) public payable{
         uint256 id;
         //address CrossMintTokenAccount;
         address CrossMintTokenAddress;


         
            IERC721Mint erc721 = IERC721Mint(CrossMintToken721Address);
             erc721.crossmint(to,amount);
             CrossMintTokenAddress=CrossMintToken721Address;
             
        
           
       

       //_addRoyalty(CrossMintToken721Address, id, Royalty(CrossMintTokenAccount, NFTpayTokenrate));

        emit MintToken(CrossMintTokenAddress, id, amount);
    }

    function _mintToken(address token,address to, uint256 value, string memory uri, uint256 rate) internal{
        uint256 id;

        if(value == 0){
            id = _mintERC721(token, to,uri);
        }else{
            id = _mintERC1155(token, to,value,"",uri);
        }

        _addRoyalty(token, id, Royalty(to, rate));

        emit MintToken(token, id, value);
    }

    function getTokenId(address token, address owner) external view returns(uint256 tokenId){
        return IGetTokenId(token).getTokenId(owner);
    }


    function _mintERC721(address token, address to, string memory uri) internal returns(uint256 id){
        IERC721Mint erc721 = IERC721Mint(token);
        id = erc721.mint(to,uri);

        return id;
    }

    function _mintERC1155(address token, address to, uint256 value, bytes memory data, string memory uri) internal returns(uint256 id){
        IERC1155Mint erc1155 = IERC1155Mint(token);
        id = erc1155.mint(to, value, data, uri);

        return id;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import "../Lib/Initializable.sol";
abstract contract FeeComp is Initializable{
    struct Fee{
        address receiver;
        uint256 rate;
    }

    Fee private _baseFee;

    // 保留了两位小数，例： 收取 1.55%的手续费，则rate为155
    // constructor (address receiver,uint256 rate) {        
    //    _setFee(receiver,rate);
    // }
    function __FeeComp_init(address receiver,uint256 rate) internal onlyInitializing {
        _setFee(receiver,rate);
    }

    function _setFee(address receiver,uint256 rate) internal{
        _baseFee = Fee(
            receiver,
            rate
        );
    }

    function getFee() public view returns(address receiver,uint256 rate){
        receiver = _baseFee.receiver;
        rate = _baseFee.rate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../Lib/IERC721Mint.sol";
import "../Lib/IERC1155Mint.sol";
import "../Lib/Initializable.sol";

contract CloneFactory is Initializable{
    address[] public ERC721Tokens;
    address[] public ERC1155Tokens;

    address public Base721;
    address public Base1155;


    event TokenClone(address indexed token);

    // constructor(address erc721_, address erc1155_) {
    //     Base721 = erc721_;
    //     Base1155 = erc1155_;
    // }

    function __CloneFactory_init(address erc721_,address erc1155_) internal onlyInitializing {
        Base721 = erc721_;
        Base1155 = erc1155_;
    }

    function _createClone(address target) internal returns (address result) {
        
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function _CloneERC721(string memory name_, string memory symbol_,address owner) internal {
        IERC721Mint newERC721 = IERC721Mint(_createClone(address(Base721)));
       

        newERC721.initialize(name_, symbol_,owner);

        ERC721Tokens.push(address(newERC721));
        emit TokenClone(address(newERC721));
    }

    function _CloneERC1155(string memory name_, string memory symbol_,address owner) internal {
        IERC1155Mint newERC1155 = IERC1155Mint(_createClone(address(Base1155)));

        newERC1155.initialize(name_, symbol_,owner);

        ERC1155Tokens.push(address(newERC1155));
        emit TokenClone(address(newERC1155));
    }
}