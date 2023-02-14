// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//pragma experimental ABIEncoderV2;
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/UniswapFactory.sol";
//import "https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/UniswapPair.sol";
//import "https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/UniswapRouter02.sol";

interface ERC20 {
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function transfer(address to, uint256 value) external returns(bool);

    function approve(address spender, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function totalSupply() external view returns(uint256);

    function balanceOf(address who) external view returns(uint256);

    function allowance(address owner, address spender) external view returns(uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}





/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public voter;
    mapping(address => bool) public Deployer;
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

    modifier onlyVoter() {
        require(msg.sender == voter);
        _;
    }

    modifier onlyDeployer() {
        require(Deployer[msg.sender]);
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

    uint256 constant minLockTime = 600; // 10 mins for degen

}



/*
contract infoStorage is Ownable {

    struct info {

        bool exists;
        string name;
        string symbol;
        string logo;
        string website;
        string github;
        string twitter;
        string reddit;
        string telegram;
        string description;
        string update;
    }

    mapping(address => info) public infoManager;

    constructor(string[10] memory _tokenInfoInput, address _presaleCreator) {

        if (!infoManager[_presaleCreator].exists) {

            info memory presaleInfo = info({
                exists: true,
                name: _tokenInfoInput[0],
                symbol: _tokenInfoInput[1],
                logo: _tokenInfoInput[2],
                website: _tokenInfoInput[3],
                github: _tokenInfoInput[4],
                twitter: _tokenInfoInput[5],
                reddit: _tokenInfoInput[6],
                telegram: _tokenInfoInput[7],
                description: _tokenInfoInput[8],
                update: _tokenInfoInput[9]
            });

            infoManager[_presaleCreator] = presaleInfo;
        }



    }

    function ChangeInfoDG(string[10] memory ChangeData) public onlyOwner {
        
        infoManager[msg.sender].logo = ChangeData[0];
        infoManager[msg.sender].website = ChangeData[1];
        infoManager[msg.sender].github = ChangeData[2];
        infoManager[msg.sender].twitter = ChangeData[3];
        infoManager[msg.sender].reddit = ChangeData[4];
        infoManager[msg.sender].telegram = ChangeData[5];
        infoManager[msg.sender].update = ChangeData[6];
        infoManager[msg.sender].description = ChangeData[7];
        
        
            info memory presaleInfo = info({
                exists: true,
                name: ChangeData[0],
                symbol: ChangeData[1],
                logo: ChangeData[2],
                website: ChangeData[3],
                github: ChangeData[4],
                twitter: ChangeData[5],
                reddit: ChangeData[6],
                telegram: ChangeData[7],
                description: ChangeData[8],
                update: ChangeData[9]
            });

            infoManager[msg.sender] = presaleInfo;


    }

    function changeLogo(string memory newLogo) public onlyOwner {

        infoManager[msg.sender].logo = newLogo;

    }

    function changeWebsite(string memory newWebsite) public onlyOwner {

        infoManager[msg.sender].website = newWebsite;

    }

    function changeGit(string memory newGit) public onlyOwner {

        infoManager[msg.sender].github = newGit;

    }

    function changeTwitter(string memory newTwitter) public onlyOwner {

        infoManager[msg.sender].twitter = newTwitter;

    }

    function changeReddit(string memory newReddit) public onlyOwner {

        infoManager[msg.sender].reddit = newReddit;

    }

    function changeTelegram(string memory newTelegram) public onlyOwner {

        infoManager[msg.sender].telegram = newTelegram;

    }

    function changeDescription(string memory newDescription) public onlyOwner {

        infoManager[msg.sender].description = newDescription;

    }

    function changeUpdate(string memory newUpdate) public onlyOwner {

        infoManager[msg.sender].update = newUpdate;

    }

}
*/


interface PresaleContractInterface {


    function CheckTotalEthRaised() external view returns(uint256);
    function CheckSoftCap() external view returns(uint256);
    function getPresaleData() external view returns(uint256[10] memory,bool[4] memory, string memory);

}

interface auditKycContractInterface {

    function getAuditKycBool(address _auditInput, address _kycInput) external view returns(bool[2] memory);

}
contract presaleStorage is Consts, Ownable {
    uint256 public presaleFees = 1 * (10**18); // 1 ETH
    uint256 public whitelistFees = 0.9 * (10**18); // 0.9 ETH
    uint public minUniPercentage = 50; //minimum 50% has to go for uniswap lock
    //address public presaleDappAddr;
    //address public routerDappAddr;
   // address public FilterAddress;
    address public auditKycContract;
    uint256 public totalRaisedOnPlatform;
    uint256 public totalRefundedFromPlatform;
    //uint256 public deltaStartEndTime = 604800;
    //  address public uniswapDappAddr;
    //  address[3] public finalizeInput;
    uint256 public tokenFee;
    // address public UNISWAP_ADDRESS = 0xc0fFee0000C824D24E0F280f1e4D21152625742b;  //Koffeeswap Address
    //  address public factoryAddress = 0xC0fFeE00000e1439651C6aD025ea2A71ED7F3Eab;     //Koffeeswap factory Address
    constructor(address _auditKycContract) {

        
       // FilterAddress = _filterAddress;
        auditKycContract = _auditKycContract;

    }

  //  using SafeMath for uint256;

    struct Presale {


        //address presaleInfoAddr;
        address _owner;
        address tokenAddress;
        address presaleAddress;
        address nftPresaleAddress;
        address uniswapDep;

        uint256 _preNum;
        uint256 createdOn;
        uint256 lp_locked;
        //bool exists;
        bool active;
        bool presale;
        bool nft;
        bool fair;
    }

    
    struct info {

        //bool exists;
        string data1;
        string data2;
        string logo;
        string website;
        string github;
        string twitter;
        string reddit;
        string telegram;
        string description;
        string update;
    }

    struct perPadStruct {
        //bool exists;
        //uint256 createdOn;
        address creator;
        uint256 presaleNum;
        uint256 presaleIndex;
    }

    mapping(address => mapping(uint256 => info)) public infoManager;
    mapping(address => mapping(uint256 => Presale)) public presales;
    mapping(address => mapping(uint256 => perPadStruct)) public presalePerPad;
    mapping(address => mapping(uint256 => uint256)) public saleIDPerPad;
    mapping(uint256 => uint256) public successSaleID;
    mapping(uint256 => uint256) public failSaleID;
    mapping(address => mapping(uint256 => uint256)) public successSaleIDPerPad;
    mapping(address => mapping(uint256 => uint256)) public failSaleIDPerPad;
    mapping(uint256 => perPadStruct) public allPresales;
    mapping(uint256 => address) public allPresalesIndexToDappCaller;
//    mapping(address => bool) public tokenDropRequired;
    //address[] public presaleOwners;
    mapping(uint256 => address) public presaleOwners;
    //governor internal GoverningContract;
   // mapping(address => mapping (uint256 => uint256)) public createdOn;
    mapping(address => address) public tokenAddrToOwnerAddr;
    mapping(address => address) public presaleAddrToOwnerAddr;
    mapping(address => address) public presaleAddrToDeployerAddr;
    mapping(address => mapping(uint256 => uint256)) public presaleOwnerToIndex;
    mapping(uint256 => uint256) public presaleOwnersPresaleNum;
    mapping(address => uint256) public tokenAddrToIndex;
    //mapping(address => bool) public RouterValid;
    //mapping(uint256 => address) public routerRecord;
    //mapping(address => uint256) public routerNumber;
    mapping(address => uint256) public ownerPresaleNumber;
    uint256 public presaleSuccessNumber;
    uint256 public presaleFailNumber;
    mapping(address => uint256) public presalePerPadNumber;
    mapping(address => uint256) public presaleSuccessPerPadNumber;
    mapping(address => uint256) public presaleFailPerPadNumber;      
    mapping(address => uint256) public presaleToPresaleNum;
    mapping(address => mapping(uint256 => uint256)) public presaleNumToIndex;
    //uint256 public totalRouters;
    uint256 public OwnerIndex;
    uint256 public liveSaleIndex;
    //uint256 public extraAmountPer = 2;
    //uint256 public extraAmountPerVal;
    //uint256 public hundred = 100;

    // function CreatePresaleDep(string[3] memory _tokenInfo, uint256[2] memory start_end_time, uint256 rate, uint256[3] memory soft_hard_cap_rate, uint256[2] memory min_max_eth, address[] memory _teamAddresses, uint256[] memory _teamAmounts, uint64[] memory _freezeTime) public{

    function CreatePresaleStorage(address tokenAddr,uint256 _lp_locked, address _creator, bool[3] memory _nftIdoFair) public onlyDeployer returns(bool) {



        //infoStorage PresaleInfo = new infoStorage(_tokenInfo, _creator);

        //PresaleInfo.transferOwnership(_creator);

        Presale memory presale = Presale({


            //presaleInfoAddr: address(PresaleInfo),
            _owner: _creator,
            tokenAddress: tokenAddr,
            presaleAddress: address(0),
            nftPresaleAddress: address(0),
            uniswapDep: address(0),
            lp_locked: _lp_locked,
            _preNum: ownerPresaleNumber[_creator],
            createdOn: block.timestamp,
            //exists: true,
            active: true,
            presale: _nftIdoFair[0],
            nft: _nftIdoFair[1],
            fair: _nftIdoFair[2]
        });

        perPadStruct memory perPadData = perPadStruct({

            creator: _creator,
            presaleNum:ownerPresaleNumber[_creator],
            presaleIndex: OwnerIndex // this is the sale ID that is used in UI

        });

 

        presales[_creator][ownerPresaleNumber[_creator]] = presale;
        presalePerPad[msg.sender][presalePerPadNumber[msg.sender]] = perPadData;
        saleIDPerPad[msg.sender][presalePerPadNumber[msg.sender]] = OwnerIndex;
        allPresales[OwnerIndex] = perPadData;
        allPresalesIndexToDappCaller[OwnerIndex] = msg.sender;
        //createdOn[_creator][ownerPresaleNumber[_creator]] = block.timestamp;




        presaleOwners[OwnerIndex] = _creator;
        presaleOwnersPresaleNum[OwnerIndex] = ownerPresaleNumber[_creator];
        presaleOwnerToIndex[_creator][ownerPresaleNumber[_creator]] = OwnerIndex;
        tokenAddrToIndex[tokenAddr] = OwnerIndex;
        //presaleNumToIndex[_creator][ownerPresaleNumber[_creator]] = OwnerIndex;

        OwnerIndex++;
        liveSaleIndex++;




        tokenAddrToOwnerAddr[tokenAddr] = _creator; //used for search bar on dapp via token address

        ownerPresaleNumber[_creator]++;
        presalePerPadNumber[msg.sender]++;
/*
        (bool addLiveFilter, bytes memory addLiveFilterReturn) = FilterAddress.call(abi.encodeWithSignature("addLive(address,address,address)", _creator, presales[_creator][ownerPresaleNumber[_creator]].presaleAddress, presales[_creator][ownerPresaleNumber[_creator]].tokenAddress));
        require(addLiveFilter, "adding to Live Filter failed");
        // address presaleReturn = abi.decode (presaleFetch, (address));
        ownerPresaleNumber[_creator]++;
        presalePerPadNumber[msg.sender]++;
        */
        return true;
    }

    function addPresaleAddr(string[10] memory _tokenInfo,address _presale, address _creator, uint256 _presaleNum) public onlyDeployer returns(bool) {

        presales[_creator][_presaleNum].presaleAddress = _presale;
        presaleToPresaleNum[_presale] = _presaleNum;
        presaleAddrToOwnerAddr[_presale] = _creator; // used for search bar via presale address
        presaleAddrToDeployerAddr[_presale] = msg.sender;
        //(bool _addLiveFilter, bytes memory addLiveFilterReturn) = FilterAddress.call(abi.encodeWithSignature("addLive(address,address,address)", _creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress));
        //require(_addLiveFilter, "adding to Live Filter failed");
        //FilterContract(FilterAddress).addLive(_creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress);

            info memory presaleInfo = info({
                //exists: true,
                data1: _tokenInfo[0],
                data2: _tokenInfo[1],
                logo: _tokenInfo[2],
                website: _tokenInfo[3],
                github: _tokenInfo[4],
                twitter: _tokenInfo[5],
                reddit: _tokenInfo[6],
                telegram: _tokenInfo[7],
                description: _tokenInfo[8],
                update: " "
            });

            infoManager[_creator][_presaleNum] = presaleInfo;

        return true;

    }

    function addPresaleAndNftSaleAddr(string[10] memory _tokenInfo,address _presale,address _nftSale, address _creator, uint256 _presaleNum) public onlyDeployer returns(bool){
        
        presales[_creator][_presaleNum].presaleAddress = _presale;
        presales[_creator][_presaleNum].nftPresaleAddress = _nftSale;
        presaleToPresaleNum[_presale] = _presaleNum;
        presaleAddrToOwnerAddr[_presale] = _creator; // used for search bar via presale address
        presaleAddrToDeployerAddr[_presale] = msg.sender;
        //(bool _addLiveFilter, bytes memory addLiveFilterReturn) = FilterAddress.call(abi.encodeWithSignature("addLive(address,address,address)", _creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress));
        //require(_addLiveFilter, "adding to Live Filter failed");
        //FilterContract(FilterAddress).addLive(_creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress);

            info memory presaleInfo = info({
                //exists: true,
                data1: _tokenInfo[0],
                data2: _tokenInfo[1],
                logo: _tokenInfo[2],
                website: _tokenInfo[3],
                github: _tokenInfo[4],
                twitter: _tokenInfo[5],
                reddit: _tokenInfo[6],
                telegram: _tokenInfo[7],
                description: _tokenInfo[8],
                update: " "
            });

            infoManager[_creator][_presaleNum] = presaleInfo;

        return true;



    }

    function addNFTPresaleAddr(address _NFTpresale, address _creator, uint256 _presaleNum) public onlyDeployer {

        presales[_creator][_presaleNum].nftPresaleAddress = _NFTpresale;

    }
    function addRouterAddr(address _router, address _creator, uint256 _presaleNum) public onlyDeployer returns(bool) {

        presales[_creator][_presaleNum].uniswapDep = _router;

        return true;

    }

    function fetchPresaleNumByOwner(address _creator) public view returns(uint256){

        return ownerPresaleNumber[_creator];

    }

     function fetchTokenAddrLiqLockTime(address _creator, uint256 _presaleNum) public view returns(address,uint256){

        return (presales[_creator][_presaleNum].tokenAddress,presales[_creator][_presaleNum].lp_locked);

    }   

    function fetchPresaleStruct(address _creator, uint256 _presaleNum) public view onlyDeployer returns(address,address,address) {

        return(presales[_creator][_presaleNum].tokenAddress,presales[_creator][_presaleNum].presaleAddress,presales[_creator][_presaleNum].uniswapDep);

    }
    function fetchNFTPresaleStruct(address _creator, uint256 _presaleNum) public view onlyDeployer returns(address,address,address,address) {

        return(presales[_creator][_presaleNum].tokenAddress,presales[_creator][_presaleNum].presaleAddress,presales[_creator][_presaleNum].uniswapDep,presales[_creator][_presaleNum].nftPresaleAddress);

    }
    function fetchPresaleTypeStatus(address _creator, uint256 _presaleNum) public view onlyDeployer returns(bool,bool,bool) {

        return(presales[_creator][_presaleNum].presale,presales[_creator][_presaleNum].nft,presales[_creator][_presaleNum].active);

    }
    function fetchNftPresaleStatAddr(address _creator, uint256 _presaleNum) public view onlyDeployer returns(bool,bool,address) {

        return(presales[_creator][_presaleNum].active,presales[_creator][_presaleNum].nft,presales[_creator][_presaleNum].nftPresaleAddress);

    }

    function fetchVoterCallData(address _creator, uint256 _presaleNum) public view onlyDeployer returns(address,address) {

        return(presales[_creator][_presaleNum].presaleAddress,presales[_creator][_presaleNum].uniswapDep);

    }
    function fetchPresaleAddress(address _creator, uint256 _presaleNum) public view onlyDeployer returns(address){

        return(presales[_creator][_presaleNum].presaleAddress);

    }

    function fetchNFTSaleAddress(address _creator, uint256 _presaleNum) public view onlyDeployer returns(address){

        return(presales[_creator][_presaleNum].nftPresaleAddress);

    }
    function setPresaleActiveFalse(address _creator, uint256 _presaleNum) public onlyDeployer returns(bool) {

        require(presales[_creator][_presaleNum].active,"not active");
        presales[_creator][_presaleNum].active = false;
         return true;

    }
    function setPresaleFilter(address _creator, uint256 _presaleNum) public onlyDeployer returns(bool) {

        require(presales[_creator][_presaleNum].active,"not active");
 
        address _presaleAddr = presales[_creator][_presaleNum].presaleAddress;
 
        uint256 totalEthRaised = PresaleContractInterface(_presaleAddr).CheckTotalEthRaised();

        uint256 SoftCap = PresaleContractInterface(_presaleAddr).CheckSoftCap();

         if (!(totalEthRaised < SoftCap) && !(totalEthRaised == 0)) {
            
            successSaleIDPerPad[msg.sender][presaleSuccessPerPadNumber[msg.sender]] = presaleOwnerToIndex[_creator][_presaleNum];
            successSaleID[presaleSuccessNumber] = presaleOwnerToIndex[_creator][_presaleNum];
            presaleSuccessPerPadNumber[msg.sender]++;
            presaleSuccessNumber++;

         }
         else if ((totalEthRaised < SoftCap) || (totalEthRaised == 0)) {
             
            failSaleIDPerPad[msg.sender][presaleFailPerPadNumber[msg.sender]] = presaleOwnerToIndex[_creator][_presaleNum];
            failSaleID[presaleFailNumber] = presaleOwnerToIndex[_creator][_presaleNum];
            presaleFailPerPadNumber[msg.sender]++;
            presaleFailNumber++;

         }
         liveSaleIndex--;
         return true;

    }
/*
    function addSuccessFilter(address _creator, uint256 _presaleNum) public onlyDeployer{

        //(bool _addSuccessFilter, bytes memory addSuccessFilterReturn) = FilterAddress.call(abi.encodeWithSignature("addSuccess(address,address,address)", _creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress));
        //require(_addSuccessFilter, "adding to Success Filter failed");
            successSaleIDPerPad[msg.sender][presaleSuccessPerPadNumber[msg.sender]] = presaleOwnerToIndex[_creator][_presaleNum];
            successSaleID[presaleSuccessNumber] = presaleOwnerToIndex[_creator][_presaleNum];
            presaleSuccessPerPadNumber[msg.sender]++;
            presaleSuccessNumber++;
        //FilterContract(FilterAddress).addSuccess(_creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress);

    }
    
    function addSuccessFilterInternal(address _creator, uint256 _presaleNum) internal{

        FilterContract(FilterAddress).addSuccess(_creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress);

    }
    */
    function addFailFilter(address _creator, uint256 _presaleNum) public onlyDeployer{  // this function is needed when presale is cancelled via voting contract

        //(bool _addFailFilter, bytes memory addFailFilterReturn) = FilterAddress.call(abi.encodeWithSignature("addFailure(address,address,address)", _creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress));
        //require(_addFailFilter, "adding to Fail Filter failed");
            failSaleIDPerPad[msg.sender][presaleFailPerPadNumber[msg.sender]] = presaleOwnerToIndex[_creator][_presaleNum];
            failSaleID[presaleFailNumber] = presaleOwnerToIndex[_creator][_presaleNum];
            presaleFailPerPadNumber[msg.sender]++;
            presaleFailNumber++;
            liveSaleIndex--;
        //FilterContract(FilterAddress).addFailure(_creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress);

    }
    /*
    function addFailFilterInternal(address _creator, uint256 _presaleNum) internal{

        FilterContract(FilterAddress).addFailure(_creator, presales[_creator][_presaleNum].presaleAddress, presales[_creator][_presaleNum].tokenAddress);


    }
    */
     function CheckBlockTimestamp() public view returns (uint256){
         
         
         return block.timestamp;
         
         
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
    function ChangeAuditKycAddr(address _newAuditKycContract) public onlyOwner {

        // require(_newFilterAddress != FilterAddress, "New addr is same as Old Addr");
        require(_newAuditKycContract != address(0), "New Addr cant be zero addr");
        auditKycContract = _newAuditKycContract;

    }


    function ChangeAirdropFee(uint _newAirdropFee) public onlyOwner {
        require(_newAirdropFee >= 0 && _newAirdropFee <= 100, "out of range fee value");
        require(_newAirdropFee != airdrop_fees_Percentage, "New fee is same as Old fee");
        airdrop_fees_Percentage = _newAirdropFee;

    }


    function changePresaleFees(uint256 _newFee) public onlyOwner {

        require((_newFee >= 0), "_newFee value must be >= 0");

        presaleFees = _newFee;

    }

    function changeWhitelistFees(uint256 _newFee) public onlyOwner {

        require((_newFee >= 0), "_newFee value must be >= 0");

        whitelistFees = _newFee;

    }




    function checkTotalEthraisedOfPresale(address presaleToRefundFromOwnerAddress, uint256 _presaleNum) public returns(uint256) {

        (bool checkEthRaised, bytes memory _totalEthRaised) = presales[presaleToRefundFromOwnerAddress][_presaleNum].presaleAddress.call(abi.encodeWithSignature("CheckTotalEthRaised()"));
        require(checkEthRaised, "failed to check eth raised");
        uint256 totalEthRaised = abi.decode(_totalEthRaised, (uint256));
        return totalEthRaised;

    }


    function getPresaleDeployerViaOwner(address _creator, uint256 _presaleNum) public view returns(address) {

        return presaleAddrToDeployerAddr[presales[_creator][_presaleNum].presaleAddress];


    }
    function getPresaleDeployer(address _presaleAddr) public view returns(address) {

        return presaleAddrToDeployerAddr[_presaleAddr];


    }







    function getNumberOfPresaleOwners() public view returns(uint256) {


        return OwnerIndex;

    }






/*
    function addRouter(address _newRouter) onlyOwner public {

        require(!RouterValid[_newRouter], "already added!");
        RouterValid[_newRouter] = true;
        routerNumber[_newRouter] = totalRouters;
        routerRecord[totalRouters] = _newRouter;
        totalRouters++;


    }

    function removeRouter(address _newRouter) onlyOwner public {

        require(RouterValid[_newRouter], "not in added list");
        RouterValid[_newRouter] = false;

    }
    */
/*
    function changeExtraTokenPer(uint256 _newPer) onlyOwner public {
        require(_newPer > 0, "Invalid percentage value");
        extraAmountPer = _newPer;

    }
*/
    function changeFeeContract(address _newContract) onlyOwner public {
        require(_newContract != address(0x0),"addr cannot be zero");
        feeContract = _newContract;
        
        
    }
    
    function addDeployer(address _deployer) onlyOwner public {

        Deployer[_deployer] = true;

    }

    function removeDeployer(address _deployer) onlyOwner public {

        Deployer[_deployer] = false;

    }
/*
    function getPresaleInfoNumbers(address _presaleOwner, uint256 _presaleNum) public view returns(uint256[3] memory){
        return [presales[_presaleOwner][_presaleNum].startTime, presales[_presaleOwner][_presaleNum].endTime, presales[_presaleOwner][_presaleNum].lp_locked];
    }
    */
    function getPresaleInfoAddresses(address _presaleOwner, uint256 _presaleNum) public view returns(address[3] memory){
        return [presales[_presaleOwner][_presaleNum].tokenAddress, presales[_presaleOwner][_presaleNum].presaleAddress, presales[_presaleOwner][_presaleNum].uniswapDep];
    }


    
    function ChangeInfoDG(string[10] memory ChangeData, uint256 _presaleNum) public {
        /*
        infoManager[msg.sender].logo = ChangeData[0];
        infoManager[msg.sender].website = ChangeData[1];
        infoManager[msg.sender].github = ChangeData[2];
        infoManager[msg.sender].twitter = ChangeData[3];
        infoManager[msg.sender].reddit = ChangeData[4];
        infoManager[msg.sender].telegram = ChangeData[5];
        infoManager[msg.sender].update = ChangeData[6];
        infoManager[msg.sender].description = ChangeData[7];
        */
            require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
            info memory presaleInfo = info({
                //exists: true,
                data1: ChangeData[0],
                data2: ChangeData[1],
                logo: ChangeData[2],
                website: ChangeData[3],
                github: ChangeData[4],
                twitter: ChangeData[5],
                reddit: ChangeData[6],
                telegram: ChangeData[7],
                description: ChangeData[8],
                update: infoManager[msg.sender][_presaleNum].update
            });

            infoManager[msg.sender][_presaleNum] = presaleInfo;


    }

    function changeLogo(string memory newLogo, uint256 _presaleNum) public {

        require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[msg.sender][_presaleNum].logo = newLogo;

    }
    function changeLogoPlatform(string memory newLogo, address _presaleOwner, uint256 _presaleNum) public onlyOwner{

        require(presales[_presaleOwner][_presaleNum].active,"presale doesnt exist");
        infoManager[_presaleOwner][_presaleNum].logo = newLogo;

    }
    function changeWebsite(string memory newWebsite, uint256 _presaleNum) public {

        require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[msg.sender][_presaleNum].website = newWebsite;

    }
    function changeWebsitePlatform(string memory newWebsite, address _presaleOwner, uint256 _presaleNum) public onlyOwner{

        //require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[_presaleOwner][_presaleNum].website = newWebsite;

    }

    function changeData1Platform(string memory newData1, address _presaleOwner, uint256 _presaleNum) public onlyOwner{

        //require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[_presaleOwner][_presaleNum].data1 = newData1;

    }

    function changeData2Platform(string memory newData2, address _presaleOwner, uint256 _presaleNum) public onlyOwner{

        //require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[_presaleOwner][_presaleNum].data2 = newData2;

    }

    function changeUpdatePlatform(string memory newUpdate, address _presaleOwner, uint256 _presaleNum) public onlyOwner{

        //require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[_presaleOwner][_presaleNum].update = newUpdate;

    }
    function changeGit(string memory newGit, uint256 _presaleNum) public {
        
        require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[msg.sender][_presaleNum].github = newGit;

    }

    function changeTwitter(string memory newTwitter, uint256 _presaleNum) public {

        require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[msg.sender][_presaleNum].twitter = newTwitter;

    }

    function changeReddit(string memory newReddit, uint256 _presaleNum) public  {

        require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[msg.sender][_presaleNum].reddit = newReddit;

    }

    function changeTelegram(string memory newTelegram, uint256 _presaleNum) public {

        require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[msg.sender][_presaleNum].telegram = newTelegram;

    }
    function changeTelegramPlatform(string memory newTelegram, address _presaleOwner, uint256 _presaleNum) public onlyOwner {

        //require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[_presaleOwner][_presaleNum].telegram = newTelegram;

    }
    function changeDescription(string memory newDescription, uint256 _presaleNum) public {

        require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[msg.sender][_presaleNum].description = newDescription;

    }

    function changeUpdate(string memory newUpdate, uint256 _presaleNum) public {

        require(presales[msg.sender][_presaleNum].active,"presale doesnt exist");
        infoManager[msg.sender][_presaleNum].update = newUpdate;

    }

    function getLiveSaleId(uint256 _iterRangeStart, uint256 _iterRangeEnd) public view returns (uint256[] memory){
        
        uint256 i = _iterRangeStart;
        uint256 j = 0;
        require(_iterRangeEnd >= _iterRangeStart,"invaid iteration range GLSI");
        uint256 iterationNum;
       // if((_iterRangeEnd - _iterRangeStart) >= OwnerIndex){

            iterationNum = OwnerIndex;

       // }
       // else{

         //   iterationNum = _iterRangeEnd - _iterRangeStart + 1;
        //}
        uint256[] memory liveSaleIDs = new uint256[](_iterRangeEnd - _iterRangeStart + 1);   
       // for(uint256 i = _iterRangeStart; i < iterationNum; i++){
            while(i < _iterRangeEnd && j < iterationNum){
                if(presales[allPresales[i].creator][allPresales[i].presaleNum].active){
                    liveSaleIDs[i - _iterRangeStart] = allPresales[OwnerIndex - i - 1].presaleIndex;
                    i++;
                }
                j++;
            }
        //} 

        return liveSaleIDs;
    }

    function getSuccessSaleId(uint256 _iterRangeStart, uint256 _iterRangeEnd) public view returns (uint256[] memory){

        require(_iterRangeEnd >= _iterRangeStart,"invaid iteration range GSSI");
        uint256 iterationNum;
        if((_iterRangeEnd - _iterRangeStart) >= presaleSuccessNumber){

            iterationNum = presaleSuccessNumber;

        }
        else{

            iterationNum = _iterRangeEnd + 1;
        }
        uint256[] memory successSaleIDs = new uint256[](_iterRangeEnd - _iterRangeStart + 1);   
        for(uint256 i = _iterRangeStart; i < iterationNum; i++){
            successSaleIDs[i - _iterRangeStart] = successSaleID[presaleSuccessNumber - 1 - i];
        } 

        return successSaleIDs;
    }

    function getFailSaleId(uint256 _iterRangeStart, uint256 _iterRangeEnd) public view returns (uint256[] memory){
        
        require(_iterRangeEnd >= _iterRangeStart,"invaid iteration range GFSI");
        uint256 iterationNum;
        if((_iterRangeEnd - _iterRangeStart) >= presaleFailNumber){

            iterationNum = presaleFailNumber;

        }
        else{

            iterationNum = _iterRangeEnd + 1;
        }
        //uint256 TotalPresales = presalePerPadNumber[_maindappAddress];
        uint256[] memory failSaleIDs = new uint256[](_iterRangeEnd - _iterRangeStart + 1);   
        for(uint256 i = _iterRangeStart; i < iterationNum; i++){
            failSaleIDs[i - _iterRangeStart] = failSaleID[presaleFailNumber - 1 - i];
        } 

        return failSaleIDs;
    }

    function getSaleIdPerPad(address _maindappAddress, uint256 _iterRangeStart, uint256 _iterRangeEnd) public view returns (uint256[] memory){
        
        require(_iterRangeEnd >= _iterRangeStart,"invaid iteration range GSIPP");
        uint256 iterationNum;
        if((_iterRangeEnd - _iterRangeStart) > presalePerPadNumber[_maindappAddress]){

            iterationNum = presalePerPadNumber[_maindappAddress];

        }
        else{

            iterationNum = _iterRangeEnd;
        }
        //uint256 padTotalPresales = presalePerPadNumber[_maindappAddress];
        uint256[] memory perPadSaleIDs = new uint256[](_iterRangeEnd - _iterRangeStart + 1);   
        for(uint256 i = _iterRangeStart; i < iterationNum; i++){
            perPadSaleIDs[i - _iterRangeStart] = saleIDPerPad[_maindappAddress][presalePerPadNumber[_maindappAddress] -1 - i];
        } 

        return perPadSaleIDs;
    }

    function getLiveSaleIdPerPad(address _maindappAddress,uint256 _iterRangeStart, uint256 _iterRangeEnd) public view returns (uint256[] memory){
        
        uint256 i = _iterRangeStart;
        uint256 j = 0;
        require(_iterRangeEnd >= _iterRangeStart,"invaid iteration range GLSIPP");
        uint256 iterationNum;
       // if((_iterRangeEnd - _iterRangeStart) >= presalePerPadNumber[_maindappAddress]){

            iterationNum = presalePerPadNumber[_maindappAddress];

       // }
       // else{

          //  iterationNum = _iterRangeEnd - _iterRangeStart + 1;
        //}
        uint256[] memory liveSaleIDsPerPad = new uint256[](_iterRangeEnd - _iterRangeStart + 1);   
       // for(uint256 i = _iterRangeStart; i < iterationNum; i++){
            while(i < _iterRangeEnd && j < iterationNum){
                if(presales[presalePerPad[_maindappAddress][i].creator][presalePerPad[_maindappAddress][i].presaleNum].active){
                    liveSaleIDsPerPad[i - _iterRangeStart] = presalePerPad[_maindappAddress][presalePerPadNumber[_maindappAddress] -1 - i].presaleIndex;
                    i++;
                }
                j++;
            }
        //} 

        return liveSaleIDsPerPad;
    }
    function getSuccessSaleIdPerPad(address _maindappAddress, uint256 _iterRangeStart, uint256 _iterRangeEnd) public view returns (uint256[] memory){
        
        require(_iterRangeEnd >= _iterRangeStart,"invaid iteration range GSSIPP");
        uint256 iterationNum;
        if((_iterRangeEnd - _iterRangeStart) > presaleSuccessPerPadNumber[_maindappAddress]){

            iterationNum = presaleSuccessPerPadNumber[_maindappAddress];

        }
        else{

            iterationNum = _iterRangeEnd;
        }
        uint256[] memory perPadSuccessSaleIDs = new uint256[](_iterRangeEnd - _iterRangeStart + 1);   
        for(uint256 i = _iterRangeStart; i < iterationNum; i++){
            perPadSuccessSaleIDs[i - _iterRangeStart] = successSaleIDPerPad[_maindappAddress][presaleSuccessPerPadNumber[_maindappAddress] -1 - i];
        } 

        return perPadSuccessSaleIDs;
    }
     function getFailSaleIdPerPad(address _maindappAddress, uint256 _iterRangeStart, uint256 _iterRangeEnd) public view returns (uint256[] memory){
        
        require(_iterRangeEnd >= _iterRangeStart,"invaid iteration range GFSIPP");
        uint256 iterationNum;
        if((_iterRangeEnd - _iterRangeStart) > presaleFailPerPadNumber[_maindappAddress]){

            iterationNum = presaleFailPerPadNumber[_maindappAddress];

        }
        else{

            iterationNum = _iterRangeEnd;
        }
        uint256[] memory perPadFailSaleIDs = new uint256[](_iterRangeEnd - _iterRangeStart + 1);   
        for(uint256 i = _iterRangeStart; i < iterationNum; i++){
            perPadFailSaleIDs[i - _iterRangeStart] = failSaleIDPerPad[_maindappAddress][presaleFailPerPadNumber[_maindappAddress] -1 - i];
        } 

        return perPadFailSaleIDs;
    }   



    function getPresaleStorageData(uint256 _index) public view returns(address[4] memory,uint256[3] memory, bool[2] memory, string[12] memory, uint256[10] memory, bool[4] memory, string memory) {


        address preOwner = allPresales[_index].creator;
        uint256 presaleNumber = allPresales[_index].presaleNum;

        
        //bool[4] memory presaleType;
        address[4] memory Addresses;
        uint256[3] memory structUintData;
        string[12] memory socialInfo;
        (uint256[10] memory presaleDataUint, bool[4] memory presaleDataBool, string memory presaleTypeString) = PresaleContractInterface(presales[preOwner][presaleNumber].presaleAddress).getPresaleData();
        bool[2] memory auditKycBools = auditKycContractInterface(auditKycContract).getAuditKycBool(presales[preOwner][presaleNumber].tokenAddress,presales[preOwner][presaleNumber]._owner);
        Addresses = [presales[preOwner][presaleNumber]._owner,presales[preOwner][presaleNumber].tokenAddress,presales[preOwner][presaleNumber].presaleAddress,presales[preOwner][presaleNumber].nftPresaleAddress];
        structUintData = [presales[preOwner][presaleNumber].lp_locked,presales[preOwner][presaleNumber]._preNum,presales[preOwner][presaleNumber].createdOn];
        //presaleType = [presales[preOwner][presaleNumber].active,presales[preOwner][presaleNumber].presale,presales[preOwner][presaleNumber].nft,presales[preOwner][presaleNumber].fair];
        socialInfo = [ERC20(presales[preOwner][presaleNumber].tokenAddress).name(),ERC20(presales[preOwner][presaleNumber].tokenAddress).symbol(),infoManager[preOwner][presaleNumber].data1,infoManager[preOwner][presaleNumber].data2,infoManager[preOwner][presaleNumber].logo,infoManager[preOwner][presaleNumber].website,infoManager[preOwner][presaleNumber].github,infoManager[preOwner][presaleNumber].twitter,infoManager[preOwner][presaleNumber].reddit,infoManager[preOwner][presaleNumber].telegram,infoManager[preOwner][presaleNumber].description,infoManager[preOwner][presaleNumber].update];
        return (Addresses,structUintData,auditKycBools,socialInfo,presaleDataUint,presaleDataBool,presaleTypeString);
    

    }
}