/**
 *Submitted for verification at polygonscan.com on 2023-01-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

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

library Strings {
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
}

contract MyFirstNFT is IERC721{
    mapping (address=>uint256) _balance;
    mapping (uint256=>address) _owner;
    mapping (uint256=>address) _approverForToken;
    mapping (address=>mapping(address=>bool)) _approverForAll;
    uint256 _counter;
    uint256 _collectionMaxItems;
    string _collectionName;
    string _collectionSymbol;
    string _collectionBaseURI;

    using Strings for uint256;

    constructor (string memory _name, string memory _symbol, string memory _baseURI, uint256 _maxItems){
        _collectionName=_name;
        _collectionSymbol=_symbol;
        _collectionBaseURI=_baseURI;
        _collectionMaxItems=_maxItems;
    }

    function balanceOf(address owner) public view returns (uint256 balance){
        return _balance[owner];
    }

    function name() public view returns (string memory){
        return _collectionName;
    }

    function symbol() external view returns (string memory){
        return _collectionSymbol;
    }

    function safeMint(address to) public {
        require(_counter<_collectionMaxItems,"Ya se han emitido todos los Token.");
        uint256 tokenId = getCurrentCounter();
        _owner[tokenId]=to;
        _balance[to]++;
        incCounter();
        require(_checkOnERC721Received(address(0),to,tokenId,""),"El recipiente no soporta NFTs");
        emit Transfer(address(0),to,tokenId);
    }

    function getCurrentCounter() internal view returns(uint256){
        return _counter;
    }

    function incCounter() internal{
        _counter++;
    }

    function ownerOf(uint256 tokenId) public view returns(address){
        return _owner[tokenId];
    }

    function burn(uint256 tokenId) public{
        address owner=_owner[tokenId];
        require(msg.sender==owner||_approverForToken[tokenId]==msg.sender||_approverForAll[owner][msg.sender],"No eres propietario del NFT o no tienes permiso.");
        _owner[tokenId]=address(0);
        _balance[owner]--;
        emit Transfer(owner,address(0),tokenId);
    }

    function safeTransferFrom(address from,address to,uint256 tokenId) public{
        safeTransferFrom(from,to,tokenId,"");
    }

    function safeTransferFrom(address from, address to,uint256 tokenId, bytes memory data) public{
        transferFrom(from,to,tokenId);
        require(_checkOnERC721Received(from,to,tokenId,data),"Recipiente no soporta NFT");
    }

    function approve(address operator, uint256 tokenId) public{        
        require(msg.sender!=operator,"No puedes darte permismos a ti mismo");
        require(msg.sender==_owner[tokenId],"No es propietario del NFT");
        _approverForToken[tokenId]=operator;
        emit Approval(msg.sender,operator,tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address){
        return _approverForToken[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public{
        address owner=_owner[tokenId];
        require(owner==from,"Token No pertenece al remitente indicado.");
        require(msg.sender==owner||_approverForToken[tokenId]==msg.sender||_approverForAll[owner][msg.sender],"No eres propietario del NFT o no tienes permiso.");
        _owner[tokenId]=to;
        _balance[from]--;
        _balance[to]++;
        emit Transfer(from,to,tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) public{
        require(msg.sender!=operator,"No puedes darte permisos a ti mismo");
        _approverForAll[msg.sender][operator]=_approved;
        emit ApprovalForAll(msg.sender,operator,_approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool){
        return _approverForAll[owner][operator];
    }

    function tokenURI(uint256 tokenId) public view returns(string memory){
        require(_owner[tokenId]!=address(0),"No existe Token.");
        return string(
            abi.encodePacked(_collectionBaseURI,tokenId.toString(),".json")
        );
    }

function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


}