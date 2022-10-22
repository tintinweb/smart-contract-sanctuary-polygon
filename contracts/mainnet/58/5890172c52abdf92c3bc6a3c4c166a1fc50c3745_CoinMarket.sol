/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

// File: token/IERC20.sol

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with 
    ///  the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// Returns the total token supply.
    function totalSupply() external view returns (uint256);

    /// Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
    /// The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
    /// This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
    /// The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// Allows _spender to withdraw from your account multiple times, up to the _value amount. 
    /// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
// File: security/AccessControl.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}
// File: security/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}
// File: CoinMarket.sol

pragma solidity ^0.8.4;



contract CoinMarket is Pausable {
    /// @dev Error message.
    string constant WRONG_PARAMETER = "wrong parameter";
    string constant ADDRESS_NOT_SET = "coin address not set";
    string constant MATIC_NOT_ENOUGH = "Matic not enough";
    string constant ID_NOT_EXISTS = "id not exists";

    /// @dev Save address of coinA/B/C sequentially.
    address[3] public coinAddresses;

    /// @dev Used as id of order.
    uint256 orderCount;

    /// @dev This event should be fired whenever address in coinAddresses is modified.
    event CoinAddressesChanged(
        uint256 indexed coinType,
        address indexed _from,
        address indexed _to,
        uint256 _time
    );

    /// @dev This event should be fired whenever an order is set.
    event OrderSet(
        uint256 indexed id,
        uint256 indexed coinType,
        address indexed launcher,
        uint256 amount,
        uint256 price,
        uint256 unit,
        bool label
    );

    event OrderBid(uint256 indexed id, uint256 amount);

    event OrderCancel(uint256 indexed id, address indexed canceler);

    struct Order {
        uint256 id; //order identity
        uint256 coinType; //order type, 0/1/2 represents coinA/B/C
        address launcher; //who build this order
        uint256 left;
        uint256 price;
        uint256 unit; //the least unit
        bool label; //true means sell, false means buy
    }

    Order[] Orders;

    /// @dev Mapping from id to index of Oreders.
    mapping(uint256 => uint256) idToIndex;
    /// @dev Whether an id exists.
    mapping(uint256 => bool) idExist;

    modifier validId(uint256 id) {
        require(idExist[id], ID_NOT_EXISTS);
        _;
    }

    /// @dev Present all orders.
    function presentOrders() external view returns (Order[] memory) {
        return Orders;
    }

    /// @dev Present one order.
    function presentOneOrder(uint256 id) external validId(id) view returns (Order memory) {
        return Orders[idToIndex[id]];
    }

    /// @dev Change coinAddress.
    ///  Caller should always be superAdmin. addr is new address of coinType.
    function changeCoinAddresses(uint256 coinType, address addr)
        external
        onlySuperAdmin
    {
        emit CoinAddressesChanged(
            coinType,
            coinAddresses[coinType],
            addr,
            block.timestamp
        );
        coinAddresses[coinType] = addr;
    }

    /// @dev Seller pending order selling coinA/B/C. Seller should call increaseAllowance in advance.
    ///  Since addr is set by superAdmin, we don't have to worry about re-entrancy attack here.
    function setSell(
        uint256 coinType,
        uint256 amount,
        uint256 price,
        uint256 unit
    ) external whenNotPaused {
        require(
            amount >= unit && unit > 0 && amount % unit == 0,
            WRONG_PARAMETER
        );
        address addr = coinAddresses[coinType];
        require(addr != address(0), ADDRESS_NOT_SET);
        idToIndex[orderCount] = Orders.length;
        idExist[orderCount] = true;
        Order memory _Order = Order({
            id: orderCount,
            coinType: coinType,
            launcher: msg.sender,
            left: amount,
            price: price,
            unit: unit,
            label: true
        });
        Orders.push(_Order);
        emit OrderSet(
            orderCount,
            coinType,
            msg.sender,
            amount,
            price,
            unit,
            true
        );
        orderCount++;
        IERC20 sc = IERC20(addr);
        sc.transferFrom(msg.sender, address(this), amount);
    }

    function bidSell(uint256 id, uint256 amount)
        external
        payable
        whenNotPaused
        validId(id)
    {
        uint256 index = idToIndex[id];
        Order memory _Order = Orders[index];
        require(amount % _Order.unit == 0, WRONG_PARAMETER);
        require(_Order.label, WRONG_PARAMETER);
        uint256 chargeAmount = amount * _Order.price;
        require(msg.value >= chargeAmount, MATIC_NOT_ENOUGH);
        Orders[index].left -= amount;
        if (Orders[index].left == 0) {
            removeInternalState(id);
        }
        IERC20 sc = IERC20(coinAddresses[_Order.coinType]);
        sc.transfer(msg.sender, amount);
        payable(_Order.launcher).transfer((chargeAmount * 9475) / 10000);
        if (msg.value > chargeAmount) {
            payable(msg.sender).transfer(msg.value - chargeAmount);
        }
        emit OrderBid(id,amount);
    }

    /// @dev Buyer pending order buying coinA/B/C.
    function setBuy(
        uint256 coinType,
        uint256 amount,
        uint256 price,
        uint256 unit
    ) external payable whenNotPaused {
        require(
            amount >= unit && unit > 0 && amount % unit == 0,
            WRONG_PARAMETER
        );
        require(coinAddresses[coinType] != address(0), ADDRESS_NOT_SET);
        uint256 chargeAmount = (price * amount * 10525) / 10000;
        require(msg.value >= chargeAmount, MATIC_NOT_ENOUGH);
        idToIndex[orderCount] = Orders.length;
        idExist[orderCount] = true;
        Order memory _Order = Order({
            id: orderCount,
            coinType: coinType,
            launcher: msg.sender,
            left: amount,
            price: price,
            unit: unit,
            label: false
        });
        Orders.push(_Order);
        emit OrderSet(
            orderCount,
            coinType,
            msg.sender,
            amount,
            price,
            unit,
            false
        );
        orderCount++;
        if (msg.value > chargeAmount) {
            payable(msg.sender).transfer(msg.value - chargeAmount);
        }
    }

    /// @dev Caller should call increaseAllowance in advance.
    function bidBuy(uint256 id, uint256 amount)
        external
        whenNotPaused
        validId(id)
    {
        uint256 index = idToIndex[id];
        Order memory _Order = Orders[index];
        require(amount % _Order.unit == 0, WRONG_PARAMETER);
        require(!_Order.label, WRONG_PARAMETER);
        address addr = coinAddresses[_Order.coinType];
        Orders[index].left -= amount;
        if (Orders[index].left == 0) {
            removeInternalState(id);
        }
        IERC20 sc = IERC20(addr);
        sc.transferFrom(msg.sender, _Order.launcher, amount);
        payable(msg.sender).transfer(amount * _Order.price);
        emit OrderBid(id,amount);
    }

    /// @dev Launcher cancel order.
    ///  Since sc is set by superAdmin, we don't have to worry about re-entrancy attack here.
    function cancelSell(uint256 id) external whenNotPaused validId(id) {
        require(msg.sender == Orders[idToIndex[id]].launcher, NO_PERMISSION);
        removeOrder(id);
    }

    /// @dev Launcher cancel order.
    ///  Since sc is set by superAdmin, we don't have to worry about re-entrancy attack here.
    function cancelSellAdmin(uint256 id) external whenPaused onlyAdmin validId(id) {
        removeOrder(id);
    }

    function removeInternalState(uint256 id) internal {
        delete idExist[id];
        uint256 index = idToIndex[id];
        delete idToIndex[id];
        uint256 l = Orders.length - 1;
        uint256 lastId = Orders[l].id;
        Orders[index] = Orders[l];
        Orders.pop();
        idToIndex[lastId] = index;
    }

    /// @dev Internal function used to remove order.
    ///  Since sc is set by superAdmin, we don't have to worry about re-entrancy attack here.
    function removeOrder(uint256 id) internal {
        uint256 index = idToIndex[id];
        Order memory _Order = Orders[index];
        uint256 amount = _Order.left;
        removeInternalState(id);
        emit OrderCancel(id, msg.sender);
        if (_Order.label) {
            IERC20 sc = IERC20(coinAddresses[_Order.coinType]);
            sc.transfer(_Order.launcher, amount);
        } else {
            payable(_Order.launcher).transfer(
                (amount * _Order.price * 10525) / 10000
            );
        }
    }
}