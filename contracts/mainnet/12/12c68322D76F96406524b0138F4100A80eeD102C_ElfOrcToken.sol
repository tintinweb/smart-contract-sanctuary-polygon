// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol"; 
import "./VRFConsumerBase.sol";
import "./IERC20.sol";
import "./Mana.sol";
import "./StakingContract.sol";

contract ElfOrcToken is ERC721Enumerable, Ownable, VRFConsumerBase{

    IERC20 public weth;

    uint256 mintEthCostPresale = 0.015 ether;
    uint256 mintEthCostMainSale = 0.03 ether;
    uint256 multiplier = 20 ether;
    uint256 public mintEthCost;

    bytes32 public keyHash;
    uint256 public fee;

    uint256 public constant MAX_TOKENS = 12200;
    uint256 public constant PUBLIC_SALE_TOKENS = 4000;
    uint256 public constant FREE_TOKENS = 1200;

    uint256 public minted;

    string orcURI;
    string elfURI;
    
    IERC721Enumerable public invitationCollection;
    Mana public mana;
    StakingContract public stakeContract;

    mapping(uint256=>bool) public isOrc;

    uint256[] public orcs;
    uint256 public elfCount;

    uint256 public stolenMints;

    struct TokenInfo {
        address minter;
        uint256 tokenId;
        bool fulfilled;
    }

    mapping(uint256=>uint256) private dataId;
    mapping(uint256=>bool) private takenDataOrcs;
    mapping(uint256=>bool) private takenDataElfs;
    
    mapping(address=>uint256) public publicSoldForWallet;
    mapping(bytes32=>TokenInfo) tokensMintedInfo;

    bool public isPresale = false;
    bool public paused = true;
    bool public fixedPrice = false;
    bool public mintWithManaAfterPresale = false;

    constructor(address _mana, address _vrf, address _link, bytes32 _keyHash, uint256 _fee, address _weth,string memory _orcURI, string memory _elfURI) ERC721("ElfOrc", "EO") VRFConsumerBase(_vrf, _link) {
        keyHash = _keyHash;
        fee = _fee;

        orcURI = _orcURI;
        elfURI = _elfURI;

        mana = Mana(_mana);
        weth = IERC20(_weth);

        weth.approve(msg.sender, type(uint256).max);

        mintEthCost = mintEthCostPresale;
    }

    function setType(uint256 tokenId, uint256 seed) internal {
        uint256 randomNum = uint256(keccak256(abi.encode(seed, 3258))) % 10;
        if (randomNum == 5) {
            isOrc[tokenId] = true;
            orcs.push(tokenId);
        }
        else{
            elfCount++;
        }
    }

    function setData(uint256 tokenId, uint256 seed) internal {
        uint256 randNum = seed;
        uint256 data;
        uint256 maxCombinations = isOrc[tokenId] ? 2000 : 12000;

        do{
            randNum = uint256(keccak256(abi.encode(randNum, 8219)));
            data = randNum % maxCombinations + 1;
        }
        while(isOrc[tokenId] ? takenDataOrcs[data] : takenDataElfs[data]);

        if(isOrc[tokenId]){
            takenDataOrcs[data] = true;
        }
        else{
            takenDataElfs[data] = true;
        }

        dataId[tokenId] = data;
    }

    function getReceiver(uint256 tokenId, address ogMinter, uint256 seed) internal view returns (address) {
        if (tokenId > FREE_TOKENS + PUBLIC_SALE_TOKENS && tokenId <= MAX_TOKENS && (uint256(keccak256(abi.encode(seed, 5312))) % 10) == 5) {
            uint256 orcIndex;
            uint256 randNum = seed;

            do{
                randNum = uint256(keccak256(abi.encode(randNum, 7943)));
                orcIndex = randNum % balanceOf(address(stakeContract));
            }
            while(!isOrc[tokenOfOwnerByIndex(address(stakeContract), orcIndex)]);

            uint256 orcId = tokenOfOwnerByIndex(address(stakeContract), orcIndex);
            
            address newOwner = stakeContract.stakedOrcTokenOwner(orcId);
            
            if (newOwner != address(0)) {
                return newOwner;
            }
        }
        return ogMinter;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override{
        TokenInfo storage token = tokensMintedInfo[requestId];
        require(token.minter != address(0));

        setType(token.tokenId, randomness);
        setData(token.tokenId, randomness);
        address receiver = getReceiver(token.tokenId, token.minter, randomness);

        if (receiver != token.minter) {
            stolenMints++;
        }

        _safeMint(receiver, token.tokenId);

        token.fulfilled = true;
    }

    function publicSale(uint16 amount) external checkIfPaused{
        require(LINK.balanceOf(address(this)) >= amount * fee, "Not enough LINK tokens on contract.");

        address tokenMinter = _msgSender();

        require(tx.origin == tokenMinter, "Contracts are not allowed to mint.");
        require(minted + amount <= FREE_TOKENS + PUBLIC_SALE_TOKENS, "Public sale over");
        require(amount > 0 && amount <= 10, "Maximum of 10 mints per transaction.");
        require(publicSoldForWallet[tokenMinter] + amount <= 50, "You can't mint more than 50 per wallet.");

        if(isPresale){
            require(invitationCollection.balanceOf(msg.sender) > 0, "Minter does not own at least one invitation token.");
        }

        uint256 price = amount * mintEthCost;

        require(weth.allowance(msg.sender,address(this)) >= price && weth.balanceOf(msg.sender) >= price, "You must pay the correct amount of ETH.");
        require(weth.transferFrom(msg.sender, address(this), price));

        for (uint16 i; i < amount; i++) {
            publicSoldForWallet[tokenMinter]++;
            minted++;
            bytes32 requestId = requestRandomness(keyHash, fee);
            tokensMintedInfo[requestId] = TokenInfo(msg.sender, minted, false);
        }
    }

    function manaPrice(uint16 amount) public view returns (uint256) {
        uint256 price;
        if(fixedPrice){
            price = 100 ether;
        }
        else{
            uint256 boughtTokens = minted + amount - FREE_TOKENS;

            price = (boughtTokens / 500 - 3) * multiplier;
        }

        return price;
    }

    function buyWithMana(uint16 amount) external checkIfPaused{
        require(LINK.balanceOf(address(this)) >= amount * fee, "Not enough LINK tokens on contract.");

        address tokenMinter = _msgSender();

        require(tx.origin == tokenMinter, "Contracts are not allowed to mint.");
        require(minted + amount <= MAX_TOKENS, "All available NFT's have beem sold out.");
        require(amount > 0 && amount <= 10, "Maximum of 10 mints per transaction.");

        if(mintWithManaAfterPresale){
            require(minted >= FREE_TOKENS + PUBLIC_SALE_TOKENS ,"You can mint with mana only after presale/mainsale.");
        }

        uint256 price = amount * manaPrice(amount);

        require(mana.allowance(tokenMinter, address(this)) >= price && mana.balanceOf(tokenMinter) >= price, "You need to send enough mana.");
        require(mana.transferFrom(tokenMinter, address(this), price));

        mana.burn(address(this), price);

        for (uint16 i; i < amount; i++) {
            minted++;
            bytes32 requestId = requestRandomness(keyHash, fee);
            tokensMintedInfo[requestId] = TokenInfo(tokenMinter, minted, false);
        }
    }

    function airdrop(address[] memory _wallets) external onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee * _wallets.length, "Not enough LINK tokens on contract.");

        for(uint256 i; i < _wallets.length; i++){
            minted++;
            bytes32 requestId = requestRandomness(keyHash, fee);
            tokensMintedInfo[requestId] = TokenInfo(_wallets[i], minted, false);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory){
        uint256 tokensOwned = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokensOwned);
        for (uint256 i; i < tokensOwned; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function orcCount() public view returns (uint256) {
        return orcs.length;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token.");
        if(isOrc[tokenId]){
            return bytes(orcURI).length > 0 ? string(abi.encodePacked(orcURI,Strings.toString(dataId[tokenId]),".json")): "";
        }
        else{
            return bytes(elfURI).length > 0 ? string(abi.encodePacked(elfURI,Strings.toString(dataId[tokenId]),".json")): "";
        }
    }

    function setMultiplier(uint256 amount) external onlyOwner{
        multiplier = amount;
    }

    function setInvitationCollection(address collection) external onlyOwner{
        invitationCollection = IERC721Enumerable(collection);
    }

    function setStakeContract(address contractAddress) external onlyOwner{
        stakeContract = StakingContract(contractAddress);
    }

    function setRewardCollection(address collection) external onlyOwner{
        mana = Mana(collection);
    }

    function setOrcURI(string memory _uri) external onlyOwner {
        orcURI = _uri;
    }

    function setElfURI(string memory _uri) external onlyOwner {
        elfURI = _uri;
    }

    function balance_WETH() external onlyOwner view returns(uint256){
        return weth.balanceOf(address(this));
    }

    function withdraw_WETH(uint256 amount) external onlyOwner{
        weth.transfer(owner(), amount);
    }

    function togglePresale() external onlyOwner{
        if(isPresale){
            isPresale = !isPresale;
            mintEthCost = mintEthCostMainSale;
        }
        else{
            isPresale = !isPresale;
            mintEthCost = mintEthCostPresale;
        }
    }

    function toggleMintAfterPresale() external onlyOwner{
        mintWithManaAfterPresale = !mintWithManaAfterPresale;
    }

    function toggleFixedPrice() external onlyOwner{
        fixedPrice = !fixedPrice;
    }

    function togglePause() external onlyOwner{
        paused = !paused;
    }

    modifier checkIfPaused(){
        require(!paused,"Contract paused!");
        _;
    }
}