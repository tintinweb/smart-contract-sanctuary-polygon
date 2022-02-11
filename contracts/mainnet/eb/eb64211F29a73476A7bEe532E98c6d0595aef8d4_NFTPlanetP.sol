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
//
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
contract NFTPlanetP is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable  {

    using SafeMath for *;
    using Strings for *;

    // The collection Name
    string private name_;

    // The collection Symbol
    string private symbol_; 

    // Initial minting price
    uint256 private minting_price_wei = 30 * 10 ** 18;

    // Visual studio, developers, and Admin
    address[] adminsOwnersDevs = 
        [
            0x2e9c6290C571392C6533Ae4e0b18e491D9D9684d, 
            0x119C701D12BCD5cB500a4671281B1c0BaE69C45e, 
            0x5af589c9004862d31431D9e645F7e2c30483E319, 
            0x2724D3c36e1f54f64f33540AC4ca431B34508814  
        ];

    // Used to start and pause the minting whitelist
    bool private switchMintWhite;

    // Used to start and pause the minting sale presale
    bool private switchMintPreSale;

    // Used to start and pause the registering whitelist
    bool private switchRegister;

    /** 
    * @notice Max NFT per mint at a time, 5 was fine
    */
    uint256 public maxMintAmount = 3;

    /** 
    * @notice Max amount own per wallet at a time
    */
    uint256 public maxAmountWallet = 10;

    /** 
    * @notice Max amount registered on whitelist
    */
    uint256 public maxAmountWhiteList = 250;
    
    // The initial NFTs base URI ipfs, format ipfs://hash_uri/
    string private initialBaseURI = "";

    // Base extension, exmple: .json, used when switch to IPFS
    string private baseExtension = ".json"; 

    // Register whitelist Quantity
    uint256[] private allRegister;

    // To get a random number generator for mint a NFT
    uint256 private randNonceMint = 0;

    // To get a random number generator for the winner award
    uint256 private randNonceWinner = 0;

    // Amount counter awards
    uint256 private giveAwardsCounter = 0;

    /** 
    * @notice Max supply, will be set by the constructor
    */
    uint256 public maxSupply;

    // Array TokenId minted by the community
    uint256[] private tokensMint;

    // Addresses into the raflle array
    address[] private arrayRaffle;

    // Array TokenId available NO minted yet
    uint256[] private tokensNoMint; 

    // Registered whitelist information
    struct infoRegistered { 
        bool bought; 
        bool active;
    }

    // Registered whitelist mapping
    mapping(address => infoRegistered) private registered;


    // Data winners
    struct dataWinners{
        address winner;
        uint256 amount;
        uint256 time;
    }

    // Array address of Awards given
    dataWinners [] awardsGiven;

    /**
    * @notice Filter by only nft owners
    * @param _tokenId The token Id
    */
    modifier onlyNFTowner(uint256 _tokenId) {
        // Require that the caller is the token owner
        require(_msgSender() == ownerOf(_tokenId), unicode"Caller is not the NFT owner");
        _;
    }

    /**
    * @notice Filter by only registered whitelist
    */
    modifier onlyRegistered() {
        // Require that the wallet is on the whitelist
        require(registered[_msgSender()].active == true, unicode'Only Registered on whitelist can mint a NFTPlanetP');
        _;
    }

    /**
    * @notice Filter only registered whitelist
    */
    modifier onlySalePreSale() {
        // Require that the presale or sale is active
        require(switchMintPreSale == true, unicode'The minting is paused, stay alert in our social media to know when we will activate it');
        _;
    }

    /**
    * @notice Emits an event when an awards is given
    * @param winner The winner of the awards
    * @param awardAmount The award Amount
    * @param time The time 
    */
    event winner_award(address winner, uint256 awardAmount, uint256 time);

    /**
    * @notice Emits an event when an appoval is removed
    * @param removedAddres The address removed from appoved
    * @param tokenId The token Id
    */
    event removeApprove(address removedAddres, uint256 tokenId); // 

    /**
    * @notice Emits an event someone win the pote
    * @param random The token id winner
    * @param winner The address winner
    */
    event winnerPote(uint256 random, address winner);

    /** 
    * @notice construct the name and the symbol of the NFTPlanetP colection
    * @param _name The Collection name given
    * @param _symbol The Collection symbol given
    */
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) ERC721(_name, _symbol) {
        name_ = _name;
        symbol_ = _symbol; 
        maxSupply = _maxSupply;
        switchRegister = false; // para pruebas debe ser false en produccion
        switchMintWhite = false; // para pruebas debe ser false en produccion
        switchMintPreSale = false;
    }

    /** 
    * @notice Upload the tokens No minted initially into the an array, it is made before to mint the collection.
    */
    function uploadTokensNoMint(uint _qty) public onlyOwner {
        uint256 qtyNoMint = tokensNoMint.length;
        require((qtyNoMint + _qty) <= maxSupply, "The quantity exceed the maxSupply");
        require(((qtyNoMint + _qty) + tokensMint.length) <= maxSupply, "The array is full_");
        require(qtyNoMint <= maxSupply, "The array is _full");
        for (uint i = qtyNoMint; i < qtyNoMint + _qty; i++) { 
            tokensNoMint.push(i+1);
        }
    }

    /** 
    * @notice Ask if an account if it is registered on the whitelist
    */
    function isRegistered(address _account) public view returns(bool register_){
        return registered[_account].active;
    }

    /** 
    * @notice Start minting on the whitelist
    */
    function startMintWhite() public onlyOwner {
        switchMintWhite = true;
    }

    /** 
    * @notice Pause minting on the whitelist
    */
    function pauseMintWhite() public onlyOwner {
        switchMintWhite = false;
    }
    
    /** 
    * @notice View the minting state of the whitelist
    */
    function stateMintWhite() public view returns(bool switchMintWhite_){
        return switchMintWhite;
    }

    /** 
    * @notice Start minting sale and presale
    */
    function startMintPreSale() public onlyOwner {
        switchMintPreSale = true;
    }

    /** 
    * @notice Pause minting sale and presale
    */
    function pauseMintPreSale() public onlyOwner {
        switchMintPreSale = false;
    }
    
    /** 
    * @notice View the minting state of the sale and presale
    */
    function stateMintPreSale() public view returns(bool switchMintPreSale_){
        return switchMintPreSale;
    }

    /** 
    * @notice Start registering on the whitelist
    */
    function startRegister() public onlyOwner {
        switchRegister = true;
    }

    /** 
    * @notice Pause registering on the whitelist
    */
    function pauseRegister() public onlyOwner {
        switchRegister = false;
    }
    
    /** 
    * @notice View the register whitelist state
    */
    function stateRegister() public view returns(bool switchRegister_){
        return switchRegister;
    }

    /** 
    * @notice Sets the max amount to mint per transaction at a time
    */
    function setMaxMintAmount(uint256 _new_maxMintAmount) public onlyOwner {
        maxMintAmount = _new_maxMintAmount;
    }

    /** 
    * @notice Sets the max amount own per wallet at a time
    */
    function setMaxAmountWallet(uint256 _new_maxAmountWallet) public onlyOwner {
        maxAmountWallet = _new_maxAmountWallet;
    }

    /**
    * @notice Self register on whitelist by anyone that want to do it
    */
    function selfRegister() public {
      // requires thet the register process is activated
      require(stateRegister() == true, 'The Register on the NFTPlanetP whitelist is paused, stay alert in our social media to know when we will activate it');
      // verifies if the whitelist is full
      require(allRegister.length < maxAmountWhiteList, "The whitelist is full try to buy in the presale"); 
      // verifies thet the wallet has been registered
      require(registered[_msgSender()].active == false, unicode"You had already registered on the NFTPlanetP whitelist"); 
      // fills in the information into the mapping
      registered[_msgSender()] = infoRegistered(false, true); 
      // add one to the register array
      allRegister.push(allRegister.length + 1);
    }

    /**
    * @notice Only the collection Owner could register a new whitelist address
    * @param _addressWhite The user address
    */
    function ownerRegister(address _addressWhite) public onlyOwner {
      // verifies if the whitelist is full
      require(allRegister.length < maxAmountWhiteList, "The whitelist is full try to buy in the presale");
      // verifies if the wallet has been registered
      require(registered[_addressWhite].active == false, unicode"This address is already registered on the NFTPlanetP whitelist"); 
      // fills in the information into the mapping
      registered[_addressWhite] = infoRegistered(false, true); 
      // add one to the register array
      allRegister.push(allRegister.length + 1);
    }

    /**
    * @notice Gets the register address amount on the whitelist
    */
    function allRegistered() public view returns(uint256 _allRegistered) {
        return allRegister.length;
    } 

    /**
    * @notice Change the NFT minting price 
    * @param _minting_price_Gwei New price in Gwei.
    */
    function Set_price_min_Gwei(uint256 _minting_price_Gwei) public onlyOwner {
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
    * @notice Mint NFTs on the whitelist
    */
    function safeMintWhiteList() public payable onlyRegistered {
        // verifies that the caller does not buy a NFT before on whitelist
        require(registered[_msgSender()].bought == false, "You have already bought a NFTP on whitelist");
        // cheks the maxSupply and the amount to mint
        require(totalSupply() + 1 <= maxSupply, "Purchase exceed the max supply of NFTP");
        // requires that the minting is activated
        require(stateMintWhite() == true, "The minting whitelist is paused, stay alert in our social media to know when we will activate it");
        // verifies if the wallet owns no more that the maximum allowed 
        require((addressOfOwner(_msgSender()).length + 1) <= maxAmountWallet, string(abi.encodePacked("You can only own ", maxAmountWallet.toString(), " NFT per wallet")));
        // calc the value of the purchase
        uint256 value = minting_price_wei;
        // verifies the correct amount of MATICs sent by the transaction
        require(msg.value == value, "Please send the correct amount of MATICs");
        // Obtaining the calc One to get the percentage base
        (bool stdo_calc, uint256 calcOne) = value.tryDiv(100);
        // Obtaining the payment distribution percentage to obtain the 50% of the value
        (bool stdo_shares, uint256 amountShares) = calcOne.tryMul(50);
        // Obtaining the payment distribution percentage to obtain the 10% of the value
        (bool stdo_sharesSocial, uint256 amountSharesSocial) = calcOne.tryMul(10);
        // giveAway gets the 40% into the contract
        (bool stdo_sub, uint256 giveAway) =  value.trySub(amountShares.add(amountSharesSocial));
        // Security filters
        require(stdo_calc && stdo_shares && stdo_sharesSocial && stdo_sub && giveAway.add(amountShares.add(amountSharesSocial)) == value, unicode"Invalid Arithmetic Shares");
        // Transfer to social mendia account
        payable(0xA2cd6519E975b4251CF678E85b5405dDc08491e5).transfer(amountSharesSocial);
        // time 
        uint256 time = block.timestamp;
        // pay to visual studio, developers, and Admin
        for (uint i = 0; i < adminsOwnersDevs.length; i++) {
            // Obtaining the payment distribution
            (bool stdo_share, uint256 amountShare) = amountShares.tryDiv(adminsOwnersDevs.length);
            // Security filters
            require(stdo_share == true, unicode"Invalid Arithmetic Share");
            // transfer the matic to the acounts
            payable(adminsOwnersDevs[i]).transfer(amountShare);
        }
        // Select random index tokenId array
        uint256 indexRandom = uint(keccak256(abi.encodePacked(time, msg.sender, randNonceMint))) % tokensNoMint.length;
        randNonceMint++;
        // token id random by the array index
        uint256 tokenId = tokensNoMint[indexRandom];
        // mint the NFT
        _safeMint(_msgSender(), tokenId);
        // Sets the tokenURI
        _setTokenURI(tokenId, _baseURI()); 
        // Iclude the tokenId sleected by random into the tokensMint
        tokensMint.push(tokenId);
        // Iclude the address into the raflle
        arrayRaffle.push(_msgSender());
        // Place the key selected by random to the end in order to delete from the NO mint array
        tokensNoMint[indexRandom] = tokensNoMint[tokensNoMint.length - 1];
        // Delete the last key in the tokensNoMint array because it was already minted by random
        tokensNoMint.pop();
        // Sets the buyer as true
        registered[_msgSender()].bought = true;
        // Start Gifts
        // Give away the awards. Conditional that give the award each 10 parts of the maxSupply minted 
        // Example: for each 250 NFTP minted in case of 5000 totalSupply there are 20 gifts. 
        if(tokensMint.length == ((maxSupply / 20) * (giveAwardsCounter + 1))){
            // Amount award each 250
            giveAwardsCounter++;
            // Awaards amount
            uint256 awardAmount = address(this).balance;
            // Obtaining the payment distribution betwen 5
            (bool stdo_share, uint256 amountShareAward) = awardAmount.tryDiv(5);
            // Security filters
            require(stdo_share == true, unicode"Invalid Arithmetic Share");
            // Paying the awards
            for (uint256 i = 0; i < 5; i++) {
                // Obtains a random number betwent zero to tokensMint.length
                uint256 indexWinner = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonceWinner))) % arrayRaffle.length;
                randNonceWinner++;
                // obtains the address winner into the raffle array
                address winner = arrayRaffle[indexWinner];
                // transfer the matic to the address winner
                payable(winner).transfer(amountShareAward);
                // add the winner to the array
                awardsGiven.push(dataWinners(winner,  amountShareAward, block.timestamp));
                // Place the key selected by random to the end in order to delete from the array
                arrayRaffle[indexWinner] = arrayRaffle[arrayRaffle.length - 1];
                // Delete the last key in the arrayRaffle array because it was already won the raffle
                arrayRaffle.pop();
                // emits an event showing the winner, the amount won and the time unix
                emit winner_award(winner, amountShareAward, block.timestamp);
            }
        }
        // End Gifts
    } 

    /**
    * @notice Mint NFTs
    * @param _mintAmount The NFT quantity per mint for presale or sale
    */
    function safeMintSalePreSale(uint256 _mintAmount) public payable onlySalePreSale {
        // cheks the maxSupply and the amount to mint
        require(totalSupply() + _mintAmount <= maxSupply, "Purchase exceed the max supply of NFTP");
        // verifies if the amount to mint is not more than the allowed
        require(_mintAmount <= maxMintAmount, string(abi.encodePacked("You can only mint ", maxMintAmount.toString(), " NFT per transaction")));
        // verifies if the wallet owns no more that the maximum allowed
        require((addressOfOwner(_msgSender()).length + _mintAmount) <= maxAmountWallet, string(abi.encodePacked("You can only own ", maxAmountWallet.toString(), " per wallet")));
        // verifies that the amount to mint is more than zero
        require(_mintAmount > 0, "You need to mint at least one NFT");
        // calc the value of the purchase
        uint256 value = minting_price_wei * _mintAmount;
        // verifies the correct amount of MATICs sent by the transaction
        require(msg.value == value, "Please send the correct amount of MATICs");
        // Obtaining the calc One to get the percentage base
        (bool stdo_calc, uint256 calcOne) = value.tryDiv(100);
        // Obtaining the payment distribution percentage to obtain the 50% of the value
        (bool stdo_shares, uint256 amountShares) = calcOne.tryMul(50);
        // Obtaining the payment distribution percentage to obtain the 10% of the value
        (bool stdo_sharesSocial, uint256 amountSharesSocial) = calcOne.tryMul(10);
        // giveAway gets the 40% into the contract
        (bool stdo_sub, uint256 giveAway) =  value.trySub(amountShares.add(amountSharesSocial));
        // Security filters
        require(stdo_calc && stdo_shares && stdo_sharesSocial && stdo_sub && giveAway.add(amountShares.add(amountSharesSocial)) == value, unicode"Invalid Arithmetic Shares");
        // Transfer to social mendia account
        payable(0xA2cd6519E975b4251CF678E85b5405dDc08491e5).transfer(amountSharesSocial);
        // time 
        uint256 time = block.timestamp;
        // pay to visual studio, developers, and Admin
        for (uint i = 0; i < adminsOwnersDevs.length; i++) {
            // Obtaining the payment distribution
            (bool stdo_share, uint256 amountShare) = amountShares.tryDiv(adminsOwnersDevs.length);
            // Security filters
            require(stdo_share == true, unicode"Invalid Arithmetic Share");
            // transfer the matic to the acounts
            payable(adminsOwnersDevs[i]).transfer(amountShare);
        }
        // Perform the minting using random process
        for (uint256 i = 0; i < _mintAmount; i++) {
            // Select random index tokenId array
            uint256 indexRandom = uint(keccak256(abi.encodePacked(time, msg.sender, randNonceMint))) % tokensNoMint.length;
            randNonceMint++;
            // token id random by the array index
            uint256 tokenId = tokensNoMint[indexRandom];
            // mint the NFT
            _safeMint(_msgSender(), tokenId);
            // Sets the tokenURI
            _setTokenURI(tokenId, _baseURI()); 
            // Iclude the tokenId sleected by random into the tokensMint
            tokensMint.push(tokenId);
            // Iclude the address into the raflle
            arrayRaffle.push(_msgSender());
            // Place the key selected by random to the end in order to delete from the NO mint array
            tokensNoMint[indexRandom] = tokensNoMint[tokensNoMint.length - 1];
            // Delete the last key in the tokensNoMint array because it was already minted by random
            tokensNoMint.pop();
            // Start Gifts
            // Give away the awards. Conditional that give the award each 10 parts of the maxSupply minted 
            // Example: for each 250 NFTP minted in case of 5000 totalSupply there are 20 gifts. 
            if(tokensMint.length == ((maxSupply / 20) * (giveAwardsCounter + 1))){
                // Amount award each 250
                giveAwardsCounter++;
                // Awaards amount
                uint256 awardAmount = address(this).balance;
                // Obtaining the payment distribution betwen 5
                (bool stdo_share, uint256 amountShareAward) = awardAmount.tryDiv(5);
                // Security filters
                require(stdo_share == true, unicode"Invalid Arithmetic Share");
                // Paying the awards
                for (uint256 ix = 0; ix < 5; ix++) {
                    // Obtains a random number betwent zero to tokensMint.length
                    uint256 indexWinner = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonceWinner))) % arrayRaffle.length;
                    randNonceWinner++;
                    // obtains the address winner into the raffle array
                    address winner = arrayRaffle[indexWinner];
                    // transfer the matic to the address winner
                    payable(winner).transfer(amountShareAward);
                    // add the winner to the array
                    awardsGiven.push(dataWinners(winner,  amountShareAward, block.timestamp));
                    // Place the key selected by random to the end in order to delete from the array
                    arrayRaffle[indexWinner] = arrayRaffle[arrayRaffle.length - 1];
                    // Delete the last key in the arrayRaffle array because it was already won the raffle
                    arrayRaffle.pop();
                    // emits an event showing the winner, the amount won and the time unix
                    emit winner_award(winner, amountShareAward, block.timestamp);
                }
            }
            // End Gifts
        }
    }

    /**
    * @notice Give awards accumulated into the contract, This function withdraw the amount of matic to any random addresses into the arrayRaffle
    *         It is recommended to pasuse the minting when this function is deployed
    * @param _winnerAmount Winner Amounts to share the accummulated
    */
    function giveAwardsManually(uint256 _winnerAmount) public payable onlyOwner {
        // Awaards amount
        uint256 awardAmount = address(this).balance;
        // Obtaining the payment distribution
        (bool stdo_share, uint256 amountShare) = awardAmount.tryDiv(_winnerAmount);
        // Security filters
        require(stdo_share == true, unicode"Invalid Arithmetic Share");
        // Paying the awards
        for (uint256 i = 0; i < _winnerAmount; i++) {
            // Obtains a random number betwent zero to (tokensMint.length-1)
            uint256 indexWinner = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonceWinner))) % arrayRaffle.length;
            randNonceWinner++;
            // obtains the address winner into the raffle array
            address winner = arrayRaffle[indexWinner];
            // transfer the matic to the address winner
            payable(winner).transfer(amountShare);
            // add the winner to the array
            awardsGiven.push(dataWinners(winner,  amountShare, block.timestamp));
            // Place the key selected by random to the end in order to delete from the array
            arrayRaffle[indexWinner] = arrayRaffle[arrayRaffle.length - 1];
            // Delete the last key in the arrayRaffle array because it was already won the raffle
            arrayRaffle.pop();
            // emits an event showing the winner, the amount won and the time unix
            emit winner_award(winner, amountShare, block.timestamp);
        }
    }

    /**
    * @notice Gets the token quantity no minted
    */
    function remainsToMint() public view returns(uint256 remain_){
        return tokensNoMint.length;
    }

    /**
    * @notice Gets the token quantity minted
    */
    function remainsMinted() public view returns(uint256 remain_){
        return tokensMint.length;
    }

    /**
    * @notice Gets the tokenId No minted by index
    * @param _index The index token Id
    */
    function tokensNoMintByIndex(uint256 _index) public view returns(uint256 tokenId_){
        return tokensNoMint[_index];
    }

    /**
    * @notice Gets the tokenId minted by index
    * @param _index The index token Id
    */
    function tokensMintByIndex(uint256 _index) public view returns(uint256 tokenId_){
        return tokensMint[_index];
    }

    /**
    * @notice Gets the winners awards array
    */
    function winnersAward() public view returns(dataWinners [] memory){
        return awardsGiven;
    }

    /**
    * @notice Gets the balance of the award accumulated into the contract
    */
    function balanceGiveAway() public view returns(uint256 _balance) {
        return address(this).balance;
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
    * @param _new_baseURI The new base uri for all tokens example "ipfs://hash_data_folder/" 
    */
    function setBaseURI(string memory _new_baseURI) public onlyOwner {
        // Sets the base URI for all Tokens, in case to move it to another server, domain or ipfs
        initialBaseURI = _new_baseURI;
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
    * @notice Returns all the NFT information as a Json format
    * @param _tokenId The token Id
    */
    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return string(abi.encodePacked(initialBaseURI, _tokenId.toString(), baseExtension));
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