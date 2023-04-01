/**
 *Submitted for verification at polygonscan.com on 2023-04-01
*/

// SPDX-License-Identifier: None

pragma solidity 0.8.17;

contract Ownership {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(oldOwner,  newOwner);
    }
}
interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}
interface IERC20 {

    function decimals() external view returns (uint256);
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
contract Cubix is Ownership {
    //contract settings
    struct pkgDetail
    {       
        string pkgName;
        uint256 pkgAmount; 
        uint256 pkgprice;     
        uint256 nfts;
        uint256 sportId;  
    }
    pkgDetail[] public PKGDetail;  

    IERC20 public cubixToken ;
    IERC20 public usdt;    
    IERC721 public nft;    

    uint256 public totalNFTs = 0; // done
    uint256 public cubixperusd = 200; //price in USD 1
    uint256 public decimalsValue = 10**18;   
    uint256 public lastUserId = 1373849;   
    bool public importedOldData ;
    //user info
    struct userInfo
    {        
        uint256 uID;
        address referrer;
        address placement;
        uint position;
        uint256 depositAmt;
        uint256 depositUSDAmt;
        uint256 directusers;
        uint256 teamCount;
        uint joiningpkg;
        uint256 pairs;      
        uint createTime;  
    }
    mapping(address => userInfo) public UserInfo;
    address public feeAddress = 0x01d0b68efEd42cd6A2caC1e66D2bb195cF608DbB;
    address public companyAddress = 0x01d0b68efEd42cd6A2caC1e66D2bb195cF608DbB;
    address public mangerAddress = 0x28B111403EC06984f653345D76730452daf97A0f;
    //user reward info
    struct userRewardInfo
    {        
        uint256 sponsorBonus;
        uint256 teamComm;
        uint256 matchingBonus;
        uint256 rankBonus;  
        uint256 infinityPoolBonus;    
        uint256 userIncomeRemaining;    
        uint256 userIncomePaid;    
    }
    mapping(address => userRewardInfo) public UserRewardInfo;
    bool public safeguard;  //putting safeguard on will halt all non-owner functions
    mapping (address => bool) public frozenAccount;
    event FrozenAccounts(address target, bool frozen);    
    event JoinEV(address indexed _user, uint256 userId, address indexed _referrer, uint256 refId, address _placement, uint256 placementId, uint256 _amount, uint256 pkgAmt, uint256 tokenRate, uint _position, uint _createTime);
    event DepositEV(address indexed _user, uint256 _amount, uint256 pkgAmt, uint256 tokenRate, uint _depTime);
    event NFTMintEvent(address indexed userAddress,uint256 indexed nftId, uint256 packId,uint256 Time);
    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == mangerAddress, 'Only authorized');
        _;
    }
    constructor(address _cubixaddress){          
        cubixToken = IERC20(_cubixaddress);                           
        PKGDetail.push(pkgDetail("Starter",30,30 * cubixperusd * decimalsValue, 1,1)); 
        PKGDetail.push(pkgDetail("Bronze",100,100 * cubixperusd * decimalsValue,6,1));   
        PKGDetail.push(pkgDetail("Silver",250,250 * cubixperusd * decimalsValue,11,1));       
        PKGDetail.push(pkgDetail("Gold",500,500 * cubixperusd * decimalsValue,25,1));
        PKGDetail.push(pkgDetail("Platinum",1000,1000 * cubixperusd * decimalsValue,57,1));
        PKGDetail.push(pkgDetail("Diamond",2500,2500 * cubixperusd * decimalsValue, 153,1)); 
        PKGDetail.push(pkgDetail("MegaPack",5000,5000 * cubixperusd * decimalsValue,343,1)); 
        PKGDetail.push(pkgDetail("Limited Edition",7500,7500 * cubixperusd * decimalsValue,650,1)); 
    }
                
    function getpkgbyIndex(uint _index) public view returns (string memory text, uint256 _amount) {
        pkgDetail storage PKGDetails = PKGDetail[_index];
        return (PKGDetails.pkgName, PKGDetails.pkgAmount);
    }
    
    function register(address referrerAddress, address placement, uint256 usdAmount, uint pkgIndex, uint _position, bool isUSDT) external returns(bool)
    {
        require(!safeguard);
        require(!frozenAccount[msg.sender], "caller has been frozen");
        require(!isContract(msg.sender),  'No contract address allowed');    
        require(importedOldData,"Old  data has not been synced");
        require(UserInfo[msg.sender].referrer == address(0),"Already registered");   
        require(UserInfo[placement].referrer != address(0) || placement == owner(),"Incorrect placement");
        pkgDetail storage PKGDetails = PKGDetail[pkgIndex];
        require(PKGDetails.pkgAmount == usdAmount, "Amount is incorrect");
        uint256 tokenAmount =PKGDetails.pkgprice ;
        UserInfo[msg.sender].joiningpkg = pkgIndex;       
        if(isUSDT && address(usdt) != address(0))
        {
            uint256 allowance = usdt.allowance(
            msg.sender,
            address(this)
            );

            require(usdAmount * decimalsValue <= usdt.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= usdAmount * decimalsValue, 'Error: Allowance less than spending');
            usdt.transferFrom(msg.sender, companyAddress, usdAmount* decimalsValue/2);
            usdt.transferFrom(msg.sender, feeAddress, usdAmount* decimalsValue/2); //50% to fee address 
        }
        else{            
            uint256 allowance = cubixToken.allowance(
            msg.sender,
            address(this)
            );

            require(tokenAmount <= cubixToken.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= tokenAmount, 'Error: Allowance less than spending');
            cubixToken.transferFrom(msg.sender, companyAddress, tokenAmount/2);
            cubixToken.transferFrom(msg.sender, feeAddress, tokenAmount/2); //50% to fee address       
        }
        
        if(referrerAddress == address(0) || referrerAddress == msg.sender || UserInfo[referrerAddress].uID == 0)
        {
            referrerAddress = owner() ;
        }
        if(placement == address(0) || placement == msg.sender || UserInfo[placement].referrer == address(0))
        {
            placement = owner() ;
        }               
        UserInfo[msg.sender].referrer = referrerAddress;
        UserInfo[msg.sender].placement = placement;
        UserInfo[msg.sender].uID = lastUserId;
        UserInfo[referrerAddress].directusers += 1;
        UserInfo[referrerAddress].teamCount += 1;
        UserInfo[msg.sender].position = _position;
        UserInfo[msg.sender].createTime = block.timestamp;
        UserInfo[msg.sender].depositAmt = tokenAmount;
        UserInfo[msg.sender].depositUSDAmt = usdAmount ; 
        lastUserId += 1 ; 
        if(address(nft) != address(0)){
            sendNFTs(msg.sender, pkgIndex);
        }
        emit JoinEV(msg.sender, UserInfo[msg.sender].uID, referrerAddress, UserInfo[referrerAddress].uID, placement, UserInfo[placement].uID, tokenAmount, usdAmount, cubixperusd, _position, block.timestamp);                                 
             
        return true;
    }
    function sendNFTs(address accountAddress, uint256 packId) internal {
        pkgDetail memory PKGDetails = PKGDetail[packId];
        uint256 counter = 1;
        while (PKGDetails.nfts >= counter) {
            mintNFT(accountAddress, packId);
            counter += 1;
        }
    }
     function mintNFT(address accountAddress, uint256 packId) internal {
        totalNFTs += 1;
        uint256 nftId = totalNFTs;
        nft.mint(accountAddress, nftId);
        emit NFTMintEvent(accountAddress, nftId, packId, block.timestamp);
    }

    function deposit(uint256 usdAmount, uint pkgIndex, bool isUSDT) external returns(bool)
    {        
        require(!safeguard);
        require(!frozenAccount[msg.sender], "caller has been frozen");
        require(!isContract(msg.sender),  'No contract address allowed');    
        require(importedOldData,"Old  data has not been synced");    
        require(UserInfo[msg.sender].referrer != address(0),"You have to register first");
        pkgDetail storage PKGDetails = PKGDetail[pkgIndex];
        require(PKGDetails.pkgAmount == usdAmount, "Amount is incorrect");
        uint256 tokenAmount= PKGDetails.pkgprice; 
        require(tokenAmount >= UserInfo[msg.sender].depositAmt  , "Must purchase higher package than previous");               
              
        if(isUSDT && address(usdt) != address(0))
        {          
            
            uint256 allowance = usdt.allowance(
            msg.sender,
            address(this)
            );

            require(usdAmount * decimalsValue  <= usdt.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= usdAmount * decimalsValue, 'Error: Allowance less than spending');
            usdt.transferFrom(msg.sender, companyAddress, usdAmount * decimalsValue/2);
            usdt.transferFrom(msg.sender, feeAddress, usdAmount * decimalsValue /2); //50% to fee address 
        }
        else{            
            uint256 allowance = cubixToken.allowance(
            msg.sender,
            address(this)
            );

            require(tokenAmount <=  cubixToken.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= tokenAmount, 'Error: Allowance less than spending');
            cubixToken.transferFrom(msg.sender, companyAddress, tokenAmount/2);
            cubixToken.transferFrom(msg.sender, feeAddress, tokenAmount/2); //50% to fee address       
        }
        
        UserInfo[msg.sender].joiningpkg = pkgIndex;
        UserInfo[msg.sender].depositAmt = tokenAmount;
        UserInfo[msg.sender].depositUSDAmt = usdAmount ; 
        if(address(nft) != address(0)){
            sendNFTs(msg.sender, pkgIndex);
        }  
        emit DepositEV(msg.sender, tokenAmount, usdAmount, cubixperusd, block.timestamp);        
        return true;
    }
    
   

    //owner functions

    function registerOldUsers(address _user, address referrerAddress, address placement, uint256 usdAmount, uint pkgIndex, uint _position, bool isUSDT) external onlyOwner returns(bool)
    {      
          
        require(!importedOldData,"Old data has been synced");
        require(UserInfo[_user].referrer == address(0),"Already registered");   
        require(UserInfo[placement].referrer != address(0) || placement == owner(),"Incorrect placement");
        pkgDetail storage PKGDetails = PKGDetail[pkgIndex];
        require(PKGDetails.pkgAmount == usdAmount, "Amount is incorrect");
        uint256 tokenAmount =PKGDetails.pkgprice;   
        UserInfo[_user].joiningpkg = pkgIndex;
        
        if(isUSDT && address(usdt) != address(0))
        {
            uint256 allowance = usdt.allowance(
            msg.sender,
            address(this)
            );

            require(usdAmount * decimalsValue <= usdt.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= usdAmount * decimalsValue, 'Error: Allowance less than spending');
            usdt.transferFrom(msg.sender, companyAddress, usdAmount * decimalsValue/2);
            usdt.transferFrom(msg.sender, feeAddress, usdAmount * decimalsValue/2); //50% to fee address 
        }
        else{
            
            uint256 allowance = cubixToken.allowance(
            msg.sender,
            address(this)
            );

            require(tokenAmount <= cubixToken.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= tokenAmount, 'Error: Allowance less than spending');
            cubixToken.transferFrom(msg.sender, companyAddress, tokenAmount/2);
            cubixToken.transferFrom(msg.sender, feeAddress, tokenAmount/2); //50% to fee address       
        }
        
        if(referrerAddress == address(0) || referrerAddress == _user || UserInfo[referrerAddress].uID == 0)
        {
            referrerAddress = owner() ;
        }
        if(placement == address(0) || placement == _user || UserInfo[placement].referrer == address(0))
        {
            placement = owner() ;
        }
        UserInfo[_user].referrer = referrerAddress;
        UserInfo[_user].placement = placement;
        UserInfo[_user].uID = lastUserId;
        UserInfo[referrerAddress].directusers += 1;
        UserInfo[referrerAddress].teamCount += 1;
        UserInfo[_user].position = _position;
        UserInfo[_user].createTime = block.timestamp;
        UserInfo[_user].depositAmt = tokenAmount;
        UserInfo[_user].depositUSDAmt = usdAmount ;  
        lastUserId += 1 ;        
        if(address(nft) != address(0)){
            sendNFTs(_user, pkgIndex);
        }
        emit JoinEV(_user, UserInfo[_user].uID, referrerAddress, UserInfo[referrerAddress].uID, placement, UserInfo[placement].uID, tokenAmount, usdAmount, cubixperusd, _position, block.timestamp);                                 
             
        return true;
    }
    
    function depositOldUsers(address _user, uint256 usdAmount, uint pkgIndex, bool isUSDT) external onlyOwner returns(bool)
    {          
         
        require(!importedOldData,"Old data has been synced");    
        require(UserInfo[_user].referrer != address(0),"User has to register first");
        pkgDetail storage PKGDetails = PKGDetail[pkgIndex];
        require(PKGDetails.pkgAmount == usdAmount, "Amount is incorrect");                  
        uint256 tokenAmount = PKGDetails.pkgprice;       
        if(isUSDT && address(usdt) != address(0))
        {   
            uint256 allowance = usdt.allowance(
            msg.sender,
            address(this)
            );

            require(usdAmount*decimalsValue  <= usdt.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= usdAmount*decimalsValue, 'Error: Allowance less than spending');
            usdt.transferFrom(msg.sender, companyAddress, usdAmount*decimalsValue/2);
            usdt.transferFrom(msg.sender, feeAddress, usdAmount*decimalsValue/2); //50% to fee address 
        }
        else{          
            uint256 allowance = cubixToken.allowance(
            msg.sender,
            address(this)
            );

            require(tokenAmount <=  cubixToken.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= tokenAmount, 'Error: Allowance less than spending');
            cubixToken.transferFrom(msg.sender, companyAddress, tokenAmount/2);
            cubixToken.transferFrom(msg.sender, feeAddress, tokenAmount/2); //50% to fee address       
        }
        
        UserInfo[_user].joiningpkg = pkgIndex;
        UserInfo[_user].depositAmt = tokenAmount;
        UserInfo[_user].depositUSDAmt = usdAmount ; 
        if(address(nft) != address(0)){
            sendNFTs(_user, pkgIndex);
        }  
        emit DepositEV(_user, tokenAmount, usdAmount, cubixperusd, block.timestamp);        
        return true;
    }
    function changeManager(address _manager) external onlyOwner
    {
        require(_manager != address(0),'Not a valid address');
        mangerAddress = _manager;
    }
    function setTokenContract(address tokenadd, address usdtadd) external onlyOwner
    {
        require(tokenadd != address(0) ,'Invalid Address');
        cubixToken = IERC20(tokenadd);
        usdt = IERC20(usdtadd);        
    }
    function setNFT(address nsftadd) external onlyAuthorized
    {
        require(nsftadd != address(0),'Invalid Address');       
        nft = IERC721(nsftadd);
    }
    function updateCubixPrice(uint256 _cubixperusd) external onlyAuthorized
    {
        cubixperusd = _cubixperusd; 
        for (uint256 index = 0; index < PKGDetail.length; index++) {
            PKGDetail[index].pkgprice = PKGDetail[index].pkgAmount * _cubixperusd  * decimalsValue;
        }

    }     
    function alreadyMintedNFT(uint256 _mintedNFT) external onlyOwner {
        totalNFTs = _mintedNFT;
    }
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    function updatePkg(uint _index, string calldata _text, uint256 _amount, uint256 _nfts, uint256 _sportsId) external onlyOwner {
        pkgDetail storage PKGDetails = PKGDetail[_index];
        PKGDetails.pkgName = _text;
        PKGDetails.pkgAmount = _amount;
        PKGDetails.pkgprice = _amount * cubixperusd * decimalsValue;
        PKGDetails.nfts = _nfts;
        PKGDetails.sportId = _sportsId;
    }
    function addPkg(string calldata _text, uint256 _amount, uint256 _nfts, uint256 _sportsId) external onlyOwner {
        PKGDetail.push(pkgDetail(_text,_amount,_amount * cubixperusd * decimalsValue,  _nfts, _sportsId));  
    }
    function removePkg(uint _index) external onlyOwner {         
        bool isDone= false;
        if(_index != PKGDetail.length - 1){
            for (uint256 i = 0; i < PKGDetail.length - 1; i++) {
                if(i == _index)
                {
                    isDone=true;
                }
                if(isDone)
                {
                    PKGDetail[i] = PKGDetail[i+1];
                }
            }
        }
        if(isDone){
            PKGDetail.pop();
        }
    }
    function updatefeeAddress(address _feeAddress, address _companyAddress) external onlyOwner
    {
        require(_feeAddress != address(0) && _companyAddress != address(0),"Invalid address");
        feeAddress = _feeAddress;
        companyAddress = _companyAddress;
    }
    function setimportedOldData(bool status) external onlyOwner
    {
        //require(!importedOldData,"Import already set to true");
        importedOldData = status;//true;
    }   
    
    function freezeAccount(address target, bool freeze) external onlyOwner {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    function changeSafeguardStatus() external onlyOwner {
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }
    function emergencyWithdrawCoin(uint256 _amount) external onlyOwner returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        require(address(this).balance >= _amount,'Insufficient Balance');
        payable(owner()).transfer(_amount);
        return true;
    }
    function emergencyWithdrawToken(address _tokenaddress, uint256 _amount) external onlyOwner returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        require(IERC20(_tokenaddress).balanceOf(address(this)) >= _amount,'Insufficient Balance');
        IERC20(_tokenaddress).transfer(owner(),_amount);
        return true;
    }
}