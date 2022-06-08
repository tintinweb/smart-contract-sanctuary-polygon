// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CONTRACTS/ERC165.sol";
import "./INTERFACES/IERC721.sol";
import "./INTERFACES/IERC721Receiver.sol";

contract Token721 is ERC165, IERC721{
    //Cual es la address dueña del token.
    mapping(uint256 => address) private owners;
    //Cuantos tokens tiene un address.
    mapping(address => uint256) private balances;
    //Regulacion de los tokens con las address aprovadas para su gestion.
    mapping(uint256 => address) private tokenApprovals;
    //Relacion de address que pueden gestionar todos los tokens de otras address.
    mapping(address => mapping(address => bool)) private operatorApprovals; 

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool){
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    //INICIO MINTEADO DEL NFT
    function _safeMint(address to, uint256 tokenId) public{
        _safeMint(to, tokenId,"");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) public{
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0),to, tokenId, _data), "ERC721 ERROR: transfer to non ERC721Receiver implementer");
    }

    //Cuando el nombre del metodo empieza por barrabaja (_myFunction() ) la nomenclatura dice q es un metodo interno.
    //Virtual significa que el metodo no esta completamente implementado y sirve para heredar.
    function _mint(address to, uint256 tokenId) internal virtual{
        require(to != address(0), "ERC721 ERROR: minto to the zero address");
        require(!_exists(tokenId),"ERC721 ERROR: token already minted");

        _beforeTokenTransfer(address(0),to,tokenId);
        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(address(0),to, tokenId);
    }
    //FIN MINTEADO DEL NFT

    //INICIO METODOS IERC721
    function balanceOf(address owner) public view virtual override returns (uint256){
        require(owner!=address(0), "ERC721 ERROR: Zero address");
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address){
        address owner = owners[tokenId];
        require(owner != address(0), "ERC721 ERROR: Token id does not exist");
        return owner;
    } 

    function approve(address to, uint256 tokenId) public virtual override{
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721 ERROR: Destination address must be different from Origin address");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721 ERROR: Netiher you are the owner nor you have permissions");
        _approve(to, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool){
        return operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override{
        require(operator != msg.sender, "ERC721 ERROR: Operator address must be different");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address){
        require(_exists(tokenId), "ERC721 ERROR: Token id does not exists");
        return tokenApprovals[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override{
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721 ERROR: You are not the owner or you do not have permissions");
        _transfer(from,to,tokenId);
    } 

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override{
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override{
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721 ERROR: You are not the owner or you do not have permissions");
        _safeTransfer(from, to, tokenId, _data);
    }
    //FIN METODOS IERC721

    function isContract(address addr) private view returns (bool){
        uint32 size;
        assembly{
            size := extcodesize(addr)
        }
        return (size>0);
    }
    
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual{
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data),"ERC721 ERROR: transfer to non ERC721Receiver implementer");
    }

    function _approve(address to, uint256 tokenId) internal virtual{
        tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool){
        if(isContract(to)){
            try IERC721Receiver(to).onERC721Receiver(msg.sender, from, tokenId, _data) returns (bytes4 retval){
                return retval == IERC721Receiver(to).onERC721Receiver.selector;
            }catch(bytes memory reason){
                if(reason.length == 0){
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }else{
                    assembly{
                        revert(add(32,reason), mload(reason))
                    }
                }
            }
        }else{
            return true;
        }
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool){
        return owners[tokenId] != address(0);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual{}

    function _transfer(address from, address to, uint256 tokenId) internal virtual{
        require(ownerOf(tokenId) == from, "ERC721 ERROR: Token id does not exists");
        require(to != address(0), "ERC721 ERROR: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        balances[from]-=1;
        balances[to]+=1;
        owners[tokenId]=to;
        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool){
        require(_exists(tokenId), "ERC721 ERROR: Token id does not exists");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../INTERFACES/IERC165.sol";

abstract contract ERC165 is IERC165{
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC721 is IERC165{
    event Transfer(address indexed from,address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Receiver{
    //Comprueba que el contrato/wallet que vaya a recibir el NFT sea compatible con el estandar.
    function onERC721Receiver(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC165mapping is IERC165{
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor(){
        supportedInterfaces[this.supportsInterface.selector] = true;
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool){
        return supportedInterfaces[interfaceId];
    }
}

interface Numbers{
    function setNumber(uint256 _num) external;
    function getNumber() external view returns(uint256);
}

contract NumbersRooms is ERC165mapping, Numbers{
    uint256 num;

    constructor(){
        supportedInterfaces[this.setNumber.selector ^ this.getNumber.selector] = true;
    }

    function setNumber(uint256 _num) external override{
        num = _num;
    }

    function getNumber() external override view returns(uint256){
        return num;
    }
}