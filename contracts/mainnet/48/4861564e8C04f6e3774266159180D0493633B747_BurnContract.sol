/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
  * HPC Cards Burn Process:
  *
  * 1. ✓ Get `TokenIds` to burn in entry and `mintAddress`
  * 2. ✓ Verify that the tokens are HPC tokens and call burn function
  * 3. ✓ For each token, try to send. It will fail if token already sent or not owned by caller, if it's ok, add to allow list.
  * 4. ✓ A getter function permit to know which address are allowed, and check the slots for each address
  *
  * NB. ✓ At any point, the burn process can be paused or restarted
  */

/**
  * @dev Abstract contract for the functions used on NFT NYC contracts.
  * 
  * `safeTransferFrom`: used to transfer the assets to `burning` address.
  * `batchId`: used to verify the token `batchIds` to check if it is HPC assets.
  */
abstract contract NFTNYCSwags {
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
    function batchId(uint256 tokenId) public virtual pure returns (uint32);
}

/**
  * @dev Contract to `burn` the HPC cards of user.
  *
  * By calling the burn function, the sender will be added to a whitelist to mint the card counterpart on Ethereum.
  */
contract BurnContract {

    /**
      * @dev Main addresses used in the contract.
      *
      * owner: Ownest deployer address
      * burnAddress: `Burn` address were the asset are sent when `burnt`
      * NFTSwagsAddress: NFT NYC swags contract address on Polygon
      */
    address owner;
    address burnAddress = 0xF3ad5b5d88D864559ad12E4D9B19c4F8B346c465;
    address NFTSwagsAddress = 0xB41660b91C8EBC19fFe345726764D4469a4Ab9F8;

    // `Boolean`to start/stop burning process.
    bool isBurning = true;
 
    // Array of all addresses than were added for the mint
    address[] allowedToMint;
    mapping (address => bool) addressesRegistered;

    // List of HPC boxes and SwagBoxes available to mint by address
    struct MintsAllowed {
        uint hpcclaimcards;
        uint swagboxcards;
    }
    mapping (address => MintsAllowed) mints;
    
    // NFT NYC Swag contract object
    NFTNYCSwags nftnyc = NFTNYCSwags(NFTSwagsAddress);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
      * @dev Getter function to check for what an address is allowed to mint.
      */
    function getMintableBy(address tokenHolder) public view returns(uint hpcAllowed, uint swagboxAllowed){
        hpcAllowed = mints[tokenHolder].hpcclaimcards;
        swagboxAllowed = mints[tokenHolder].swagboxcards;
    }

    /**
      * @dev Getter function to check which addresses are allowed to mint.
      */
    function getAllowedAddresses() public view returns(address[] memory){
        return allowedToMint;
    }

    /**
      * @dev Main caller function of the contract. Burn a set of `NFTNYCCards` for allowed `mintAddress`
      *
      * The function will create two arrays for HPC Claim Cards and Swagbox Cards and fill these arrays with cards when batchID is matching.
      */
    function burn(address mintAddress, uint[] memory NFTNYCCards) public {
        uint[] memory hpcclaimcards = new uint[](NFTNYCCards.length);
        uint[] memory swagboxcards = new uint[](NFTNYCCards.length);

        for (uint i = 0; i < NFTNYCCards.length; i++) {
            uint batchID = getBatchId(NFTNYCCards[i]);

            if (batchID == 204384){
                hpcclaimcards[i] = NFTNYCCards[i];
            }
            if (batchID == 5201699){
                swagboxcards[i] = NFTNYCCards[i];
            }
        }

        emit LogArray(hpcclaimcards);
        emit LogArray(swagboxcards);

        burnHPC(mintAddress, hpcclaimcards, swagboxcards);
    }

    /**
      * @dev Getter function to check the batchId on NFT NYC Contract
      */
    function getBatchId(uint256 currentID) internal view returns (uint32 batchId) {
        return nftnyc.batchId(currentID);
    }

    /**
      * @dev Calling burn function for each cards and registering the address as allowed minter.
      */
    function burnHPC(address mintAddress, uint[] memory hpcclaimcards, uint[] memory swagboxcards) internal {
        require(isBurning);

    	for (uint i = 0; i < hpcclaimcards.length; i++) {
            if(hpcclaimcards[i] != 0){
                _burnHPCCard(mintAddress, hpcclaimcards[i]);
            }
        }
        for (uint i = 0; i < swagboxcards.length; i++) {
            if(swagboxcards[i] != 0){
                _burnSwagboxCard(mintAddress, swagboxcards[i]);
            }
        }

        if (addressesRegistered[mintAddress] == false){
            addressesRegistered[mintAddress] = true;
            registerAddress(mintAddress);
        }
    }

    /**
      * @dev Burn an HPC Card
      */
    function _burnHPCCard(address tokenHolder, uint tokenID) internal {
        transfer(tokenHolder, tokenID, true);
    }

    /**
      * @dev Burn an Swagbox Card
      */
    function _burnSwagboxCard(address tokenHolder, uint tokenID) internal {
        transfer(tokenHolder, tokenID, false);
    }

    /**
      * @dev Transfer from `tokenHolder` to `burnAddress`, effectively burning the card represented by `tokenID`
      */
    function transfer(address tokenHolder, uint tokenID, bool isHPCCard) internal {
        try nftnyc.safeTransferFrom(tokenHolder, burnAddress, tokenID) {
            emit Log("Transfer Ok");
            if (isHPCCard){
                incrementHPCClaimCards(tokenHolder);
            } else {
                incrementSwagBoxCards(tokenHolder);
            }

        } catch {
            emit Log("Transfer call failed");
        }
    }

    /**
      * @dev Register address of `tokenHolder`as allowed to mint.
      */
    function registerAddress(address tokenHolder) internal { 
        allowedToMint.push(tokenHolder);  
    }

    /**
      * @dev Add one HPC box minting slot(s) to `tokenHolder`
      */
    function incrementHPCClaimCards(address tokenHolder) internal {
        mints[tokenHolder].hpcclaimcards = mints[tokenHolder].hpcclaimcards + 1;
    }

    /**
      * @dev Add one Swag box minting slot(s) to `tokenHolder`
      */
    function incrementSwagBoxCards(address tokenHolder) internal {
        mints[tokenHolder].swagboxcards = mints[tokenHolder].swagboxcards + 1;
    }

    /**
      * @dev `Òwner only` function to switch the burn contract between ON & OFF
      */
    function changeBurnStatus(bool status) external onlyOwner {
        isBurning = status;
    }

    /**
      * @dev `Òwner only` function to add HPC box minting slot(s) to `tokenHolder`
      */
    function addHPCClaimCardsToAddress(address tokenHolder, uint amount) external onlyOwner {
        if (addressesRegistered[tokenHolder] == false){
            addressesRegistered[tokenHolder] = true;
            registerAddress(tokenHolder);
        }
        mints[tokenHolder].hpcclaimcards = mints[tokenHolder].hpcclaimcards + amount;
    }

    /**
      * @dev `Òwner only` function to add Swag box minting slot(s) to `tokenHolder`
      */
    function addSwagBoxCardsToAddress(address tokenHolder, uint amount) external onlyOwner {
        if (addressesRegistered[tokenHolder] == false){
            addressesRegistered[tokenHolder] = true;
            registerAddress(tokenHolder);
        }
        mints[tokenHolder].swagboxcards = mints[tokenHolder].swagboxcards + amount;
    }

    /**
      * @dev Log events
      */
    event Log(string message);
    event LogArray(uint[] message);
}