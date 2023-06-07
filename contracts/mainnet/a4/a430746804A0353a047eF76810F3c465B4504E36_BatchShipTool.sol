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
    function mintDegCoin() external;
    function userWithdrawal(address user) external view returns (uint256);
}

interface IDegFactory {
    function serialShip(string memory serial) external view returns (address);
    function ticketAmount(string calldata _serail) external view returns (uint256);
}

interface IDegShip {
    function orderAmountById(address _user, uint _orderIndex) external view returns (uint256);
    function checkOrderCondition(address _user,uint _index, uint256 _amount) external view returns (bool);
}

interface IDegCrew{
    function transferOwnership(address newOwner) external;
    function checkRefer(address user) external view returns (address);
    function register(address from, address refer) external;
    function userTakeOrderInShip(address _user, address _ship) external view returns (uint);
}

interface IDegCommander {
    function register(address refer) external;
    function launchShip(string memory serial, uint256 _amount) external payable;
    function reEntry(string memory serial) external payable;
}

interface IDegSlot{
    function registeSlot(address ref) external;
    function launchShip(string calldata _serial, uint256 _amout) external;
    function reLaunchShip(string calldata _serial) external;
    function transferAdmin(address newAdmin) external;
    function transferOwner(address newOwner) external;

    function serialLaunchTime(string calldata) external view returns (uint);
    function quit() external;
    function withdrawDeg() external;
    function withdraw() external;
    function withdrawBenifit() external;
}

contract DegShipSlot is IDegSlot, Ownable{

    address public commander;
    address public swap;
    address public degToken;
    address public degFactory;
    address public degCrew;

    address public admin;

    mapping(string => uint) public serialLaunchTime;

    uint256 public hostAmount;

    constructor(address _admin, address _commander, address _swap, address _token, address _factory, address _crew){
        admin = _admin;
        commander = _commander;
        swap = _swap;
        degToken = _token;
        degFactory = _factory;
        degCrew = _crew;
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
        serialLaunchTime[_serial] = block.timestamp;
    }

    function reLaunchShip(string memory _serial) public {
        address _shipAddr = IDegFactory(degFactory).serialShip(_serial);
        uint _shipIndex = IDegCrew(degCrew).userTakeOrderInShip(address(this), _shipAddr);
        uint256 _shipAmt = IDegShip(_shipAddr).orderAmountById(address(this), _shipIndex);
        require(address(this).balance >= _shipAmt, "Insufficient ship ticket relaunch");
        IDegCommander(commander).reEntry{value: _shipAmt}(_serial);
        serialLaunchTime[_serial] = block.timestamp;
    }

    event SlotQuitEvent(address _addr);

    function quit() public onlyAdmin {
        withdraw();
        withdrawDeg();
        emit SlotQuitEvent(msg.sender);
    }

    event SlotWithdrawDegEvent(address _admin, uint256 _bal);

    function withdrawDeg() public onlyAdmin {
        uint256 degBal = IDegSwap(swap).userWithdrawal(address(this));
        if (degBal > 0){
            IDegSwap(swap).mintDegCoin();
        }
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

    function withdrawBenifit() public onlyAdmin {
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

    address public degCommander = 0x855A66b2D814Ac221a804BAA0fa5e3506A4F4E0c; 
    address public degSwap = 0x10eC58aB42691f0108cC6f06C017bb00366e427D;
    address public degCoin = 0x8c7027AE2FBcce8A3C2ac7bCaa6340fB796aB306;
    address public degFactory = 0x5b90ddaD47C630b5D83227b3CDef0AE755425249;
    address public degCrew = 0xB8585b946659C0bCE884F4A85B587758fBEb43eA;

    uint256 public degPrice = 10e18;//10 Deg
    uint256 public degLaunchPrice = 1e17;// 0.1Deg
    mapping(address => uint256) public degRecharge;

    mapping(address => address[]) public userSlots;
    mapping(address => address[]) public userRegSlots;
    mapping(address => address[]) public launchedSlots;

    mapping(string => mapping(address =>  uint)) public userLaunchTime;
    mapping(address => bool) public isSlot;
    mapping(address => uint) public slotIndex;
    uint public switchBindType;

    receive() external payable {}

    function setDegPrice(uint256 _price) external onlyOwner {
        degPrice = _price;
    }

    function setDegLaunchPrice(uint256 _price) external onlyOwner {
        degLaunchPrice = _price;
    }

    function setSwitchBindType(uint _type) external onlyOwner {
        switchBindType = _type;
    }

    function balanceOfTool(address addr) public view returns (uint256){
        return degRecharge[addr];
    }

    event RechargeToolBalEvent(address _addr, uint256 _amount);
    function rechargeToolBalance(uint256 amount) public {
        require(amount >= degPrice, "Error recharge amount");
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

    event CreateSlotEvent(address _admin, uint _count, string _serial, uint256 _amount);
    function createSlot(uint count, string memory _serial, uint256 _amount) public payable {
        require(count > 0, "Error slot num");
        require(lenOfSlots(msg.sender) + count <= 500, "Overflow count");
        uint256 ticket = IDegFactory(degFactory).ticketAmount(_serial);
        require(_amount >= 50*2 && _amount.mod(ticket*2) == 0 );

        uint256 slotCost = count*degPrice;
        require(balanceOfTool(msg.sender) >= slotCost, "Insufficient slot balance");
        uint256 slotAmount = count*_amount;
        require(msg.value >= slotAmount, "Insufficient ticket balance");
        degRecharge[msg.sender] = degRecharge[msg.sender] - slotCost;
        for (uint i = 0; i < count; i++) {
            address newSlot = address(new DegShipSlot(msg.sender, degCommander, degSwap, degCoin, degFactory, degCrew));
            payable(newSlot).transfer(_amount);
            userSlots[newSlot].push(newSlot);
            isSlot[newSlot] = true;
        }
        emit CreateSlotEvent(msg.sender, count, _serial, _amount);
    }

    function lenOfSlots(address addr) public view returns (uint){
        return userSlots[addr].length;
    }

    function lenOfRegSlots(address addr) public view returns(uint) {
        return userRegSlots[addr].length;
    }

    function lenOfLaunchedSlots(address addr) public view returns(uint) {
        return launchedSlots[addr].length;
    }

    function registSlot(address ref, uint count) public {
        require(count > 0, "Error count");
        require(lenOfSlots(msg.sender) - lenOfRegSlots(msg.sender) >= count, "Insufficient slot count");
        for(uint i = 0; i < count; i++){
            bindRelations(ref);
        }
    }

    event BindRelationEvent(address _addr, address _slot, address _ref, uint _index);

    function bindRelations(address ref) public {
        require(lenOfSlots(msg.sender) > lenOfRegSlots(msg.sender), "Insufficient bind slots");
        uint beforeIdx = slotIndex[msg.sender];
        address currentSlot = userSlots[msg.sender][beforeIdx];
        address refer = IDegCrew(degCrew).checkRefer(currentSlot);
        if (refer == address(0)){
            if (switchBindType == 0){
                IDegCrew(degCrew).register(currentSlot, ref);
            } else {
                IDegSlot(currentSlot).registeSlot(ref);
            }
            userRegSlots[msg.sender].push(currentSlot);
            slotIndex[msg.sender] = beforeIdx + 1;
            emit BindRelationEvent(msg.sender, currentSlot, ref, beforeIdx);
        }
    }

    function swapDeg() public onlyOwner {
        uint256 bal = IERC20(degCoin).balanceOf(address(this));
        IDegSwap(degSwap).swapSell(bal);
    }

    function batchLaunchShip(string memory _serial, uint256 _amount) public {
        address[] memory slots = userRegSlots[msg.sender];
        for (uint i = 0; i < slots.length; i++) {
            address slot = slots[i];
            try IDegSlot(slot).launchShip(_serial, _amount) {
                launchedSlots[msg.sender].push(slot);
                userLaunchTime[_serial][msg.sender] = block.timestamp;
            } catch {}
        }
    }

    function batchRelaunch(string memory _serial) public {
        address[] memory slots = launchedSlots[msg.sender];
        uint count = slots.length;
        require(balanceOfTool(msg.sender) >= degLaunchPrice*count, "Insufficient tool balance");

        uint256 totalFee;
        for (uint i = 0; i < count; i++) {
            address _slot = slots[i];
            totalFee = totalFee + degLaunchPrice;
            slotReLaunch(_slot, msg.sender, _serial);
        }
        degRecharge[msg.sender] = degRecharge[msg.sender] - totalFee;
    }

    function slotReLaunch(address _slot, address _user, string memory _serial) private {
        uint _time = IDegSlot(_slot).serialLaunchTime(_serial);
        if (_time > 0 && _time <= block.timestamp) {
            try IDegSlot(_slot).reLaunchShip(_serial) {
                // do nothing
                userLaunchTime[_serial][_user] = block.timestamp;
            } catch {}
        }
    }

    function relaunchBySlotAddr(address _slot, string memory _serial) public {
        require(isSlot[_slot], "Wrong slot");
        require(balanceOfTool(msg.sender) >= degLaunchPrice, "Insufficient tool balance");
        degRecharge[msg.sender] = degRecharge[msg.sender] - degLaunchPrice;
        slotReLaunch(_slot, msg.sender, _serial);
    }

    function quitSlot() public {
        address[] memory slots = launchedSlots[msg.sender];
        for (uint i = 0; i < slots.length; i++) {
            address slot = slots[i];
            try IDegSlot(slot).quit() {} catch {}
        }
    }

    function withdrawSlotDeg() public {
        address[] memory slots = launchedSlots[msg.sender];
        for (uint i = 0; i < slots.length; i++) {
            address slot = slots[i];
            try IDegSlot(slot).withdrawDeg() {} catch {}
        }
    }

    function withdrawSlotBenifit() public {
        address[] memory slots = launchedSlots[msg.sender];
        for (uint i = 0; i < slots.length; i++) {
            address slot = slots[i];
            IDegSlot(slot).withdrawBenifit();
        }
    }

    event TransferAllSlotEvent(address _oldAdmin, address _newAdmin, uint _count);

    function transferAllSlot(address newAdmin) public {
        address[] memory slots = userSlots[msg.sender];
        require(slots.length > 0, "No slot");
        IERC20(degCoin).transferFrom(msg.sender, address(this), slots.length*degPrice);
        for (uint i = 0; i < slots.length; i++) {
            address slot = slots[i];
            IDegSlot(slot).transferAdmin(newAdmin);
        }
        address[] memory regSlots = userRegSlots[msg.sender];
        address[] memory launched = launchedSlots[msg.sender];

        delete userSlots[msg.sender];
        delete userRegSlots[msg.sender];
        delete launchedSlots[msg.sender];

        userSlots[newAdmin] = slots;
        userRegSlots[newAdmin] = regSlots;
        launchedSlots[newAdmin] = launched;

        emit TransferAllSlotEvent(msg.sender, newAdmin, slots.length);
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