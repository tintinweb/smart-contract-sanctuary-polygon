// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract SB_REVC is ERC721, ERC721Enumerable, Ownable {
// contract Doodles_Working is ERC721, ERC721Enumerable, Ownable {

    //-----------------------------------------------------------
    // added new : using Strings for uint256; otherwise, cannot use
    // tokenId.toString()
    using Strings for uint256;

    string public PROVENANCE;
    
    // bool public saleIsActive = false;
    string private _baseURIextended;

    
    uint256 public constant MAX_SUPPLY = 400;
    // uint256 public MAX_SUPPLY = 10000;
    uint256 public max_public_mint = MAX_SUPPLY-totalSupply();
    uint256 public max_whitelist_mint = MAX_SUPPLY-totalSupply();
    uint256 public price_per_token = 0.0002 ether; //0.123
    //
    // uint256 public constant PRICE_PER_TOKEN = 0.123 ether;
    // remove constant

    //--------------------------------------------
    string baseURI;
    string public baseExtension = ".json";
    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri;
    
    address public owner_address;
    address public admin_address;
    address public sysadm_address;


    // Itpunk.sol, TPunks

    struct userAirdrop {
        bool isExists;
        uint256 id;
        // mapping (uint256 => address) referral;
        uint256 referral_buy_index;
    }

    mapping (address => userAirdrop) public usersAirdrop;
    
    mapping (uint256 => address) public usersAirdropAddress;
    
    uint256 public airDrop_id = 1000;
    
    // uint256 public airDrop_reward = 100 trx;
    uint256 public airDrop_reward = 0.0002 ether;

    event Whitelisted(address indexed account, bool isWhitelisted);
    event RemoveWhitelisted(address indexed account, bool isWhitelisted);
    event Minted(address indexed _address, uint256 quantity);
    event SetPublicMintGeneral(uint256 PublicMintMax);
    event SetWhiteListMintMaxGeneral(uint256 WhiteListMintMax);
    event SetWhiteListMintMaxSpecific(address indexed _address, uint256 WhiteListMintMax);

    function startAirDrop() public returns (uint256){
        
        require(!usersAirdrop[msg.sender].isExists, 'This account already started airdrop');
        
        userAirdrop memory ua = userAirdrop({
            isExists : true,
            id : airDrop_id,
            referral_buy_index : 0
        });
        
        usersAirdrop[msg.sender] = ua;
        
        usersAirdropAddress[airDrop_id] = msg.sender;
        
        airDrop_id++;
        
        return usersAirdrop[msg.sender].id;
        
    }

    mapping (uint256 => address) public winners;

    function mintNFTAirDrop(uint256 numberOfNfts, uint256 _airDrop_id) public payable {

        uint256 ts = totalSupply();

        // require(start_sale, 'sale is not start');
        require(!paused);
        // require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        // require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(ts + numberOfNfts <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        
        
        //require(getNFTPrice().mul(numberOfNfts) == msg.value, "Trx value sent is not correct");

        require(price_per_token * numberOfNfts <= msg.value, "Ether value sent is not correct");


        // require(numberOfNfts <= 20, "You may not buy more than 20 NFTs at once");
        uint256 mint_limit;
        if (isWhiteListActive){
            require(whitelistedAddress[msg.sender], "Client is not on White list");
            // mint_limit=max_whitelist_mint;
            mint_limit=_whitelist_mint_max[msg.sender];
            _whitelist_mint_max[msg.sender] -= numberOfNfts;
        } else {
            mint_limit=max_public_mint;  
        }

        require(numberOfNfts <= mint_limit, "Exceeded max token purchase");


        uint256 msgValue = msg.value;

        for (uint i = 0; i < numberOfNfts; i++) {

            // uint256 mintIndex = getNextPunkIndex();
            //-----------------------------
            uint id = randomIndex();
            numTokens = numTokens + 1;
            //-----------------------------

            // _safeMint(msg.sender, mintIndex);
            _safeMint(msg.sender, id);

        }

        (bool sent, ) = owner_address.call{value: msg.value}("");
        // (bool sent, ) = owner_address.call{value: price_per_token * numberOfTokens}("");

        require(sent, "Failed to send Ether");

        emit Minted(msg.sender, numberOfNfts);

        // nonce = 0;

        if(usersAirdrop[usersAirdropAddress[_airDrop_id]].isExists){
            
            if(usersAirdropAddress[_airDrop_id] != msg.sender){
            
                usersAirdrop[usersAirdropAddress[_airDrop_id]].referral_buy_index = usersAirdrop[usersAirdropAddress[_airDrop_id]].referral_buy_index + numberOfNfts;
                
                address ads = usersAirdropAddress[_airDrop_id];
                address _fads = ads;
                
                for(uint256 i=0; i<5; i++){
                    
                    address wads = winners[i];
                    
                    if(usersAirdrop[wads].isExists){
                        
                        if(wads == _fads){
                            winners[i] = ads;
                            break;
                        }else if(usersAirdrop[ads].referral_buy_index > usersAirdrop[wads].referral_buy_index){
                            winners[i] = ads;
                            ads = wads;
                        }
                        
                    }else{
                        winners[i] = ads;
                        break;
                    }
                    
                }
                
                uint256 amount = airDrop_reward * numberOfNfts;
                
                msgValue = msgValue - amount;
                
                // (bool success, ) = address(uint160(usersAirdropAddress[_airDrop_id])).call.value(amount)("");
                (bool success1, ) = address(uint160(usersAirdropAddress[_airDrop_id])).call{value:amount}("");
                require(success1, "Address: unable to send value, recipient may have reverted");
            }
            
        }
        
        // (bool success, ) = address(uint160(owner())).call.value(msgValue)("");
        (bool success, ) = address(uint160(owner())).call{value:msgValue}("");
        require(success, "Address: unable to send value, recipient may have reverted");
          
    }



    // function getNextPunkIndex() private returns(uint256){
        
        
    //     if(punks_index_exists_length > 1){
    //         nonce++;
    //         for (uint256 i = 0; i < punks_index_exists_length; i++) {
    //             uint256 n = i + uint256(keccak256(abi.encodePacked(now + nonce))) % (punks_index_exists_length - i);
    //             uint256 temp = punks_index_exists[n];
    //             punks_index_exists[n] = punks_index_exists[i];
    //             punks_index_exists[i] = temp;
    //         }
    //     }else if(punks_index[punks_index_exists[0]] == punks_per_colum){
    //         revert("we don't have any item !");
    //     }
        
    //     uint256 p_index = ((punks_index[punks_index_exists[0]]) + ((punks_index_exists[0] * punks_per_colum)));
        
    //     punks_index[punks_index_exists[0]]++;
        
    //     if(punks_index[punks_index_exists[0]] >= punks_per_colum){
    //         punks_index_exists_length--;
    //         punks_index_exists[0] = punks_index_exists[punks_index_exists_length];
    //     }
        
    //     return p_index;
        
    // }

    //--------------------------------------------

    // // mapping(address => uint16) private _allowList;
    // mapping(address => uint8) private _allowList;

    // constructor() ERC721("Doodles", "DOODLE") {
    // }

    constructor(
        address ownerAddress,
        address adminAddress,
        address sysadmAddress,
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri 
    ) ERC721(_name, _symbol) {

        //----------------------------------------------
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        owner_address = ownerAddress;
        admin_address = adminAddress;
        sysadm_address = sysadmAddress;
        //----------------------------------------------
    
    }

    //----------------------------------------------
    // PBE
    // internal
    // 
    // function _baseURI() internal view virtual override returns (string memory) {
    //     return baseURI;
    // }
    // Defined twice


    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {    
        notRevealedUri = _notRevealedURI;
    }


    function setNotRevealedURIExternal(string memory _notRevealedURI) external {
    // function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        notRevealedUri = _notRevealedURI;
    }



    //only owner
    function reveal() public {
    // function reveal() public onlyOwner {
    
      // replace onlyOwner with owner or admin
    
      require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
      revealed = true;
    }

    function setNewCost(uint256 _newCost) public {
    // function setCost(uint256 _newCost) public onlyOwner {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        //cost = _newCost;
        price_per_token = _newCost;
    }

    function setBaseExtension(string memory _newBaseExtension) public {
    // function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public {
    // function pause(bool _state) public onlyOwner {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        paused = _state;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }


    function setMaxPublicMint(uint16 _max_public_mint) external {
    // function setMaxPublicMint(uint16 _max_public_mint) public {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        max_public_mint = _max_public_mint;

        emit SetPublicMintGeneral(max_public_mint);
    }

    function setMaxWhiteListMint(uint16 _max_whitelist_mint) external {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        max_whitelist_mint = _max_whitelist_mint;

        emit SetWhiteListMintMaxGeneral(max_whitelist_mint);
    }


    // MAX_SUPPLY cannot be a variable, because TOKEN_LIMIT for indices needs
    // to be a constant.
    // function setMaxSupply(uint256 _maxSupply) public {
    
    //     // replace onlyOwner with owner or admin
        
    //     require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        
    //     MAX_SUPPLY = _maxSupply;
    // }
    

    // TMEEBIT
    uint internal numTokens = 0;
    uint internal nonce = 0;
    uint internal constant TOKEN_LIMIT = MAX_SUPPLY;
    // uint internal TOKEN_LIMIT = MAX_SUPPLY;
    uint[TOKEN_LIMIT] internal indices;
    // // mapping (uint256 => address) internal idToOwner;
    // // mapping(address => uint256[]) internal ownerToIds;
    // // mapping(uint256 => uint256) internal idToOwnerIndex;


    // function _addNFToken(address _to, uint256 _tokenId) internal {
    //     require(idToOwner[_tokenId] == address(0), "Cannot add, already owned.");
    //     idToOwner[_tokenId] = _to;

    //     ownerToIds[_to].push(_tokenId); 
    //     // idToOwnerIndex[_tokenId] = ownerToIds[_to].length.sub(1);
    //     idToOwnerIndex[_tokenId] = ownerToIds[_to].length-1;
    // }


    function randomIndex() internal returns (uint) {
        uint totalSize = TOKEN_LIMIT - numTokens;
        uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value+1;
        // return value.add(1);
    }

    function changeAdmin(address newAdminAddress) external {
        require(msg.sender==owner_address|| msg.sender == sysadm_address, "notOwnerNorSysadm");
        admin_address = newAdminAddress;
    }


    function userHoldToken(address userAddress) external view returns (bool) {
        uint256 userTokenBalance = balanceOf(userAddress);
        if (userTokenBalance>0){
            return true;
        } else {
            return false;
        }
    }


    // function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    //     uint256 ownerTokenCount = balanceOf(_owner);
    //     uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    //         for (uint256 i; i < ownerTokenCount; i++) {
    //         tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    //         }
    //     return tokenIds;
    // }

    // refer walletOfOwner(address _owner) above
    // function tokenIdsOfOwner(address _owner) public view returns (uint256[] memory) {
    //     uint256 ownerTokenCount = balanceOf(_owner); // find how many tokens own by Owner
    //     uint256[] memory tokenIds = new uint256[](ownerTokenCount); // set the array size of tokenIds
    //         for (uint256 i; i < ownerTokenCount; i++) {
    //             tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    //         }
    //     return tokenIds; // tokenIds is an array of tokenIds
    // }

    //---------------------------------------------------------------------

    // refer tokenIdsOfOwner(address _owner)
    function clientTokenIDs(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner); // find how many tokens own by Owner
        uint256[] memory tokenIds = new uint256[](ownerTokenCount); // set the array size of tokenIds
            for (uint256 i; i < ownerTokenCount; i++) {
                tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            }
        return tokenIds; // tokenIds is an array of tokenIds
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    
    
    function setBaseURI(string memory baseURI_) public onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setBaseURIExternal(string memory baseURI_) external {
    // function setBaseURI(string memory baseURI_) public onlyOwner() {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        _baseURIextended = baseURI_;
    }

    
    // function setBaseURI(string memory baseURI_) external onlyOwner() {
    //     _baseURIextended = baseURI_;
    // }
    //
    // change from external to public, input at contract creation using constructor, 
    // instead of adding it later
    

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public {
    // function setProvenance(string memory provenance) public onlyOwner {
        // replace onlyOwner with owner

        require(msg.sender == owner_address,"Not Owner");

        PROVENANCE = provenance;
    }


    //-----------------------------------------------------------------------------------

    // mapping(address => uint16) private _allowList;
    // function setAllowList(address[] calldata addresses, uint256 numAllowedToMint) external {
    //     require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
    //     for (uint256 i = 0; i < addresses.length; i++) {
    //         _allowList[addresses[i]] = numAllowedToMint;
    //     }
    // }

    bool public isWhiteListActive = false;

    mapping (address => bool) public whitelistedAddress;
    mapping (address => uint256) public _whitelist_mint_max;
    address[] public whiteList;

    uint256 whiteListId = 0;

    mapping (address => uint256) public whiteListIdMap; // whiteListId starts at 1

    
    function whiteListQuantity() external view returns (uint256) {
        return whiteList.length;
    }

    // struct WhiteListData {
    //     address _address;
    //     bool _status;
    //     uint256 _whiteListId;
    // }

    // struct WhiteListId {
    //     uint256 _whiteListId;
    // }

    // WhiteListData[] public _whiteListData;

    // mapping (address => WhiteListData) whitelistedStatusId;

    
    // mapping (address => bool) private whitelistedAddress;
    // remove private for whitelistedAddress

    
    
    function setWhiteListActiveStatus(bool _status) external {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        isWhiteListActive = _status;
    }

    // whiteListUserArray(address[] calldata _address), in case we ONLY remove whitelist user in bulk, 
    // never a specific one. So, no need for whiteListId and whiteListIdMap
    
    function whiteListUserArray(address[] calldata _address) public {
    // function addAndChangeWhiteListStatus(address _address) public onlyOwner {

        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        for (uint256 i = 0; i < _address.length; i++) {
            whitelistedAddress[_address[i]] = true;

            _whitelist_mint_max[_address[i]]=max_whitelist_mint;

            whiteList.push(_address[i]);

            emit Whitelisted(_address[i], true);
        }

    }


    // struct WhiteListData {
    //     bool _status;
    //     uint256 _whiteListId;
    // }

    // uint256 whiteListId = 0;

    // WhiteListData[] public _whiteListData;


    // whiteListUserArrayWithId, for removing one whitelist user
    function whiteListUserArrayWithId(address[] calldata _address) public {
    // function addAndChangeWhiteListStatus(address _address) public onlyOwner {

        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        for (uint256 i = 0; i < _address.length; i++) {

            whitelistedAddress[_address[i]] = true;
            
            _whitelist_mint_max[_address[i]]=max_whitelist_mint;

            whiteList.push(_address[i]);

            whiteListId++;

            whiteListIdMap[_address[i]]=whiteListId; // whiteListId starts with 1 

            emit Whitelisted(_address[i], true);
        }

    }

    // Initialize a struct, Method 1
        // struct User {
        //     uint id;
        //     address upline;
        //     uint32 directCount;

        //     uint32 board1usedTurnP1;   
        //     uint32 board1usedTurnP2;
        
        // }

        // User memory user = User({
        // id: lastUserId,
        // upline: uplineAddress,
        // directCount: 0,
        // board1usedTurnP1:0,   
        // board1usedTurnP2:0 });


        // Initialize a struct, Method 2
        // struct Ticket {
        //     uint ticketNo; 
        //     uint userId;
        //     bool filled;
        // }

        // p2Boards[1].push(Ticket(p2BoardTicketCount[1],1,false));

            //_whiteListData.push(WhiteListData(_address[i],true, whiteListId));



    function whiteListNumAvailableToMint(address addr) external view returns (uint256) {
    // function numAvailableToMint(address addr) external view returns (uint8) {
        return _whitelist_mint_max[addr];
    }


    // if paused, whitelisted, with address input return will be false, 
    // otherwise, check boolean status
    function viewWhiteListStatus(address _address) public view returns (bool) {
        // if (paused) {
        //     return false;
        // }
        return whitelistedAddress[_address];
    }

    // removeWhiteListStatusArray(), in case we ONLY remove whitelist user in bulk, never a specific one. So,
    // no need for whiteListId and whiteListIdMap
    
    function removeWhiteListStatusArray() public {
    // function removeWhiteListStatus(address _address) public onlyOwner {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        require(whiteList.length>0,"No more whitelisted user");

        
        for (uint256 i = 0; i < whiteList.length; i++) {
            // require(whitelistedAddress[_address] != false); 
            whitelistedAddress[whiteList[i]] = false;

            _whitelist_mint_max[whiteList[i]]=0;

            emit RemoveWhitelisted(whiteList[i], false);
        }

        whiteList = new address[](0);
                 
    }


    function removeWhiteListStatusArrayWithId() public {
    // function removeWhiteListStatus(address _address) public onlyOwner {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        require(whiteList.length>0,"No more whitelisted user");

        
        for (uint256 i = 0; i < whiteList.length; i++) {
            // require(whitelistedAddress[_address] != false); 
            whitelistedAddress[whiteList[i]] = false;

            _whitelist_mint_max[whiteList[i]]=0;

            // mapping (address => uint256) public whiteListIdMap;

            whiteListIdMap[whiteList[i]]=0;

            emit RemoveWhitelisted(whiteList[i], false);
        }

        whiteList = new address[](0);
        // WhiteListData[] public _whiteListData;
        // _whiteListData = new WhiteListData[](0);
        whiteListId=0;
                 
    }


    function updateWhiteListIdMapAfterSingleRemove(uint index) private {
        for (uint256 i = index+1; i<whiteList.length;i++){ // index + 1, is the next element
            // mapping (address => uint256) public whiteListIdMap; // whiteListId starts at 1
            // address[] public whiteList;

            whiteListIdMap[whiteList[i]]=whiteListIdMap[whiteList[i]]-1; // last element is whiteList.length-1
        }
    }

    // removeNoOrder not used, for reference only
    function removeNoOrder(uint index) private {
        whiteList[index]=whiteList[whiteList.length-1]; // replace the target element with the last element
        whiteList.pop(); // delete the last element
    }

    function removeInOrder(uint index) private {
        // address[] public whiteList;
        for (uint i=index; i<whiteList.length-1;i++){
            whiteList[index]=whiteList[index+1]; // replace the target element with the next element
        }
        whiteList.pop(); // delete the last element
    }

    // removeSingleWhiteListStatus without Id is NOT POSSIBLE, because not able to update whiteList
    function removeSingleWhiteListStatusWithId(address _address) public {
    // function removeWhiteListStatus(address _address) public onlyOwner {
        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        require(whiteList.length>0,"No more whitelisted user");

        // require(whitelistedAddress[_address] != false); 
        whitelistedAddress[_address] = false;

        _whitelist_mint_max[_address]=0;

        uint index = whiteListIdMap[_address]-1; // find the index in whiteList, minus 1 as starts with 1, not 0

        updateWhiteListIdMapAfterSingleRemove(index); // update whiteListIdMap first before whiteList
        
        whiteListIdMap[_address]=0; // remove Id from address map

        removeInOrder(index); // update whiteList

        emit RemoveWhitelisted(_address, false);
        
        // whiteList = new address[](0);
        // WhiteListData[] public _whiteListData;
        // _whiteListData = new WhiteListData[](0);
        // whiteListId=0;
                 
    }


    // function removeSingleWhiteListStatus(address _address) public {
    // // function removeWhiteListStatus(address _address) public onlyOwner {
    //     // replace onlyOwner with owner or admin
        
    //     require(whitelistedAddress[_address] != false);
    //     whitelistedAddress[_address] = false;

    //     // _whitelist_mint_max[msg.sender]=0;
    //     _whitelist_mint_max[_address]=0;

    //     emit Whitelisted(_address, false);
    // }

    function addSingleWhiteListUserWithLimitMint(address _address, uint256 _whitelist_limit_mint) public {
    // function addAndChangeWhiteListStatus(address _address) public onlyOwner {

        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        require(whitelistedAddress[_address] != true);
        whitelistedAddress[_address] = true;

        _whitelist_mint_max[_address]=_whitelist_limit_mint;

        // _whitelist_mint_max[_address]=max_whitelist_mint;

        whiteList.push(_address);
        
        emit Whitelisted(_address, true);

    }

        // if (_whitelist_mint_max[msg.sender]==0){
        //     _whitelist_mint_max[msg.sender]=max_whitelist_mint;
        // }

        // if (_whitelist_mint_max[_address]==0){
        //     _whitelist_mint_max[_address]=max_whitelist_mint;
        // }

    

    function addSingleWhiteListUserWithLimitMintWithId(address _address, uint256 _whitelist_limit_mint) public {
    // function addAndChangeWhiteListStatus(address _address) public onlyOwner {

        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        require(whitelistedAddress[_address] != true);
        whitelistedAddress[_address] = true;

        _whitelist_mint_max[_address]=_whitelist_limit_mint;

        // _whitelist_mint_max[_address]=max_whitelist_mint;

        whiteList.push(_address);

        whiteListId++;

        whiteListIdMap[_address]=whiteListId;
        
        emit Whitelisted(_address, true);
    
    }

        // if (_whitelist_mint_max[msg.sender]==0){
        //     _whitelist_mint_max[msg.sender]=max_whitelist_mint;
        // }

        // if (_whitelist_mint_max[_address]==0){
        //     _whitelist_mint_max[_address]=max_whitelist_mint;
        // }


    function editSingleWhiteListUserWithLimitMint(address _address, uint256 _whitelist_limit_mint) public {
    // function addAndChangeWhiteListStatus(address _address) public onlyOwner {

        // replace onlyOwner with owner or admin
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        require(whitelistedAddress[_address] == true);
        // whitelistedAddress[_address] = true;

        _whitelist_mint_max[_address]=_whitelist_limit_mint;

        emit SetWhiteListMintMaxSpecific(_address, _whitelist_limit_mint);
   
    }


    function mint(uint256 numberOfTokens) public payable {
    // function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        
        require(!paused);
        // add new, require(!paused);
        // require(saleIsActive, "Sale must be active to mint tokens");
        // require(publicSaleIsActive, "Public Sale must be active to mint tokens");

        // added new, !isWhiteListActive, either public sale or whitelist sale
        // require(!isWhiteListActive, "Whitelist Sale is active");

        
        // require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        // replace MAX_PUBLIC_MINT to mint_limit

        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(price_per_token * numberOfTokens <= msg.value, "Ether value sent is not correct");


        uint256 mint_limit;
        if (isWhiteListActive){
            require(whitelistedAddress[msg.sender], "Client is not on White list");
            // mint_limit=max_whitelist_mint;
            mint_limit=_whitelist_mint_max[msg.sender];
            _whitelist_mint_max[msg.sender] -= numberOfTokens;
        } else {
            mint_limit=max_public_mint;  
        }

        require(numberOfTokens <= mint_limit, "Exceeded max token purchase");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            
            //-----------------------------
            uint id = randomIndex();
            numTokens = numTokens + 1;
            //-----------------------------
            _safeMint(msg.sender, id);
            
            // _safeMint(msg.sender, ts + i);
            // tokenId change from ts + i, i.e. totalSupply()+i, to id

        }

        // payable(owner_address).transfer(price_per_token * numberOfTokens);

        (bool sent, ) = owner_address.call{value: msg.value}("");
        // (bool sent, ) = owner_address.call{value: price_per_token * numberOfTokens}("");

        require(sent, "Failed to send Ether");

        emit Minted(msg.sender, numberOfTokens);
    }

    function withdrawContractBalance() external {
    // function withdraw() public onlyOwner {
    // replace onlyOwner with owner
        require(msg.sender == owner_address,"Not Owner");
        uint balance = address(this).balance;
        // payable(msg.sender).transfer(balance);

        (bool sent, ) = owner_address.call{value: balance}("");
        // (bool sent, ) = owner_address.call{value: msg.value}("");
        
        require(sent, "Failed to send Ether");

    }
}