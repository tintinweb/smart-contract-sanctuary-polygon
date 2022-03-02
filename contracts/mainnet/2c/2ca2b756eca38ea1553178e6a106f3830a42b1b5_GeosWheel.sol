/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

/*
  /$$$$$$                                          /$$          
 /$$__  $$                                        | $$          
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$ | $$ /$$   /$$
| $$ /$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$| $$  | $$
| $$|_  $$| $$$$$$$$| $$  \ $$| $$  \ $$| $$  \ $$| $$| $$  | $$
| $$  \ $$| $$_____/| $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$
|  $$$$$$/|  $$$$$$$|  $$$$$$/| $$$$$$$/|  $$$$$$/| $$|  $$$$$$$
 \______/  \_______/ \______/ | $$____/  \______/ |__/ \____  $$
                              | $$                     /$$  | $$
                              | $$                    |  $$$$$$/
                              |__/                     \______/ 
       /$$      /$$ /$$                           /$$           
      | $$  /$ | $$| $$                          | $$           
      | $$ /$$$| $$| $$$$$$$   /$$$$$$   /$$$$$$ | $$           
      | $$/$$ $$ $$| $$__  $$ /$$__  $$ /$$__  $$| $$           
      | $$$$_  $$$$| $$  \ $$| $$$$$$$$| $$$$$$$$| $$           
      | $$$/ \  $$$| $$  | $$| $$_____/| $$_____/| $$           
      | $$/   \  $$| $$  | $$|  $$$$$$$|  $$$$$$$| $$           
      |__/     \__/|__/  |__/ \_______/ \_______/|__/           
                                                                
                                                                
                                                                

                        *** 00 00 ***
                   *0                 0*
               *0                         0*
            *0                               0*
          *0                                   0*
        *0                                       0*
       *0                                         0*
      *0                                           0*
     *0                                             0*
     *0                                             0*
     *0                                             0*
     *0                                             0*
     *0                                             0*
      *0                                           0*
       *0                                         0*
        *0                                       0*
          *0                                   0*
            *0                                0*
               *0                         0*
                   *0                 0*
                       *** 00 00 ***
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;




interface GeoPolyNFT {
    function getMintingString(uint256) external view returns(string memory);
    function balanceOf(address,uint256) external returns(uint256);
    function isApprovedForAll(address,address) external view returns (bool);
    function safeTransferFrom(address,address,uint256,uint256,bytes calldata) external;
    function getWalletNFTs(address) external view returns(uint256[] memory);
    function getNumOfNFTs(address) external view returns(uint256);
}

interface GeoPolyToken {
    function decimals() external view returns(uint256);
    function transferFrom(address,address,uint256) external returns (bool);    
    function allowance(address,address) external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface GeoPolyFarming {
    function spinBalance(address wallet) external view returns(uint256);
    function removeSpin(address owner, uint256 amount) external;
}

interface GeoPolyLibrary {

    function doAll(string calldata) external pure returns(uint256,uint256,uint256,string memory,string memory);
}

abstract contract Authorizables {
    mapping(address => bool) private _authorized;
    mapping(address => bool) private _allowed;

    constructor(){
        _authorized[msg.sender] = true;
    }

    modifier onlyAuthorized {
        require(_authorized[msg.sender], "GeopolyWheel: Not Authorized");
        _;
    }
    modifier onlyAllowed {
        require(_authorized[msg.sender] || _allowed[msg.sender], "GeopolyWheel: Not Allowed");
        _;
    }

    function toggleAllowed(address _addr) public onlyAuthorized {
        _allowed[_addr] = !_allowed[_addr];
    }

    function toggleAuthorized(address _addr) public onlyAuthorized {
        _authorized[_addr] = !_authorized[_addr];
    }
}

contract GeosTokens {
    bytes4 _ERC1155Selector = 0xf23a6e61;
    /**
     * boring ERC1155 function to acknowledge that GeopolyFarms can receieve ERC1155 tokens
     */
    function onERC1155Received(address ,address ,uint256 ,uint256 ,bytes calldata) public view returns(bytes4){
        return(_ERC1155Selector);
    }
    /**
     * boring ERC1155 function to send tokens
     */
    function send1155Token(address token, address owner, uint256 tokenId) internal returns(bool) {
        require(GeoPolyNFT(token).balanceOf(address(this), tokenId) > 0, "GeopolyWheel: We do not own this NFT.");
        GeoPolyNFT(token).safeTransferFrom(address(this), owner, tokenId, 1, "");
        return true;
    }
    /**
     * boring ERC1155 function to recieve tokens
     */
    function recieve1155Token(address token, address owner, uint256 tokenId) internal virtual returns(bool) {
        require(GeoPolyNFT(token).balanceOf(owner, tokenId) > 0, "GeopolyWheel: Cannot approve GEO$ NFT you dont own");
        require(GeoPolyNFT(token).isApprovedForAll(owner, address(this)), "GeopolyWheel: Need to approve us for GEO$ NFT");
        GeoPolyNFT(token).safeTransferFrom(owner, address(this), tokenId, 1, "");
        return true;
    }
    /**
     * boring ERC20 function to send tokens
     */
    function send20Token(address token, address reciever, uint256 amount) internal returns(bool){
        require(GeoPolyToken(token).balanceOf(address(this)) > amount, "GeopolyWheel: No enough balance");
        require(GeoPolyToken(token).transfer(reciever, amount), "GeopolyWheel: Cannot currently transfer");
        return true;
    }
    /**
     * boring ERC20 function to recieve tokens
     */
    function recieve20Token(address token, address sender, uint256 amount) internal virtual returns(bool) {
        require(GeoPolyToken(token).allowance(sender, address(this)) >= amount, "GeopolyWheel: Need to approve us for GEO$ ");
        require(GeoPolyToken(token).transferFrom(sender, address(this), amount), "GeopolyWheel: Need to pay us GEO$ ");
        return true;
    }
}

contract VRFRequestIDBase {

  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));

    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);

    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;


  mapping(bytes32 => uint256) 
    private nonces;

  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }


  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "GeopolyWheel: Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

contract GeosContracts {
    address public geos20 = 0xf1428850f92B87e629c6f3A3B75BffBC496F7Ba6;
    address public geos1155 = 0x0b72a80C151DeC838Cb6fBCE002c09eD35897345;
    address public geoslibrary = 0x44DA64602f77f7Caded40D71E0f1A252E6800064;
    address public geosfarming = 0x7d99a94E13C9E62ea1b120cd77cCE0AfC293AE0c;
}

contract GeosVault is GeosContracts, Authorizables, GeosTokens {

    enum RewardPackage {
        ID_I, // 50 GEO$
        ID_II, // 250 GEO$
        ID_III, // 500 GEO$
        ID_IV, // 1000 GEO$
        ID_V, // 5000 GEO$
        ID_VI, // 20000 GEO$
        ID_VII, // C NFT
        ID_VIII, // B NFT
        ID_IX, // A NFT
        ID_X // * NFT
    }

    struct NFTReward {
        uint256 _tokenId;
        RewardPackage _tokenRp;
    }

    function _sendTokens(address to, uint256 amount) internal {

        send20Token(geos20, to, amount);
    }

    function _sendNFTs(address to, uint256 tokenId) internal {

        send1155Token(geos1155, to, tokenId);
    }

    function _getVaultRewardsNFT() internal view returns(NFTReward[] memory rewards){
        uint256[] memory _vaultNFTs = getVaultNFTs();
        rewards = new NFTReward[](_vaultNFTs.length);
        for(uint256 i=0; i<_vaultNFTs.length; i++ ){
            rewards[i] = NFTReward(_vaultNFTs[i], getNFTRewardPackage(_vaultNFTs[i]));
        }
        return rewards;
    }

     function getNFTRewardPackage(uint256 tokenId) internal view returns(RewardPackage rt) {
        (uint256 _category,,uint256 _usdtPrice,,) = GeoPolyLibrary(geoslibrary).doAll(GeoPolyNFT(geos1155).getMintingString(tokenId));
        if(_category == 23 || _category == 24){
            return (RewardPackage.ID_X);
        }else if(_usdtPrice <= 300){
            return (RewardPackage.ID_VII);
        }else if (_usdtPrice <= 600){
            return (RewardPackage.ID_VIII);
        }else{
            return (RewardPackage.ID_IX);
        }
    }

    function getVaultNFTs() public view returns(uint256[] memory){
        return(GeoPolyNFT(geos1155).getWalletNFTs(address(this)));
    }

    function getVaultTokens() public view returns(uint256){
        return(GeoPolyToken(geos20).balanceOf(address(this)));
    }

    function policy1155Tokens(address to,address nft_contract, uint256 tokenId) external onlyAllowed {
        send1155Token(nft_contract, to, tokenId);
    }

    function withdrawNative(uint256 amount, address to) external onlyAllowed {
        require(address(this).balance >= amount,"GeopolyWheel: Not enough balance");
        require(payable(to).send(amount), "GeopolyWheel: Cannot process withdrawal to this address");
    }

    function withdraw20Tokens(address token, uint256 amount, address to) external onlyAllowed {
        require(GeoPolyToken(token).balanceOf(address(this)) > amount, "GeopolyWheel: Not enough balance");
        require(GeoPolyToken(token).transfer(to, amount));
    }
}

contract GeosWheel is VRFConsumerBase, GeosVault {

    event RewardGiven(address indexed nftOwner, uint8 rewardPackage, uint256 tokenId, uint256 tokenAmout);

    uint256 constant packagesLength = 10;
    mapping(uint8 => uint256) _packageChance;

    uint256 internal packageLen;
    uint256 internal rewardTracker;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal mainRandomness;

    mapping(address => RewardPackage[]) _walletSpins;


    // VRF Coordinator, // LINK Token
    constructor() VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0,  0xb0897686c545045aFc77CF20eC7A532E3120E0F1){
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK 
    }


    function fillPackageChance(uint256[] memory chances) public onlyAuthorized {
        require(chances.length == packagesLength, "GeopolyWheel: Chances Array need to have a length of 10");
        for(uint8 i=0; i<chances.length; i++){
            _packageChance[i] = chances[i];
        }
    }

    function addPackageChance(uint8 _index, uint256 _amount) public onlyAuthorized {
        _packageChance[_index] += _amount;
    }

    function fulfillRandomness(bytes32 , uint256 randomness) internal override {

        mainRandomness = randomness;
    }

    function getRandomNumber() public onlyAllowed returns(bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "GeopolyWheel: Not enough LINK - fill contract with LINK");
        return requestRandomness(keyHash, fee);
    }

    function spinWheel(address spinner, uint256 spinTimes) public {
        require(spinner == msg.sender, "GeopolyWheel: Only owner of spins can spin the wheel");
        require(GeoPolyFarming(geosfarming).spinBalance(msg.sender) >= spinTimes && spinTimes > 0, "GeopolyWheel: Cannot Spin more than your spin balance");
        GeoPolyFarming(geosfarming).removeSpin(msg.sender, spinTimes);
        for(uint256 i=0; i< spinTimes; i++){
            giveReward(spinner);
        }
    }

    function getWalletSpins(address wallet) public view returns(RewardPackage[] memory){
      return(_walletSpins[wallet]);
    }

    function _getRandomReward(uint256 _randomValue) internal pure returns(uint256) {

         return((_randomValue % packagesLength) + 1);
    }

    function _getRandomRewardIncrementer(uint256 _index) public view returns(uint256){

        return(((uint256(keccak256(abi.encode(mainRandomness, _index)))) % packagesLength) + 1);
    }

    function _getTokenAmountReward(RewardPackage rt) internal pure returns(uint256){
        if(rt == RewardPackage.ID_I){
            return (50 ether);
        }else if (rt == RewardPackage.ID_II){
            return (250 ether);
        }else if (rt == RewardPackage.ID_III){
            return (500 ether);
        }else if (rt == RewardPackage.ID_IV){
            return (1000 ether);
        }else if (rt == RewardPackage.ID_V){
            return (5000 ether);
        }else if (rt == RewardPackage.ID_VI){
            return (20000 ether);
        }else{
            return (0 ether);
        }
    }

    function _getTokenIdReward(RewardPackage rt) internal view returns(uint256){
        uint256[] memory _vaultNFTs = getVaultNFTs();
        for(uint256 i=0; i<_vaultNFTs.length; i++ ){
            if(getNFTRewardPackage(_vaultNFTs[i]) == rt){
                return _vaultNFTs[i];
            }
        }
        revert("GeopolyWheel: No NFT for such reward");
    } 

    function giveReward(address to) internal  {
        (RewardPackage packageType, uint256 packageVar) = _getReward();
        if(uint8(packageType) <= uint8(6)){
            _sendTokens(to, packageVar);
            emit RewardGiven(to, uint8(packageType), 0, packageVar);
        }else {
            _sendNFTs(to, packageVar);
            emit RewardGiven(to, uint8(packageType), packageVar, 0);
        }
        
        rewardTracker += 1;
        if(rewardTracker == 9){
            getRandomNumber();
            rewardTracker = 0;
        }

        _walletSpins[to].push(packageType);
    }

    function _getReward() internal returns(RewardPackage _rewardPackage, uint256 _rewardVar){
        uint256 _rr = _getRandomRewardIncrementer(rewardTracker);
        for(uint256 i=_rr; i >= 0; i--){
            if(_packageChance[uint8(i)] > 0){
                _rewardPackage = RewardPackage(i);
                _packageChance[uint8(i)] -=1;
                break;
            }
        }
        return(_rewardPackage, uint8(_rewardPackage) <= uint8(6) ? _getTokenAmountReward(_rewardPackage) : _getTokenIdReward(_rewardPackage));
    }
}