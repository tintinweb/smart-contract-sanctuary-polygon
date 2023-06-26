// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";

interface IDegSwap {
    function swapSell(uint256 tokenAmount) external;
    function publicMintDegCoin(address user) external;
    function userWithdrawal(address user) external view returns (uint256);
}

interface IDegFactory {
    function serialShip(string memory serial) external view returns (address);
    function ticketAmount(string calldata _serail) external view returns (uint256);
}

interface IDegShip {
    function orderInfos(address _user, uint _orderIndex) external view returns (uint256, uint256, uint256, bool);
}

interface IDegCrew{
    function userTakeOrderInShip(address _user, address _ship) external view returns (uint);
    function transferOwnership(address newOwner) external;
    function checkRefer(address user) external view returns (address);
    function register(address from, address refer) external;
    function userInfo(address _user) external view returns (address referrer,uint8 level,uint32 directNum,uint32 tenGenNum,uint32 fiveGenNum,uint256 start,uint256 totalDeposit,uint256 totalRevenue);
}

interface IDegCommander {
    function register(address refer) external;
    function launchShip(string memory serial, uint256 _amount) external payable;
    function reEntry(string memory serial) external payable;
}

interface IDegSlot{
    function admin() external view returns (address);
    function registeSlot(address ref) external;
    function launchShip(string calldata _serial, uint256 _amout) external;
    function reLaunchShip(string calldata _serial, uint256 _oamount) external;
    function transferAdmin(address newAdmin) external;
    function transferOwner(address newOwner) external;

    function quit() external;
    function withdrawDeg() external;
    function withdraw() external;
    function withdrawBenifit() external;
}

interface IDegBatchShipTool{
    function degCommander() external view returns(address);
    function degSwap() external view returns(address);
    function degCoin() external view returns(address);
    function degFactory() external view returns(address);
    function degCrew() external view returns(address);
}

contract DegShipSlot is IDegSlot, Ownable{

    address public immutable batchShipTool;
    address public immutable commander;
    address public immutable swap;
    address public immutable degToken;

    address public admin;

    uint256 public hostAmount;

    constructor(address _admin, address _tool){
        admin = _admin;
        batchShipTool = _tool;
        commander = IDegBatchShipTool(batchShipTool).degCommander();
        swap = IDegBatchShipTool(batchShipTool).degSwap();
        degToken = IDegBatchShipTool(batchShipTool).degCoin();
    }

    modifier onlyAdmin(){
        require(msg.sender == admin || msg.sender == owner(), "Error admin");
        _;
    }

    receive() external payable {}

    function registeSlot(address ref) public onlyAdmin {
        IDegCommander(commander).register(ref);
    }

    function launchShip(string memory _serial, uint256 _amt) public {
        require(_amt > 0, "error slot");
        require(address(this).balance >= _amt, "Insufficient ship ticket");
        IDegCommander(commander).launchShip{value: _amt}(_serial, _amt);
        hostAmount = hostAmount + _amt;
    }

    function reLaunchShip(string memory _serial, uint256 _shipAmt) public {
        IDegCommander(commander).reEntry{value: _shipAmt}(_serial);
    }

    event SlotQuitEvent(address _addr);

    function quit() public onlyAdmin {
        withdraw();
        withdrawDeg();
        emit SlotQuitEvent(msg.sender);
    }

    event SlotWithdrawDegEvent(address _admin, uint256 _bal);

    function withdrawDeg() public {
        uint256 tokenBal = IERC20(degToken).balanceOf(address(this));
        if (tokenBal > 0){
            IERC20(degToken).transfer(admin, tokenBal);
            emit SlotWithdrawDegEvent(admin, tokenBal);
        }
    }

    event SlotWithdrawEvent(address _admin, uint256 _ben);
    function withdraw() public onlyAdmin {
        uint256 bal = address(this).balance;
        if (bal > 0){
            payable(admin).transfer(bal);
            emit SlotWithdrawEvent(admin, bal);
        }
    }

    function withdrawBenifit() public {
        uint256 bal = address(this).balance;
        if (bal > 0 && bal > hostAmount) {
            uint256 ben = bal - hostAmount;
            payable(admin).transfer(ben);
            emit SlotWithdrawEvent(admin, ben);
        }
    }

    function transferAdmin(address newAdmin) public onlyOwner{
        admin = newAdmin;
    }

    function transferOwner(address newOwner) public onlyOwner{
        transferOwnership(newOwner);
    }
}


contract BatchShipTool is Ownable {
    using SafeMath for uint256; 

    address public degCommander = 0x50bD4dA964C14c415564fAee0cBA72D60F9576bc; 
    address public degSwap = 0x10eC58aB42691f0108cC6f06C017bb00366e427D;
    address public degCoin = 0x8c7027AE2FBcce8A3C2ac7bCaa6340fB796aB306;
    address public degFactory = 0x5b90ddaD47C630b5D83227b3CDef0AE755425249;
    address public degCrew = 0xB8585b946659C0bCE884F4A85B587758fBEb43eA;

    uint256 public degPrice = 10e18;//10 Deg
    uint256 public degLaunchPrice = 1e17;// 0.1Deg
    uint public maxSlotCount = 100;// max slots
    mapping(address => uint256) public degRecharge;

    // mapping(address => mapping(string => uint)) public slotLaunchTime;
    mapping(address => bool) public isSlot;

    mapping(address => address[]) public userSlots;
    mapping(address => uint) public slotRegIndex;
    mapping(address => mapping(string => uint)) public slotExeIndex;
    uint public switchBindType;

    receive() external payable {}

    function balanceOfTool(address addr) public view returns (uint256){
        return degRecharge[addr];
    }

    function lenOfSlots(address addr) public view returns (uint){
        return userSlots[addr].length;
    }

    function lenOfUnRegSlots(address addr) public view returns(uint) {
        if(userSlots[addr].length == 0){
            return 0;
        }
        return userSlots[addr].length - slotRegIndex[addr];
    }

    function lenOfAvaLaunchedSlots(address addr,string memory _serial) public view returns(uint) {
        return slotRegIndex[addr] - slotExeIndex[addr][_serial];
    }

    function lenOfLaunchedSlots(address addr,string memory _serial) public view returns(uint) {
        return slotExeIndex[addr][_serial];
    }

    function crewDepositAmount(address _addr) public view returns(uint256 totalDeposit) {
        (,,,,,,totalDeposit,) = IDegCrew(degCrew).userInfo(_addr);
    }

    function shipOrder(address _slot, string memory _serial) public view returns (uint256 _amount, uint256 _unfreeze) {
        address _ship =  IDegFactory(degFactory).serialShip(_serial);
        uint _index = IDegCrew(degCrew).userTakeOrderInShip(_slot, _ship);
        if (_index > 0) {
            (_amount,,_unfreeze,) = IDegShip(_ship).orderInfos(_slot, _index - 1);
        }
    }

    function amountOfSerialShip(address _slot,string memory _serial) public view returns(uint256 _amount){
        (_amount,) = shipOrder(_slot, _serial);
    }

    event RechargeToolBalEvent(address _addr, uint256 _amount);
    function rechargeToolBalance(uint256 amount) public {
        require(amount >= degLaunchPrice, "Error recharge amount");
        IERC20(degCoin).transferFrom(msg.sender, address(this), amount);
        degRecharge[msg.sender] = degRecharge[msg.sender] + amount;
        emit RechargeToolBalEvent(msg.sender, amount);
    }

    event WithdrawToolBalEvent(address _addr);
    function withdrawToolBalance() public {
        uint256 toolBal = balanceOfTool(msg.sender);
        require(toolBal > 0, "Insufficient tool balance");
        IERC20(degCoin).transfer(msg.sender, toolBal);
        degRecharge[msg.sender] = degRecharge[msg.sender] - toolBal;
        emit WithdrawToolBalEvent(msg.sender);
    }

    event CreateSlotEvent(address indexed _admin, address indexed _slot);

    function createSlot(uint count) public {
        require(count > 0, "Error slot num");
        require(lenOfSlots(msg.sender) + count <= maxSlotCount, "Overflow count");
        uint256 slotCost = count*degPrice;
        require(balanceOfTool(msg.sender) >= slotCost, "Insufficient slot balance");
        degRecharge[msg.sender] = degRecharge[msg.sender] - slotCost;
        for (uint i = 0; i < count; i++) {
            address newSlot = address(new DegShipSlot(msg.sender, address(this)));
            userSlots[msg.sender].push(newSlot);
            isSlot[newSlot] = true;
            emit CreateSlotEvent(msg.sender, newSlot);
        }
    }

    event BindRelationEvent(address indexed _addr, address indexed _slot, address indexed _ref, uint _index);

    function bindRelations(address _user, address ref) internal {
        uint beforeIdx = slotRegIndex[_user]; // initial 0
        address currentSlot = userSlots[_user][beforeIdx];
        address refer = IDegCrew(degCrew).checkRefer(currentSlot);
        if (refer == address(0)) {
            if (switchBindType == 0){
                IDegSlot(currentSlot).registeSlot(ref);
            } else {
                IDegCrew(degCrew).register(currentSlot, ref);
            }
            slotRegIndex[_user] = beforeIdx + 1;
            emit BindRelationEvent(_user, currentSlot, ref, beforeIdx);
        }
    }

    function registSlot(address ref, uint count) public {
        require(crewDepositAmount(ref) > 0, "Invalid ref");
        require(count > 0, "Error count");
        require(lenOfUnRegSlots(msg.sender) >= count, "Insufficient slot count");
        for(uint i = 0; i < count; i++) {
            bindRelations(msg.sender, ref);
        }
    }

    function registOneSlot(address ref) public {
        require(crewDepositAmount(ref) > 0, "Invalid ref");
        require(lenOfUnRegSlots(msg.sender) > 0, "Insufficient bind slots");
        bindRelations(msg.sender, ref);
    }

    event SlotLaunchEvent(address indexed _slot, string indexed _serial, uint _time);
    function batchLaunchShip(uint count, string memory _serial, uint256 _amount) public payable {
        require(count > 0 && lenOfAvaLaunchedSlots(msg.sender, _serial) >= count, "Error count");
        address _shipAddr = IDegFactory(degFactory).serialShip(_serial);
        require(_shipAddr != address(0), "Invalid serial");
        uint256 ticket = IDegFactory(degFactory).ticketAmount(_serial);
        require(_amount.mod(ticket) == 0, "Invalid launch amount" );
        uint256 slotAmount = count*_amount;
        require(msg.value >= slotAmount*2, "Insufficient ticket balance");

        for (uint i = 0; i < count; i++) {
            address _slot = userSlots[msg.sender][slotExeIndex[msg.sender][_serial]];
            payable(_slot).transfer(_amount*2); // another half send once
            IDegSlot(_slot).launchShip(_serial, _amount);
            slotExeIndex[msg.sender][_serial] = slotExeIndex[msg.sender][_serial] + 1;
            (,uint256 _unfreeze) = shipOrder(_slot, _serial);
            emit SlotLaunchEvent(_slot, _serial, _unfreeze);
        }
    }

    event SlotReLaunchEvent(address indexed _slot, string indexed _serial, uint _relaunch);

    function slotReLaunch(address _slot, string memory _serial) internal {
        (,uint256 _unfreeze) = shipOrder(_slot, _serial);
        if (_unfreeze > 0 && _unfreeze <= block.timestamp) {
            uint256 _orderAmount = amountOfSerialShip(_slot, _serial);
            if (address(_slot).balance >= _orderAmount) {
                IDegSlot(_slot).reLaunchShip(_serial, _orderAmount);
                (,uint relaunchAt) = shipOrder(_slot, _serial);
                emit SlotReLaunchEvent(_slot, _serial, relaunchAt);
            }
        }
    }

    function batchRelaunchInner(address who, uint count, string memory _serial) internal {
        uint256 totalFee;
        for (uint i = 0; i < count; i++) {
            address _slot = userSlots[who][i];
            slotReLaunch(_slot, _serial);
            totalFee = totalFee + degLaunchPrice;
        }
        degRecharge[who] = degRecharge[who] - totalFee;
    }

    function batchRelaunchByOther(address who, string memory _serial) public {
        uint count = slotExeIndex[who][_serial];
        require(count > 0, "No slot launched");
        require(balanceOfTool(who) >= degLaunchPrice*count, "Insufficient tool balance");
        batchRelaunchInner(who, count, _serial);
    }

    function batchRelaunchSlotsByOther(address[] memory _slots, string memory _serial) public {
        require(_slots.length > 0 && _slots.length <= 100, "Error relaunch slots len");
        for (uint i = 0; i < _slots.length; i++){
            address _slot = _slots[i];
            address _admin = IDegSlot(_slot).admin();
            if (_admin != address(0) && balanceOfTool(_admin) >= degLaunchPrice){
                slotReLaunch(_slot, _serial);
                degRecharge[_admin] = degRecharge[_admin] - degLaunchPrice;
            }
        }
    }

    function batchRelaunch(string memory _serial) public {
        uint count = slotExeIndex[msg.sender][_serial];
        require(count > 0, "No slot launched");
        require(balanceOfTool(msg.sender) >= degLaunchPrice*count, "Insufficient tool balance");
        batchRelaunchInner(msg.sender, count, _serial);
    }

    function relaunchBySlotAddr(address _slot, string memory _serial) public {
        require(isSlot[_slot], "Wrong slot");
        address _admin = IDegSlot(_slot).admin();
        require(_admin != address(0), "Invalid admin");
        require(balanceOfTool(_admin) >= degLaunchPrice, "Insufficient slot admin deg balance");
        slotReLaunch(_slot, _serial);
        degRecharge[_admin] = degRecharge[_admin] - degLaunchPrice;
    }

    function slotSwapMintDeg(address _slot) public {
        uint256 degBal = IDegSwap(degSwap).userWithdrawal(_slot);
        uint256 poolBal = IERC20(degCoin).balanceOf(degSwap);
        if (degBal > 0 && poolBal >= degBal){
            IDegSwap(degSwap).publicMintDegCoin(_slot);
        }
    }

    function quitSlot(string memory _serial) public {
        require(slotExeIndex[msg.sender][_serial] > 0, "No Executing slot");
        for (uint i = 0; i < slotExeIndex[msg.sender][_serial]; i++) {
            address _slot = userSlots[msg.sender][i];
            IDegSlot(_slot).withdraw();
            slotSwapMintDeg(_slot);
            IDegSlot(_slot).withdrawDeg();
        }
    }

    function quitSlotBySlot(address[] memory slots) public {
        require(slots.length > 0, "No Executing slot");
        for (uint i = 0; i < slots.length; i++) {
            address _slot = slots[i];
            if (isSlot[_slot]){
                IDegSlot(_slot).withdraw();
                slotSwapMintDeg(_slot);
                IDegSlot(_slot).withdrawDeg();
            }
        }
    }

    function withdrawSlotDeg(string memory _serial) public {
        require(slotExeIndex[msg.sender][_serial] > 0, "No Executing slot");
        for (uint i = 0; i < slotExeIndex[msg.sender][_serial]; i++) {
            address _slot = userSlots[msg.sender][i];
            slotSwapMintDeg(_slot);
            IDegSlot(_slot).withdrawDeg();
        }
    }

    function withdrawSlotDegBySlot(address[] memory slots) public {
        require(slots.length > 0, "No Executing slot");
        for (uint i = 0; i < slots.length; i++) {
            address _slot = slots[i];
            if (isSlot[_slot]){
                slotSwapMintDeg(_slot);
                IDegSlot(_slot).withdrawDeg();
            }
        }
    }

    function withdrawSlotBenifit(string memory _serial) public {
        require(slotExeIndex[msg.sender][_serial] > 0, "No Executing slot");
        for (uint i = 0; i < slotExeIndex[msg.sender][_serial]; i++) {
            address _slot = userSlots[msg.sender][i];
            IDegSlot(_slot).withdrawBenifit();
        }
    }

    function withdrawSlotProfitBySlot(address[] memory slots) public {
        require(slots.length > 0, "No Executing slot");
        for (uint i = 0; i < slots.length; i++) {
            address _slot = slots[i];
            if (isSlot[_slot]){
                IDegSlot(_slot).withdrawBenifit();
            }
        }
    }

    function setDegCommander(address _commander) external onlyOwner{
        degCommander = _commander;
    }

    function setMaxSlotCount(uint _max) external onlyOwner{
        maxSlotCount = _max;
    }

    function setDegPrice(uint256 _price) external onlyOwner {
        degPrice = _price;
    }

    function setDegLaunchPrice(uint256 _price) external onlyOwner {
        degLaunchPrice = _price;
    }

    function setSwitchBindType(uint _type) external onlyOwner {
        switchBindType = _type;
    }

    function swapDeg() public onlyOwner {
        uint256 bal = IERC20(degCoin).balanceOf(address(this));
        IDegSwap(degSwap).swapSell(bal);
    }

    function transferCrewOwner(address newOwner) external onlyOwner{
        IDegCrew(degCrew).transferOwnership(newOwner);
    }

    function batchTransferSlotOwner(address[] memory _slots, address newAddr) external onlyOwner{
        for (uint i = 0; i<_slots.length; i++){
            transferSlotOwner(_slots[i], newAddr);
        }
    }

    function transferSlotOwner(address _slot, address newAddr) public onlyOwner{
        IDegSlot(_slot).transferOwner(newAddr);
    }

    function withdrawDeg() public onlyOwner {
        uint256 bal = IERC20(degCoin).balanceOf(address(this));
        IERC20(degCoin).transfer(msg.sender, bal);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
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