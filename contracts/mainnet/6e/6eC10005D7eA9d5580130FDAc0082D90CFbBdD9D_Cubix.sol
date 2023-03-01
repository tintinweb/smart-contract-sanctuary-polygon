/**
 *Submitted for verification at polygonscan.com on 2023-03-01
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
        uint256 nfts;
        uint256 sportId;  
    }
    pkgDetail[] public PKGDetail;
  

    IERC20 public cubixToken ;
    IERC20 public usdt;    
    IERC721 public nft;    

    uint256 public totalNFTs = 0; // done
    uint256 public tokenPrice = 1e8; //price in USD 1
    uint256 constant denominator = 1e8;
    address public defaultreferrer;
    uint256 public lastUserId = 1373849;
   // uint public withdrawFeePerc = 5;
    bool public importedOldData = true;
    //user info
    struct userInfo
    {        
        uint256 uID;
        address referrer;
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
    address public feeAddress;
    address public companyAddress;
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
    //event withdrawEV(address indexed _user, uint256 _amount, uint256 tokenRate, bool _isUSDT);
    event JoinEV(address indexed _user, uint256 userId, address indexed _referrer, uint256 _amount, uint256 pkgAmt, uint256 tokenRate, uint _position, uint _createTime);
    event DepositEV(address indexed _user, uint256 _amount, uint256 pkgAmt, uint256 tokenRate, uint _depTime);
    event NFTMintEvent(address indexed userAddress,uint256 indexed nftId, uint256 packId,uint256 Time);
    
    constructor(address _feeAddress, address _companyAddress, address _cubixaddress, address _usdt, address _nftadd){
        feeAddress = _feeAddress;  
        companyAddress = _companyAddress;      
        cubixToken = IERC20(_cubixaddress);
        usdt = IERC20(_usdt);
        nft = IERC721(_nftadd);
        defaultreferrer = owner();         
        PKGDetail.push(pkgDetail("Starter",30,1,1)); 
        PKGDetail.push(pkgDetail("Bronze",100,6,1));   
        PKGDetail.push(pkgDetail("Silver",250,11,1));       
        PKGDetail.push(pkgDetail("Gold",500,25,1));
        PKGDetail.push(pkgDetail("Platinum",1000,57,1));
        PKGDetail.push(pkgDetail("Diamond",2500,153,1)); 
    }
                
    function getpkgbyIndex(uint _index) public view returns (string memory text, uint256 _amount) {
        pkgDetail storage PKGDetails = PKGDetail[_index];
        return (PKGDetails.pkgName, PKGDetails.pkgAmount);
    }
    
    function register(address referrerAddress, uint256 usdAmount, uint pkgIndex, uint _position, bool isUSDT) external returns(bool)
    {
        require(!safeguard);
        require(!frozenAccount[msg.sender], "caller has been frozen");
        require(!isContract(msg.sender),  'No contract address allowed');    
        require(importedOldData,"Old  data has not been synced");
        require(UserInfo[msg.sender].referrer == address(0),"Already registered");   
        pkgDetail storage PKGDetails = PKGDetail[pkgIndex];
        require(PKGDetails.pkgAmount == usdAmount, "Amount is incorrect");
        uint256 tokenAmount ;
        UserInfo[msg.sender].joiningpkg = pkgIndex;
        usdAmount = usdAmount * 1e18;
        if(isUSDT)
        {
            uint256 allowance = usdt.allowance(
            msg.sender,
            address(this)
            );

            require(usdAmount <= usdt.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= PKGDetails.pkgAmount, 'Error: Allowance less than spending');
            usdt.transferFrom(msg.sender, companyAddress, usdAmount/2);
            usdt.transferFrom(msg.sender, feeAddress, usdAmount/2); //50% to fee address 
        }
        else{
            tokenAmount = usdAmount / (tokenPrice/denominator);
            uint256 allowance = cubixToken.allowance(
            msg.sender,
            address(this)
            );

            require(tokenAmount <= cubixToken.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= PKGDetails.pkgAmount, 'Error: Allowance less than spending');
            cubixToken.transferFrom(msg.sender, companyAddress, tokenAmount/2);
            cubixToken.transferFrom(msg.sender, feeAddress, tokenAmount/2); //50% to fee address       
        }
        
        if(referrerAddress == address(0) || referrerAddress == msg.sender)
        {
            referrerAddress = defaultreferrer ;
        }
        UserInfo[msg.sender].referrer = referrerAddress;
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
        emit JoinEV(msg.sender, UserInfo[msg.sender].uID, referrerAddress, tokenAmount, usdAmount, tokenPrice, _position, block.timestamp);                                 
             
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
        usdAmount = usdAmount * 1e18;
        require(usdAmount >= UserInfo[msg.sender].depositAmt / (tokenPrice/denominator) , "Must purchase higher package than previous");               
        uint256 tokenAmount ;       
        if(isUSDT)
        {          
            
            uint256 allowance = usdt.allowance(
            msg.sender,
            address(this)
            );

            require(usdAmount  <= usdt.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= PKGDetails.pkgAmount, 'Error: Allowance less than spending');
            usdt.transferFrom(msg.sender, companyAddress, usdAmount/2);
            usdt.transferFrom(msg.sender, feeAddress, usdAmount /2); //50% to fee address 
        }
        else{
            tokenAmount = usdAmount  / (tokenPrice/denominator); 
            uint256 allowance = cubixToken.allowance(
            msg.sender,
            address(this)
            );

            require(tokenAmount <=  cubixToken.balanceOf(msg.sender), 'Error: Insufficient Balance');
            require(allowance >= PKGDetails.pkgAmount, 'Error: Allowance less than spending');
            cubixToken.transferFrom(msg.sender, companyAddress, tokenAmount/2);
            cubixToken.transferFrom(msg.sender, feeAddress, tokenAmount/2); //50% to fee address       
        }
        
        UserInfo[msg.sender].joiningpkg = pkgIndex;
        UserInfo[msg.sender].depositAmt = tokenAmount;
        UserInfo[msg.sender].depositUSDAmt = usdAmount ; 
        if(address(nft) != address(0)){
            sendNFTs(msg.sender, pkgIndex);
        }  
        emit DepositEV(msg.sender, tokenAmount, usdAmount, tokenPrice, block.timestamp);        
        return true;
    }
   /* function withdrawIncome(bool isUSDT) external 
    {
        require(!safeguard);
        require(!frozenAccount[msg.sender], "caller has been frozen");
        require(!isContract(msg.sender),  'No contract address allowed');
        address user = msg.sender;
        uint256 amount =(UserInfo[user].depositAmt/ (tokenPrice/denominator)) + (UserRewardInfo[user].userIncomeRemaining - UserRewardInfo[user].userIncomePaid);
        require(amount > 0, "No amount to withdraw");        
        UserRewardInfo[user].userIncomePaid += amount; 
        UserInfo[user].depositAmt = 0;
        UserInfo[user].depositUSDAmt = 0;
        uint256 withdrawFee = amount * withdrawFeePerc / 100;
        if(isUSDT)
        {            
            require(amount <= usdt.balanceOf(address(this)), 'Error: Insufficient Balance');          
            usdt.transfer(user, amount - withdrawFee );
            usdt.transfer(feeAddress, withdrawFee); //50% to fee address 
            emit withdrawEV(user, amount, tokenPrice, isUSDT);  
        }
        else{
            uint256 tokenToWithdraw = amount / (tokenPrice/denominator);
            withdrawFee = withdrawFee / (tokenPrice/denominator);
            require(tokenToWithdraw <= cubixToken.balanceOf(address(this)), 'Error: Insufficient Balance');          
            cubixToken.transfer(user, tokenToWithdraw - withdrawFee );
            cubixToken.transfer(feeAddress, withdrawFee); //50% to fee address      
            emit withdrawEV(user, tokenToWithdraw, tokenPrice, isUSDT);              
        }            
              
    }*/

    //owner functions
    function setTokenContract(address tokenadd, address usdtadd, address nsftadd) external onlyOwner
    {
        require(tokenadd != address(0) && usdtadd != address(0),'Invalid Address');
        cubixToken = IERC20(tokenadd);
        usdt = IERC20(usdtadd);
        nft = IERC721(nsftadd);
    }
    function setCubixTokenPrice(uint256 usdPrice) external onlyOwner
    {
        tokenPrice = usdPrice; //1 Cubix rate in USD 
    }
   /* function updateUserIncome(address[] memory _users, uint256[] memory _sponsorBonus, uint256[] memory _teamComm,uint256[] memory _matchingBonus,
        uint256[] memory _rankBonus, uint256[] memory _infinityPoolBonus, uint256[] memory _userIncomeRemaining) external onlyOwner
    {
        require(_users.length <= 20, "Not more than 20 at a time");
        require(_users.length == _sponsorBonus.length && _users.length == _teamComm.length && _users.length == _matchingBonus.length && _users.length == _rankBonus.length && _users.length == _infinityPoolBonus.length && _users.length == _userIncomeRemaining.length,"Invalid value");
        for(uint i=0; i< _users.length; i++)
        {
            UserRewardInfo[_users[i]].sponsorBonus = _sponsorBonus[i];
            UserRewardInfo[_users[i]].teamComm = _teamComm[i];
            UserRewardInfo[_users[i]].matchingBonus = _matchingBonus[i];
            UserRewardInfo[_users[i]].rankBonus = _rankBonus[i];
            UserRewardInfo[_users[i]].infinityPoolBonus = _infinityPoolBonus[i];
            UserRewardInfo[_users[i]].userIncomeRemaining = _userIncomeRemaining[i];
        }
    }*/
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
        PKGDetails.nfts = _nfts;
        PKGDetails.sportId = _sportsId;
    }
    function addPkg(string calldata _text, uint256 _amount, uint256 _nfts, uint256 _sportsId) external onlyOwner {
        PKGDetail.push(pkgDetail(_text,_amount, _nfts, _sportsId));  
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
        PKGDetail.pop();
    }
    function updatefeeAddress(address _feeAddress, address _companyAddress) external onlyOwner
    {
        require(_feeAddress != address(0) && _companyAddress != address(0),"Invalid address");
        feeAddress = _feeAddress;
        companyAddress = _companyAddress;
    }
    function setimportedOldData() external onlyOwner
    {
        require(!importedOldData,"Import already set to true");
        importedOldData = true;
    }
   /* function setWithdrawFee(uint _perc) external onlyOwner
    {
        withdrawFeePerc = _perc;
    }*/
    
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