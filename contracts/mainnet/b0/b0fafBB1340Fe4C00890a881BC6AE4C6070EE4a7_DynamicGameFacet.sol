// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// ERC721 Token 🎫 in Diamond Standard.
import "../tokens/ERC721Diamond.sol";
// LibERC721 📃 Allows For Helper Functions
import {LibERC721} from "../libraries/LibERC721.sol";
// Helper ⛑ we wrote to encode in Base64
import "../libraries/Base64.sol";
// LibDiamond 💎 Allows For Diamond Storage
import "../libraries/LibDiamond.sol";
// Structs imported from AppStorage
import {CharacterAttributes, BigBoss} from "../libraries/LibAppStorage.sol";
// Hardhat Console Debugging Easy
// import "hardhat/console.sol";


// @title NFT Based Mini Game
/// @author Shiva Shanmuganathan
/// @notice You can use this contract for implementing a simple NFT based game to change NFT Metadata
/// @dev All function calls are currently implemented without side effects
contract DynamicGameFacet is ERC721Diamond {


  // Events to show that a Minting & Attacking action has been completed 
  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp);


  // Data is passed in to the contract when it's first created initializing the characters.
  // We're going to actually pass these values in from from run.js.
  
    /// @notice Update Fee to mint the NFTs
    /// @dev Only the contract owner will be able to update the minting fee
    /// @param _fee The updated fee is passed by contract owner
    function updateFee(uint256 _fee) external {

        LibDiamond.enforceIsContractOwner();
        s.fee = _fee;

    }


  /// @notice Mints the NFT of the selected character
  /// @dev The payable function requires users to pay the fee amount to mint the NFT. 
  /// @param _characterIndex The index of the character the user chooses to Mint
  
  function mintCharacterNFT(uint _characterIndex) external payable{
    require(msg.value >= s.fee);
    uint256 newItemId = s._tokenIds;

    _safeMint(msg.sender, newItemId);

    s.nftHolderAttributes[newItemId] = CharacterAttributes({
      
      characterIndex: _characterIndex,
      name: s.defaultCharacters[_characterIndex].name,
      imageURI: s.defaultCharacters[_characterIndex].imageURI,
      hp: s.defaultCharacters[_characterIndex].hp,
      maxHp: s.defaultCharacters[_characterIndex].hp,
      attackDamage: s.defaultCharacters[_characterIndex].attackDamage,
      levels: s.defaultCharacters[_characterIndex].levels
      
    });

    // console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);  

    
    s.totalTokens = newItemId;
    s._tokenIds += 1;
    
    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);

  }


  /// @notice View Function that returns NFT Metadata of token as a string 
  /// @dev The tokenURI function is overridden to get character attributes and return the  json object as string
  /// @param _tokenId It is used to uniquely identify NFTs
  /// @return Returns the encoded json object as string
  /// @inheritdoc ERC721Diamond
  function tokenURI(uint256 _tokenId) public view override returns (string memory) 
  {
    CharacterAttributes memory charAttributes = s.nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(charAttributes.hp);
    string memory strMaxHp = Strings.toString(charAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

    string memory json = Base64.encode(

        abi.encodePacked(
          '{"name": "',
          charAttributes.name,
          ' -- NFT #: ',
          Strings.toString(_tokenId),
          '", "description": "An epic NFT", "image": "ipfs://',
          charAttributes.imageURI,
          '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ', strAttackDamage,'}, { "trait_type": "Levels", "value": "',charAttributes.levels,'"} ]}'          
        )
    );

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );
    
    return output;
  }


  /// @notice User with NFT can attack the Boss [Metadata Of NFT Changes Here]
  /// @dev The Health of Boss & User's NFT is reduced becuase of attack. [Metadata Of NFT Changes Here]
  /// The user's address is used to get the NFT the user owns
  /// Health of Boss & Hero is reduced due to fight  
  function attackBoss(uint tokenID) public {
    // Get the state of the player's NFT.
    
    // uint256 nftTokenIdOfPlayer = s.nftHolders[msg.sender][_index];
    require(s._owners[tokenID] == msg.sender, "Not NFT Owner");
    CharacterAttributes storage player = s.nftHolderAttributes[tokenID];

    // console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
    // console.log("Boss %s has %s HP and %s AD", s.bigBoss.name, s.bigBoss.hp, s.bigBoss.attackDamage);
    // Make sure the player has more than 0 HP.
    require (
      player.hp > 0,
      "Error: character must have HP to attack boss."
    );

    // Make sure the boss has more than 0 HP.
    require (
      s.bigBoss.hp > 0,
      "Error: boss must have HP to attack boss."
    );

    // Allow player to attack boss.
    if (s.bigBoss.hp < player.attackDamage) {
      s.bigBoss.hp = 0;
    } else {
      s.bigBoss.hp = s.bigBoss.hp - player.attackDamage;
    }

    // Allow boss to attack player.
    if (player.hp < s.bigBoss.attackDamage) {
      player.hp = 0;
    } else {
      player.hp = player.hp - s.bigBoss.attackDamage;
    }

    // Console for ease.
    // console.log("%s attacked Boss. Boss hp: %s\n", player.name, s.bigBoss.hp);
    // console.log("Boss attacked %s. %s hp: %s\n", player.name, player.name ,player.hp);
    emit AttackComplete(s.bigBoss.hp, player.hp);
  }


  /// @notice Function to check whether user owns an NFT
  /// @dev If the user has NFTs, Struct with Attributes of NFTs is returned 
  /// @dev If not, empty struct is returned when user does not have any NFTs
  /// @return A struct containing the Token's Attributes are returned 
  /// The address of message sender is used to get the tokenId
  //// The tokenId is then used to get the attributes of NFT 
  function checkIfUserHasNFT() public view returns (CharacterAttributes[] memory) {
    
    uint[] memory nftArray = LibERC721._tokensOfOwner(msg.sender);

    if(nftArray.length == 0){
      CharacterAttributes[] memory emptyStruct;
      return emptyStruct;
    }

    CharacterAttributes[] memory charArray = new CharacterAttributes[](nftArray.length);

    for(uint i=0; i<nftArray.length; i++){

        charArray[i] = s.nftHolderAttributes[nftArray[i]];

    }

    return charArray;

  }
  
  /// @notice View function to check the attributes of Boss
  /// @dev public view function that returns attributes of boss as struct
  /// @return A struct containing the attributes of Boss is returned
  function getBigBoss() public view returns (BigBoss memory) {
    
    return s.bigBoss;

  }

  /// @notice View function to get attributes of all default characters
  /// @dev public view function that returns attributes of all default characters as struct
  /// @return A struct containing the attributes of all default characters is returned
  function getAllDefaultCharacters() external view returns (CharacterAttributes[] memory) {

    return s.defaultCharacters;

  }


  /// @notice Withdraw function for contract owner to withdraw the funds
  /// @dev call function is used to transfer balance over transfer function due to security reasons
  /// enforceIsContractOwner is used to verify the contract owner
  function withdraw() external {

    LibDiamond.enforceIsContractOwner();
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");

  }

  /// @notice View function to get tokenIDs of user
  /// @dev external view function that returns all tokenIDs of user
  /// @return val is an array of tokenIDs owner by the user
  function nftHolders(address user) external view returns(uint256[] memory val) {

    return LibERC721._tokensOfOwner(user);

  }

  /// @notice View function to get characterAttributes of tokenID 
  /// @dev external view function that returns character attributes of tokenID
  /// @return CharacterAttributes of tokenID
  function nftHolderAttributes(uint256 tokenID) external view returns(CharacterAttributes memory) {

    return LibERC721.getNFTHolderAttributes(tokenID);

  }

  /// @notice View function to get total number of tokens 
  /// @dev external view function that returns total number of tokens
  /// @return val is total number of tokens as uint
  function totalTokens() external view returns(uint256 val) {

    val = s.totalTokens;

  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../libraries/LibAppStorage.sol";
import "../libraries/LibMeta.sol";
import "../libraries/LibERC721.sol";

import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

// Hardhat Console Debugging Easy
// import "../console.sol";

abstract contract ERC721Diamond is Context, ERC165, IERC721Enumerable {
    AppStorage internal s;
    using Address for address;
    using Strings for uint256;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721Enumerable).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IDiamondCut).interfaceId ||
        interfaceId == type(IDiamondLoupe).interfaceId ||
        interfaceId == type(IERC173).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return s._allTokens.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return LibERC721._tokenOfOwnerByIndex(owner, index);
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return s._allTokens[index];
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return LibERC721._balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return LibERC721._ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        
        require(to != owner, "ERC721: approval to current owner");
        
        
        require(
            LibMeta.msgSender() == owner || isApprovedForAll(owner, LibMeta.msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        

        LibERC721._approve(to, tokenId);
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return s._tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != LibMeta.msgSender(), "ERC721: approve to caller");

        s._operatorApprovals[LibMeta.msgSender()][operator] = approved;
        emit ApprovalForAll(LibMeta.msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return s._operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(LibMeta.msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        LibERC721._transfer(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(LibMeta.msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        LibERC721._safeTransfer(from, to, tokenId, _data);
        emit Transfer(from, to, tokenId);
    }

    // function _safeTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes memory _data
    // ) internal virtual {
    //     _transfer(from, to, tokenId);
    //     require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    // }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        // console.log("owner address: ",s._owners[tokenId]);
        return s._owners[tokenId] != address(0);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        // console.log("Checkpoint Reached");
        // console.log(tokenId);
        // console.log(exists(tokenId));
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        // console.log("Checkpoint Reached 2");
        address owner = ownerOf(tokenId);
        // console.log("owner address: ",owner);
        // console.log("user address: ",LibMeta.msgSender());
        // console.log("Checkpoint Reached 2");
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            LibERC721._checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        LibERC721._beforeTokenTransfer(address(0), to, tokenId);

        s._balances[to] += 1;
        s._owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        LibERC721._beforeTokenTransfer(owner, address(0), tokenId);

        LibERC721._approve(address(0), tokenId);

        s._balances[owner] -= 1;
        delete s._owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // function _transfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual {
    //     require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    //     require(to != address(0), "ERC721: transfer to the zero address");

    //     _beforeTokenTransfer(from, to, tokenId);

    //     _approve(address(0), tokenId);

    //     s._balances[from] -= 1;
    //     s._balances[to] += 1;
    //     s._owners[tokenId] = to;

    //     emit Transfer(from, to, tokenId);
    // }


    // function _approve(address to, uint256 tokenId) internal virtual {
    //     s._tokenApprovals[tokenId] = to;
    //     emit Approval(ownerOf(tokenId), to, tokenId);
    // }

    // function _checkOnERC721Received(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes memory _data
    // ) private returns (bool) {
    //     if (to.isContract()) {
    //         try IERC721Receiver(to).onERC721Received(LibMeta.msgSender(), from, tokenId, _data) returns (bytes4 retval) {
    //             return retval == IERC721Receiver.onERC721Received.selector;
    //         } catch (bytes memory reason) {
    //             if (reason.length == 0) {
    //                 revert("ERC721: transfer to non ERC721Receiver implementer");
    //             } else {
    //                 assembly {
    //                     revert(add(32, reason), mload(reason))
    //                 }
    //             }
    //         }
    //     } else {
    //         return true;
    //     }
    // }


    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual {
    //     if (from == address(0)) {
    //         _addTokenToAllTokensEnumeration(tokenId);
    //     } else if (from != to) {
    //         _removeTokenFromOwnerEnumeration(from, tokenId);
    //     }
    //     if (to == address(0)) {
    //         _removeTokenFromAllTokensEnumeration(tokenId);
    //     } else if (to != from) {
    //         _addTokenToOwnerEnumeration(to, tokenId);
    //     }
    // }

    // function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    //     uint256 length = balanceOf(to);
    //     s._ownedTokens[to][length] = tokenId;
    //     s._ownedTokensIndex[tokenId] = length;
    // }

    // function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    //     s._allTokensIndex[tokenId] = s._allTokens.length;
    //     s._allTokens.push(tokenId);
    // }

    // function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    //     uint256 lastTokenIndex = balanceOf(from) - 1;
    //     uint256 tokenIndex = s._ownedTokensIndex[tokenId];

    //     if (tokenIndex != lastTokenIndex) {
    //         uint256 lastTokenId = s._ownedTokens[from][lastTokenIndex];

    //         s._ownedTokens[from][tokenIndex] = lastTokenId;
    //         s._ownedTokensIndex[lastTokenId] = tokenIndex;
    //     }

    //     delete s._ownedTokensIndex[tokenId];
    //     delete s._ownedTokens[from][lastTokenIndex];
    // }

    // function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    //     uint256 lastTokenIndex = s._allTokens.length - 1;
    //     uint256 tokenIndex = s._allTokensIndex[tokenId];

    //     uint256 lastTokenId = s._allTokens[lastTokenIndex];

    //     s._allTokens[tokenIndex] = lastTokenId;
    //     s._allTokensIndex[lastTokenId] = tokenIndex;

    //     delete s._allTokensIndex[tokenId];
    //     s._allTokens.pop();
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library LibRentalStorage {

        struct RentalInfo {

            uint256 price;
            uint256 expiresAt;
            uint256 maxRental;
            address payable seller;
            address renter;
            bool isRented;
            
        }



        // This struct contains a mapping from TokenID to struct.
        struct RentalMarketData {
            // mapping of nftAddress to token id to StakeInfo   
            mapping(uint256 => RentalInfo) Rental;
        }

        // Returns the struct from a specified position in contract storage
        // ds is short for DiamondStorage
        function diamondStorage() internal pure returns(RentalMarketData storage ds) {
            // Specifies a random position from a hash of a string
            bytes32 storagePosition = keccak256("diamond.storage.LibRentalStorage");
            // Set the position of our struct in contract storage
            assembly {
                ds.slot := storagePosition
            }
        }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        sender_ = msg.sender;
    }

    function checkContains(uint256[] memory array, uint256 value) internal pure returns(bool){
        for(uint256 i = 0; i < array.length; i++){
            if(array[i] == value){
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./LibAppStorage.sol";
import "./LibMeta.sol";
import "./LibRentalStorage.sol";

import {CharacterAttributes, BigBoss} from "../libraries/LibAppStorage.sol";

// Hardhat Console Debugging Easy
// import "hardhat/console.sol";

library LibERC721 {
    using Address for address;

    function _tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            index < _balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return s._ownedTokens[owner][index];
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return s._balances[owner];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address owner = s._owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function _tokensOfOwner(
        address _owner
    ) internal view returns (uint256[] memory) {
        uint256 tokenCount = _balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = _tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // function fetchUserNFTs(address user) internal view returns(uint256[] memory) {

    //     uint256 length = _balanceOf(user);
    //     uint256[] memory val = new uint256[](length);
    //     AppStorage storage s = LibAppStorage.diamondStorage();
    //     for(uint i; i < length; i++){

    //        val[i] = s._ownedTokens[user][i];

    //     }

    //     return val;

    // }

    function getNFTHolderAttributes(
        uint256 tokenID
    ) internal view returns (CharacterAttributes memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.nftHolderAttributes[tokenID];
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(
            _ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        AppStorage storage s = LibAppStorage.diamondStorage();

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        s._balances[from] -= 1;
        s._balances[to] += 1;
        s._owners[tokenId] = to;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
        LibRentalStorage.RentalMarketData storage rss = LibRentalStorage
            .diamondStorage();
        LibRentalStorage.RentalInfo storage rental_asset = rss.Rental[tokenId];
        require(rental_asset.isRented == false, "NFT Already Rented.");
    }

    function _approve(address to, uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._tokenApprovals[tokenId] = to;
        // emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._allTokensIndex[tokenId] = s._allTokens.length;
        s._allTokens.push(tokenId);
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balanceOf(to);
        AppStorage storage s = LibAppStorage.diamondStorage();

        s._ownedTokens[to][length] = tokenId;
        s._ownedTokensIndex[tokenId] = length;
    }

    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lastTokenIndex = _balanceOf(from) - 1;
        uint256 tokenIndex = s._ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s._ownedTokens[from][lastTokenIndex];

            s._ownedTokens[from][tokenIndex] = lastTokenId;
            s._ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete s._ownedTokensIndex[tokenId];
        delete s._ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lastTokenIndex = s._allTokens.length - 1;
        uint256 tokenIndex = s._allTokensIndex[tokenId];

        uint256 lastTokenId = s._allTokens[lastTokenIndex];

        s._allTokens[tokenIndex] = lastTokenId;
        s._allTokensIndex[lastTokenId] = tokenIndex;

        delete s._allTokensIndex[tokenId];
        s._allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AppConstants {
    uint256 constant isTestMode = 1;
    uint256 constant publicPrice = 1000000000000000;
    uint256 constant dayInSeconds = 86400;
    uint256 constant hourInSeconds = 3600;
    uint256 constant minutesInSeconds = 60;
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;
}

// We'll hold our character's attributes in a struct.
struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
    string levels;
}

// We create a struct to keep track of bigBoss's attributes
struct BigBoss {
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
}

struct AppStorage {
    //ERC721
    string _name;
    string _symbol;
    mapping(uint256 => address) _owners;
    mapping(address => uint256) _balances;
    mapping(uint256 => address) _tokenApprovals;
    mapping(address => mapping(address => bool)) _operatorApprovals;
    //ERC721Enumerable
    mapping(address => mapping(uint256 => uint256)) _ownedTokens;
    mapping(uint256 => uint256) _ownedTokensIndex;
    uint256[] _allTokens;
    mapping(uint256 => uint256) _allTokensIndex;
    //ERC721URIStorage
    mapping(uint256 => string) _tokenURIs; //not used
    // The tokenId is the NFTs unique identifier, it's just a number that goes
    // 0, 1, 2, 3, etc.
    uint256 totalTokens;
    uint256 _tokenIds;
    // This array help us hold the default data for our characters.
    // This will be helpful when we mint new characters and need to know things like their HP, AD, etc.
    CharacterAttributes[] defaultCharacters;
    // We create a mapping from the nft's tokenId => that NFTs attributes.
    mapping(uint256 => CharacterAttributes) nftHolderAttributes;
    // bigBoss is the Bad Guy that our Heroes Fight against
    BigBoss bigBoss;
    // A fee to mint the Characterrs.
    uint256 fee;
    uint256 _status;
    string baseUri;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}