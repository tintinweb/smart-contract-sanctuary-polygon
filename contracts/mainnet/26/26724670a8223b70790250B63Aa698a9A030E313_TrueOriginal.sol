/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    /*
    * @dev Provides information about the current execution context, including the
    * sender of the transaction and its data. While these are generally available
    * via msg.sender and msg.data, they should not be accessed in such a direct
    * manner, since when dealing with GSN meta-transactions the account sending and
    * paying for execution may not be the actual sender (as far as an application
    * is concerned).
    *
    * This contract is only required for intermediate, library-like contracts.
    */
    contract Context {
        // Empty internal constructor, to prevent people from mistakenly deploying
        // an instance of this contract, which should be used via inheritance.
        constructor () { }
        // solhint-disable-previous-line no-empty-blocks

        function _msgSender() internal view returns (address )  {
            return msg.sender;
        }

        function _msgData() internal view returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }



    /**
    * @dev Contract module which provides a basic access control mechanism, where
    * there is an account (an owner) that can be granted exclusive access to
    * specific functions.
    *
    * This module is used through inheritance. It will make available the modifier
    * `onlyOwner`, which can be applied to your functions to restrict their use to
    * the owner.
    */
    contract Ownable is Context {
        address private _owner;

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        /**
        * @dev Initializes the contract setting the deployer as the initial owner.
        */
        constructor () {
            address msgSender = _msgSender();
            _owner = msgSender;
            emit OwnershipTransferred(address(0), msgSender);
        }

        /**
        * @dev Returns the address of the current owner.
        */
        function owner() public view returns (address) {
            return _owner;
        }

        /**
        * @dev Throws if called by any account other than the owner.
        */
        modifier onlyOwner() {
            require(isOwner(), "Ownable: caller is not the owner");
            _;
        }

        /**
        * @dev Returns true if the caller is the current owner.
        */
        function isOwner() public view returns (bool) {
            return _msgSender() == _owner;
        }


        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
        */
        function transferOwnership(address newOwner) public onlyOwner {
            _transferOwnership(newOwner);
        }

        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        */
        function _transferOwnership(address newOwner) internal {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }
    }




    /**
    * @title TRUE Original version 2.0
    * @notice Contract is not payable.
    * Owner can add document tokens.
    * This contact belongs to:
    *
    * ::  TRUE  ::
    * :: VERIFY ::
    * 
    *
    */
    contract TrueOriginal is Ownable {
        
        //Token struct
        struct Token {
            uint256     tokenId; 
            bytes32     tokenHash;
            uint64      tokenExpires; 
            uint64      issuedOn;
            string      tokenURI;
        }
        
        //Array containing all token
        mapping (uint256 => Token) tokens;
    
        //Holds the mapping for token ids
        mapping (uint256 => bool) tokenIds;
    
        //Emit Event for new tokens
        event NewToken(uint256 tokenId);
        event TokenExists(uint256 tokenId);
        
        function _baseURI() internal view virtual returns (string memory) {
            return 'https://meta.trueoriginal.com/';
        }
        
    
        function addToken(uint256 _tokenId, bytes32  _tokenHash, uint64 _tokenExpires, uint64 _issuedOn, string memory _tokenURI)  onlyOwner  public{ 
            if(!tokenIds[_tokenId]){
                tokenIds[_tokenId] = true;
                tokens[_tokenId] = Token(_tokenId,_tokenHash,_tokenExpires,_issuedOn,_tokenURI);
                emit NewToken(_tokenId);
            }else{
                emit TokenExists(_tokenId);
            }
        }
        
    
        function addManyTokens(uint256[] memory _tokenId, bytes32[] memory _tokenHash, uint64[] memory _tokenExpires, uint64[] memory _issuedOn, string[] memory _tokenURI)  onlyOwner  public{ 
            for (uint256 i = 0; i < _tokenId.length; i++) {
            addToken(_tokenId[i],_tokenHash[i],_tokenExpires[i],_issuedOn[i],_tokenURI[i]);
            } 
        }

        
        function getToken(uint256 _tokenId) public view returns (bytes32,uint64,uint64,string memory) {
            require(tokenIds[_tokenId], "getToken: _tokenId is not found");
            return (tokenHash(_tokenId),tokenExpires(_tokenId),tokenIssuedOn(_tokenId),tokenURI(_tokenId));
        }
        

        function tokenURI(uint256 _tokenId) public view returns (string memory) {
            require(tokenIds[_tokenId], "getTokenURI: _tokenId is not found");

            string memory URI   = tokens[_tokenId].tokenURI;
            string memory base  = _baseURI();

            // If there is no base URI, return the token URI.
            if (bytes(base).length == 0) {
                return URI;
            }
            // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            if (bytes(URI).length > 0) {
                return string(abi.encodePacked(base, URI));
            }

            return tokens[_tokenId].tokenURI;
        }


        
        
        function tokenHash(uint256 _tokenId) public view returns (bytes32) {
            require(tokenIds[_tokenId], "getTokenHash: _tokenId is not found");
            return tokens[_tokenId].tokenHash;
        }
        
        function tokenExpires(uint256 _tokenId) public view returns (uint64) {
            require(tokenIds[_tokenId], "getTokenExpires: _tokenId is not found");
            return tokens[_tokenId].tokenExpires;
        }
        
        function tokenIssuedOn(uint256 _tokenId) public view returns (uint64) {
            require(tokenIds[_tokenId], "getTokenIssuedOn: _tokenId is not found");
            return tokens[_tokenId].issuedOn;
        }    
    }