/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: @opengsn/contracts/src/interfaces/IRelayRecipient.sol

pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// File: @opengsn/contracts/src/BaseRelayRecipient.sol

// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;


/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// File: contracts/BullsEye.sol

pragma solidity ^0.8.6;





contract BullsEye is BaseRelayRecipient {
    using Address for address;
    address payable public owner;
    struct BullsEyeEvent{
        uint32 startTime;
        uint32 endTime;
        string name;
        string statement;
        address creator;
        uint256 outcome;
        bool resolved;
        uint32[4] bands;
        uint16[4] payoutForBands;
        uint16 creatorCommissionBasisPoints;
        uint256 precision;
        address oracle;
        bool isRealMoney;
    }
    struct Market{
        uint256 totalPlayers;
        uint256 minPrediction;
        mapping(uint256 => uint256) distribution;
        uint256 maxPrediction;
        uint256 totalPot;
    }
    struct PlayerPrediction{
        uint256 prediction;
        uint256 wagerAmount;
    }
    uint16 operatorCommissionBasisPoints = 100;
    mapping(bytes32 => BullsEyeEvent) public bullsEyeEvents;
    mapping(bytes32 => Market) public market;
    mapping(bytes32 => mapping(address => uint256)) public winningsForGame;
    mapping(bytes32 => mapping(uint8 => uint256[])) public valuesForBands;
    mapping(bytes32 => mapping(address => PlayerPrediction[])) public playerPredictions;
    mapping(bytes32 => mapping(uint256 => uint256)) public predictionWagerTotals;
    mapping(bytes32 => mapping(uint8 => PlayerPrediction[])) public band_predictions;
    mapping(bytes32 => mapping(address => bool)) public claims;
    mapping(bytes32 => address[]) public players;
    mapping(address => uint256) public balances;
    event EventCreated(bytes32 indexed key, uint32 endTime, string name, address indexed creator, string instrument);
    event Deposit(address indexed account, uint256 amount);
    event Debug(address account, string label, uint256 data1, uint256 data2, uint256 data3);
    
    constructor(address trustedForwarder){
        owner = payable(_msgSender());
        _setTrustedForwarder(trustedForwarder);
    }
    function setTrustedForwarder(address trustedForwarder) external isOwner {
        _setTrustedForwarder(trustedForwarder);
    }
    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0";
    }
    function getEventID(uint32 startTime, uint32 endTime, string memory name, address oracle) public pure returns (bytes32 eventID){
        eventID = keccak256(abi.encodePacked(startTime, endTime, name, oracle));
    }
    function createEvent(uint32 startTime, uint32 endTime, string calldata name, string calldata statement, uint32[4] calldata bands, uint16[4] calldata payoutForBands, uint16 creatorCommissionBasisPoints, uint32 precision, address oracle, bool isRealMoney) external payable{
        bytes32 key = getEventID(startTime, endTime, name, oracle);
        require(bullsEyeEvents[key].startTime == 0, 'Already exists');
        string memory instrument = '';
        if (oracle != address(0)){
            instrument = symbol(oracle);
            require(keccak256(abi.encodePacked(instrument)) != keccak256(abi.encodePacked('Oracle must be an AggregatorV3Interface contract')), 'Oracle must be an AggregatorV3Interface contract');
        }
        bullsEyeEvents[key] = BullsEyeEvent(startTime, endTime, name, statement, _msgSender(), 0, false, bands, payoutForBands, creatorCommissionBasisPoints, precision, oracle, isRealMoney);
        if (true == bullsEyeEvents[key].isRealMoney){
            market[key].totalPot += msg.value;
        }
        emit EventCreated(key, endTime, name, _msgSender(), instrument);
    }
    function symbol(address oracle) private view returns (string memory) {
        require(oracle.isContract(), "Oracle must be a contract address");
        try AggregatorV3Interface(oracle).description() returns (string memory description) {
            return description;
        } catch (bytes memory) {
            return "Oracle must be an AggregatorV3Interface contract";
        }
    }
    
    function getBand(bytes32 key, uint8 index) external view returns (uint32 band){
        band = bullsEyeEvents[key].bands[index];
    }
    function getPayoutForBand(bytes32 key, uint8 index) external view returns (uint16 payoutBasisPoints){
        payoutBasisPoints = bullsEyeEvents[key].payoutForBands[index];
    }
    function makePrediction(bytes32 key, uint256 amount, uint256 userPrediction) external payable{
        require(bullsEyeEvents[key].endTime > 0, 'Invalid Event');
        require(bullsEyeEvents[key].endTime > block.timestamp, 'Event Expired');
        uint256 prediction = rounded(userPrediction, bullsEyeEvents[key].precision);
        if (true == bullsEyeEvents[key].isRealMoney){
            balances[_msgSender()] += msg.value;
            require(balances[_msgSender()] >= amount, 'Not enough balance');
            balances[_msgSender()] -= amount;
        } 
        else {
            amount = 1e18;
        }
        if (market[key].minPrediction > prediction) market[key].minPrediction = prediction;
        if (market[key].maxPrediction < prediction) market[key].maxPrediction = prediction;
        market[key].distribution[prediction] ++;
        market[key].totalPot += amount;
        predictionWagerTotals[key][prediction] += amount;
        playerPredictions[key][_msgSender()].push(PlayerPrediction(prediction, amount));
        bool exists = false;
        for (uint i=0; i<players[key].length; i++){
            if (players[key][i] == _msgSender()) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            players[key].push(_msgSender());
            market[key].totalPlayers ++;
        }
    }
    function getRelevantRound(address oracle, uint timestampBoundary) public view returns (uint80 relevantRound, uint relevantRoundAnswer){
        (uint80 roundId,int answer,,uint roundTimestamp,) = AggregatorV3Interface(oracle).latestRoundData();
        if (roundTimestamp <= timestampBoundary) return (0,0);
         relevantRound = roundId;
         relevantRoundAnswer = uint(answer);
        while (roundTimestamp > timestampBoundary){
            (roundId,answer,,roundTimestamp,) = AggregatorV3Interface(oracle).getRoundData(roundId - 1);
            if (roundTimestamp > timestampBoundary){
                relevantRound = roundId;
                relevantRoundAnswer = uint(answer);
            }
        } 
    }
    function resolveEvent(bytes32 key, uint eventOutcome, bool movePlayerWinnings) external {
        require(bullsEyeEvents[key].endTime > 0, 'Invalid Event');
        require(bullsEyeEvents[key].endTime < block.timestamp, 'Early to resolve');
        require(bullsEyeEvents[key].resolved == false, 'Event Already Resolved');
        require(_msgSender() == bullsEyeEvents[key].creator || _msgSender() == owner, 'Only Creator/Operator can resolve');
        if (bullsEyeEvents[key].oracle != address(0)){
            (uint80 relevantRound,uint roundAnswer) = getRelevantRound(bullsEyeEvents[key].oracle, bullsEyeEvents[key].endTime);
            if (relevantRound > 0){
                if (roundAnswer > 0){
                    eventOutcome = roundAnswer;
                    _processOutcome(key, eventOutcome, movePlayerWinnings);
                }
            }
        }
        else _processOutcome(key, eventOutcome, movePlayerWinnings);
        
    }
    function _processOutcome(bytes32 key, uint eventOutcome, bool movePlayerWinnings) internal {
        uint256 outcome = rounded(eventOutcome, bullsEyeEvents[key].precision);
        bullsEyeEvents[key].outcome = outcome;
        bullsEyeEvents[key].resolved = true;
        if (movePlayerWinnings){
            for (uint i=0; i<market[key].totalPlayers; i++){
                claimForPlayer(key, players[key][i]);
            }
            balances[bullsEyeEvents[key].creator] += market[key].totalPot;
            market[key].totalPot = 0;
        }
    }
    function claim(bytes32 key) external returns (uint256 winningsForPlayer){
        winningsForPlayer = claimForPlayer(key, _msgSender());
    }
    function claimForPlayer(bytes32 key, address player) public returns (uint256 winningsForPlayer) {
        require(bullsEyeEvents[key].endTime > 0, 'Invalid Event');
        require(bullsEyeEvents[key].resolved == true, 'Event Not Resolved');
        require(claims[key][player] == false, 'Already claimed');
        claims[key][player] = true;
        
        for (uint16 i=0; i<playerPredictions[key][player].length; i++){
            PlayerPrediction memory playerPrediction = playerPredictions[key][player][i];
            uint8 bandIndex = getDeltaBandIndex(playerPrediction.prediction, bullsEyeEvents[key].outcome, bullsEyeEvents[key].bands);
            emit Debug(player, 'bandIndex', playerPrediction.prediction, bullsEyeEvents[key].outcome, uint256(bandIndex));
            if (bandIndex == 255){
                winningsForPlayer = 0;
                continue;
            }
            (uint256 lowerValueLowerBand,
            uint256 higherValueLowerBand,
            uint256 lowerValueHigherBand,
            uint256 higherValueHigherBand) = getLowerUpperBounds(key, bandIndex); 
            
            uint wagersInBand;
            for (uint v=lowerValueLowerBand; v<=higherValueLowerBand; v+=bullsEyeEvents[key].precision){
                wagersInBand += predictionWagerTotals[key][v];
            }
            for (uint v=lowerValueHigherBand; v<=higherValueHigherBand; v+=bullsEyeEvents[key].precision){
                wagersInBand += predictionWagerTotals[key][v];
            }
            winningsForPlayer += (playerPrediction.wagerAmount * market[key].totalPot * bullsEyeEvents[key].payoutForBands[bandIndex])/(wagersInBand * 10000); 
        }
        uint256 creatorCommission = (winningsForPlayer * bullsEyeEvents[key].creatorCommissionBasisPoints)/10000;
        uint256 operatorCommission = (creatorCommission * operatorCommissionBasisPoints)/10000;
        market[key].totalPot -= winningsForPlayer;
        winningsForGame[key][player] += winningsForPlayer;
        if (bullsEyeEvents[key].isRealMoney){
            balances[player] += (winningsForPlayer - creatorCommission);
            balances[bullsEyeEvents[key].creator] += (creatorCommission - operatorCommission);
            balances[owner] += operatorCommission;
        }    
    }
    function getLowerUpperBounds(bytes32 key, uint8 bandIndex) internal view returns (uint256 lowerValueLowerBand,
            uint256 higherValueLowerBand,
            uint256 lowerValueHigherBand,
            uint256 higherValueHigherBand) {
        
            uint256 delta = rounded((bullsEyeEvents[key].bands[bandIndex] * bullsEyeEvents[key].outcome)/1000000, bullsEyeEvents[key].precision);
            lowerValueLowerBand = bullsEyeEvents[key].outcome - delta;
            if (bandIndex == 0){
                higherValueLowerBand = bullsEyeEvents[key].outcome - bullsEyeEvents[key].precision;
                lowerValueHigherBand = bullsEyeEvents[key].outcome;
            }
            else {
                uint256 delta1 = rounded((bullsEyeEvents[key].bands[bandIndex-1] * bullsEyeEvents[key].outcome)/1000000, bullsEyeEvents[key].precision);
                higherValueLowerBand = bullsEyeEvents[key].outcome - delta1 - bullsEyeEvents[key].precision;
                lowerValueHigherBand = bullsEyeEvents[key].outcome + delta1 + bullsEyeEvents[key].precision;     
            } 
            higherValueHigherBand = bullsEyeEvents[key].outcome + delta; 
    }
    function getDeltaBasisPoints(uint256 prediction, uint256 outcome) public pure returns (uint32 deltaBasisPoints){
        uint256 delta = prediction > outcome ? prediction - outcome : outcome - prediction;
        deltaBasisPoints = uint32((delta * 1000000) / outcome);        
    }
    function getDeltaBandIndex(uint256 prediction, uint256 outcome, uint32[4] memory bands) public pure returns (uint8 bandIndex){
        uint32 deltaBasisPoints = getDeltaBasisPoints(prediction, outcome);
        bandIndex = 255;
        for (uint8 b=0; b<bands.length; b++){
            if (deltaBasisPoints <= bands[b]){
                bandIndex = b;
                break;
            }
        }
    }
    function loopTest(uint loop) external pure returns (uint256 output){
        for (uint i=0; i<loop; i++){
            output = i;
        }
    }
    function rounded(uint val, uint divisor) public pure returns (uint256 output){
        uint mod = val % divisor;
        mod < (divisor/2) ? output = val - mod : output = val - mod + divisor;
    }
    function withdraw() public{
        transferBalance(_msgSender());
    }
    function deposit() external payable{
        balances[_msgSender()] += msg.value;
        emit Deposit(_msgSender(), msg.value);
    }
    function transferBalance(address player) public{
        uint256 balance = balances[player];
        if (balance > 0) {
            balances[player] = 0;
            payable(player).transfer(balance);
        }
    }
    function setOperatorCommission(uint16 _operatorCommission) external isOwner{
        operatorCommissionBasisPoints = _operatorCommission;
    }
    modifier isOwner() {
        require(_msgSender() == owner);
        _;
    }

}