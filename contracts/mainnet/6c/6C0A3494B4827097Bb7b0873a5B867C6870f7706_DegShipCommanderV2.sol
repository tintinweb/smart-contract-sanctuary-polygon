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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./DegShipFactoryV2.sol";
import "./interfaces/IDegShipV2.sol";
import "./interfaces/IDegCrewExtend.sol";
import "./interfaces/IDegShipCommanderV2.sol";
import "./interfaces/IDegSwap.sol";

contract DegShipCommanderV2 is IDegShipCommanderV2, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IDegShipFactoryV2 public shipFactory;
    IDegCrewExtend public immutable shipCrew;

    IDegSwap public degSwap = IDegSwap(0x10eC58aB42691f0108cC6f06C017bb00366e427D);

    uint256 private constant MAX = type(uint256).max;

    mapping(address => uint256) public shipRewardPool;
    mapping(address => uint256) public shipTotalReward;

    bool public isUpdateShipOrder;
    mapping(address => mapping(address => bool)) public shipPointCollect;

    bool public isLuckPool;
    mapping(address => uint256) public luckPool;
    mapping(address => bool) public luckDividend;

    address[] public feeReceiver;

    struct LastedDeposit{
        string serial;
        address user;
        uint256 amount;
        uint256 time;
    }

    LastedDeposit[] public lastedDeposits;

    mapping(uint => uint256) public dayRecordPool;
    mapping(uint => uint256) public dayInvestTotal;
    mapping(uint => mapping(address => uint256)) public dayUserInvestTotal;

    uint public immutable aDay = 1 days; 
    uint public immutable startTime;
    uint public recordDay;

    constructor(
        address _crewAddress
    ) {
        startTime = 1681941600;
        shipFactory = new DegShipFactoryV2(startTime, aDay, address(this), msg.sender);
        shipCrew = IDegCrewExtend(_crewAddress);   
    }

    receive() external payable {}

    modifier onlyCrewOrShip() {
        require(msg.sender == address(shipCrew) || shipCrew.isCaller(msg.sender) || msg.sender == owner(), "Wrong ship or crew by address");
        _;
    }

    modifier onlyCrew(){
        require(msg.sender == address(shipCrew), "Wrong crew call");
        _;
    }

    function setFeeReceiver(address[] memory _addrs) external onlyOwner{
        feeReceiver = _addrs;
    }

    function setShipFactory(address _factory) external onlyOwner{
        shipFactory = IDegShipFactoryV2(_factory);
    }

    function getSerials() external view returns (string[] memory) {
        return shipFactory.getSerials();
    }

    function crewAddress() external view returns (address) {
        return address(shipCrew);
    }

    function initNewSerialShip(string memory serial, uint256 ticketPrice, uint256 percent, uint256 perCycle) private returns (address newShip){
        newShip = shipFactory.shipCreated(serial, shipFactory.serialIndex(serial), ticketPrice, percent, perCycle);
    }

    function createNewSerialShip(string memory serial, uint256 ticketPrice, uint256 percent, uint256 perCycle) external onlyOwner{
        require(shipFactory.serialShip(serial) == address(0), "Serial exist");
        address shipAddr = initNewSerialShip(serial, ticketPrice, percent, perCycle);
        shipCrew.addCaller(shipAddr);
        shipFactory.setSerialShip(serial, shipAddr);
    }

    event EventShipIncome(address indexed _ship, uint256 _amount);

    function shipIncome(address _ship, uint256 _income) private {
        unchecked {
            shipRewardPool[_ship] += _income;
        }
        emit EventShipIncome(_ship, _income);
    }

    event EventShipOutcome(address indexed _ship, uint256 _amount);
    event EventShipInsufficientReward(address indexed _ship);

    function shipOutcome(address _ship, address _user, uint256 _outcome) external onlyCrewOrShip() {
        uint256 nowReleaseToken = shipReleaseAmountToStop(_ship);
        _outcome = nowReleaseToken >= _outcome ? _outcome : nowReleaseToken;
        if( _outcome > 0 ){
            unchecked {
                shipTotalReward[_ship] += _outcome;
            }
            address ticket = shipFactory.getTicketTokenByShip(_ship);
            if (ticket == address(0)){
                payable(_user).transfer(_outcome);
            }else{
                IERC20(ticket).transfer(_user, _outcome);
            }
            emit EventShipOutcome(_ship, _outcome);
        } else {
            emit EventShipInsufficientReward(_ship);
        }
    }

    function shipReleaseAmountToStop(address _ship) public view returns (uint256) {
        return shipRewardPool[_ship] > shipTotalReward[_ship] ? shipRewardPool[_ship].sub(shipTotalReward[_ship]) : 0;
    }

    function checkShipStop(address _ship) public view returns (bool) {
        if (shipRewardPool[_ship] > 0 && shipReleaseAmountToStop(_ship) == 0) {
            return true;
        }
        return false;
    }

    event EventDestroyShipOfSerial(address indexed oldShip, address indexed newShip);

    function destroyShipOfSerial(string memory serial) private {
        address oldShip = shipFactory.serialShip(serial);
        uint256 percents = IDegShipV2(oldShip).dayRewardPercents();
        uint256 perCycle = IDegShipV2(oldShip).dayPerCycle();
        uint256 shipPrice = shipFactory.ticketAmount(serial);
        address newShip = initNewSerialShip(serial, shipPrice, percents,perCycle);
        shipCrew.addCaller(newShip);
        shipFactory.addSerialNewShip(serial, newShip);
        emit EventDestroyShipOfSerial(oldShip, newShip);
    }

    function shipIndexStatus(string memory serial, uint8 sindex) external view returns (bool) {
        address ship = shipFactory.serialIndexShip(serial, sindex);
        return IDegShipV2(ship).stopped();
    }

    function _basicDistributeDeposit(address _ticket, address _ship, uint256 _amount) private returns (uint256 totalFee){
        uint256 nodeFee = _amount.mul(3).div(1000);
        uint256 daoFee = _amount.mul(2).div(1000);
        uint256 techFee = _amount.mul(1).div(1000);
        uint256 coinFee = _amount.mul(10).div(1000);
        uint256 fomoFee = _amount.mul(2).div(1000);

        if (_ticket == address(0)) {
            payable(feeReceiver[0]).transfer(nodeFee);
            payable(feeReceiver[1]).transfer(daoFee);
            payable(feeReceiver[2]).transfer(coinFee);
            payable(feeReceiver[3]).transfer(techFee);
            if (isLuckPool == false){
                payable(feeReceiver[4]).transfer(fomoFee);
            }
        } else {
            IERC20(_ticket).transfer(feeReceiver[0], nodeFee);
            IERC20(_ticket).transfer(feeReceiver[1], daoFee);
            IERC20(_ticket).transfer(feeReceiver[3], techFee);
            uint256 totalCollect = coinFee;
            if (isLuckPool == false){
                totalCollect += fomoFee;
            }
            IERC20(_ticket).transfer(feeReceiver[4], totalCollect);
        }
        if (isLuckPool == true){
            luckPool[_ship] += fomoFee;
        }

        if (_ticket == address(0)) {
            // only origin coin mint coin
            dayRecordPool[recordDay] += coinFee;
        }
        unchecked {
            totalFee = nodeFee + daoFee + coinFee + techFee + fomoFee;
        }
    }

    function _distributeDeposit(address _ticket, address _ship, uint256 _amount) private {
        uint256 totalFee = _basicDistributeDeposit(_ticket, _ship, _amount);
        uint256 _poolAmount = _amount.sub(totalFee);
        // Record pool amount
        shipIncome(_ship, _poolAmount);
    }

    function register(address refer) external {
        require(refer != msg.sender, "Cannot refer your self");
        require(refer != address(0), "Refer is illegel");
        shipCrew.register(msg.sender, refer);
    }

    event ShipStopped(address indexed _ship);

    modifier recordDayModifier() {
        if (getDay() > recordDay){
            recordDay = getDay();
        }
        _;
    }

    modifier prepareShipStock(string memory serial) {
        if (!shipFactory.stockReset(serial, recordDay) && shipFactory.shipSupply(serial) > 0) {
            shipFactory.setDayShipStock(serial, recordDay, shipFactory.shipSupply(serial));
        }
        _;
    }

    event CheckLastShipPointEvent(address indexed _user, address indexed _ship, uint256 _amount);

    function checkLastShipPoint(address _user, string memory _serial) private {
        // check my last ship point
        address lastShip = shipFactory.lastShipOfSerial(_serial);
        if (lastShip != address(0)) {
            uint nowOrderId = shipCrew.userTakeOrderInShip(_user, lastShip);
            if (nowOrderId > 0) {
                uint256 amount = IDegShipV2(lastShip).orderAmountByUnfreezeId(_user, nowOrderId - 1);
                if ( amount > 0 ) {
                    if (isUpdateShipOrder) {
                        // will open to use this function after M0T1 banned
                        IDegShipV2(lastShip).destroyUserOrder(_user, nowOrderId - 1);
                        shipCrew.addUserPointBalance(_user, amount);
                        emit CheckLastShipPointEvent(_user, lastShip, amount);
                    } else if (!shipPointCollect[lastShip][_user]){
                        // fixed old version ship contract, it'll unused after the second ship destroyed
                        shipCrew.addUserPointBalance(_user, amount);
                        shipPointCollect[lastShip][_user] = true;
                        emit CheckLastShipPointEvent(_user, lastShip, amount);
                    }
                }
            }
        }
    }

    function afterLaunch(address _token, string memory serial, address _ship, uint256 _amount) private {
        // record invest order infos
        if (_token == address(0)){
            recordMintCoin(msg.sender, _amount);
        }
        recordDeposits(serial, msg.sender, _amount);
        // ship stopped gameover
        bool _checkShipStatus = checkShipStop(_ship);
        if ( _checkShipStatus ) {
            // stopped start another ship
            luckDividend[_ship] = true;
            if(shipFactory.shipFactoryAutoMaker(serial)) {
                destroyShipOfSerial(serial);
            }
            emit ShipStopped(_ship);
        }
    }

    function beforOrderCheck(address _ship) private view {
        require(_ship != address(0), "Invalid ship serial");
        bool _shipStatus = IDegShipV2(_ship).stopped();
        require(!_shipStatus, "Ship stopped");
        // check last order and this order is passed
    }

    function getDay() public view returns (uint) {
        if (block.timestamp > startTime){
            return (block.timestamp - startTime) / aDay;
        }else{
            return 0;
        }
    }

    function shipStockCheck(string memory serial) public view returns(uint) {
        if (shipFactory.stockReset(serial, recordDay)) {
            return shipFactory.shipStocks(serial, recordDay);
        } else {
            return shipFactory.shipSupply(serial);
        }
    }

    event EventLaunch(address indexed _user, address indexed _ship, uint256 _amount, uint _orderIndex);
    event EventReLaunch(address indexed _user, address indexed _ship, uint256 _amount, uint _orderIndex);

    // serial's ticket token and amount
    function ticketTokenAndAmount(string memory serial) public view returns(address ticketToken, uint256 ticketAmount){
        ticketToken = shipFactory.ticketToken(serial);
        ticketAmount = shipFactory.ticketAmount(serial); 
    }

    function launchShip(string memory serial, uint256 _amount) external payable recordDayModifier prepareShipStock(serial) {
        address _ticketToken;
        uint256 ticketAmount;
        (_ticketToken, ticketAmount) = ticketTokenAndAmount(serial);
        require(_amount >= ticketAmount && _amount.mod(ticketAmount) == 0, "Ticket amount err");
        require(_amount.div(ticketAmount) <= shipFactory.limitLaunchNum(serial), "Overflow the num");
        address _launchShipAddr = shipFactory.serialShip(serial);
        beforOrderCheck(_launchShipAddr);

        if (shipFactory.shipSupply(serial) > 0){
            require(shipStockCheck(serial) >= _amount, "Insufficient stocks");
        }

        address _refer = shipCrew.checkRefer(msg.sender);
        require(_refer != address(0), "Regist first");
        // user now order index
        uint nowOrderId = shipCrew.userTakeOrderInShip(msg.sender, _launchShipAddr);
        require(nowOrderId == 0, "Must new launch");
        // pay ticket
        if(_ticketToken == address(0)){
            require(msg.value >= _amount, "pay amount error");
        }else{
            IERC20(_ticketToken).transferFrom(msg.sender, address(this), _amount);
        }
        
        _distributeDeposit(_ticketToken, _launchShipAddr, _amount);
        // check last ship point
        checkLastShipPoint(msg.sender, serial);
        // main launch the ship
        IDegShipV2(_launchShipAddr).launch(msg.sender, _amount, nowOrderId);

        if (shipFactory.shipSupply(serial) > 0) {
            shipFactory.subStock(serial, recordDay, _amount);
        }
        afterLaunch(_ticketToken, serial, _launchShipAddr, _amount);
        // user point to dividend
        shipCrew.pointDividend(msg.sender, _launchShipAddr);
        // trigger collect my deg mint
        degSwap.collectUserDegBal(msg.sender);
        emit EventLaunch(msg.sender, _launchShipAddr, _amount, nowOrderId);
    }

    function reEntry(string memory serial) external payable recordDayModifier prepareShipStock(serial) {
        address _launchShipAddr = shipFactory.serialShip(serial);
        // check ship status
        beforOrderCheck(_launchShipAddr);
        uint nowOrderId = shipCrew.userTakeOrderInShip(msg.sender, _launchShipAddr);
        require(nowOrderId > 0, "None order regist");
        uint256 _amount = IDegShipV2(_launchShipAddr).orderAmountById(msg.sender, nowOrderId - 1);
        bool _condition = IDegShipV2(_launchShipAddr).checkOrderCondition(msg.sender, nowOrderId - 1, _amount);
        require(_condition, "Order condition is not allowed!");
        // relaunch now ship
        address _ticketToken = shipFactory.ticketToken(serial);
        // pay ticket
        if(_ticketToken == address(0)){
            require(msg.value >= _amount, "pay amount error");
        }else{
            IERC20(_ticketToken).transferFrom(msg.sender, address(this), _amount);
        }

        _distributeDeposit(_ticketToken, _launchShipAddr, _amount);
        // check last ship point
        // checkLastShipPoint(msg.sender, serial); only launch to check
        // relaunch
        IDegShipV2(_launchShipAddr).reLaunch(msg.sender, nowOrderId);
        // after launch process
        afterLaunch(_ticketToken, serial, _launchShipAddr, _amount);
        // user point to dividend
        shipCrew.pointDividend(msg.sender, _launchShipAddr);
        // trigger collect my deg mint
        degSwap.collectUserDegBal(msg.sender);
        emit EventReLaunch(msg.sender, _launchShipAddr, _amount, nowOrderId);
    }

    // share fomo bonus trigger by any one
    function dividendFomoBonus(address _ship) external {
        require(luckDividend[_ship], "Ship not ended");
        uint256 totalPool = luckPool[_ship];
        require(totalPool > 0, "Pool is empty");
        address ticketToken = shipFactory.getTicketTokenByShip(_ship);
        uint totalInvestor = IDegShipV2(_ship).getDepositorsLength();
        if (totalInvestor > 0) {
            uint endIndex = totalInvestor - 1;
            uint startIndex = endIndex > 50 ? endIndex - 50 : 0;

            uint256 thirdTotalBouns = totalPool.mul(50).div(100);
            uint256 thirdBonus = thirdTotalBouns.div(46);
            uint256 secondTotalBonus = totalPool.mul(20).div(100);
            uint256 secondBonus = secondTotalBonus.div(3);
            uint256 firstBonus = totalPool.sub(thirdTotalBouns).sub(secondTotalBonus);
            for (uint i = startIndex + 1; i <= endIndex; i++) {
                address accuqire = IDegShipV2(_ship).depositors(i);
                uint bonus;
                if (i == endIndex) {
                    //30%
                    bonus = firstBonus;
                } else if(i > endIndex - 4 && i < endIndex){
                    //20% div 3
                    bonus = secondBonus;
                } else {
                    bonus = thirdBonus;
                }
                if( bonus > 0 ){
                    if (ticketToken == address(0)) {
                        payable(accuqire).transfer(bonus);
                    } else {
                        IERC20(ticketToken).transfer(accuqire, bonus);
                    }
                }
            }
        }
        luckPool[_ship] = 0;
    }

    function dividendFomoFirstBonus(address _ship, uint256 _amount) external onlyOwner{
        require(address(this).balance >= _amount, "insufficient amount");
        address ticketToken = shipFactory.getTicketTokenByShip(_ship);
        uint totalInvestor = IDegShipV2(_ship).getDepositorsLength();
        if (totalInvestor > 0) {
            uint endIndex = totalInvestor - 1;
            uint startIndex = endIndex > 4 ? endIndex - 4 : 0;

            uint256 secondTotalBonus = _amount.mul(40).div(100);
            uint256 secondBonus = secondTotalBonus.div(3);
            uint256 firstBonus = _amount.sub(secondTotalBonus);
            for (uint i = startIndex + 1; i <= endIndex; i++) {
                address accuqire = IDegShipV2(_ship).depositors(i);
                uint bonus;
                if (i == endIndex) {
                    //30%
                    bonus = firstBonus;
                } else if(i > endIndex - 4 && i < endIndex){
                    //20% div 3
                    bonus = secondBonus;
                } 

                if( bonus > 0 ){
                    if (ticketToken == address(0)) {
                        payable(accuqire).transfer(bonus);
                    } else {
                        IERC20(ticketToken).transfer(accuqire, bonus);
                    }
                }
            }
        }
    }

    // check my bonus point
    function checkMyPoint(string memory _serial) external payable {
        checkLastShipPoint(msg.sender, _serial);
    }

    function getLastedDepositsLength() external view returns (uint) {
        return lastedDeposits.length;
    }

    function recordMintCoin(address _user, uint256 _amount) private {
        uint _today = getDay();
        unchecked {
            dayInvestTotal[_today] += _amount;
            dayUserInvestTotal[_today][_user] += _amount;
        }
    }

    function recordDeposits(string memory _serial, address _user, uint256 _amount) private {
        lastedDeposits.push(LastedDeposit(
            _serial,
            _user,
            _amount,
            block.timestamp
        ));
    }

    function collectGas(address _addr) external onlyOwner {
        payable(_addr).transfer(address(this).balance);
    }

    function emergencyWithdraw(address _token, address _user, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_user, _amount);
    }

    function setDegSwap(address _addr) external onlyOwner{
        degSwap = IDegSwap(_addr);
    }

    function setSwitcher(bool _luck) external onlyOwner{
        isLuckPool = _luck;
    }

    function setUpdateShipOrder(bool _flag) external onlyOwner{
        isUpdateShipOrder = _flag;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDegShipFactoryV2.sol";
import "./libraries/Strings.sol";
import "./DegShipV2.sol";

contract DegShipFactoryV2 is IDegShipFactoryV2, Ownable {
    
    string[] public serials;
    mapping(string => address) public serialShip; // serial's ship address
    mapping(string => uint256) public serialIndex; // serial's ship round
    mapping(address => string) public shipToSerial; // record ship's serial
    mapping(string => mapping(uint256 => address)) public serialIndexShip;

    mapping(string => bool) public shipFactoryAutoMaker;
    mapping(string => address) public ticketToken;
    mapping(string => uint256) public ticketAmount;

    mapping(string => uint) public limitLaunchNum;
    mapping(string => uint256) public shipSupply;
    mapping(string => mapping(uint => uint256)) public shipStocks;
    mapping(string => mapping(uint => bool)) public stockReset;

    address public commander;
    mapping(address => bool) public isCaller;  // contract caller allowed

    uint public immutable startTime;
    uint public immutable factoryDay;

    constructor (uint _time, uint _ady, address _commander, address _ow){
        startTime = _time;
        factoryDay = _ady;
        commander = _commander; 
        isCaller[_commander] = true;
        _transferOwnership(_ow);
    }

    modifier onlyCaller() {
        require(isCaller[msg.sender] || msg.sender == owner(), "Wrong Caller");
        _;
    }

    function setCommander(address _commander) external onlyOwner{
        isCaller[commander] = false;
        commander = _commander;
        isCaller[_commander] = true;
    }

    function setCaller(address _caller, bool _flag) external onlyOwner{
        isCaller[_caller] = _flag;
    }

    // must need set when the ship start up
    function setSerialTicketPrice(string memory _serial, uint256 amount) external onlyOwner{
        ticketAmount[_serial] = amount;
    }

    function setSerialTicketToken(string memory _serial, address token) external onlyOwner{
        ticketToken[_serial] = token;
    }

    function addSerials(string memory _serial) external onlyOwner{
        require(serialShip[_serial] == address(0), "Serial exist");
        serials.push(_serial);
        shipFactoryAutoMaker[_serial] = true;
    }

    function setShipFactoryAutoMaker(string memory _serial, bool _flag) external onlyOwner{
        shipFactoryAutoMaker[_serial] = _flag;
    }

    function setShipSupply(string memory _serial, uint256 _num) external onlyOwner{
        shipSupply[_serial] = _num;
    }

    function setStockReset(string memory _serial, uint _day, bool _flag) external onlyOwner{
        stockReset[_serial][_day] = _flag;
    }

    function setShipLimitNum(string memory _serial, uint _num) external onlyOwner{
        limitLaunchNum[_serial] = _num;
    }

    // private function
    function addSerialShip(string memory _serial, address _ship) private {
        serialShip[_serial] = _ship;
        shipToSerial[_ship] = _serial;
    }

    function addSerialIndexShip(string memory _serial, uint256 _index, address _ship) private{
        serialIndexShip[_serial][_index] = _ship;
    }

    event ShipCreated(address indexed _ship, string _serial, uint256 _index, uint256 _price);
    // commaner function
    function shipCreated(
        string memory _serial, 
        uint256 _index, 
        uint256 _amount,
        uint256 percent, 
        uint256 perCycle) external onlyCaller returns (address ship) {
        require(shipFactoryAutoMaker[_serial], "Serial make ship closed");
        address newShip = address(new DegShipV2());
        ticketAmount[_serial] = _amount;
        if (limitLaunchNum[_serial] == 0){
            limitLaunchNum[_serial] = 1;
        }
        IDegShipV2(newShip).initialize(commander, _serial, string(abi.encodePacked(_serial, Strings.toString(_index))), percent, perCycle);
        ship = newShip;
        emit ShipCreated(newShip, _serial, _index, _amount);
    }

    function setSerialShip(string memory _serial, address _ship) external onlyCaller{
        addSerialShip(_serial, _ship);
        addSerialIndexShip(_serial, serialIndex[_serial], _ship);
    }

    function addSerialNewShip(string memory _serial, address _newShip) external onlyCaller{
        addSerialShip(_serial, _newShip);
        serialIndex[_serial] += 1;
        addSerialIndexShip(_serial, serialIndex[_serial], _newShip);
    }

    function setDayShipStock(string memory _serial, uint _day, uint256 _num) external onlyCaller{
        shipStocks[_serial][_day] = _num;
        stockReset[_serial][_day] = true;
    }

    function subStock(string memory _serial, uint _day, uint256 _num) external onlyCaller{
        shipStocks[_serial][_day] -= _num;
    }

    // public function
    function getDay() public view returns (uint){
        if ( block.timestamp > startTime){
            return (block.timestamp - startTime) / factoryDay;
        } else {
            return 0;
        }
    }

    function getSerialLen() public view returns (uint256){
        return serials.length;
    }

    function getSerials() public view returns (string[] memory){
        return serials;
    }

    function getSerialByIndex(uint256 _index) public view returns (string memory){
        return serials[_index];
    }

    function getTicketTokenByShip(address _ship) public view returns (address){
        return ticketToken[shipToSerial[_ship]];
    }

    function getTicketAmountByShip(address _ship) public view returns (uint256){
        return ticketAmount[shipToSerial[_ship]];
    }

    // last ship
    function lastShipOfSerial(string memory _serail) public view returns(address _ship) {
        if (serialIndex[_serail] > 0) {
            _ship = serialIndexShip[_serail][serialIndex[_serail] - 1];
        }
    }

    function getDepositorByInterval(address _ship, uint _start, uint _end) public view returns (address[] memory) {
        uint len = IDegShipV2(_ship).getDepositorsLength();
        address[] memory addrs;
        if (len == 0 || _start > _end){
            addrs = new address[](1);
            addrs[0] = address(0);
            return addrs;
        }

        if (_end >= len){
            _end = len - 1;
        }

        addrs = new address[](_end - _start + 1);
        for (uint i = _start; i <= _end; i++) {
            addrs[i - _start] = IDegShipV2(_ship).depositors(i);
        }
        return addrs;
    }

    function getDepositorByNum(address _ship, uint _num) external view returns(address[] memory){
        uint len = IDegShipV2(_ship).getDepositorsLength();
        uint _start;
        address[] memory addrs;
        if ( len == 0 ) {
            addrs = new address[](1);
            addrs[0] = address(0);
            return addrs;
        } else if (len > _num) {
            _start = len - _num;
            addrs = new address[](_num);
        } else {
            addrs = new address[](len);
        }
        for (uint i = _start; i <= len - 1; i++) {
            addrs[i - _start] = IDegShipV2(_ship).depositors(i);
        }
        return addrs;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IDegCrew.sol";
import "./interfaces/IDegShipCommanderV2.sol";
import "./interfaces/IDegShipV2.sol";

contract DegShipV2 is IDegShipV2 {
    using SafeMath for uint256; 

    string public shipName;
    IDegCrew public crewAddress;
    uint public startTime;

    address public factory;
    string public shipSerial;

    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    uint256 public dayPerCycle = 1 days;

    uint256 public dayRewardPercents = 1; // static reward

    IDegShipCommanderV2 public commander;

    bool public stopped = false;

    constructor() {
        factory = msg.sender;
    }

    event EventInitialShip(address indexed _commander, string _name, address _crew, uint _percent, uint _perCycle);

    function initialize(address _commander,
        string memory _serial, 
        string memory _name, uint256 _dayReward, uint256 _perCycle) external {
        require(msg.sender == factory, 'DegShip Factory: FORBIDDEN'); // sufficient check
        shipName = _name;
        shipSerial = _serial;
        commander = IDegShipCommanderV2(_commander);
        crewAddress = IDegCrew(commander.crewAddress());
        
        startTime = block.timestamp;
        dayRewardPercents = _dayReward;
        dayPerCycle = _perCycle;
        emit EventInitialShip(_commander, shipName, address(crewAddress), dayRewardPercents, dayPerCycle);
    }

    event ShipLaunched(address indexed _from, bool _shipStatus, uint256 _amount);

    function afterLaunch(address from, uint256 amount) private {
        stopped = commander.checkShipStop(address(this));
        emit ShipLaunched(from, stopped, amount);
    }

    // start
    function launch(address from, uint256 _amount, uint orderIndex) external {
        require(msg.sender == address(commander), "Invalid commander");
        crewAddress.deposit(from, _amount);
        // _unfreezeFundAndUpdateReward(from, orderIndex);
        uint nowTime = block.timestamp;
        if (nowTime < commander.startTime()) {
            nowTime = commander.startTime();
        }
        uint256 unfreezeTime = nowTime.add(dayPerCycle);
        orderInfos[from].push(OrderInfo(
            _amount, 
            nowTime, 
            unfreezeTime,
            false
        ));
        depositors.push(from);
        crewAddress.updateUserDepositShipOid(from, address(this), orderIndex + 1);
        afterLaunch(from, _amount);
    }

    function reLaunch(address from, uint orderIndex) external {
        require(msg.sender == address(commander), "Invalid commander");
        OrderInfo storage order = orderInfos[from][orderIndex - 1];
        crewAddress.reDeposit(from, address(this), order.amount, orderIndex);
        _unfreezeFundQuit(from, order.amount);
        
        uint nowTime = block.timestamp;
        uint256 _unfreezeTime = nowTime.add(dayPerCycle);
        order.start = nowTime;
        order.unfreeze = _unfreezeTime;

        afterLaunch(from, order.amount);
    }

    function destroyUserOrder(address _user, uint _orderIndex) external {
        require(msg.sender == address(commander), "Invalid commander");
        require(block.timestamp >= orderInfos[_user][_orderIndex].unfreeze, "Order is still running" );
        orderInfos[_user][_orderIndex].isUnfreezed = true;
    }

    function getOrderLength(address _user) public view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() public view returns(uint256) {
        return depositors.length;
    }

    function orderAmountById(address _user, uint _orderIndex) public view returns (uint256){
        return orderInfos[_user][_orderIndex].amount;
    }

    function orderAmountByUnfreezeId(address _user, uint _orderIndex) public view returns (uint256){
        if(orderInfos[_user][_orderIndex].isUnfreezed == false){
            return orderAmountById(_user, _orderIndex);
        }
        return 0;
    }

    function checkOrderCondition(address _user, uint _index, uint256 _amount) public view returns (bool){
        if(_amount >= orderInfos[_user][_index].amount && block.timestamp >= orderInfos[_user][_index].unfreeze){
            return true;
        }
        return false;
    }

    function _unfreezeFundQuit(address _user, uint256 _amount) private {
        uint256 staticReward = _amount.mul(dayRewardPercents).div(100);
        commander.shipOutcome(address(this), _user, _amount.add(staticReward));
    }

    // function _unfreezeFundAndUpdateReward(address _user, uint256 _nowLen) private {
    //     if(_nowLen > 0){
    //         OrderInfo storage order = orderInfos[_user][_nowLen - 1];
    //         if(order.isUnfreezed == false){
    //             order.isUnfreezed = true;
    //             _unfreezeFundQuit(_user, order.amount);
    //         }
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDegCrew {
    function register(address from, address refer) external;
    function deposit(address, uint256) external;
    function reDeposit(address from, address ship, uint256 _amount, uint _orderIndex) external;
    function updateLevel(address) external;
    function isCaller(address) external view returns (bool);

    function checkRefer(address user) external view returns (address);
    function userRevenue(address user) external view returns (uint256);
    
    function addUserPointBalance(address _user, uint256 _amount) external;
    function subUserPointBalance(address _user, uint256 _amount) external;
    function balanceOfPoint(address _user) external view returns (uint256);
    function updateUserDepositShipOid(address _user, address _ship, uint _oid) external;
    function userTakeOrderInShip(address _user, address _ship) external view returns (uint);

    function pointDividend(address _user, address _ship) external;
    function myPointAvailable(address _user, uint _day) external view returns (uint256 _bonus);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IDegCrew.sol";

interface IDegCrewExtend is IDegCrew{
    function addCaller(address) external;
    function modifyCaller(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDegShipCommanderV2 {
    function crewAddress() external view returns (address);
    function shipOutcome(address, address, uint256) external;
    function checkShipStop(address) external view returns (bool);
    function shipReleaseAmountToStop(address _ship) external view returns (uint256);

    function getDay() external view returns (uint);
    function startTime() external view returns (uint);
    function dayRecordPool(uint _day) external view returns (uint256);
    function dayInvestTotal(uint _day) external view returns (uint256);
    function dayUserInvestTotal(uint _day, address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDegShipFactoryV2 {
    function getDay() external view returns(uint256);
    function getSerials() external view returns(string[] calldata);
    function getSerialLen() external view returns (uint256);
    function getSerialByIndex(uint256 _index) external view returns(string calldata);

    function serialShip(string calldata) external view returns (address);
    function serialIndex(string calldata) external view returns (uint256);
    function shipToSerial(address) external view returns (string calldata);
    function serialIndexShip(string calldata, uint256) external view returns (address);
    function shipFactoryAutoMaker(string calldata) external view returns(bool);

    // public last ship
    function lastShipOfSerial(string memory _serail) external view returns(address _ship);
    function getDepositorByNum(address _ship, uint _num) external view returns(address[] memory addrs);

    // only commander
    function setSerialShip(string memory _serial, address _ship) external;
    function addSerialNewShip(string memory _serial, address _newShip) external;
    function shipCreated(string calldata _serial, uint256 _index, 
        uint256 _amount, uint256 percent, uint256 perCycle) external returns (address _ship);

    function subStock(string memory _serial,uint _day, uint256 _num) external;
    function setDayShipStock(string memory _serial, uint _day, uint256 _num) external;

    // public 
    function ticketToken(string calldata _serail) external view returns (address);
    function ticketAmount(string calldata _serail) external view returns (uint256);
    function getTicketTokenByShip(address _ship) external view returns (address);
    function getTicketAmountByShip(address _ship) external view returns (uint256);

    function limitLaunchNum(string calldata _serial) external view returns (uint);
    function shipSupply(string calldata _serial) external view returns(uint256);
    function shipStocks(string calldata _serial, uint day) external view returns (uint256);

    function stockReset(string calldata _serial, uint day) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDegShipV2 {
    function initialize(address _commander,string calldata _serial, string calldata _name, uint256 _percent, uint256 _perCycle) external;

    function dayPerCycle() external view returns (uint256);
    function dayRewardPercents() external view returns (uint256);

    function checkOrderCondition(address _user,uint _index, uint256 _amount) external view returns (bool);
    function orderAmountById(address _user, uint _orderIndex) external view returns (uint256);
    function orderAmountByUnfreezeId(address _user, uint _orderIndex) external view returns (uint256);
    function getOrderLength(address _user) external view returns(uint256);

    function depositors(uint) external view returns(address);
    function getDepositorsLength() external view returns(uint256);

    function destroyUserOrder(address from, uint orderIndex) external;
    function launch(address from, uint256 amount, uint orderIndex) external;
    function reLaunch(address from, uint orderIndex) external;
    function stopped() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDegSwap {
    function collectUserDegBal(address _user) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

library Strings {
    
    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}