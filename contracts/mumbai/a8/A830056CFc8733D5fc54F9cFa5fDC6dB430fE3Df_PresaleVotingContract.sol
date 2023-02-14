// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//pragma experimental ABIEncoderV2;


library SafeMath {
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
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract storagedappMaps {

    //mapping(address => address) public tokenAddrToOwnerAddr;
    mapping(address => address) public presaleAddrToOwnerAddr;
    mapping(address => address) public presaleAddrToDeployerAddr;
    //mapping(address => uint256) public presaleOwnerToIndex;
    //mapping(address => uint256) public tokenAddrToIndex;
    //mapping(address => uint256) public ownerPresaleNumber;
    mapping(address => uint256) public presaleToPresaleNum;

}

interface storagedapp {

    function getPresaleDeployerViaOwner(address _creator, uint256 _presaleNum) external view returns(address);
    function getPresaleDeployer(address _presaleAddr) external view returns(address);
}
interface maindapp {

    function voterCallsFinalizeRefund(address presaleToRefundFromOwnerAddress,uint256 _presaleNum) external;
    function voterCallsFinalizeRefundAnytime(address presaleToRefundFromOwnerAddress,uint256 _presaleNum) external;

}

interface presale {

    function CheckTotalEthRaised() external view returns(uint256);
    function CheckSoftCap() external view returns(uint256);
    function presaleEndTime() external view returns(uint256);
}

contract PresaleVotingContract is Ownable {

    bool public votingEnabled = true;
    bool public votingOnlyOwnerEnabled = true;
    bool public votingWhitelistEnabled = true;

    address public storageDappAddr;
    //address public mainDappAddr;
    address public templateCrowdSaleAddr;
    mapping(uint256 => address) public indexToCaller;
    mapping(address => uint256) public callerToIndex;
    mapping(address => bool) public callerToBool;
    mapping(address => address) public callerToPresaleAddr;
    mapping(address => address) public presaleAddrToCaller;
    mapping(address => address) public callerToOwnerAddr;
    mapping(address => address) public ownerAddrToCaller;
    mapping(uint256 => address) public indexToPresaleAddr;
    mapping(uint256 => address) public indexToOwnerAddr;
    mapping(uint256 => address) public indexToOwner;
    mapping(address => uint256) public ownerToIndex;
    mapping(address => bool) public ownerToBool;
    mapping(address => uint256) public finalizeCallByUserTimestamp;
    mapping(address => mapping(uint256 => uint256)) public finalizeCallByOwnerTimestamp;
    mapping(address => uint256) public finalizeCallByWhitelistTimestamp;
    mapping(address => bool) public voterFinalizeEnableFlag;
    mapping(address => uint256) public voterEnableFlagTime;
    mapping(address => bool) public finalized;
    mapping(address => bool) public whitelist;
    mapping(address => string) public whitelistToName;
    mapping(string => address) public whitelistNameToAddr;
    uint256 public callerIndex;
    uint256 public ownerIndex;
    uint256 public checkEndTime;
    uint256 public voterFinalizeTime = 172800;
    uint256 public minimumTime = 7200;

    constructor(address addrStorage)  {
        storageDappAddr = addrStorage;
        //mainDappAddr = addrMain;
    }

    using SafeMath
    for uint256;

    function ownerCallsFinalizeRefundMainDapp(uint256 _presaleNum) public { //only presaleCreator to finalize

        require(votingOnlyOwnerEnabled, "ownerCallIsDisabled");
        address mainDappAddr = storagedapp(storageDappAddr).getPresaleDeployerViaOwner(msg.sender,_presaleNum);
       // (bool _ownerfinalized, bytes memory _finalizedReturn) = address(mainDappAddr).call(abi.encodeWithSignature("voterCallsFinalizeRefundAnytime(address,uint256)", msg.sender,_presaleNum));
       // require(_ownerfinalized, "presaleOwner Emergency Finalization call failed");
        maindapp(mainDappAddr).voterCallsFinalizeRefundAnytime( msg.sender,_presaleNum);
        //indexToOwner[ownerIndex] = msg.sender;
        //ownerToIndex[msg.sender] = ownerIndex;
        //ownerToBool[msg.sender] = true;
        //ownerIndex++;
        finalizeCallByOwnerTimestamp[msg.sender][_presaleNum] = block.timestamp;
    }

    function whitelistCallsFinalizeRefundMainDapp(address addrPre) public { //only presaleCreator to finalize

        require(votingWhitelistEnabled, "whitelistCallIsDisabled");
        require(whitelist[msg.sender], "not whitelisted");
        address presaleOwnerAddress = storagedappMaps(storageDappAddr).presaleAddrToOwnerAddr(addrPre);
        uint256 presaleNum = storagedappMaps(storageDappAddr).presaleToPresaleNum(addrPre);
        address mainDappAddr = storagedappMaps(storageDappAddr).presaleAddrToDeployerAddr(addrPre);
        //(bool _ownerfinalized, bytes memory _finalizedReturn) = address(mainDappAddr).call(abi.encodeWithSignature("voterCallsFinalizeRefundAnytime(address,uint256)", presaleOwnerAddress,presaleNum));
        //require(_ownerfinalized, "whitelist Emergency Finalization call failed");
        maindapp(mainDappAddr).voterCallsFinalizeRefundAnytime(presaleOwnerAddress,presaleNum);

        finalized[addrPre] = true;
        indexToCaller[callerIndex] = msg.sender;
        callerToIndex[msg.sender] = callerIndex;
        callerToBool[msg.sender] = true;
        indexToPresaleAddr[callerIndex] = addrPre;
        indexToOwnerAddr[callerIndex] = presaleOwnerAddress;
        callerToPresaleAddr[msg.sender] = addrPre;
        presaleAddrToCaller[addrPre] = msg.sender;
        callerToOwnerAddr[msg.sender] = presaleOwnerAddress;
        ownerAddrToCaller[presaleOwnerAddress] = msg.sender;
        callerIndex++;
        finalizeCallByUserTimestamp[addrPre] = block.timestamp;
        finalizeCallByWhitelistTimestamp[addrPre] = block.timestamp;
    }

    function voterCallsFinalizeRefundMainDapp(address addrPre) public { //anyone to be able to finalize after voterFinalizeTime

        require(!finalized[addrPre], "already finalized!");
        require(votingEnabled, "voterCallIsDisabled");
        uint256 presaleNum = storagedappMaps(storageDappAddr).presaleToPresaleNum(addrPre);
        //(bool _endtime, bytes memory _endtimeFetch) = address(addrPre).call(abi.encodeWithSignature("presaleEndTime()"));
        //require(_endtime, "presale address is incorrect... No endTime observed");
        //uint256 endtimeReturn = abi.decode(_endtimeFetch, (uint256));
        uint256 endtimeReturn = presale(addrPre).presaleEndTime();

        require((block.timestamp > endtimeReturn.add(voterFinalizeTime)), "voter cannot finalze if time is not greater than presale _endtime + voterFinalizeTime");

        address presaleOwnerAddress = storagedappMaps(storageDappAddr).presaleAddrToOwnerAddr(addrPre);
        address mainDappAddr = storagedappMaps(storageDappAddr).presaleAddrToDeployerAddr(addrPre);
       // (bool _voterfinalized, bytes memory _finalizedReturn) = address(mainDappAddr).call(abi.encodeWithSignature("voterCallsFinalizeRefund(address,uint256)", presaleOwnerAddress,presaleNum));
       // require(_voterfinalized, "voter Emergency Finalization call failed");
        maindapp(mainDappAddr).voterCallsFinalizeRefund(presaleOwnerAddress,presaleNum);
        finalized[addrPre] = true;
        indexToCaller[callerIndex] = msg.sender;
        callerToIndex[msg.sender] = callerIndex;
        callerToBool[msg.sender] = true;
        indexToPresaleAddr[callerIndex] = addrPre;
        indexToOwnerAddr[callerIndex] = presaleOwnerAddress;
        callerToPresaleAddr[msg.sender] = addrPre;
        presaleAddrToCaller[addrPre] = msg.sender;
        callerToOwnerAddr[msg.sender] = presaleOwnerAddress;
        ownerAddrToCaller[presaleOwnerAddress] = msg.sender;
        callerIndex++;
        finalizeCallByUserTimestamp[addrPre] = block.timestamp;
    }


    function voterCallsFinalizeRefundMainDappHardCap(address addrPre) public { //anyone to be able to finalize after voterFinalizeTime if voterFinalizeEnableFlag is enabled

        require(!finalized[addrPre], "already finalized!");
        require(votingEnabled, "voterCallIsDisabled");
        require(voterFinalizeEnableFlag[addrPre], "voter Finalize flag is disabled");
        require(voterEnableFlagTime[addrPre] > 0, "voterEnableFlagTime not setup");
        require((block.timestamp > voterEnableFlagTime[addrPre].add(voterFinalizeTime)), "voter cannot finalze if time is not greater than voterEnableFlagTime + voterFinalizeTime");
        uint256 presaleNum = storagedappMaps(storageDappAddr).presaleToPresaleNum(addrPre);
        address presaleOwnerAddress = storagedappMaps(storageDappAddr).presaleAddrToOwnerAddr(addrPre);

        address mainDappAddr = storagedappMaps(storageDappAddr).presaleAddrToDeployerAddr(addrPre);
       // (bool _voterfinalized, bytes memory _finalizedReturn) = address(mainDappAddr).call(abi.encodeWithSignature("voterCallsFinalizeRefund(address,uint256)", presaleOwnerAddress,presaleNum));
       // require(_voterfinalized, "voter Emergency Finalization call by enable flag failed");
        maindapp(mainDappAddr).voterCallsFinalizeRefund(presaleOwnerAddress,presaleNum);
        finalized[addrPre] = true;
        indexToCaller[callerIndex] = msg.sender;
        callerToIndex[msg.sender] = callerIndex;
        callerToBool[msg.sender] = true;
        indexToPresaleAddr[callerIndex] = addrPre;
        indexToOwnerAddr[callerIndex] = presaleOwnerAddress;
        callerToPresaleAddr[msg.sender] = addrPre;
        presaleAddrToCaller[addrPre] = msg.sender;
        callerToOwnerAddr[msg.sender] = presaleOwnerAddress;
        ownerAddrToCaller[presaleOwnerAddress] = msg.sender;
        callerIndex++;
        finalizeCallByUserTimestamp[addrPre] = block.timestamp;
    }


    function voterCallsFinalizeRefundMainDappSoftCap(address addrPre) public { //anyone to be able to finalize after voterFinalizeTime if voterFinalizeEnableFlag is enabled

        require(!finalized[addrPre], "already finalized!");
        require(votingEnabled, "voterCallIsDisabled");

        //(bool _softcap, bytes memory _softcapFetch) = address(addrPre).call(abi.encodeWithSignature("CheckSoftCap()"));
        //require(_softcap, "potential wrong address-No soft Cap observed");
        //uint256 softcapReturn = abi.decode(_softcapFetch, (uint256));

        uint256 softcapReturn = presale(addrPre).CheckSoftCap();

        //(bool _totalETHRaised, bytes memory _totalETHRaisedFetch) = address(addrPre).call(abi.encodeWithSignature("CheckTotalEthRaised()"));
        //require(_totalETHRaised, "potential wrong address-No ETH raised observed");
        //uint256 totalETHRaisedReturn = abi.decode(_totalETHRaisedFetch, (uint256));
        uint256 totalETHRaisedReturn = presale(addrPre).CheckTotalEthRaised();

        //(bool _presaleEndTime, bytes memory _presaleEndTimeFetch) = address(addrPre).call(abi.encodeWithSignature("presaleEndTime()"));
        //require(_presaleEndTime, "presaleEndTime not available");
        //uint256 presaleEndTimeReturn = abi.decode(_presaleEndTimeFetch, (uint256));
        uint256 presaleEndTimeReturn = presale(addrPre).presaleEndTime();
        require((totalETHRaisedReturn < softcapReturn && block.timestamp >= presaleEndTimeReturn), "ETHraised more that scap or timer not ended");

        require(presaleStatusCheckSoftCap(addrPre),"condition not met");
        
        address presaleOwnerAddress = storagedappMaps(storageDappAddr).presaleAddrToOwnerAddr(addrPre);
        uint256 presaleNum = storagedappMaps(storageDappAddr).presaleToPresaleNum(addrPre);

        address mainDappAddr = storagedappMaps(storageDappAddr).presaleAddrToDeployerAddr(addrPre);
        //(bool _voterfinalized, bytes memory _finalizedReturn) = address(mainDappAddr).call(abi.encodeWithSignature("voterCallsFinalizeRefund(address,uint256)", presaleOwnerAddress,presaleNum));
        //require(_voterfinalized, "voter Emergency Finalization with raised less than SoftCap failed");
        maindapp(mainDappAddr).voterCallsFinalizeRefund(presaleOwnerAddress,presaleNum);
        finalized[addrPre] = true;
        indexToCaller[callerIndex] = msg.sender;
        callerToIndex[msg.sender] = callerIndex;
        callerToBool[msg.sender] = true;
        indexToPresaleAddr[callerIndex] = addrPre;
        indexToOwnerAddr[callerIndex] = presaleOwnerAddress;
        callerToPresaleAddr[msg.sender] = addrPre;
        presaleAddrToCaller[addrPre] = msg.sender;
        callerToOwnerAddr[msg.sender] = presaleOwnerAddress;
        ownerAddrToCaller[presaleOwnerAddress] = msg.sender;
        callerIndex++;
        finalizeCallByUserTimestamp[addrPre] = block.timestamp;
    }

    function presaleStatusCheckSoftCap(address addrPre) internal view returns(bool){

        //(bool _softcap, bytes memory _softcapFetch) = address(addrPre).call(abi.encodeWithSignature("CheckSoftCap()"));
        //require(_softcap, "potential wrong address-No soft Cap observed");
        //uint256 softcapReturn = abi.decode(_softcapFetch, (uint256));
        uint256 softcapReturn = presale(addrPre).CheckSoftCap();

        //(bool _totalETHRaised, bytes memory _totalETHRaisedFetch) = address(addrPre).call(abi.encodeWithSignature("CheckTotalEthRaised()"));
        //require(_totalETHRaised, "potential wrong address-No ETH raised observed");
        //uint256 totalETHRaisedReturn = abi.decode(_totalETHRaisedFetch, (uint256));

        uint256 totalETHRaisedReturn = presale(addrPre).CheckTotalEthRaised();

        //(bool _presaleEndTime, bytes memory _presaleEndTimeFetch) = address(addrPre).call(abi.encodeWithSignature("presaleEndTime()"));
        //require(_presaleEndTime, "presaleEndTime not available");
        //uint256 presaleEndTimeReturn = abi.decode(_presaleEndTimeFetch, (uint256));

        uint256 presaleEndTimeReturn = presale(addrPre).presaleEndTime();

        return(totalETHRaisedReturn < softcapReturn && block.timestamp >= presaleEndTimeReturn);



    }
    function CheckBlockTimestamp() public view returns(uint256) {


        return block.timestamp;


    }


    function changeVoterFinalizeTime(uint256 _newVoterTime) public onlyOwner {

        require((_newVoterTime >= minimumTime), "_newvoterTime must be >= minimum time");

        voterFinalizeTime = _newVoterTime;

    }

    function changeVoterMinTime(uint256 _newMinTime) public onlyOwner {

        require((_newMinTime >= 0), "_newMinTime must be >= 0");

        minimumTime = _newMinTime;

    }

    function disableVoterCall() public onlyOwner {

        votingEnabled = false;


    }


    function enableVoterCall() public onlyOwner {

        votingEnabled = true;


    }

    function disableWhitelistCall() public onlyOwner {

        votingWhitelistEnabled = false;


    }


    function enableWhitelistCall() public onlyOwner {

        votingWhitelistEnabled = true;


    }

    function disableOwnerCall() public onlyOwner {

        votingOnlyOwnerEnabled = false;


    }


    function enableOwnerCall() public onlyOwner {

        votingOnlyOwnerEnabled = true;


    }

    function updateStorageDappAddr(address _newStoragedapp) public onlyOwner {

        storageDappAddr = _newStoragedapp;



    }
    /*
    function updateMainDappAddr(address _newMaindapp) public onlyOwner {

        mainDappAddr = _newMaindapp;



    }
    */
    function addToWhitelist(address _whitelistAddr, string memory _name) onlyOwner public {


        whitelist[_whitelistAddr] = true;

        whitelistToName[_whitelistAddr] = _name;
        whitelistNameToAddr[_name] = _whitelistAddr;

    }

    function removeFromWhitelist(address _whitelistAddr) onlyOwner public {


        whitelist[_whitelistAddr] = false;



    }

    function voterFinalizeEnable(address addrPre) public {

        require(!voterFinalizeEnableFlag[addrPre], "already enabled!");

        (bool _closed, bytes memory _closeCheck) = address(addrPre).call(abi.encodeWithSignature("hasClosed()"));
        require(_closed, "presale not closed");
        bool presaleClosed = abi.decode(_closeCheck, (bool));

        require(presaleClosed, "presale has not finished yet!");


        voterFinalizeEnableFlag[addrPre] = true;
        voterEnableFlagTime[addrPre] = block.timestamp;

    }

    function getVoterFinalizeEnableFlag(address addrPre) public view returns(bool) {
        return voterFinalizeEnableFlag[addrPre];
    }
}