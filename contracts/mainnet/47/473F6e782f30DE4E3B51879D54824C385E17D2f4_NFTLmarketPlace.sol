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

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

/**
* @notice Using solidity 0.8.0 is not allowed notice on private elements, justo regular coments we had to use.
*/
interface INFTLatinoAmerica {
    /**
     * @notice Call the interface method to transfer an token
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;  
    /**
     * @notice  Call the interface method to gets the approved account for any token Id 
     */
    function getApproved(uint256 _tokenId) external view returns (address _approved);  
    /**
     * @notice  Call the interface method to gets the owner of any token Id
     */
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
}

contract NFTLmarketPlace is Ownable {

    using SafeMath for *;
    using Strings for *;

    //Porcentaje fee for resell, the contract start with 1 percent (100) and maximum 2.5 percent would be set
    uint256 private percentage = 100;

    /**
     * @notice NFT for sell structure 
     */
    struct nftSelling {
        bool status;
        uint256 price;
        uint256 percentage;
        address owner;
    }

    // Relating the token Id with the structure
    mapping(uint256 => nftSelling) private Nft_Selling;

    /**
     * @notice Filter only the tokens consigned by NFTLatinoAmerica contract to this NFTLmarketPlace contract
     * @param _NFT_Contract Contract address to be called
     * @param _tokenId The token Id that is going to check
     */
    modifier only_consigned(uint256 _tokenId, address _NFT_Contract) {
        address approved = INFTLatinoAmerica(_NFT_Contract).getApproved(_tokenId);
        require(approved == address(this), unicode"This NFT has not been consigned for Sale in this contract");
        _;
    } 

    /**
     * @notice Filter only nft owners
     * @param _NFT_Contract Contract address to be called
     * @param _tokenId The token Id that is going to filter
     */
    modifier onlyNFTowner(uint256 _tokenId, address _NFT_Contract) {
        require(_msgSender() == INFTLatinoAmerica(_NFT_Contract).ownerOf(_tokenId), unicode"You are not the Owner of this NFT");
        _;
    }

    /**
     * @notice call the NFT contrat to safeTranferFrom the NFT, the buyer will be just the msg_sender, 
     *         and have to have the MATICs amount available in order to the function continue flowing
     * @param _NFT_Contract contract address to be called
     * @param _tokenId the token Id that is going to buy
     */  
    function buy_NFT_consigned(address _NFT_Contract, uint256 _tokenId) public payable only_consigned(_tokenId, _NFT_Contract) {

        // Verifies that the NFT has all ready been set with a correct price
        require(see_NFT_value_wei(_NFT_Contract, _tokenId) > 0, unicode'This NFT has no price assigned by the Owner');

        // Verifies that the NFT has been placed for sale
        require(Nft_Selling[_tokenId].status == true, 'The NFT has not been placed for Sale');

        // Obtain the NFT value given by the owner in the INFTLatinoAmerica colection contract
        uint256 value = see_NFT_value_wei(_NFT_Contract, _tokenId);

        // Filter the MATICs sent by the transaction
        require(msg.value == value, unicode"Please send the correct amount of MATICs");

        // Obtaining the address involved in the transacction
        address nft_owner_address = INFTLatinoAmerica(_NFT_Contract).ownerOf(_tokenId); 
        address buyer_address = _msgSender();
        address seller_address = owner();

        // Check if the buyer is not the owner
        require(buyer_address != nft_owner_address, unicode"You can't buy your own NFTs");

        // Obtaining the payment distribution
        (bool stdo_mul, uint256 seller_amount) = value.tryDiv(Nft_Selling[_tokenId].percentage);
        (bool stdo_sub, uint256 nft_owner_amount) =  value.trySub(seller_amount);

        // Security filters
        require(stdo_mul && stdo_sub && seller_amount.add(nft_owner_amount) == value, unicode"Invalid Arithmetic");

        // Pay the MATICs to the owner token
        payable(nft_owner_address).transfer(nft_owner_amount);
 
        // Pay the MATICs to the seller, just a percentage specified
        payable(seller_address).transfer(seller_amount);

        // Sets the selling status false
        Nft_Selling[_tokenId].status == false;

        // Transfer the token to the new owner
        INFTLatinoAmerica(_NFT_Contract).safeTransferFrom(nft_owner_address, buyer_address, _tokenId);
    }

    /**
     * @notice Sets the NFT price only by the owner
     * @param _NFT_Contract contract address to be called
     * @param _new_Gwei_value contract address to be called
     * @param _tokenId the token Id that is going to set
     */  
    function Set_NFT_value_Gwei(address _NFT_Contract, uint256 _new_Gwei_value, uint256 _tokenId) public onlyNFTowner(_tokenId, _NFT_Contract) {
        // requires the NFT value given by the creator to be more than zero. 1000000000 is 1 Gwei and 1000000 Gwei is equal to 0.001 ETH
        require(_new_Gwei_value > 1000000, "You must give a price more than 0.001 MATICs");
        // convert Gwai to wei
        (bool stdo_mul, uint256 new_wei_value) = _new_Gwei_value.tryMul(10**9);
        // verify the arithmetic
        require(stdo_mul == true, unicode"Invalid Arithmetic, enter a price");
        // sets the price sale and new owner information
        Nft_Selling[_tokenId] = nftSelling(true, new_wei_value, percentage, _msgSender());
    }

    /**
     * @notice See the NFT price
     * @param _NFT_Contract contract address to be called
     * @param _tokenId the token Id that is going to check
     */  
    function see_NFT_value_wei(address _NFT_Contract, uint256 _tokenId) public view only_consigned(_tokenId, _NFT_Contract) returns(uint256 price_wei) {
        // verifies that the NFT has not been sold
        if(INFTLatinoAmerica(_NFT_Contract).ownerOf(_tokenId) != Nft_Selling[_tokenId].owner){
            return 0;
        }
        // requires the a new owner have to set a new price
        if(Nft_Selling[_tokenId].status != true){
            return 0;
        }
        // verifies that the NFT has not been sold
        require(Nft_Selling[_tokenId].status == true, 'The NFT has not been assigned a Sale price');
        // requires the a new owner have to set a new price
        require(INFTLatinoAmerica(_NFT_Contract).ownerOf(_tokenId) == Nft_Selling[_tokenId].owner, unicode'As a new owner you must assign a sale price');
        return Nft_Selling[_tokenId].price;
    }

    /**
     * @notice Sets the fee percentage for resell, the contract start with 1 percent and maximum 2.5 percent would be set
     * @param _percentage The new percent to be charged
     */  
    function setPercentage(uint256 _percentage) public onlyOwner {
        require(_percentage >= 40 && _percentage <= 100, 'The percentage must be more than 1 percent and less than 2.5 percent');
        percentage = _percentage;
    }

    /**
     * @notice See the percentage specified
     */  
    function seePercentage() public view returns(uint256 percent_) {
        return percentage;
    }
}