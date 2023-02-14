// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//pragma experimental ABIEncoderV2;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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

contract variables {

    address public constant platformTokenETH = 0xF063fE1aB7a291c5d06a86e14730b00BF24cB589; // Sale token address valid for mainnet ETH
    address public constant platformTokenBSC = 0x04F73A09e2eb410205BE256054794fB452f0D245; // Sale token address valid for mainnet BSC
    address public team_acc = 0xC14fb72518E67B008f1BD8E195861472f8128090;    //valid for mainnet
    uint256  public minPlatTokenReq = 1000000000000000000000;  //1000 sale tokens
    address public dead = 0x000000000000000000000000000000000000dEaD;
    bool public burn = false;
    bool public feesEnabled = false;
    uint256 public regFees = 1000000000000000000;
    uint256 public discountPer = 10;
    uint256 public referrerPer = 5;
} 



contract DxReferral is variables,Ownable {
    using SafeMath for uint256;    
    mapping(address => bool) public Referrers;
    mapping(address => string) public ReferralCode;
    mapping(string => address) public codeToReferrer;
    mapping(address => address) public referredBy;
    mapping(string => bool) public uniqueCodeCheck;
    mapping(string => uint256) public codeToDiscount;
    mapping(address => uint256) public referrerToPer;
    mapping(address => string) public referredByName; 
    mapping(uint256 => address) public AllReferrers;
    mapping(address => bool) public blocked;
    mapping(address => bool) public deployer;
    mapping(address => uint256) public referrerEarnedAmount;
    mapping(string => uint256) public codeUsedNumber;
    mapping(string => mapping(uint256 => address)) public codeToPresaleList;
    mapping(address => string) public presaleAddrToCodeUsed;
    mapping(address => uint256) public tier;
    mapping(uint256 => uint256) public tierPer;
    mapping(uint256 => uint256) public tierDiscount;
    mapping(uint256 => uint256) public tierToAmountRequired; 
    mapping(address => bool) public SpecialReferrer;
    mapping(address => bool) public whitelisted;
    uint256 public referrerNumber;
    uint256 public maxTier;
    uint256 public maxCodeLength = 11;
    uint256 public maxNameLength = 11;
    uint256 public maxDiscount = 50;
    bool public whitelistEnabled = false;
    constructor( uint256[] memory _tierPer, uint256[] memory _tierDiscount, uint256[] memory _tierAmountRequired) {

        require(_tierPer.length == _tierDiscount.length,"array size mismatch");
        for(uint256 i = 0; i < _tierPer.length; i++){
            tierPer[i] = _tierPer[i];
            tierDiscount[i] = _tierDiscount[i];
            tierToAmountRequired[i] = _tierAmountRequired[i] * 10**18;
            maxTier++;
        }
        
        becomeReferrer("dx","default");
        enableWhitelist();
    }
    function becomeReferrer(string memory _name, string memory _code) public payable {
        require(!blocked[msg.sender],"wallet not acceptable");
        require(!Referrers[msg.sender],"already a referrer");
        if(whitelistEnabled){
            require(whitelisted[msg.sender],"not whitelisted");
        }
        bytes memory tempStringCode = bytes(_code);
        bytes memory tempStringName= bytes(_name);
        //require(keccak256(abi.encodePacked(_code)) != keccak256(abi.encodePacked("")), "invalid code");
        require(tempStringCode.length != 0 && tempStringCode.length < maxCodeLength,"invalid code");
        require(tempStringName.length != 0 && tempStringName.length < maxNameLength,"invalid name");  
        require(!uniqueCodeCheck[_code],"code taken");
        require(_checkName(_code),"invalid code characters");
        require(_checkName(_name) ,"invalid name characters");
        if(feesEnabled){
            if(burn){
                require(IERC20(platformTokenBSC).transferFrom(msg.sender,dead,minPlatTokenReq), "sale token transfer fail");
            }
            else{
                require(msg.value >= regFees,"msg.value must be >= drop fees");
                payable(team_acc).transfer(regFees);
            }
        } 

        Referrers[msg.sender] = true;
        uniqueCodeCheck[_code] = true;
        codeToDiscount[_code] = tierDiscount[0];
        ReferralCode[msg.sender] = _code;
        codeToReferrer[_code] = msg.sender;
        referredByName[msg.sender] = _name;
        referrerToPer[msg.sender] = referrerPer;
        AllReferrers[referrerNumber] = msg.sender;
        referrerNumber++;
        
        
    }

    function becomeReferrerByOwner(address _wallet, string memory _name, string memory _code) public onlyOwner payable {
        require(!blocked[_wallet],"wallet not acceptable");
        require(!Referrers[_wallet],"already a referrer");
        if(whitelistEnabled){
            require(whitelisted[_wallet],"not whitelisted");
        }
        bytes memory tempStringCode = bytes(_code);
        bytes memory tempStringName= bytes(_name);
        //require(keccak256(abi.encodePacked(_code)) != keccak256(abi.encodePacked("")), "invalid code");
        require(tempStringCode.length != 0 && tempStringCode.length < maxCodeLength,"invalid code");
        require(tempStringName.length != 0 && tempStringName.length < maxNameLength,"invalid name");  
        require(!uniqueCodeCheck[_code],"code taken");
        require(_checkName(_code),"invalid code characters");
        require(_checkName(_name) ,"invalid name characters");
        if(feesEnabled){
            if(burn){
                require(IERC20(platformTokenBSC).transferFrom(msg.sender,dead,minPlatTokenReq), "sale token transfer fail");
            }
            else{
                require(msg.value >= regFees,"msg.value must be >= drop fees");
                payable(team_acc).transfer(regFees);
            }
        } 

        Referrers[_wallet] = true;
        uniqueCodeCheck[_code] = true;
        codeToDiscount[_code] = tierDiscount[0];
        ReferralCode[_wallet] = _code;
        codeToReferrer[_code] = _wallet;
        referredByName[_wallet] = _name;
        referrerToPer[_wallet] = referrerPer;
        AllReferrers[referrerNumber] = _wallet;
        referrerNumber++;
        
        
    }
  function changeMaxCodeLength(uint256 _newCodeLength) public onlyOwner {

    maxCodeLength = _newCodeLength;


  }
  function changeMaxNameCodeLength(uint256 _newNameLength) public onlyOwner {

    maxNameLength = _newNameLength;


  }
    function updateCodeUseNumber(string memory _code, address _presaleAddress) public returns(bool) {

        require(deployer[msg.sender],"only deployer allowed");
        codeToPresaleList[_code][codeUsedNumber[_code]] = _presaleAddress;
        presaleAddrToCodeUsed[_presaleAddress] = _code;
        codeUsedNumber[_code]++;
        return true;
        
    }

    function updateName(string memory _newName) public {
        require(Referrers[msg.sender],"account not found");
        bytes memory tempStringName= bytes(_newName);
        require(tempStringName.length != 0 && tempStringName.length < maxNameLength,"invalid name");
        require(_checkName(_newName),"invalid input characters"); 
        referredByName[msg.sender] = _newName;
        
        
    }
    function updateReferrerAmounts(address _referrer, uint256 _updateAmount) public returns(bool) {

        require(deployer[msg.sender],"only deployer allowed");
        referrerEarnedAmount[_referrer] += _updateAmount;
        return true;

    }
    
    function updateDeadAddress(address _newDeadAddress) onlyOwner public {
        
        dead = _newDeadAddress;
        
        
    }    
 


    function updateMyTier() public {
        require(!SpecialReferrer[msg.sender],"not eligible for upgrade");
        require(Referrers[msg.sender],"not registered");
        require(tier[msg.sender] < maxTier.sub(1),"already max tier");
        
        require(referrerEarnedAmount[msg.sender] > tierToAmountRequired[tier[msg.sender].add(1)],"not eligible yet");
        tier[msg.sender]++;
        codeToDiscount[ReferralCode[msg.sender]] = tierDiscount[tier[msg.sender]];

    }

function setTierPer(uint256[] memory _tierLevel, uint256[] memory _tierPer) onlyOwner public {
        
        require(_tierLevel.length == _tierPer.length,"array length mismatch");
        for(uint256 i = 0; i < _tierLevel.length; i++){
            tierPer[_tierLevel[i]] = _tierPer[i];
            maxTier++;
        }

        


}
function setTierToAmountRequired(uint256[] memory _tierLevel, uint256[] memory _tierAmountRequired) onlyOwner public {

        for(uint256 i = 0; i < _tierLevel.length; i++){
            tierToAmountRequired[_tierLevel[i]] = _tierAmountRequired[i];
        }


}

function setReferrerTier(address _referrer, uint256 _tier) onlyOwner public {

    require(_tier < maxTier,"tier more than max limit");
    tier[_referrer] = _tier;
    codeToDiscount[ReferralCode[_referrer]] = tierDiscount[tier[_referrer]];

}
function setReferrerDiscount(address _referrer, uint256 _discount) onlyOwner public {

    require(_discount <= maxDiscount,"cannot exceed max discount");
    require(Referrers[_referrer],"input address is not referrer");
    //require(_tier < maxTier,"tier more than max limit");
    //tier[_referrer] = _tier;
    codeToDiscount[ReferralCode[_referrer]] = _discount;

}
function unsetSpecialReferrer(address _referrer) onlyOwner public {

    SpecialReferrer[_referrer] = false;



}

function setSpecialReferrer(address _referrer) onlyOwner public {

    SpecialReferrer[_referrer] = true;



}

function setMaxTier(uint256 _newMaxTier) onlyOwner public {

    require(_newMaxTier > maxTier,"new tier cannot be smaller");
    maxTier = _newMaxTier;


}

function setMaxDiscount(uint256 _newMaxDiscount) onlyOwner public {

    require(_newMaxDiscount <= 100,"new discount cannot be more than 100");
    maxDiscount = _newMaxDiscount;

}

function changeSaleRequired(uint256 _newFeeAmount) public onlyOwner {
    
    require(_newFeeAmount >= 0,"invalid amount");
    minPlatTokenReq = _newFeeAmount;
    
    
    
}

function changeFees(uint256 _newFeeAmount) public onlyOwner {
    
    require(_newFeeAmount >= 0,"invalid amount");
    regFees = _newFeeAmount;
    
   
    
}
function changeDiscountPer(uint256 _newPer) public onlyOwner {
    
    require(_newPer <= 100,"invalid amount");
    discountPer = _newPer;
    
    
}



function blockReferrer(address _walletAddress) public onlyOwner {
    require(!blocked[_walletAddress],"already blocked");
    Referrers[_walletAddress] = false;
    uniqueCodeCheck[ReferralCode[_walletAddress]] = false;
    blocked[_walletAddress] = true;
    //Referrers[_walletAddress] = false;
    
    
}

function unBlockReferrer(address _walletAddress) public onlyOwner {
    
    require(blocked[_walletAddress],"already unblocked");
    Referrers[_walletAddress] = true;
    uniqueCodeCheck[ReferralCode[_walletAddress]] = true;
    blocked[_walletAddress] = false;
    //Referrers[_walletAddress] = false;
    
    
}

function updateDiscountPer(address _walletAddress, uint256 _specialDiscountPer) public onlyOwner {
    
    require(_specialDiscountPer <= 100,"invalid discount per");
    require(!blocked[_walletAddress],"wallet blocked");
    require(Referrers[_walletAddress],"wallet not active");
    require(uniqueCodeCheck[ReferralCode[_walletAddress]],"code not found");
    codeToDiscount[ReferralCode[_walletAddress]] = _specialDiscountPer;   
    
}

function updateDiscountPerViaCode(string memory _code, uint256 _specialDiscountPer) public onlyOwner {
    
    require(uniqueCodeCheck[_code],"code not found");
    require(_specialDiscountPer <= 100,"invalid discount per");
    require(!blocked[codeToReferrer[_code]],"wallet blocked");
    require(Referrers[codeToReferrer[_code]],"wallet not active");
    codeToDiscount[_code] = _specialDiscountPer;   
    
}

function _checkName(string memory _name) public pure returns(bool){
        uint allowedChars =0;
        bytes memory byteString = bytes(_name);
        bytes memory allowed = bytes("abcdefghijklmnopqrstuvwxyz");  //here you put what character are allowed to use
        for(uint i=0; i < byteString.length ; i++){
           for(uint j=0; j<allowed.length; j++){
              if(byteString[i]==allowed[j] )
              allowedChars++;         
           }
        }
        if(allowedChars<byteString.length){
            return false;
        }
        return true;
    }
    function enableFees() public onlyOwner{
        
        
        feesEnabled = true;
        
    }
    function disableFees() public onlyOwner{
        
        
        feesEnabled = false;
        
    }    
    function enableBurn() public onlyOwner{
        
        
        burn = true;
        
    }
    function disableBurn() public onlyOwner{
        
        
        burn = false;
        
    }

    function addDeployer(address _newDeployer) public onlyOwner {
        
        require(!deployer[_newDeployer],"already added");
        deployer[_newDeployer] = true;


    }
     function removeDeployer(address _oldDeployer) public onlyOwner {
        
        require(deployer[_oldDeployer],"already removed");
        deployer[_oldDeployer] = false;

    }

    function enableWhitelist() public onlyOwner {
        
        require(!whitelistEnabled,"already enabled");
        whitelistEnabled = true;

    }
    function disableWhitelist() public onlyOwner {
        require(whitelistEnabled,"already disabled");
        whitelistEnabled = false;

    }
    function addToWhitelist(address[] memory _whitelistAddresses) public onlyOwner {
        
        for(uint256 i = 0; i < _whitelistAddresses.length; i++){
            whitelisted[_whitelistAddresses[i]] = true;
        }

    }
    function removeFromWhitelist(address[] memory _whitelistAddresses) public onlyOwner {
        
        for(uint256 i = 0; i < _whitelistAddresses.length; i++){
            whitelisted[_whitelistAddresses[i]] = false;
        }

    }          
  /*   
    function getTotalTokensByAuditor(address _Auditor) public view returns(address[] memory) {
        
        address[] memory auditedTokenList = new address[](AuditorNumbers[_Auditor]);
        for(uint256 i = 0; i < AuditorNumbers[_Auditor]; i++){
            auditedTokenList[i] = AuditorTotalList[_Auditor][i];
    }
        
     return auditedTokenList;   
        
    }
   
    function getData(address _token) public view returns(bool,address,string memory,string memory,string memory,string memory,string memory) {
        
        return (AuditVerfied[_token],auditedBy[_token],auditedByName[_token],auditorComment[_token],auditorComment1[_token],auditorComment2[_token],auditorScore[_token]);
        
        
    }
    */
    function getDiscountedPrice(string memory _code) public view returns(uint256){

        return codeToDiscount[_code];

    }
    function fetchCodeOwner(string memory _code) public view returns(address){

        return codeToReferrer[_code];

    }
    function fetchCodeOwnerPercentage(string memory _code) public view returns(uint256){
        
        if(keccak256(abi.encodePacked(_code)) == keccak256(abi.encodePacked("default"))){

            return 0;

        }
        return tierPer[tier[codeToReferrer[_code]]];

    }
    function validateCode(string memory _code) public view returns(bool){

        return uniqueCodeCheck[_code];

    }
    function presalesPerCode(string memory _code) public view returns (address[] memory) {
        uint256 codeUsedNum = codeUsedNumber[_code];
        address[] memory presaleList = new address[](codeUsedNum);   
        for(uint256 i = 0; i < codeUsedNum; i++){
            presaleList[i] = codeToPresaleList[_code][i];
        }  
    
        return presaleList; 


    }
    function getAllReferrers() public view returns (address[] memory){
     address[] memory referrerList = new address[](referrerNumber);   
        for(uint256 i = 0; i < referrerNumber; i++){
            referrerList[i] = AllReferrers[i];
    }  
    
    return referrerList;    
        
        
    }

    function getAllReferralCode() public view onlyOwner returns (string[] memory){

     string[] memory referralCodeList = new string[](referrerNumber);   
        for(uint256 i = 0; i < referrerNumber; i++){
            referralCodeList[i] = ReferralCode[AllReferrers[i]];
    }  
    
    return referralCodeList;    
        
        
    }

    function getAllReferralInfo() public view onlyOwner returns (string[] memory, address[] memory, uint256[] memory, uint256[] memory){

     string[] memory referrerName = new string[](referrerNumber);
     address[] memory referrerAddress = new address[](referrerNumber);
     uint256[] memory referrerPer = new uint256[](referrerNumber);
     uint256[] memory referrerToDiscount = new uint256[](referrerNumber);   
        for(uint256 i = 0; i < referrerNumber; i++){
            referrerName[i] = referredByName[AllReferrers[i]];
            referrerAddress[i] = AllReferrers[i];
            referrerPer[i] = referrerToPer[AllReferrers[i]];
            referrerToDiscount[i] = codeToDiscount[ReferralCode[AllReferrers[i]]];

    }  
    
    return (referrerName,referrerAddress,referrerPer,referrerToDiscount);    
        
        
    }
    function getTierInfo() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory){

     uint256[] memory tierLevel = new uint256[](maxTier);
     uint256[] memory tierPercentage = new uint256[](maxTier);
     uint256[] memory tierDiscounts = new uint256[](maxTier);
     uint256[] memory tierEarningsRequirement =  new uint256[](maxTier);   
        for(uint256 i = 0; i < maxTier; i++){
            tierLevel[i] = i;
            tierPercentage[i] = tierPer[i];
            tierDiscounts[i] = tierDiscount[i];
            tierEarningsRequirement[i] = tierToAmountRequired[i];

    }  
    
    return (tierLevel,tierPercentage,tierDiscounts,tierEarningsRequirement);    
        
        
    }
}