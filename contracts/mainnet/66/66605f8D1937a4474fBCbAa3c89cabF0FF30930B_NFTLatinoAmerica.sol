// SPDX-License-Identifier: MIT 
//                                                                                                     
//                                    @       @@   @@@@@@@  @@@@@@@@                                   
//                                    @@      @@   @@@@@@@  @@@@@@@@                                   
//                                    @@@     @@   @@          @@                                      
//                                    @@@@    @@   @@          @@                                      
//                                    @@@@@   @@   @@          @@                                      
//                                    @@@@@@  @@   @@@@@@      @@                                      
//                                    @@@@@@@@@@   @@@@@@      @@                                      
//                                    @@@  @@@@@   @@          @@                                      
//                                    @@@   @@@@   @@          @@                                      
//                                    @@@    @@@   @@          @@                                      
//                                    @@@     @@   @@          @@                                      
//                                    @@@      @   @@          @@                                      
//                                                                                                     
//                                                                                                     
//   @@       @@    @@@@@@ @@  @    @     @@@       @     @@     @@  @@@@  @@@@   @@    @@@     @@     
//   @@       @@    @@@@@@ @@  @    @   @@@@@@     @@@    @@@   @@@  @@@@  @@@@@  @@   @@@@@    @@     
//   @@      @@@@     @@   @@  @@   @   @@   @@    @@@    @@@   @@@  @     @   @  @@  @@       @@@@    
//   @@      @@@@     @@   @@  @@@  @  @@    @@    @ @@   @@@@ @@@@  @     @  @@  @@ @@        @@ @    
//   @@     @@  @     @@   @@  @@@@@@  @@     @   @@ @@   @@@@@@@@@  @@@@  @@@@@  @@ @@        @  @@   
//   @@     @@@@@@    @@   @@  @  @@@  @@    @@   @@@@@@  @@ @@@ @@  @     @@@@   @@ @@       @@@@@@   
//   @@     @@@@@@    @@   @@  @   @@   @@  @@@  @@@@@@@  @@ @@@ @@  @     @  @@  @@  @@      @@@@@@   
//   @@@@  @@    @@   @@   @@  @    @    @@@@@   @@    @  @@  @  @@  @@@@  @   @@ @@   @@@@@ @@    @@  
//                                                                                                     
//                                                                                                     
// A NFTLatinoAmerica Project

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol"; 
import "./Ownable.sol";
import "./SafeMath.sol";

/**
* @notice Using solidity 0.8.0 is not allowed notice on private elements, just regular coments we had to use.
*/
contract NFTLatinoAmerica is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable  {
 
    using SafeMath for *;
    using Strings for *;
    
    // The collection Name
    string private name_;
    
    // The collection Symbol
    string private symbol_; 
    
    // Initial minting price
    uint256 private minting_price_wei = 1 * 10 ** 18;
    
    // Used to start and pause the minting
    bool private switchMint;

    // Used to start and pause the Registering
    bool private switchRegister;
    
    // The initial NFTs base URI, data file gets the JSON with out extention
    string private initialBaseURI = "https://nftlatinoamerica.com/meta-data/data/";

    // Base extension, exmple: .json used when switch to IPFS
    string private baseExtension = ".json";

    // Base Image Uri to migrate to IPFS
    string private initialImageBaseURI = "";

    // Register Quantity 
    uint256[] private allRegister;

    /**
     * @notice Save the unique hash artistic name
     */
    struct unique_hash_name {
        bool unique;
    }
    
    // Mapping unique name
    mapping(bytes32 => unique_hash_name) private name_unique;

    /**
     * @notice Save the unique hash NFTL string
     */
    struct unique_hash {
        bool unique;
    }
    
    // Mapping Token unique hash
    mapping(bytes32 => unique_hash) private token_unique;
    
    // Mapping the base URI for any token Id
    mapping(uint256 => string) private tokenBaseURI;
    
    // Mapping the artistic name with the address
    mapping(string => address) private adreesArtisticName;

    /**
     * @notice Meta data extra information
     */
    struct tokenURI_st {
        string name;
        string description;
        uint256 resolution;
        uint256 colors_amount;
        string artisticName;
        bytes32 file;
        uint256 time;
    }
    
    // Mapping meta data extra information and the token Id
    mapping(uint256 => tokenURI_st) private token_info;

    /**
     * @notice Registered Users Information
     */
    struct infoRegistered {
        string artisticName;
        bool onSistem;
        uint256 nftFreeMint;
        bool active;
    }
    
    // Registered Users mapping
    mapping(address => infoRegistered) private registered;

    /**
    * @notice Filter only nft owners
    * @param _tokenId The token Id
    */
    modifier onlyNFTowner(uint256 _tokenId) {
        require(_msgSender() == ownerOf(_tokenId), unicode"Caller is not the NFT owner");
        _;
    }

    /**
     * @notice Filter only registered users
     */
    modifier onlyRegistered() {
        require(registered[_msgSender()].active == true, unicode'Only Registered and Activated users can mint in NFTLatinoAmerica Collection, if you are not registered Go to <strong>Register</strong>');
        _;
    }
    
    /**
    * @notice Emits an event when a token is mint
    * @param hash_str Special hash
    * @param tokenId The token Id
    * @param time The time
    * @param ctr The contract address
     */
    event NFT_mint(string hash_str, uint256 tokenId, uint256 time, address ctr); 

    /**
    * @notice Emits an event when an appoval is removed
    * @param removedAddres The address removed from appoved
    * @param tokenId The token Id
    */
    event removeApprove(address removedAddres, uint256 tokenId); // 

    /** 
    * @notice construct the name and the symbol of the NFTLatinoAmerica colection
    * @param _name The Collection name given
    * @param _symbol The Collection symbol given
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        name_ = _name;
        symbol_ = _symbol; 
        switchMint = false;
        switchRegister = false;
    }

    /** 
    * @notice Ask if an account is registered
    */
    function isRegistered(address _account) public view returns(bool register_){
        return registered[_account].onSistem;
    }

    /** 
    * @notice Start minting
    */
    function startMint() public onlyOwner {
        switchMint = true;
    }

    /** 
    * @notice Pause minting
    */
    function pauseMint() public onlyOwner {
        switchMint = false;
    }
    
    /** 
    * @notice View the minting state
    */
    function stateMint() public view returns(bool switchMint_){
        return switchMint;
    }

    /** 
    * @notice Start Registering
    */
    function startRegister() public onlyOwner {
        switchRegister = true;
    }

    /** 
    * @notice Pause Registering
    */
    function pauseRegister() public onlyOwner {
        switchRegister = false;
    }
    
    /** 
    * @notice View the register state
    */
    function stateRegister() public view returns(bool switchRegister_){
        return switchRegister;
    }

    /**
    * @notice Self Register
    * @param _artisticName The artistic name given
    */
    function selfRegister(string memory _artisticName) public {
        // requires the register activated
        require(stateRegister() == true, 'The Register process is paused, stay alert in our social media to know when we will activate it');
        // makes the _artisticName hash
        bytes32 name_hash = keccak256(abi.encodePacked(_artisticName));
        // obtains the information about if this artisticName
        bool is_unique = name_unique[name_hash].unique;
        // verifies if the artisticName has been created before
        require(is_unique == false, "The artisticName that you are trying to register is not available, Please try with another one");
        // verifies the wallet has been registered
        require(registered[_msgSender()].onSistem == false, unicode"You had already registered in NFTLatinoAmerica Collection");
        // verifies the artisticName length
        require(bytes(_artisticName).length <= 20, unicode"Your Artistic name is too long, up to 20 and more than 1 characters is allowed");
        // verifies the artisticName length
        require(bytes(_artisticName).length >= 2, unicode"Your Artistic name is too short, up to 20 and more than 1 characters is allowed");
        // register the artisticName
        registered[_msgSender()] = infoRegistered(_artisticName, true, 0, true);
        // sets the _artisticName hash as a unique inside the NFTLatinoAmerica Collection
        name_unique[name_hash].unique = true;
        // add one to the register array
        allRegister.push(allRegister.length + 1);
    }

    /**
    * @notice Only Owner will Register a new crypto Artist, this in case of filter only address verified avoiding the spam
    * @param _artisticName The artistic name given 
    * @param _artistAddress The artist address
    */
    function ownerRegister(address _artistAddress, string memory _artisticName) public onlyOwner {
        // makes the _artisticName hash
        bytes32 name_hash = keccak256(abi.encodePacked(_artisticName));
        // obtains the information about if this artisticName
        bool is_unique = name_unique[name_hash].unique;
        // verifies if the artisticName has been created before
        require(is_unique == false, "The artisticName that you are trying to register is not available, Please try with another one");
        // verifies the wallet has been registered
        require(registered[_artistAddress].onSistem == false, unicode"This address is already registered in NFTLatinoAmerica Collection");
        // verifies the artisticName length
        require(bytes(_artisticName).length <= 20, unicode"The Artistic name is too long, up to 20 and more than 1 characters is allowed");
        // verifies the artisticName length
        require(bytes(_artisticName).length >= 2, unicode"The Artistic name is too short, up to 20 and more than 1 characters is allowed");
        // register the artisticName
        registered[_artistAddress] = infoRegistered(_artisticName, true, 0, true);
        // sets the _artisticName hash as a unique inside the NFTLatinoAmerica Collection
        name_unique[name_hash].unique = true;
        // add one to the register array
        allRegister.push(allRegister.length + 1);
    }

    function allRegistered() public view returns(uint256 _allRegistered) {
        return allRegister.length;
    }

    /**
    * @notice Sets free mint tokens to any artist that deserves it
    * @param _artistAddress The artistic address given
    * @param _nftsFree NFTs free mint
    */
    function setFreeMint(address _artistAddress, uint256 _nftsFree) public onlyOwner {
        require(registered[_artistAddress].onSistem == true, unicode"This Artist is not Registered");
        require(registered[_artistAddress].active == true, unicode"This Artist is not Active");
        registered[_artistAddress].nftFreeMint = registered[_artistAddress].nftFreeMint + _nftsFree;
    }

    /**
    * @notice Self inactive to any artist that create span
    * @param _artistAddress The artistic address given
    * @param _stdo The state, false or true
    */
    function setInactiveArtist(address _artistAddress, bool _stdo) public onlyOwner {
        require(registered[_artistAddress].onSistem == true, unicode"This Artist is not Registered");
        registered[_artistAddress].active = _stdo;
    }

    /**
    * @notice Returns free mint tokens quantity of an account
    */
    function nftsFreeMint() public view returns(uint256 nftsFree) {
        return registered[_msgSender()].nftFreeMint;
    }

    /**
    * @notice Returns the artistic name of an account
    * @param _artistAddress The artistic address given
    */
    function myArtisticName(address _artistAddress) public view returns(string memory artisticName) {
        require(registered[_artistAddress].onSistem == true, unicode"This Artist is not Registered");
        return registered[_artistAddress].artisticName;
    }

    /**
    * @notice Returns the artistic name of an account
    * @param _artisticName The artistic name given
    */
    function myAccountByName(string memory _artisticName) public view returns(address account) {
        require(registered[adreesArtisticName[_artisticName]].onSistem == true, unicode"This Artist is not Registered");
        return adreesArtisticName[_artisticName];
    }

    /**
    * @notice Configure the NFT minting price 
    * @param _minting_price_Gwei New price in Gwei.
    */
    function Set_price_min_Gwei(uint256 _minting_price_Gwei) public onlyOwner {
        if (_minting_price_Gwei == 0 || _minting_price_Gwei < 0) {
            minting_price_wei = 0;
        }
        // convert Gwai to wei
        (bool stdo_mul, uint256 _minting_price_wei) = _minting_price_Gwei.tryMul(10**9);
        // verify the arithmetic
        require(stdo_mul == true, unicode"Invalid Arithmetic, enter a correct price");
        // set the minting price
        minting_price_wei = _minting_price_wei;
    }

    /**
    * @notice See price NFT minting in wei
    */
    function see_price_wei() public view returns(uint256 _minting_price_wei) {
        return minting_price_wei;
    }

    /**
    * @notice Mint a single NFT
    * @param _NFT_pixels The NFTLatinoAmerica special string obtained trought NFTLatinoAmerica.com, if represents the pixels ubication and colors at the same time
    * @param _name NFT name given by the NFT creator
    * @param _description NFT description given by the NFT creator
    * @param _resolution NFT resolution selected by the creator where the NFT_pixels was performed
    * @param _colorsAmount Colors amount used in the NFT
    */
    function safeMint(string memory _NFT_pixels, string memory _name, string memory _description, uint256 _resolution, uint256 _colorsAmount) public payable onlyRegistered {
        // requires the mint activated
        require(stateMint() == true, 'The minting is paused, stay alert in our social media to know when we will activate it');
        // makes the NFT Unique hashing the _NFT_pixels in a bytes32 variable
        bytes32 token_hash = keccak256(abi.encodePacked(_NFT_pixels));
        // obtains the information about if this token in unique
        bool is_unique = token_unique[token_hash].unique;
        // obtains the length of the string
        uint256 long_token = bytes(_NFT_pixels).length;
        // timestamp minting
        uint256 time = block.timestamp;
        // check the resolution of the NFT
        (bool a, uint256 b) = (_resolution*2).tryMul(_resolution);
        // requires name no more than 70 characters
        require(bytes(_name).length <= 70, "The characters amount in the name needs to be less than 70");
        // requires description no more than 160 characters
        require(bytes(_description).length <= 160, "The characters amount in the description needs to be less than 160");
        // requires no more than 200 colors and no less than 2 colors
        require(_colorsAmount <= 200 && _colorsAmount >= 2, "Incorrect Colors Amount");
        // requires just two kind of resolutions 24 and 35
        require(_resolution == 24 || _resolution == 35, unicode"Incorrect Resolution, you must create your NFT in NFTLatinoAmerica.com");
        // verifies the amount of pixels
        require(long_token == b && a == true, string(abi.encodePacked("The pixels are not correct")));
        // verifies if the token has been created before
        require(is_unique == false, "The NFT you are trying to mine has already been created");
        // sets the tokenId as the next totalSupply() adding one
        uint256 tokenId = totalSupply() + 1;
        // verifies if the account is free mint
        if(nftsFreeMint() < 1){
            // verifies the correct amount of MATICs sent by the transaction
            require(msg.value == minting_price_wei, unicode"Please send the correct amount of MATICs");
            // pay to admin
            payable(owner()).transfer(msg.value);
        }else if(nftsFreeMint() >= 1){
            // verifies the correct amount of MATICs sent by the transaction
            require(msg.value == 0, unicode"Please send the correct amount of MATICs");
            // subtract one from the nfts free mint
            registered[_msgSender()].nftFreeMint = registered[_msgSender()].nftFreeMint - 1;
        }else{
            require(true == false, "Error trying to read the free mint nfts inventory");
        }
        // mint the NFT in the NFTLatinoAmerica Collection
        _safeMint(_msgSender(), tokenId);
        // NFT file
        bytes32 file = keccak256(abi.encodePacked(_name, _description, _resolution.toString(), _colorsAmount.toString(), time.toString()));
        // safe the token URI
        tokenBaseURI[tokenId] = string(abi.encodePacked(initialBaseURI, toBytes32String(file), "/")); 
        // sets the NFT information inside the mapping token_info
        token_info[tokenId] = tokenURI_st(_name, _description, _resolution, _colorsAmount, registered[_msgSender()].artisticName, file, time); // guarda nombre y descripcion del token creado
        // sets the NFT hash as a unique token inside the NFTLatinoAmerica Collection
        token_unique[token_hash].unique = true; // guarda el hash del token el el struct
        // save the artistic name with the address
        adreesArtisticName[registered[_msgSender()].artisticName] = _msgSender();
        // sets the tokenURI internal 
        _setTokenURI(tokenId, _NFT_pixels);
        // emit an event showing that a NFT has been minted by the msgSender and its tokenId
        emit NFT_mint(toBytes32String(file), tokenId, time, address(this));
    }

    /**
    * @notice Delete the last address approved and reset it to zero address as the default
    * @param _tokenId The token Id
    */
    function removeApproved(uint256 _tokenId) public onlyNFTowner(_tokenId) {
        // gets the current approved address
        address oldApproved = getApproved(_tokenId);
        // verifies that exist a valid address approved
        require(address(0) != oldApproved, unicode"Your NFT had not been approved by another account");
        // sets the approved function to zero address in order to reset the approved function
        approve(address(0), _tokenId);
        // emits an event showing that an address has been remove to transfer any token Id
        emit removeApprove(oldApproved, _tokenId);
    }

    // Overrride the internal base URI
    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    /**
    * @notice  Sets the base URI if any change happens with the main domain, just the collection owner could modify it
    *            Warning the Minting has to be Paused mean while this process is updating
    * @param _new_baseURI The new base uri for all tokens example "ipfs://hash_data_folder/"
    * @param _imageBaseURI the new base Image Uri example: "ipfs://hash_img_folder/"
    */
    function setBaseURI(string memory _new_baseURI, string memory _imageBaseURI) public onlyOwner {
        // Sets the base URI for all Tokens, in case to move it to another server or domain
        for (uint256 i = 1; i <= totalSupply(); i++) {
            tokenBaseURI[i] = string(abi.encodePacked(_new_baseURI));
        }
        initialImageBaseURI = _imageBaseURI;
    }

    /**
    * @notice  Sets all base extension for metadata
    * @param _newBaseExtension The new base extension for all meta data, example .json
    */
    function setBaseExtention(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    /**
    * @notice  Overrride just internal
    * @param _tokenId The token Id
    */
    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(_tokenId);
    }

    /**
    * @notice Returns all the NFT information as a Json format, where include the 'img' whish is the canvas and javascript code to reconstruct the NFT using a HTML or PHP empty file and open it in a browser
    * @param _tokenId The token Id
    */
    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory extention;
        if(keccak256(abi.encodePacked(initialBaseURI, toBytes32String(token_info[_tokenId].file), "/")) == keccak256(abi.encodePacked(tokenBaseURI[_tokenId]))){
            // Coming from internal server, do not use extention
            extention = "";
        }else{
            // Coming from external server, may be use IPFS, it is set .json by default
            extention = baseExtension;
        }
        string memory token_uri = string(abi.encodePacked(tokenBaseURI[_tokenId], _tokenId.toString(), extention));
        return token_uri;
    }

    /**
    * @notice Returns all the NFT information as a Json format, where include the 'img' whish is the canvas and javascript code to reconstruct the NFT using a HTML or PHP empty file and open it in a browser
    * @param _tokenId The token Id
    */
    function jsonTokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory imageUri;
        if(keccak256(abi.encodePacked(initialBaseURI, toBytes32String(token_info[_tokenId].file), "/")) == keccak256(abi.encodePacked(tokenBaseURI[_tokenId]))){
            imageUri = string(abi.encodePacked("https://nftlatinoamerica.com/meta-data/images/", toBytes32String(token_info[_tokenId].file), "/"));
        }else{
            imageUri = initialImageBaseURI;
        }
        string memory token_uri_1 = string(abi.encodePacked('{"name":"', token_info[_tokenId].name, '",', '"description":"', token_info[_tokenId].description, '",', '"image":"', imageUri, _tokenId.toString(), '.png', '",', '"attributes": [{"trait_type": "Resolution", "value": "', (token_info[_tokenId].resolution*100).toString(), 'x', (token_info[_tokenId].resolution*100).toString(), '"},'));
        string memory token_uri_2 = string(abi.encodePacked(token_uri_1, '{"trait_type": "Colors Amount", "value": "', token_info[_tokenId].colors_amount.toString(), '"},', '{"trait_type": "Crypto Artist", "value": "', token_info[_tokenId].artisticName, '"},', '{"display_type": "date", "trait_type": "birthday", "value":"', token_info[_tokenId].time.toString(), '"}]', '}'));
        return token_uri_2;
    }

    /**
    * @notice Returns the canvas and javascript code in order to recreate the NFT in case of lose the main domain. introduce the code into a HTML or PHP empty file and open it in a browser or server and show the NFT image
    * @param _tokenId The token Id
    */
    function see_NFT_canva(uint256 _tokenId) public view returns(string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory str_1 = '<canvas id="CV" width="';
        string memory str_2 = '00" height="';
        string memory str_3 = '00" style="width: 500px;margin: 0 auto;display: flex;"></canvas><script>var cv=document.getElementById("CV"),res=parseInt(cv.attributes[1].value)/100,ctx=cv.getContext("2d"),cw=cv.width,NFT="';
        string memory str_4 = '",mtx="eyJBQSI6ImY5ZWJlYSIsIkFCIjoiZjJkN2Q1IiwiQUMiOiJlNmIwYWEiLCJBRCI6ImQ5ODg4MCIsIkFFIjoiY2Q2MTU1IiwiQUYiOiJjMDM5MmIiLCJBRyI6ImE5MzIyNiIsIkFIIjoiOTIyYjIxIiwiQUkiOiI3YjI0MWMiLCJBSiI6IjY0MWUxNiIsIkJBIjoiZmRlZGVjIiwiQkIiOiJmYWRiZDgiLCJCQyI6ImY1YjdiMSIsIkJEIjoiZjE5NDhhIiwiQkUiOiJlYzcwNjMiLCJCRiI6ImU3NGMzYyIsIkJHIjoiY2I0MzM1IiwiQkgiOiJiMDNhMmUiLCJCSSI6Ijk0MzEyNiIsIkJKIjoiNzgyODFmIiwiQ0EiOiJmNWVlZjgiLCJDQiI6ImViZGVmMCIsIkNDIjoiZDdiZGUyIiwiQ0QiOiJjMzliZDMiLCJDRSI6ImFmN2FjNSIsIkNGIjoiOWI1OWI2IiwiQ0ciOiI4ODRlYTAiLCJDSCI6Ijc2NDQ4YSIsIkNJIjoiNjMzOTc0IiwiQ0oiOiI1MTJlNWYiLCJEQSI6ImY0ZWNmNyIsIkRCIjoiZThkYWVmIiwiREMiOiJkMmI0ZGUiLCJERCI6ImJiOGZjZSIsIkRFIjoiYTU2OWJkIiwiREYiOiI4ZTQ0YWQiLCJERyI6IjdkM2M5OCIsIkRIIjoiNmMzNDgzIiwiREkiOiI1YjJjNmYiLCJESiI6IjRhMjM1YSIsIkVBIjoiZWFmMmY4IiwiRUIiOiJkNGU2ZjEiLCJFQyI6ImE5Y2NlMyIsIkVEIjoiN2ZiM2Q1IiwiRUUiOiI1NDk5YzciLCJFRiI6IjI5ODBiOSIsIkVHIjoiMjQ3MWEzIiwiRUgiOiIxZjYxOGQiLCJFSSI6IjFhNTI3NiIsIkVKIjoiMTU0MzYwIiwiRkEiOiJlYmY1ZmIiLCJGQiI6ImQ2ZWFmOCIsIkZDIjoiYWVkNmYxIiwiRkQiOiI4NWMxZTkiLCJGRSI6IjVkYWRlMiIsIkZGIjoiMzQ5OGRiIiwiRkciOiIyZTg2YzEiLCJGSCI6IjI4NzRhNiIsIkZJIjoiMjE2MThjIiwiRkoiOiIxYjRmNzIiLCJHQSI6ImU4ZjhmNSIsIkdCIjoiZDFmMmViIiwiR0MiOiJhM2U0ZDciLCJHRCI6Ijc2ZDdjNCIsIkdFIjoiNDhjOWIwIiwiR0YiOiIxYWJjOWMiLCJHRyI6IjE3YTU4OSIsIkdIIjoiMTQ4Zjc3IiwiR0kiOiIxMTc4NjQiLCJHSiI6IjBlNjI1MSIsIkhBIjoiZThmNmYzIiwiSEIiOiJkMGVjZTciLCJIQyI6ImEyZDljZSIsIkhEIjoiNzNjNmI2IiwiSEUiOiI0NWIzOWQiLCJIRiI6IjE2YTA4NSIsIkhHIjoiMTM4ZDc1IiwiSEgiOiIxMTdhNjUiLCJISSI6IjBlNjY1NSIsIkhKIjoiMGI1MzQ1IiwiSUEiOiJlOWY3ZWYiLCJJQiI6ImQ0ZWZkZiIsIklDIjoiYTlkZmJmIiwiSUQiOiI3ZGNlYTAiLCJJRSI6IjUyYmU4MCIsIklGIjoiMjdhZTYwIiwiSUciOiIyMjk5NTQiLCJJSCI6IjFlODQ0OSIsIklJIjoiMTk2ZjNkIiwiSUoiOiIxNDVhMzIiLCJKQSI6ImVhZmFmMSIsIkpCIjoiZDVmNWUzIiwiSkMiOiJhYmViYzYiLCJKRCI6IjgyZTBhYSIsIkpFIjoiNThkNjhkIiwiSkYiOiIyZWNjNzEiLCJKRyI6IjI4YjQ2MyIsIkpIIjoiMjM5YjU2IiwiSkkiOiIxZDgzNDgiLCJKSiI6IjE4NmEzYiIsIktBIjoiZmVmOWU3IiwiS0IiOiJmY2YzY2YiLCJLQyI6ImY5ZTc5ZiIsIktEIjoiZjdkYzZmIiwiS0UiOiJmNGQwM2YiLCJLRiI6ImYxYzQwZiIsIktHIjoiZDRhYzBkIiwiS0giOiJiNzk1MGIiLCJLSSI6IjlhN2QwYSIsIktKIjoiN2Q2NjA4IiwiTEEiOiJmZWY1ZTciLCJMQiI6ImZkZWJkMCIsIkxDIjoiZmFkN2EwIiwiTEQiOiJmOGM0NzEiLCJMRSI6ImY1YjA0MSIsIkxGIjoiZjM5YzEyIiwiTEciOiJkNjg5MTAiLCJMSCI6ImI5NzcwZSIsIkxJIjoiOWM2NDBjIiwiTEoiOiI3ZTUxMDkiLCJNQSI6ImZkZjJlOSIsIk1CIjoiZmFlNWQzIiwiTUMiOiJmNWNiYTciLCJNRCI6ImYwYjI3YSIsIk1FIjoiZWI5ODRlIiwiTUYiOiJlNjdlMjIiLCJNRyI6ImNhNmYxZSIsIk1IIjoiYWY2MDFhIiwiTUkiOiI5MzUxMTYiLCJNSiI6Ijc4NDIxMiIsIk5BIjoiZmJlZWU2IiwiTkIiOiJmNmRkY2MiLCJOQyI6ImVkYmI5OSIsIk5EIjoiZTU5ODY2IiwiTkUiOiJkYzc2MzMiLCJORiI6ImQzNTQwMCIsIk5HIjoiYmE0YTAwIiwiTkgiOiJhMDQwMDAiLCJOSSI6Ijg3MzYwMCIsIk5KIjoiNmUyYzAwIiwiT0EiOiJmZGZlZmUiLCJPQiI6ImZiZmNmYyIsIk9DIjoiZjdmOWY5IiwiT0QiOiJmNGY2ZjciLCJPRSI6ImYwZjNmNCIsIk9GIjoiZWNmMGYxIiwiT0ciOiJkMGQzZDQiLCJPSCI6ImIzYjZiNyIsIk9JIjoiOTc5YTlhIiwiT0oiOiI3YjdkN2QiLCJQQSI6ImY4ZjlmOSIsIlBCIjoiZjJmM2Y0IiwiUEMiOiJlNWU3ZTkiLCJQRCI6ImQ3ZGJkZCIsIlBFIjoiY2FjZmQyIiwiUEYiOiJiZGMzYzciLCJQRyI6ImE2YWNhZiIsIlBIIjoiOTA5NDk3IiwiUEkiOiI3OTdkN2YiLCJQSiI6IjYyNjU2NyIsIlFBIjoiZjRmNmY2IiwiUUIiOiJlYWVkZWQiLCJRQyI6ImQ1ZGJkYiIsIlFEIjoiYmZjOWNhIiwiUUUiOiJhYWI3YjgiLCJRRiI6Ijk1YTVhNiIsIlFHIjoiODM5MTkyIiwiUUgiOiI3MTdkN2UiLCJRSSI6IjVmNmE2YSIsIlFKIjoiNGQ1NjU2IiwiUkEiOiJmMmY0ZjQiLCJSQiI6ImU1ZThlOCIsIlJDIjoiY2NkMWQxIiwiUkQiOiJiMmJhYmIiLCJSRSI6Ijk5YTNhNCIsIlJGIjoiN2Y4YzhkIiwiUkciOiI3MDdiN2MiLCJSSCI6IjYxNmE2YiIsIlJJIjoiNTE1YTVhIiwiUkoiOiI0MjQ5NDkiLCJTQSI6ImViZWRlZiIsIlNCIjoiZDZkYmRmIiwiU0MiOiJhZWI2YmYiLCJTRCI6Ijg1OTI5ZSIsIlNFIjoiNWQ2ZDdlIiwiU0YiOiIzNDQ5NWUiLCJTRyI6IjJlNDA1MyIsIlNIIjoiMjgzNzQ3IiwiU0kiOiIyMTJmM2MiLCJTSiI6IjFiMjYzMSIsIlRBIjoiZWFlY2VlIiwiVEIiOiJkNWQ4ZGMiLCJUQyI6ImFiYjJiOSIsIlREIjoiODA4Yjk2IiwiVEUiOiI1NjY1NzMiLCJURiI6IjJjM2U1MCIsIlRHIjoiMjczNzQ2IiwiVEgiOiIyMTJmM2QiLCJUSSI6IjFjMjgzMyIsIlRKIjoiMTcyMDJhIn0",mxd=JSON.parse(atob(unescape(encodeURIComponent(mtx)))),ch=cv.height,gpx=ctx.getImageData(0,0,res,res),cnt=0,cls="",c=0,y=0,x=0;for(let I=0;I<NFT.length;I++){const i=NFT[I];cnt<2&&(cls+=i,cnt++),2===cnt&&(ctx.fillStyle="#"+mxd[cls],ctx.fillRect(x,y,100,100),x===100*res-100?(x=0,y+=100):x+=100,cls="",cnt=0)}</script>';
        string memory resol = token_info[_tokenId].resolution.toString();
        string memory canvas = string(abi.encodePacked(str_1, resol, str_2, resol, str_3, super.tokenURI(_tokenId), str_4));
        return canvas;
    }

    /**
    * @notice Returns the NFTLatinoAmerica special codification string in order to be decoded by NFTLatinoAmerica.com and show the NFT as a canva image
    * @param _tokenId The token Id
    */
    function see_NFT_str(uint256 _tokenId) public view returns(string memory) {        
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return super.tokenURI(_tokenId);
    }

    /**
     * @dev Returns a token array owned by a given address. Mainly for ease for frontend devs.
     * @param _address The address to get the tokens of.
     */
    function addressOfOwner(address _address) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_address);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokensId;
    }

    /**
     * @dev Returns the address string
     * @param _hash_st The bytes32 to convert to string.
     */
    function toBytes32String(bytes32 _hash_st) internal pure returns (string memory) {
        bytes memory s = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            bytes1 b = bytes1(_hash_st[i]);
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked('0x', s));
    }

    /**
     * @dev Returns the address string
     * @param _address The address to convert to string.
     */
    function toAsciiString(address _address) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_address)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked('0x', s));
    }

    /**
     * @dev Returns bytes converted
     * @param _b bytes1
     */
    function char(bytes1 _b) internal pure returns (bytes1 c) {
        if (uint8(_b) < 10) return bytes1(uint8(_b) + 0x30);
        else return bytes1(uint8(_b) + 0x57);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId); 
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) { 
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }
}