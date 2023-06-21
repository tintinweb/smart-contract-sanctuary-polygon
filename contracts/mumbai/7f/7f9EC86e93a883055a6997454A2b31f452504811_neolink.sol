// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @title Theirsverse NFT
import "SafeERC20.sol";
import "IERC721.sol";
import "ERC1155.sol";
import "IERC721Metadata.sol";
import "IERC721Enumerable.sol";
import "MerkleProof.sol";
import "Ownable.sol";
import "AccessControl.sol";
import "ReentrancyGuard.sol";
import "Address.sol";
import "Pausable.sol";
import "ERC721A.sol";

contract neolink is Ownable, ERC721A, Pausable, AccessControl, ReentrancyGuard {
    
    struct rewardinfo{
        uint256 id;
        uint256 lvl;
    }
    uint256 public immutable maxSupply;
    //max 1st count for 1st round
    uint256 public constant MAX_1ST_ROUND = 100;
    //max 2nd count for 1st round
    uint256 public constant MAX_2ND_ROUND = 1000;
    //max reward counter for 1st round
    uint256 public constant MAX_REWARD1ST = 50;
    //max reward counter for 2nd round
    uint256 public constant MAX_REWARD2ND = 50;

    //logging all reward infos;
    rewardinfo[] public rewardInfos;
    //random index value,init with the max random range by every group
    uint256 private remaining;
    //the random group log,clear by every group time
    mapping(uint256 => uint256) private idxcache;

    address payable public payment;
    uint256 public saleStartTime;
    bytes32 public merkleRoots;
    uint256 public whitelistPrices = 0;//0.0 eth white list sale prices
    uint256 public publicSalePrice = 200000000000000000;//0.2eth
    string public baseURI;
    
    //gift for first time.
    bool private _isGift1stActive = true;
    //gift for second time.
    bool private _isGift2ndActive = true;
    //if can sale
    bool private canSend = false;
    mapping(address => uint256) public amountNFTsPerWhitelistMint;
    mapping(address => uint256) public amountNFTsPerPublicMint;

    constructor(
        //uint256 _saleStartTime,
        uint256 _maxSupply,
        address _owner,
        address _devAdmin,
        address _paymentAddress
    ) ERC721A("Noelink Official", "NOELINK") {
        //saleStartTime = _saleStartTime;
        maxSupply = _maxSupply;
        payment = payable(_paymentAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _devAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        transferOwnership(_owner);
        
    }

    modifier _notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier _saleBetweenPeriod(uint256 _start, uint256 _end) {
        require(currentTime() >= saleStartTime + _start * 1 days, "sale has not started yet");
        require(currentTime() < saleStartTime + _end * 1 days, "sale is finished");
        _;
    } 
 
    //only owner
    function flipGift1stActive() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isGift1stActive = !_isGift1stActive;
    }

    //only owner
    function flipGift2ndActive() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isGift2ndActive = !_isGift2ndActive;
    }
 
    function giftFor1st() public onlyRole(DEFAULT_ADMIN_ROLE){
        require(_isGift1stActive  == true, "game is not begin");
        //initRandom(MAX_1ST_ROUND);
        remaining = MAX_1ST_ROUND;
        uint256 rand;
        //gift 50 reward
        for(uint256 i=0;i<MAX_REWARD1ST;i++) {
            rand = randomIndex();
            rewardinfo memory rewardinfo1=rewardinfo(rand,2);
            rewardInfos.push(rewardinfo1);
        }
        for(uint256 i=0;i<MAX_REWARD1ST;i++){
            delete idxcache[rewardInfos[i].id];
        }
        _isGift1stActive = false;
    }

    function giftFor2nd() public onlyRole(DEFAULT_ADMIN_ROLE){
        require(_isGift2ndActive  == true, "game is not begin");
        //initRandom(MAX_2ND_ROUND-MAX_1ST_ROUND);
        remaining = MAX_2ND_ROUND-MAX_1ST_ROUND;
        uint256 rand;
        //gift 50 reward
        rewardinfo memory rewardinfo1;
        for(uint256 i=0;i<MAX_REWARD2ND;i++) {
            rand = MAX_1ST_ROUND+randomIndex();
            rewardinfo1=rewardinfo(rand,3);
            rewardInfos.push(rewardinfo1);
        }
        rand = randomIndex(MAX_REWARD1ST+MAX_REWARD2ND);
        rewardinfo1 = rewardInfos[rand];
        rewardinfo1.lvl = 1;
        rewardInfos[rand] = rewardinfo1;
        _isGift2ndActive = false;
    }
    
    function queryRewards() public view returns (rewardinfo[] memory){
        return rewardInfos;
    }

    function randomIndex() internal returns (uint256 index) {
        //RNG
        uint256 i = uint(blockhash(block.number - 1)) % remaining;

        // if there's a cache at cache[i] then use it
        // otherwise use i itself
        index = idxcache[i] == 0 ? i : idxcache[i];

        // grab a number from the tail
        idxcache[i] = idxcache[remaining - 1] == 0 ? remaining - 1 : idxcache[remaining - 1];
        remaining = remaining - 1;
    }

    function randomIndex(uint256 rangex) internal view returns (uint256 index) {
        index = uint(blockhash(block.number - 1)) % rangex;
    }

    function whitelistMint(bytes32[] calldata _proof) external payable _notContract whenNotPaused nonReentrant {
        uint256 _quantity = 1;
        require(
                amountNFTsPerWhitelistMint[msg.sender] + _quantity <= 1,
                "You can only get 1 NFT on the Whitelist Sale"
        );   
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed");
        uint256 totalPrice = whitelistPrices * _quantity;
        require(msg.value >= totalPrice, "Not enough funds");
        require(isWhiteListed(_proof, merkleRoots, msg.sender), "Not Whitelisted");
        amountNFTsPerWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        refundIfOver(totalPrice);
    }

    //must be sale after whitelist mint
    function publicSaleMint()
        external
        payable
        whenNotPaused
        _notContract
        //_saleBetweenPeriod(2, 3)
        nonReentrant
    {
        uint256 _quantity = 1;
        require(totalSupply() >=MAX_1ST_ROUND, "It'll be started after mint all whitelist");
        require(amountNFTsPerPublicMint[msg.sender] + _quantity <= 1, "You can only get 1 NFT on the Public Sale");
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed");
        uint256 totalPrice = publicSalePrice * _quantity;
        require(msg.value >= totalPrice, "Not enough funds");
        amountNFTsPerPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        refundIfOver(totalPrice);
    }

    function whitelistAirdrop(address[] calldata _accounts)
        external        
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_accounts.length > 0, "No accounts provided");
        for (uint256 i = 0; i < _accounts.length; i++) {
            uint256 quantity = 1;
            require(quantity > 0, "Quantity must be greater than 0");
            require(totalSupply() + quantity <= maxSupply, "Max supply exceed");
            amountNFTsPerWhitelistMint[_accounts[i]] += quantity;
            _batchMint(_accounts[i], quantity);
        }
    }

    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            Address.sendValue(payable(msg.sender), msg.value - price);
        }
    }

    function withdraw() public whenNotPaused {
        uint256 amount = address(this).balance;
        if (amount > 0) {
            Address.sendValue(payment, amount);
        }
    }
    
    function withdraw(IERC20 token) public whenNotPaused {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");
        SafeERC20.safeTransfer(token, payment, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721A) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function setPayment(address _paymentAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payment = payable(_paymentAddress);
    }


    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function canSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        canSend = true;
    }

    function canNotSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        canSend = false;
    }

    function currentTime() private view returns (uint256) {
        return block.timestamp;
    }

    function setBaseURI(string calldata uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    function setMerkleRoot(bytes32 _merkleRoots) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoots = _merkleRoots;
    }

    function setSaleStartTime(uint256 _saleStartTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleStartTime = _saleStartTime;
    }

    function grantAdminRole(address account) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) external onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

     function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }    

    function _batchMint(address _account, uint256 _quantity) internal {
        require(_quantity > 0, "Quantity must be greater than 0");
        _safeMint(_account,_quantity);
    }

    function isWhiteListed(
        bytes32[] calldata _proof,
        bytes32 _merkleRoot,
        address _account
    ) private pure returns (bool) {
        return MerkleProof.verify(_proof, _merkleRoot, leaf(_account));
    }

    function leaf(address _account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }
    
    function _beforeTokenTransfers(address from,
        address to,
        uint256 startTokenId,
        uint256 quantity)
        internal virtual override
    {
        super._beforeTokenTransfers(from, to, startTokenId,quantity);
        if(from!=address(0))
          require(canSend, "TokenTransfers: Sending is not allowed now ");
    }
     
}