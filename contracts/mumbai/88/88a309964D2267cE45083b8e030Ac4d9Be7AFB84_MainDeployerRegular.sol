// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//pragma experimental ABIEncoderV2;
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/UniswapFactory.sol";
//import "https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/UniswapPair.sol";
//import "https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/UniswapRouter02.sol";

interface ERC20 {
    function transfer(address to, uint256 value) external returns(bool);

    function approve(address spender, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function totalSupply() external view returns(uint256);

    function balanceOf(address who) external view returns(uint256);

    function allowance(address owner, address spender) external view returns(uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



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
    address public voter;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyVoter() {
        require(msg.sender == voter);
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




contract Consts {
    uint constant TOKEN_DECIMALS = 18;
    uint8 constant TOKEN_DECIMALS_UINT8 = 18;
    uint constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;
    address public feeContract;

    uint256 airdrop_fees_Percentage = 2;

    uint256 public minLockTime = 2592000; // 10 mins for degen
    uint256 constant minStartDeltaTime = 600; // presale must be atleast 10 mins in future;
}

interface RouterContractInterface {

    function Approve() external returns(bool);

    function getpair(address token) external view returns(address);

    function AddLiquidity(uint256 amountTokenDesired) external payable;

    //function AddLiquidity() external payable;

    function refundUniLP(address _routerAddress) external payable;

    function refundUniLPbyPlatform(address _routerAddress) external payable;

    function uniBalance(address token) external view returns(uint256);


}
interface RouterDappInterface {


    function createRouter(address _tokenAddress, address _creatorAdress, uint256 _locktime, address routerAddressInput, uint256 _extraAmount, string memory _logo) external returns (address);

}
interface StorageContractInterface {

    //function CreatePresaleStorage(string[10] memory _tokenInfo, address tokenAddr, uint256 _lp_locked, address _creator, bool[3] memory _nftIdoFair) external returns(bool);
    function CreatePresaleStorage(address tokenAddr,uint256 _lp_locked, address _creator, bool[3] memory _nftIdoFair) external returns(bool);
    function addPresaleAddr(string[10] memory _tokenInfo, address _presale, address _creator, uint256 _presaleNum) external returns(bool);
    function fetchPresaleNumByOwner(address _creator) external returns(uint256);
    function fetchTokenAddrLiqLockTime(address _creator, uint256 _presaleNum) external view returns(address,uint256);
    function addRouterAddr(address _router, address _creator, uint256 _presaleNum) external returns(bool);
    function fetchPresaleStruct(address _creator, uint256 _presaleNum) external view returns(address,address,address);
    function setPresaleActiveFalse(address _creator, uint256 _presaleNum) external returns (bool);
    function setPresaleFilter(address _creator, uint256 _presaleNum) external returns (bool);
    function fetchPresaleAddress(address _creator, uint256 _presaleNum) external view returns(address);
    function fetchVoterCallData(address _creator, uint256 _presaleNum) external view returns(address,address);
    function addFailFilter(address _creator, uint256 _presaleNum) external;
    
}
interface PresaleDappInterface {

    function CreatePresaleRegular(address[4] memory presaleAddressInput_Router, uint256[2] memory start_end_time, uint256[5] memory soft_hard_cap_rate_min_max_eth, uint256[2] memory uniRatePercentage, uint256[2] memory extraAmountPer_lockTime) external returns(address);

}

interface PresaleContractInterface {

    function uniswapPercentage() external returns(uint256);
    function uniswapRate() external returns(uint256);
    function CheckTotalEthRaised() external view returns(uint256);
    function CheckSoftCap() external view returns(uint256);
    function mintForPlatform(address _platform, address _referrer, uint256 _refPer, bool tokenFeeToRef) external returns(bool);
    function mintForUniswap(address _routerAddr) external;
    function finalize(address[2] memory __finalizeInfo, uint256 refPer, bool validFinalize) external returns(bool);
    function finalizeAnytime(address[2] memory __finalizeInfo, bool validFinalize) external returns(bool);
    function enableWhitelist() external;
    function disableWhitelist() external;
    function addToWhitelist(address WhitelistAddress) external;
    function removeFromWhitelist(address WhitelistAddress) external;

}
interface ReferralContract {

    function getDiscountedPrice(string memory _code) external returns(uint256);
    function validateCode(string memory _code) external returns(bool);
    function fetchCodeOwner(string memory _code) external returns(address);
    function fetchCodeOwnerPercentage(string memory _code) external returns(uint256);
    function updateReferrerAmounts(address _referrer, uint256 _updateAmount)  external returns(bool);  
    function updateCodeUseNumber(string memory _code, address _presaleAddress) external returns(bool);
}

interface FeeCheckContractInterface {

    function getFees(string memory _dappName) external view returns(uint256);
    function getWhitelistFees(string memory _dappWhitelistName) external view returns(uint256);

}

interface FeeDepositContractInterface {

    function payment(uint256 _dappNum) external payable;

}

contract MainDeployerRegular is Consts, Ownable {
    //uint256 public presaleFees = 1 * (10**18); // 1 ETH
    //uint256 public whitelistFees = 0.9 * (10**18); // 0.9 ETH
    uint public minUniPercentage = 50; //minimum 50% has to go for uniswap lock
    address public presaleDappAddr;
    address public referralDappAddr;
    //address public presaleNFTDappAddr;
    //address public NFTDappAddr;
   // address public routerDappAddr;
    //address public FilterAddress;
    address public storageContract;
    address public feeCheckContract;
    uint256 public totalRaisedOnPlatform;
    uint256 public totalRefundedFromPlatform;
    uint256 public deltaStartEndTime = 2592000;
    string public dappName = "PresaleDeployer";
    string public dappFeeName = "regPresaleFees";
    string public dappWhitelistFeeName = "regWhitelistFees";
    uint256 public tokenFee;
    bool public referralDisabled;
    bool public tokenFeeToReferrer;
    bool public activeFalse = true;
    bool public filter = true;
    // address public UNISWAP_ADDRESS = 0xc0fFee0000C824D24E0F280f1e4D21152625742b;  //Koffeeswap Address
    //  address public factoryAddress = 0xC0fFeE00000e1439651C6aD025ea2A71ED7F3Eab;     //Koffeeswap factory Address
    constructor(address _presaleDappAddr, address _feeRecieveContract, address _storageContract, address _referralContract, address _feeCheckContract) {

        presaleDappAddr = _presaleDappAddr;
        feeContract = _feeRecieveContract;
        storageContract = _storageContract;
        referralDappAddr = _referralContract;
        feeCheckContract = _feeCheckContract;
    }

    using SafeMath
    for uint256;
/*
    struct finalizeData {
        //bool exists; 
        bool active;
        address uniswapDep;
        uint uniswapPercentage;
        uint256 uniswapRate;
        address tokenAddress;
        address presaleAddress;
        address nftPresaleAddress;
        bool nft;
        bool presale;
    }
    */
   
    mapping(address => bool) public presales;
    //mapping(address => finalizeData) public finalizeDataStruct;
    mapping(address => mapping(uint256 => bool)) public presaleFinalized;
    mapping(address => address) public presaleToReferrer;
    mapping(address => uint256) public presaleToRefPer;
    mapping(uint256 => address) public presaleOwners;

    mapping(address => bool) public RouterValid;
    mapping(uint256 => address) public routerRecord;
    mapping(address => uint256) public routerNumber;
    uint256 public totalRouters;

    uint256 public extraAmountPer = 2;
    //uint256 public extraAmountPerVal;
    uint256 public hundred = 100;

    bool public creationPresaleEnabled = true;
    bool public creationNFTPresaleEnabled = true;
    
    function CreatePresaleDep(string[10] memory _tokenInfo, address tokenAddr, uint256[2] memory start_end_time, uint256[5] memory soft_hard_cap_rate_min_max_eth, uint256[3] memory uniswap_info_arr, address _routerAddress, string memory _referralCode) public payable {
        require(creationPresaleEnabled, "creation Presale disabled");
        
        //require(!presales[msg.sender], "User already made a presale");
        require(start_end_time[0] > block.timestamp, "start time not in future");
        require(start_end_time[1] <= (start_end_time[0].add(deltaStartEndTime)), "presale duration exceeds limit");
        require(soft_hard_cap_rate_min_max_eth[0] >= (soft_hard_cap_rate_min_max_eth[1].div(2)), "scap must be atleast half of hcap!");
        require(soft_hard_cap_rate_min_max_eth[3] > 0, "min cont must be > 0");
        require(soft_hard_cap_rate_min_max_eth[4] >= soft_hard_cap_rate_min_max_eth[3], "max cont must be >= min cont");
        //uint256[2] memory start_end_time = [start_end_gov_time[0], start_end_gov_time[1]];
        require(RouterValid[_routerAddress], "invalid router address");

        if(referralDisabled){

            require(keccak256(abi.encodePacked(_referralCode)) == keccak256(abi.encodePacked("default")),"only default code allowed");
        }
        if(keccak256(abi.encodePacked(_referralCode)) != keccak256(abi.encodePacked("default"))){
            require(ReferralContract(referralDappAddr).validateCode(_referralCode),"invalid discount code");
            require(msg.value >= (FeeCheckContractInterface(feeCheckContract).getFees(dappFeeName)).mul(hundred.sub(ReferralContract(referralDappAddr).getDiscountedPrice(_referralCode))).div(hundred), "msg.value must be equal to referral fee!");
        //payable(feeContract).transfer(msg.value);
        //if(ReferralContract(referralDappAddr).fetchCodeOwnerPercentage(_referralCode) > 0){
            uint256 referrerAmount = (msg.value).mul(ReferralContract(referralDappAddr).fetchCodeOwnerPercentage(_referralCode)).div(100);
            payable(ReferralContract(referralDappAddr).fetchCodeOwner(_referralCode)).call{value:referrerAmount}("");
            FeeDepositContractInterface(feeContract).payment{value: (msg.value).mul(hundred.sub(ReferralContract(referralDappAddr).fetchCodeOwnerPercentage(_referralCode))).div(100)}(0); // 0 at the end means it will be registerred in the fee deposit contract as a referral regular presale
            //payable(feeContract).transfer((msg.value).mul(hundred.sub(ReferralContract(referralDappAddr).fetchCodeOwnerPercentage(_referralCode))).div(100));
            require(ReferralContract(referralDappAddr).updateReferrerAmounts(ReferralContract(referralDappAddr).fetchCodeOwner(_referralCode), referrerAmount),"referrerAmountUpdate failed");
        }
        else{
            require(msg.value >= FeeCheckContractInterface(feeCheckContract).getFees(dappFeeName), "msg.value must be equal to presale fee!");
            FeeDepositContractInterface(feeContract).payment{value: msg.value}(1);  // 1 at the end means it will be registerred in the fee deposit contract as a NO referral regular presale
            //payable(feeContract).transfer(msg.value);

        }
        
        //  require(start_end_gov_time[1] >= now.add(minTimeThreshold),"presale end time less than minimum threshold");

        require((start_end_time[0].add(minStartDeltaTime)) <= start_end_time[1], "presale period less than minimum");
        require(uniswap_info_arr[0] > (start_end_time[1].add(minLockTime)), "Lock time must be higher than presale end plus minimum lock time");

        // require(soft_hard_cap_rate_min_max_eth[5] >=0 && soft_hard_cap_rate_min_max_eth[5] <=100, "Governance amount is beyond range");

        require((uniswap_info_arr[2] > minUniPercentage), "Uniswap percentage is lower than min threshold");

        // require((uniswap_info_arr[2].add(soft_hard_cap_rate_min_max_eth[5])) <= 100, "gov plus uni % greater than 100");

        //(bool storageSuccess, bytes memory storageFetch) = storageContract.call(abi.encodeWithSignature("CreatePresaleStorage(string[10],address,uint256[6],uint256,address,bool[2])", _tokenInfo, tokenAddr, soft_hard_cap_rate_min_max_eth,uniswap_info_arr[0],msg.sender,[true,false,false]));
        //require(storageSuccess, "storage creation failed");
        require(StorageContractInterface(storageContract).CreatePresaleStorage(tokenAddr,uniswap_info_arr[0],msg.sender,[true,false,false]),"storage addition failed");



        //(bool presaleSuccess, bytes memory presaleFetch) = presaleDappAddr.call(abi.encodeWithSignature("CreatePresaleRegular(address[3],uint256[2],uint256[6],uint256[2])",  [address(this), msg.sender, tokenAddr], start_end_time, soft_hard_cap_rate_min_max_eth, [uniswap_info_arr[1],uniswap_info_arr[2]],extraAmountPer));
        //require(presaleSuccess, "presale creation failed");
        //address presaleAddrReturn = abi.decode(presaleFetch, (address));

        address presaleAddrReturn = PresaleDappInterface(presaleDappAddr).CreatePresaleRegular([address(this), msg.sender, tokenAddr,_routerAddress], start_end_time, soft_hard_cap_rate_min_max_eth, [uniswap_info_arr[1],uniswap_info_arr[2]],[extraAmountPer,uniswap_info_arr[0]]);


        presaleToReferrer[presaleAddrReturn] = ReferralContract(referralDappAddr).fetchCodeOwner(_referralCode);
        presaleToRefPer[presaleAddrReturn] = ReferralContract(referralDappAddr).fetchCodeOwnerPercentage(_referralCode);

        //(bool presaleNumFetch, bytes memory presaleNum) = storageContract.call(abi.encodeWithSignature("fetchPresaleNumByOwner(address)",msg.sender));
        //require(presaleNumFetch, "presaleNum fetch failed");
        //uint256 presaleNumCorrect = (abi.decode(presaleNum, (uint256))).sub(1);

        uint256 presaleNumCorrect = (StorageContractInterface(storageContract).fetchPresaleNumByOwner(msg.sender)).sub(1);

        //(bool presaleAdd, bytes memory presaleAddFetch) = storageContract.call(abi.encodeWithSignature("addPresaleAddr(address,address,uint256)", presaleAddrReturn,msg.sender,presaleNumCorrect)); // subtraction by 1 is important to set it to correct presale storage since creating storage increments the variable by 1
        //require(presaleAdd, "presale addr add failed");

        require(StorageContractInterface(storageContract).addPresaleAddr(_tokenInfo,presaleAddrReturn,msg.sender,presaleNumCorrect),"presale addr add failed");

       /* if(_allInOne){
            createRouter(msg.sender,_routerAddress,presaleNumCorrect,_tokenInfo[2]);
        }
        */
        require(ReferralContract(referralDappAddr).updateCodeUseNumber(_referralCode,presaleAddrReturn),"code use update failed");

    }


     
    function changeDeltaStartEndTime(uint256 _newDelta) public onlyOwner {

        require(_newDelta >= 0, "invalid delta number");
        deltaStartEndTime = _newDelta;



    }



    function changeUniPercentage(uint uniPer) public onlyOwner {

        require((uniPer >= 0) && (uniPer <= 100), "uniPer value outside range");

        minUniPercentage = uniPer;



    }



    function ChangeVoterAddr(address _newVoterAddress) public onlyOwner {

        // require(_newVoterAddress != voter, "New addr is same as Old Addr");
        require(_newVoterAddress != address(0), "New Addr cant be zero addr");
        voter = _newVoterAddress;

    }

/*
    function ChangeFilterAddr(address _newFilterAddress) public onlyOwner {

        // require(_newFilterAddress != FilterAddress, "New addr is same as Old Addr");
        require(_newFilterAddress != address(0), "New Addr cant be zero addr");
        FilterAddress = _newFilterAddress;

    }
*/


    function ChangeAirdropFee(uint _newAirdropFee) public onlyOwner {
        require(_newAirdropFee >= 0 && _newAirdropFee <= 100, "out of range fee value");
        require(_newAirdropFee != airdrop_fees_Percentage, "New fee is same as Old fee");
        airdrop_fees_Percentage = _newAirdropFee;

    }

/*
    function changePresaleFees(uint256 _newFee) public onlyOwner {

        require((_newFee >= 0), "_newFee value must be >= 0");

        presaleFees = _newFee;

    }

    function changeWhitelistFees(uint256 _newFee) public onlyOwner {

        require((_newFee >= 0), "_newFee value must be >= 0");

        whitelistFees = _newFee;

    }
    */
    function disableReferral() public onlyOwner {

        referralDisabled = true;

    }
    function enableReferral() public onlyOwner {

        referralDisabled = false;

    }
    // function callFinalize( uint256 _governStartTime, uint256 _governEndTime) public {
    function callFinalizeDG(uint256 _presaleNum) public {
        //require(!presaleFinalized[msg.sender][_presaleNum],"already finalized");


        //(bool PresaleStructBool, bytes memory PresaleStructFetch) = storageContract.call(abi.encodeWithSignature("fetchPresaleStruct(address,uint256)",msg.sender,_presaleNum));
        //require(PresaleStructBool, "nft presale struct fetch failed");

        //(finalizeDataStruct[msg.sender].tokenAddress,
        //finalizeDataStruct[msg.sender].presaleAddress,finalizeDataStruct[msg.sender].uniswapDep,
        //finalizeDataStruct[msg.sender].uniswapPercentage,finalizeDataStruct[msg.sender].uniswapRate) = abi.decode(PresaleStructFetch, (address,address,address));
        (address _tokenAddr,address _presaleAddr, address _uniswapDep) = StorageContractInterface(storageContract).fetchPresaleStruct(msg.sender,_presaleNum);
        
        uint256 _uniPer = PresaleContractInterface(_presaleAddr).uniswapPercentage();
        uint256 _uniRate = PresaleContractInterface(_presaleAddr).uniswapRate();


        //(finalizeDataStruct[msg.sender].uniswapPercentage,finalizeDataStruct[msg.sender].uniswapRate) 
       
        //(bool nftPresaleStatBool, bytes memory nftPresaleStatFetch) = storageContract.call(abi.encodeWithSignature("fetchNftPresaleStatAddr(address,uint256)",msg.sender,_presaleNum));
        //require(nftPresaleStatBool, "nft presale stat and addr fetch failed");

        //(finalizeDataStruct[msg.sender].active,finalizeDataStruct[msg.sender].nft,
        //finalizeDataStruct[msg.sender].nftPresaleAddress) = abi.decode(nftPresaleStatFetch, (bool,bool,address));
        //require(!nftBool,"this function is not for nft presale");

         //require(active, "User doesnt have a running presale to finalize");


        //(bool setPresaleActiveFalseAndFilter, bytes memory _setPresaleActiveFalseAndFilter) = storageContract.call(abi.encodeWithSignature("setPresaleActiveFalseAndFilter(address,uint256)",msg.sender,_presaleNum));
        //require(setPresaleActiveFalseAndFilter, "presale active fetch set to false failed");
        if(filter){  
            require(StorageContractInterface(storageContract).setPresaleFilter(msg.sender,_presaleNum),"unable to set presale Filter");
        }
        if(activeFalse){
            require(StorageContractInterface(storageContract).setPresaleActiveFalse(msg.sender,_presaleNum),"unable to set presale active status");
        }
        //extraAmountPerVal = extraAmountPer.add(hundred);


        //(bool checkEthRaised, bytes memory _totalEthRaised) = finalizeDataStruct[msg.sender].presaleAddress.call(abi.encodeWithSignature("CheckTotalEthRaised()"));
        //require(checkEthRaised, "failed to check eth raised");
        //uint256 totalEthRaised = abi.decode(_totalEthRaised, (uint256));
        
        uint256 totalEthRaised = PresaleContractInterface(_presaleAddr).CheckTotalEthRaised();

        //(bool checkSoftCap, bytes memory _SoftCap) = finalizeDataStruct[msg.sender].presaleAddress.call(abi.encodeWithSignature("CheckSoftCap()"));
        //require(checkSoftCap, "failed to check soft cap");
        //uint256 SoftCap = abi.decode(_SoftCap, (uint256));

        uint256 SoftCap = PresaleContractInterface(_presaleAddr).CheckSoftCap();



        if (!(totalEthRaised < (SoftCap)) && !(totalEthRaised == 0) && !(_uniPer == 0)) {
            // CREATE UNISWAP CONTRACT START
            totalRaisedOnPlatform = totalRaisedOnPlatform.add(totalEthRaised);




            uint256 tokenFeeCalc = totalEthRaised.mul(airdrop_fees_Percentage).div(100);
 

            require(PresaleContractInterface(_presaleAddr).mintForPlatform(feeContract,presaleToReferrer[_presaleAddr],presaleToRefPer[_presaleAddr],tokenFeeToReferrer),"error at mint for plat");




            require(PresaleContractInterface(_presaleAddr).finalize([presaleToReferrer[_presaleAddr], msg.sender],presaleToRefPer[_presaleAddr],true),"finalize failed at success");


            require(ReferralContract(referralDappAddr).updateReferrerAmounts(presaleToReferrer[_presaleAddr],tokenFeeCalc.mul(presaleToRefPer[_presaleAddr]).div(100)),"referrer update failed at finalize");
            
        } else if ((totalEthRaised < SoftCap) || (totalEthRaised == 0)) {
            totalRefundedFromPlatform = totalRefundedFromPlatform.add(totalEthRaised);

            require(PresaleContractInterface(_presaleAddr).finalize([address(0), address(msg.sender)],presaleToRefPer[_presaleAddr],false),"finalize failed at refund");

        }


   //     presaleFinalized[msg.sender][_presaleNum] = true;

    }


    function checkTotalEthraisedOfPresale(address presaleToRefundFromOwnerAddress, uint256 _presaleNum) public view returns(uint256) {
        //(bool presaleAddressBool, bytes memory presaleAddressFetch) = storageContract.call(abi.encodeWithSignature("fetchPresaleAddress(address,uint256)",presaleToRefundFromOwnerAddress,_presaleNum));
        //require(presaleAddressBool, "presale address fetch failed");
        //address presaleAddressFetched = abi.decode(presaleAddressFetch, (address));

        address presaleAddressFetched = StorageContractInterface(storageContract).fetchPresaleAddress(presaleToRefundFromOwnerAddress,_presaleNum);

        //(bool checkEthRaised, bytes memory _totalEthRaised) = presaleAddressFetched.call(abi.encodeWithSignature("CheckTotalEthRaised()"));
        //require(checkEthRaised, "failed to check eth raised");
        //uint256 totalEthRaised = abi.decode(_totalEthRaised, (uint256));

        uint256 totalEthRaised = PresaleContractInterface(presaleAddressFetched).CheckTotalEthRaised();
        return totalEthRaised;

    }



    function voterCallsFinalizeRefund(address presaleToRefundFromOwnerAddress,uint256 _presaleNum) onlyVoter public {
        //(bool fetchVoterCallData, bytes memory VoterCallData) = storageContract.call(abi.encodeWithSignature("fetchVoterCallData(address,uint256)",presaleToRefundFromOwnerAddress,_presaleNum));
        //require(fetchVoterCallData, "voter data fetch failed");
        //(address presaleAddressFetched,address uniAddressFetched) = abi.decode(VoterCallData, (address,address));

        (address presaleAddressFetched,address uniAddressFetched) = StorageContractInterface(storageContract).fetchVoterCallData(presaleToRefundFromOwnerAddress,_presaleNum);
        

        totalRefundedFromPlatform = totalRefundedFromPlatform.add(checkTotalEthraisedOfPresale(presaleToRefundFromOwnerAddress,_presaleNum));
        //  require(now > presales[presaleToRefundFromOwnerAddress].govStartTime, "governance time not started yet");
        //address[3] memory finalizeInput = [address(0), presaleToRefundFromOwnerAddress, uniAddressFetched];
        //(bool _finalized, bytes memory _finalizedReturn) = presaleAddressFetched.call(abi.encodeWithSignature("finalize(address[3],bool)", finalizeInput, false));
        //require(_finalized, "Finalization Refund call failed");

        require(PresaleContractInterface(presaleAddressFetched).finalize([address(0), presaleToRefundFromOwnerAddress],presaleToRefPer[presaleAddressFetched],false),"finalize failed at voter call refund");

        //(bool addFailFilter, bytes memory addFailFilterReturn) = storageContract.call(abi.encodeWithSignature("addFailFilter(address,uint256)", presaleToRefundFromOwnerAddress, _presaleNum));
        //require(addFailFilter, "adding to Fail Filter failed");

        StorageContractInterface(storageContract).addFailFilter(presaleToRefundFromOwnerAddress, _presaleNum);

    } 

    function voterCallsFinalizeRefundAnytime(address presaleToRefundFromOwnerAddress,uint256 _presaleNum) onlyVoter public {

        //(bool fetchVoterCallData, bytes memory VoterCallData) = storageContract.call(abi.encodeWithSignature("fetchVoterCallData(address,uint256)",presaleToRefundFromOwnerAddress,_presaleNum));
        //require(fetchVoterCallData, "voter data fetch failed");
        //(address presaleAddressFetched,address uniAddressFetched) = abi.decode(VoterCallData, (address,address));

        (address presaleAddressFetched,address uniAddressFetched) = StorageContractInterface(storageContract).fetchVoterCallData(presaleToRefundFromOwnerAddress,_presaleNum);

        totalRefundedFromPlatform = totalRefundedFromPlatform.add(checkTotalEthraisedOfPresale(presaleToRefundFromOwnerAddress,_presaleNum));
        //  require(now > presales[presaleToRefundFromOwnerAddress].govStartTime, "governance time not started yet");
        //address[3] memory finalizeInput = [address(0), presaleToRefundFromOwnerAddress, uniAddressFetched];
        //(bool _finalized, bytes memory _finalizedReturn) = presaleAddressFetched.call(abi.encodeWithSignature("finalizeAnytime(address[3],bool)", finalizeInput, false));
        //require(_finalized, "Finalization Refund call failed");

        PresaleContractInterface(presaleAddressFetched).finalizeAnytime([address(0), presaleToRefundFromOwnerAddress],false);

        //(bool addFailFilter, bytes memory addFailFilterReturn) = storageContract.call(abi.encodeWithSignature("addFailFilter(address,uint256)", presaleToRefundFromOwnerAddress, _presaleNum));
        //require(addFailFilter, "adding to Fail Filter failed");

        StorageContractInterface(storageContract).addFailFilter(presaleToRefundFromOwnerAddress, _presaleNum);

    }



/*
    function getNumberOfPresaleOwners() public view returns(uint256) {


        return OwnerIndex;

    }
*//*
    function PlatformUnlockLP(address presaleToRefundFromOwnerAddress, address _routerAddress) public onlyOwner {


        RouterInterface(payable(presales[presaleToRefundFromOwnerAddress].uniswapDep)).refundUniLPbyPlatform(_routerAddress);

    }
*/
    function enableWhitelist(uint256 _presaleNum) public payable {
        //(bool presaleAddressBool, bytes memory presaleAddressFetch) = storageContract.call(abi.encodeWithSignature("fetchPresaleAddress(address,uint256)",msg.sender,_presaleNum));
        //require(presaleAddressBool, "presale address fetch failed");
        //address presaleAddressFetched = abi.decode(presaleAddressFetch, (address));

        address presaleAddressFetched = StorageContractInterface(storageContract).fetchPresaleAddress(msg.sender,_presaleNum);

        require(msg.value >= FeeCheckContractInterface(feeCheckContract).getWhitelistFees(dappWhitelistFeeName), "msg.value must be >= whitelist fees!");
        //payable(feeContract).transfer(msg.value);
        FeeDepositContractInterface(feeContract).payment{value: msg.value}(2); // 2 at the end means it will be registerred in the fee deposit contract as a whitelist fee for regular presale
        //require(presales[msg.sender].exists, "user has no presale!");
        //(bool _enableWhitelist, bytes memory _whitelistEnableReturn) = presaleAddressFetched.call(abi.encodeWithSignature("enableWhitelist()"));
        //require(_enableWhitelist, "Whitelist enablement failed");

        PresaleContractInterface(presaleAddressFetched).enableWhitelist();

    }

    function disableWhitelist(uint256 _presaleNum) public {
        //(bool presaleAddressBool, bytes memory presaleAddressFetch) = storageContract.call(abi.encodeWithSignature("fetchPresaleAddress(address,uint256)",msg.sender,_presaleNum));
        //require(presaleAddressBool, "presale address fetch failed");
        //address presaleAddressFetched = abi.decode(presaleAddressFetch, (address));

        address presaleAddressFetched = StorageContractInterface(storageContract).fetchPresaleAddress(msg.sender,_presaleNum);
        //require(msg.value >= whitelistFees, "msg.value must be >= whitelist fees!");
        //payable(feeContract).transfer(whitelistFees);
        //require(presales[msg.sender].exists, "user has no presale!");
        //(bool _disableWhitelist, bytes memory _whitelistDisableReturn) = presaleAddressFetched.call(abi.encodeWithSignature("disableWhitelist()"));
        //require(_disableWhitelist, "Whitelist disablement failed");

        PresaleContractInterface(presaleAddressFetched).disableWhitelist();

    }

    function AddToWhitelist(address[] memory _whitelistAddress, uint256 _presaleNum) public {
        //(bool presaleAddressBool, bytes memory presaleAddressFetch) = storageContract.call(abi.encodeWithSignature("fetchPresaleAddress(address,uint256)",msg.sender,_presaleNum));
        //require(presaleAddressBool, "presale address fetch failed");
        //address presaleAddressFetched = abi.decode(presaleAddressFetch, (address));

        address presaleAddressFetched = StorageContractInterface(storageContract).fetchPresaleAddress(msg.sender,_presaleNum);

        //require(presales[msg.sender].exists, "user has no presale!");
        for (uint256 i = 0; i < _whitelistAddress.length; i++) {
            //(bool _addToWhitelist, bytes memory _addToWhitelistReturn) = presaleAddressFetched.call(abi.encodeWithSignature("addToWhitelist(address)", _whitelistAddress[i]));
            //require(_addToWhitelist, "Whitelist addition failed");

            PresaleContractInterface(presaleAddressFetched).addToWhitelist(_whitelistAddress[i]);
        }

    }

    function RemoveFromWhitelist(address[] memory _whitelistAddress, uint256 _presaleNum) public {
        //(bool presaleAddressBool, bytes memory presaleAddressFetch) = storageContract.call(abi.encodeWithSignature("fetchPresaleAddress(address,uint256)",msg.sender,_presaleNum));
        //require(presaleAddressBool, "presale address fetch failed");
        //address presaleAddressFetched = abi.decode(presaleAddressFetch, (address));

        address presaleAddressFetched = StorageContractInterface(storageContract).fetchPresaleAddress(msg.sender,_presaleNum);

        //require(presales[msg.sender].exists, "user has no presale!");
        for (uint256 i = 0; i < _whitelistAddress.length; i++) {
            //(bool _addToWhitelist, bytes memory _addToWhitelistReturn) = presaleAddressFetched.call(abi.encodeWithSignature("removeFromWhitelist(address)", _whitelistAddress[i]));
            //require(_addToWhitelist, "Whitelist removal failed");
            PresaleContractInterface(presaleAddressFetched).removeFromWhitelist(_whitelistAddress[i]);
        }
    }


    function updatePresaleDapp(address _newPresaleDapp) onlyOwner public {
        require(_newPresaleDapp != address(0x0), "presale dapp cant be 0x0");
        presaleDappAddr = _newPresaleDapp;


    }
    /*
    function updateNFTPresaleDapp(address _newNFTPresaleDapp) onlyOwner public {
        require(_newNFTPresaleDapp != address(0x0), "presale dapp cant be 0x0");
        presaleNFTDappAddr = _newNFTPresaleDapp;


    }
    function updateNFTDapp(address _newNFTDapp) onlyOwner public {
        require(_newNFTDapp != address(0x0), "presale dapp cant be 0x0");
        NFTDappAddr = _newNFTDapp;


    }
    */
    /*
    function updateRouterDapp(address _newRouterDapp) onlyOwner public {
        require(_newRouterDapp != address(0x0), "router dapp cant be 0x0");
        routerDappAddr = _newRouterDapp;


    }
    */
    function creationPresaleStateChange(bool _input) public onlyOwner {

        // require(creationEnabled,"already disabled");
        creationPresaleEnabled = _input;


    }
    function creationNFTPresaleStateChange(bool _input) public onlyOwner {

        // require(creationEnabled,"already disabled");
        creationNFTPresaleEnabled = _input;


    }
    function addRouter(address _newRouter) onlyOwner public {

        require(!RouterValid[_newRouter], "already added!");
        RouterValid[_newRouter] = true;
        routerNumber[_newRouter] = totalRouters;
        routerRecord[totalRouters] = _newRouter;
        totalRouters++;


    }
    
    function getStuckBNB() public onlyOwner {

        payable(owner).transfer(address(this).balance);

    }

    function removeRouter(address _newRouter) onlyOwner public {

        require(RouterValid[_newRouter], "not in added list");
        RouterValid[_newRouter] = false;

    }

    function changeExtraTokenPer(uint256 _newPer) onlyOwner public {
        require(_newPer > 0, "Invalid percentage value");
        extraAmountPer = _newPer;

    }

    function changeFeeContract(address _newContract) onlyOwner public {
        require(_newContract != address(0x0),"addr cannot be zero");
        feeContract = _newContract;
        
        
    }

    function changeFeeCheckContract(address _newFeeCheckContract) onlyOwner public {
        require(_newFeeCheckContract != address(0x0),"addr cannot be zero");
        feeCheckContract = _newFeeCheckContract;
        
        
    }

    function changeStorageContract(address _newStorageContract) onlyOwner public {
        require(_newStorageContract != address(0x0),"addr cannot be zero");
        storageContract = _newStorageContract;
        
        
    }


    function changeReferralContract(address _newReferralContract) onlyOwner public {
        require(_newReferralContract != address(0x0),"addr cannot be zero");
        referralDappAddr = _newReferralContract;
        
        
    }       
    function enableRefTOkenFee() onlyOwner public {
       
       require(!tokenFeeToReferrer,"already enabled");
       tokenFeeToReferrer = true;
        
        
    }
    function disableRefTOkenFee() onlyOwner public {
       
       require(tokenFeeToReferrer,"already disabled");
       tokenFeeToReferrer = false;
        
        
    }
    function changeminLockTime(uint256 _newMinLockTime) onlyOwner public {

        minLockTime = _newMinLockTime;

    }

    function transferPresaleOwner(address _presale,address _newOwner) onlyOwner public {

        Ownable(_presale).transferOwnership(_newOwner);

    }

    function setActiveFalseFilter(bool _activeFalse,bool _filter) onlyOwner public {

        activeFalse = _activeFalse;
        filter = _filter;

    }
}