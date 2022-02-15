// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./geutils.sol";
import "./IGENft.sol";

contract GollumNFT is ERC721Enumerable, Ownable,GeUtils {
    using Strings for uint256;

    uint256 public showURITokenId;
    uint256 public nextMintTokenId;
    uint256 public MAX_SUPPLY = 100000;

    uint256 public MINTPRICE;

    uint256 public ECOPRICE;

    string public __baseURI;

    //address(0) use eth
    address public mintTokenAddr;

    //mint use ecotoken
    address public ecoTokenAddr;
    
    //activityControlContract
    address public activityContractAddr;

    uint256 public avaliableCount;

    uint256 public mintedCount;

    bool public mintable = false;

    uint256 public totalSupplyRemaining = MAX_SUPPLY;

    //public sale ,id is zero
    uint256 public activityId;
    //activityId=>address=>config
    mapping(uint256=>mapping(address => MintConfig)) allowAddress;

    //tokenId=>mintDate
    mapping(uint256=>uint256) tokenMintDate;

    event Mintable(bool mintable);

    event AvaliableCount(uint256 avaliableCount);

    event MintedCount(uint256 mintedCount);

    constructor(uint256 _nextMintTokenId) ERC721("GollumNFT", "GLUM") {
        nextMintTokenId = (_nextMintTokenId == 0)?1:_nextMintTokenId;
        // MINTPRICE = 0.06 ether;
    }

    modifier isMintable() {
        require(mintable, "NFT cannot be minted yet.");
        _;
    }

    modifier isNotExceedAvailableSupply(uint256 _amount) {

        if(activityId >0 && msg.sender != activityContractAddr){
            require(allowAddress[activityId][msg.sender].maxMintCount >0,'you cant mint now');
            require(balanceOf(msg.sender) + _amount <= allowAddress[activityId][msg.sender].maxMintCount,'you mint too much');
        }

        require(
            mintedCount + _amount <= avaliableCount,
            "There are no more remaining NFT's to mint."
        );
        _;
    }

    modifier isAllowList() {
        if(activityId >0 && msg.sender != activityContractAddr)
        {
            require(
               allowAddress[activityId][msg.sender].maxMintCount > 0,
                "You're not on the list."
            );   
        }
        _;
    }
    
    function setShowURITokenId(uint256 _tokenId) external onlyOwner {
        showURITokenId = _tokenId;
    }

    function setActivityId(uint256 _activityId) external onlyOwner{
        activityId = _activityId;
    }

    function setEcoPrice(uint256 ecoPrice) external onlyOwner{
        ECOPRICE = ecoPrice;
    }

    function setPrice(uint256 mintPrice) external onlyOwner{
        MINTPRICE = mintPrice;
    }

    function setNextMintTokenId(uint256 _nextMintTokenId) external onlyOwner {
        nextMintTokenId = _nextMintTokenId;
    }

    function setMintTokenAddr(address _tokenAddr) external onlyOwner {
        mintTokenAddr = _tokenAddr;
    }

    function setEcoMintTokenAddr(address tokenAddr) external onlyOwner {
        ecoTokenAddr = tokenAddr;
    }
    
    function setActivityContractAddr(address _activityContractAddr) external onlyOwner{
        activityContractAddr = _activityContractAddr;
    }

    function mintTarget(uint256 tokenId) external onlyOwner {
        tokenMintDate[tokenId] = GeUtils.getDateIndex();//fix but undeploy
        _safeMint(msg.sender, tokenId);
        totalSupplyRemaining--;
        mintedCount++;
    }

    function ecoMint(address mintFor,uint256 amount)
        external
        isMintable
        isAllowList
        isNotExceedAvailableSupply(amount)
    {
        require(ecoTokenAddr != address(0),"eco token not set");
        require(ECOPRICE >0,"ecoMint disable now");
        
        if(activityContractAddr != address(0) && msg.sender == activityContractAddr) {
            //no token
            require(mintFor != address(0),"invalid mintFor");
        }else {
            mintFor = msg.sender;
            require(activityId == 0,"no eco mintable");
            uint256 needTokenBalance = amount * ECOPRICE;
            IERC20 token = IERC20(ecoTokenAddr);
            require(
                token.allowance(mintFor,address(this)) >= needTokenBalance,
                "approve eco token first!"
            );
            require(
                token.balanceOf(mintFor) >= needTokenBalance,
                "no enough eco token to mint"
            );
            token.transferFrom(mintFor,address(this),needTokenBalance);
        }
        
        _mintAction(mintFor,amount);
    }

    function mint(uint256 amount)
        external
        payable
        isMintable
        isAllowList
        isNotExceedAvailableSupply(amount)
    {
        if (msg.sender != owner())
        {
            require(MINTPRICE >0,'invalid price');
            uint256 needTokenBalance = amount * MINTPRICE;
            if(mintTokenAddr == address(0))
            {
                require(
                    msg.value >= needTokenBalance,
                    "There was not enough/extra ETH transferred to mint an NFT."
                );
            }else {
                IERC20 token = IERC20(mintTokenAddr);
                require(
                    token.allowance(msg.sender,address(this)) >= needTokenBalance,
                    "you must approve token to mint an NFT."
                );
                require(
                    token.balanceOf(msg.sender) >= needTokenBalance,
                    "There was not enough token transferred to mint an NFT."
                );
                token.transferFrom(msg.sender,address(this),needTokenBalance);
            }
        }

        _mintAction(msg.sender,amount);
    }


    function _mintAction(address mintFor,uint256 amount) internal {
        for (uint256 index = 0; index < amount; index++) {
            uint256 id = nextMintTokenId;
            tokenMintDate[id] = GeUtils.getDateIndex();
            _safeMint(mintFor, id);
            nextMintTokenId ++;
            totalSupplyRemaining--;
            mintedCount++;
        }
    }
    
    

    function getTokenMintDate(uint256 id) external view returns(uint256) {
        return tokenMintDate[id];
    }


    function setbaseURI(string memory _URI) external onlyOwner {
        __baseURI = _URI;
    }

    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;

        emit Mintable(mintable);
    }


    function setAvaliableCount(uint256 _avaliableCount) external onlyOwner {
        avaliableCount = _avaliableCount;

        emit AvaliableCount(avaliableCount);
    }

    function setmintedCount(uint256 _mintedCount) external onlyOwner {
        mintedCount = _mintedCount;

        emit MintedCount(mintedCount);
    }

    function getAllowAddressInfo(uint256 _activityId,address _address) external view returns(MintConfig memory) {
        return allowAddress[_activityId][_address];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance >0 ,"no balance");
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawToken(address erc20TokenAddr) external onlyOwner {
        IERC20 token = IERC20(erc20TokenAddr);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >0 ,"not any token");
        token.transfer(owner(),tokenBalance);
    }

    function setAddressesToAllowList(uint256 _activityId,address _address,uint256 _maxMintCount)
        external
    {
        require(msg.sender == owner() || activityContractAddr != address(0) && msg.sender == activityContractAddr,'audit fail246');
        require(_activityId >0,'invalid _activityId');
         allowAddress[_activityId][_address] = MintConfig({
             maxMintCount:_maxMintCount
         });
    }

    function removeAddressFromAllowList(uint256 _activityId,address _address) public onlyOwner {
        delete allowAddress[_activityId][_address];
    }

        /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory thebaseURI = __baseURI;
        string memory tokenFile = showURITokenId >= tokenId ? tokenId.toString():"default";
        return bytes(thebaseURI).length > 0 ? string(abi.encodePacked(thebaseURI,"/meta/", tokenFile,".txt")) : "";
    }

    function balance() external view returns(uint256) {
        return address(this).balance;
    }
}