// https://t.me/dicebounty
// https://dicebounty.com/

import { SafeMath } from 'SafeMath.sol';
import 'Ownable.sol';
import { ReentrancyGuard } from 'ReentrancyGuard.sol';
import { IERC20 } from 'ERC20.sol';


contract DBPublicPresale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    // Maps user to the number of tokens owned
    mapping (address => uint256) public tokensOwned;
    mapping (address => uint256) public lastTokensClaimed;
    mapping (address => uint256) public numClaims;
    mapping (address => uint256) public tokensToclaimed;
    mapping (address => uint256) public buyTime;
    mapping (address => uint256) public PayedMatic;
    
    
    IERC20 DiceBounty;
    
    bool isClaimActive;
    bool isSaleActive;
    
    uint256 startingTimeStamp;
    uint256 totalTokensSold = 0;
    uint256 MaticLotteryed = 0;
    uint256 price;
    uint256 MaticReceived = 0;
    uint256 PublicPresaleStartTime = 1626609600;

    address[] PublicPresaleeBuyer;
        
    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor () public {
        isSaleActive = false;
        isClaimActive = false;
        price = 200;
    }

    receive() external payable {
        buy (msg.sender);
    }

    function buy (address beneficiary) public payable nonReentrant {
        address _buyer = beneficiary;
        uint256 _Matic = msg.value;
        uint256 tokens  = _Matic  * price;
        require(block.timestamp >= PublicPresaleStartTime || isSaleActive, "NotStart");
        require (_Matic >= 50 ether, "Matic is lesser than min value");
        require (_Matic <= 999 ether, "Matic is greater than max value");
        require (MaticReceived+_Matic <= 100000 ether, "Private Presale sold out");
        require(tokensOwned[_buyer] + tokens <= price * 5000 ether, "Private presale at most buy 5000 Matic");
        PayedMatic[_buyer] = PayedMatic[_buyer].add(_Matic);
        tokensOwned[_buyer] = tokensOwned[_buyer].add(tokens);
        tokensToclaimed[_buyer] = tokensToclaimed[_buyer].add(tokens);
        totalTokensSold = totalTokensSold.add(tokens);
        buyTime[_buyer] = block.timestamp;
        MaticReceived = MaticReceived.add(msg.value);
        if(BuyerAddresIsExist(_buyer) == false){
            PublicPresaleeBuyer.push(_buyer);
        }
        emit TokenBuy(beneficiary, tokens);
   
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }
    
    function getJoiner() public view returns(address[] memory){
        return PublicPresaleeBuyer;
    }
    
    function SetPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function GetTokensOwned(address _address) external view returns (uint256) {
        return tokensOwned[_address];
    }

    function getTotalTokensSold() public view returns(uint256){
        return totalTokensSold;
    }

    function getTokensToClaimed(address _address) external view returns(uint256) {
        return tokensToclaimed[_address];
    }
    
    function getMaticReceived() public view returns(uint256){
        return MaticReceived;
    }
    
    function getLastTokensClaimed () external view returns (uint256) {
        return lastTokensClaimed[msg.sender];
    }

    function getDBLeft() external view returns (uint256) {
        return DiceBounty.balanceOf(address(this));
    }

    function getNumClaims () external view returns (uint256) {
        return numClaims[msg.sender];
    }

    function claimTokens() external nonReentrant {
        require (tokensOwned[msg.sender] > 0, "NO TOKENS TO CLAIM");
        require (tokensToclaimed[msg.sender] > 0, "NO TOKENS TO CLAIM");
        require (DiceBounty.balanceOf(address(this)) >= tokensOwned[msg.sender], "ERROR DB TOKEN NOT ENOUGH");
        require (numClaims[msg.sender] < 1, "DO NOT CLAIM REPEATLY");
        require (isClaimActive,"Claim Not Start");
        tokensToclaimed[msg.sender] = tokensToclaimed[msg.sender].sub(tokensOwned[msg.sender]);
        lastTokensClaimed[msg.sender] = block.timestamp;
        numClaims[msg.sender] = numClaims[msg.sender].add(1);
        DiceBounty.transfer(msg.sender, tokensOwned[msg.sender]);
        emit TokenClaim(msg.sender, tokensOwned[msg.sender]);
    }


    function setClaimActive(bool _active) public onlyOwner{
        isClaimActive = _active;
    }
    
    function resetToken(IERC20 _DBNewToken) public onlyOwner {
        DiceBounty = _DBNewToken;
    }

    function withdrawFunds () external onlyOwner {
        (msg.sender).transfer(address(this).balance);
    }
    
   function randUint256(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length;
    }
    
    function BuyerAddresIsExist(address _address) internal view returns(bool){
        for(uint256 i = 0; i < PublicPresaleeBuyer.length ; i++){
            if(_address == PublicPresaleeBuyer[i]){
                return true;
            }
        }
        return false;
    }
    
    function AddHasKeyAddress(address _address) public onlyOwner{
            PublicPresaleeBuyer.push(_address);
    }



    function setSaleStartTime(uint256 _time) public onlyOwner{
        PublicPresaleStartTime = _time;
    }

    function getBuyTime(address _address) public view returns(uint256){
        return buyTime[_address];
    }
    
    function getClaimTokenTime(address _address) public view returns(uint256){
        return lastTokensClaimed[_address];
    }
    
    
    
    function getprivatePresaleMemberAddressByIndex(uint256 _index) public view returns(address){
        return PublicPresaleeBuyer[_index];
    }


    function withdrawUnsoldTokens() external onlyOwner {
        DiceBounty.transfer(msg.sender, DiceBounty.balanceOf(address(this)));
    }
}